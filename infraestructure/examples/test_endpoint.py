#!/usr/bin/env python3
"""
SageMaker Endpoint Testing Script

This script provides utilities to test and monitor your deployed SageMaker endpoints.
It supports multiple frameworks and includes examples for common use cases.

Usage:
    python test_sagemaker_endpoint.py --endpoint-name my-endpoint --payload data.json
    python test_sagemaker_endpoint.py --endpoint-name my-endpoint --interactive
    python test_sagemaker_endpoint.py --endpoint-name my-endpoint --batch data.csv
"""

import json
import argparse
import sys
import csv
from typing import Dict, Any, List
from pathlib import Path

import boto3
import numpy as np
from datetime import datetime


class SageMakerEndpointTester:
    """Helper class to test SageMaker endpoints"""

    def __init__(self, endpoint_name: str, region: str = "us-east-1"):
        """Initialize the tester with endpoint details"""
        self.endpoint_name = endpoint_name
        self.region = region
        self.client = boto3.client("sagemaker-runtime", region_name=region)
        self.sm_client = boto3.client("sagemaker", region_name=region)

    def get_endpoint_info(self) -> Dict[str, Any]:
        """Get information about the endpoint"""
        response = self.sm_client.describe_endpoint(EndpointName=self.endpoint_name)
        return {
            "name": response["EndpointName"],
            "status": response["EndpointStatus"],
            "instance_type": response["ProductionVariants"][0]["InstanceType"],
            "instance_count": response["ProductionVariants"][0]["CurrentInstanceCount"],
            "creation_time": response["CreationTime"].isoformat(),
            "last_modified": response["LastModifiedTime"].isoformat(),
        }

    def invoke_endpoint_json(self, payload: Dict[str, Any]) -> Dict[str, Any]:
        """Invoke endpoint with JSON payload"""
        try:
            response = self.client.invoke_endpoint(
                EndpointName=self.endpoint_name,
                ContentType="application/json",
                Body=json.dumps(payload),
            )
            result = json.loads(response["Body"].read().decode())
            return {"success": True, "predictions": result, "latency": response.get("ResponseMetadata", {}).get("HTTPHeaders", {}).get("date")}
        except Exception as e:
            return {"success": False, "error": str(e)}

    def invoke_endpoint_csv(self, payload: str) -> Dict[str, Any]:
        """Invoke endpoint with CSV payload"""
        try:
            response = self.client.invoke_endpoint(
                EndpointName=self.endpoint_name,
                ContentType="text/csv",
                Body=payload,
            )
            result = response["Body"].read().decode()
            return {"success": True, "predictions": result}
        except Exception as e:
            return {"success": False, "error": str(e)}

    def batch_invoke(self, payloads: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Invoke endpoint with multiple payloads"""
        results = []
        for i, payload in enumerate(payloads):
            print(f"Processing batch item {i + 1}/{len(payloads)}...", end="\r")
            result = self.invoke_endpoint_json(payload)
            results.append(result)
        print(f"Processing batch item {len(payloads)}/{len(payloads)}... ✓")
        return results


def main():
    parser = argparse.ArgumentParser(
        description="Test AWS SageMaker endpoints",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    parser.add_argument(
        "--endpoint-name",
        required=True,
        help="Name of the SageMaker endpoint to test",
    )
    parser.add_argument(
        "--region",
        default="us-east-1",
        help="AWS region (default: us-east-1)",
    )
    parser.add_argument(
        "--payload",
        help="JSON file containing the test payload",
    )
    parser.add_argument(
        "--data",
        help="Path to data file (JSON or CSV)",
    )
    parser.add_argument(
        "--interactive",
        action="store_true",
        help="Interactive mode - enter payloads manually",
    )
    parser.add_argument(
        "--info",
        action="store_true",
        help="Display endpoint information",
    )
    parser.add_argument(
        "--batch",
        help="Batch file with multiple payloads (JSON lines format)",
    )
    parser.add_argument(
        "--output",
        help="Output file to save results (JSON)",
    )

    args = parser.parse_args()

    tester = SageMakerEndpointTester(args.endpoint_name, args.region)

    try:
        # Display endpoint info if requested
        if args.info or (not args.payload and not args.interactive and not args.batch):
            print("\n📊 Endpoint Information:")
            print("-" * 60)
            info = tester.get_endpoint_info()
            for key, value in info.items():
                print(f"  {key:.<30} {value}")
            print("-" * 60 + "\n")

        # Single payload test
        if args.payload:
            print("📤 Loading payload from file...")
            with open(args.payload, "r") as f:
                payload = json.load(f)

            print(f"⏱️  Invoking endpoint '{args.endpoint_name}'...")
            result = tester.invoke_endpoint_json(payload)

            if result["success"]:
                print("✅ Success!")
                print("\n📥 Response:")
                print(json.dumps(result["predictions"], indent=2))
            else:
                print(f"❌ Error: {result['error']}")
                sys.exit(1)

            if args.output:
                with open(args.output, "w") as f:
                    json.dump(result, f, indent=2)
                print(f"\n💾 Results saved to {args.output}")

        # Interactive mode
        elif args.interactive:
            print("🔄 Interactive Mode (press Ctrl+C to exit)")
            print("-" * 60)
            counter = 1
            try:
                while True:
                    print(f"\nRequest #{counter}:")
                    print("Enter JSON payload (or 'quit' to exit):")
                    user_input = input("> ").strip()

                    if user_input.lower() == "quit":
                        print("Exiting interactive mode.")
                        break

                    try:
                        payload = json.loads(user_input)
                    except json.JSONDecodeError:
                        print("❌ Invalid JSON. Please try again.")
                        continue

                    print(f"⏱️  Invoking endpoint...")
                    result = tester.invoke_endpoint_json(payload)

                    if result["success"]:
                        print("✅ Response:")
                        print(json.dumps(result["predictions"], indent=2))
                    else:
                        print(f"❌ Error: {result['error']}")

                    counter += 1
            except KeyboardInterrupt:
                print("\n\nExiting interactive mode.")

        # Batch mode
        elif args.batch:
            print(f"📂 Loading batch data from {args.batch}...")
            payloads = []

            with open(args.batch, "r") as f:
                for line in f:
                    payloads.append(json.loads(line.strip()))

            print(f"📊 Processing {len(payloads)} payloads...")
            results = tester.batch_invoke(payloads)

            # Summary
            successful = sum(1 for r in results if r["success"])
            failed = len(results) - successful

            print(f"\n📈 Batch Results:")
            print(f"  ✅ Successful: {successful}")
            print(f"  ❌ Failed: {failed}")

            if args.output:
                with open(args.output, "w") as f:
                    json.dump(results, f, indent=2)
                print(f"\n💾 Results saved to {args.output}")

    except FileNotFoundError as e:
        print(f"❌ File not found: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        sys.exit(1)


# Example payloads for different frameworks
EXAMPLE_PAYLOADS = {
    "pytorch": {
        "instances": [[1.0, 2.0, 3.0, 4.0], [5.0, 6.0, 7.0, 8.0]],
    },
    "tensorflow": {
        "instances": [[1.0, 2.0, 3.0, 4.0]],
    },
    "xgboost": {
        "instances": [[1.0, 2.0, 3.0, 4.0, 5.0]],
    },
    "sklearn": {
        "instances": [[1.0, 2.0, 3.0, 4.0]],
    },
}


def create_example_payload(framework: str, output_file: str = "example_payload.json"):
    """Create an example payload for a framework"""
    if framework not in EXAMPLE_PAYLOADS:
        print(f"❌ Unknown framework: {framework}")
        print(f"Available: {', '.join(EXAMPLE_PAYLOADS.keys())}")
        sys.exit(1)

    payload = EXAMPLE_PAYLOADS[framework]
    with open(output_file, "w") as f:
        json.dump(payload, f, indent=2)
    print(f"✅ Example payload created: {output_file}")


if __name__ == "__main__":
    # If no arguments provided, show help
    if len(sys.argv) == 1:
        import subprocess

        subprocess.run([sys.executable, __file__, "--help"])
    else:
        main()
