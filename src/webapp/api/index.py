import json
import os
import boto3
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource("dynamodb")
TABLE_NAME = os.environ.get("DYNAMODB_TABLE", "biti-predictions-dev")
table = dynamodb.Table(TABLE_NAME)


def handler(event, context):
    headers = {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET,OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type",
    }

    if event.get("httpMethod") == "OPTIONS":
        return {"statusCode": 200, "headers": headers, "body": ""}

    params = event.get("queryStringParameters") or {}
    symbol = params.get("symbol")
    limit = min(int(params.get("limit", 50)), 500)

    try:
        if symbol:
            resp = table.query(
                KeyConditionExpression=Key("symbol").eq(symbol),
                ScanIndexForward=False,
                Limit=limit,
            )
        else:
            resp = table.scan(Limit=limit)

        items = resp.get("Items", [])
        # Convert Decimal to float for JSON serialization
        items = json.loads(json.dumps(items, default=str))

        return {
            "statusCode": 200,
            "headers": headers,
            "body": json.dumps({"count": len(items), "items": items}),
        }
    except Exception as e:
        return {
            "statusCode": 500,
            "headers": headers,
            "body": json.dumps({"error": str(e)}),
        }
