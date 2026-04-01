import json
import os
import math
import boto3
from urllib.request import urlopen
from urllib.parse import urlencode
from datetime import datetime

ENDPOINT_NAME = os.environ.get("ENDPOINT_NAME", "bitcoin-direction-classifier-v1")
BINANCE_URL = "https://api.binance.us/api/v3/klines"
SYMBOL = "BTCUSDT"
INTERVAL = "5m"
LIMIT = 100

runtime = boto3.client("sagemaker-runtime")


def feature_engineering(candles):
    """Replicates the 'Pro' features using only built-in math."""
    closes = [float(c[4]) for c in candles]
    opens = [float(c[1]) for c in candles]
    highs = [float(c[2]) for c in candles]
    lows = [float(c[3]) for c in candles]
    volumes = [float(c[5]) for c in candles]
    timestamps = [int(c[0]) for c in candles]

    i = len(candles) - 1

    # Wicks
    oc_max = max(opens[i], closes[i])
    oc_min = min(opens[i], closes[i])
    upper_wick = (highs[i] - oc_max) / closes[i]
    lower_wick = (oc_min - lows[i]) / closes[i]

    # RSI (14-period)
    gains, losses = [], []
    for j in range(len(closes) - 14, len(closes)):
        delta = closes[j] - closes[j - 1]
        gains.append(delta if delta > 0 else 0)
        losses.append(-delta if delta < 0 else 0)
    avg_gain = sum(gains) / 14
    avg_loss = sum(losses) / 14
    rsi = 100 if avg_loss == 0 else 100 - (100 / (1 + avg_gain / avg_loss))

    # Volume change (log1p diff)
    volume_change = math.log1p(volumes[i]) - math.log1p(volumes[i - 1])

    # Cyclical time features
    dt = datetime.utcfromtimestamp(timestamps[i] / 1000)
    hour = dt.hour
    dow = dt.weekday()
    hour_sin = math.sin(2 * math.pi * hour / 24)
    hour_cos = math.cos(2 * math.pi * hour / 24)
    day_sin = math.sin(2 * math.pi * dow / 7)
    day_cos = math.cos(2 * math.pi * dow / 7)

    return [upper_wick, lower_wick, rsi, volume_change, hour_sin, hour_cos, day_sin, day_cos]


def handler(event, context):
    try:
        # 1. Fetch candles from Binance
        params = urlencode({"symbol": SYMBOL, "interval": INTERVAL, "limit": LIMIT})
        with urlopen(f"{BINANCE_URL}?{params}") as resp:
            candles = json.loads(resp.read())

        # 2. Feature engineering
        features = feature_engineering(candles)

        # 3. Invoke SageMaker endpoint
        payload = ",".join(str(v) for v in features)
        sm_response = runtime.invoke_endpoint(
            EndpointName=ENDPOINT_NAME,
            ContentType="text/csv",
            Body=payload,
        )

        # 4. Parse prediction
        prediction_prob = float(sm_response["Body"].read().decode())
        direction = "UP" if prediction_prob > 0.5 else "DOWN"

        result = {
            "symbol": SYMBOL,
            "timestamp": str(datetime.utcnow()),
            "probability_up": round(prediction_prob, 4),
            "prediction_5_mins": direction,
        }
        print(f"Inference Result: {result}")

        return {"statusCode": 200, "body": json.dumps(result)}

    except Exception as e:
        print(f"Error: {str(e)}")
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}
