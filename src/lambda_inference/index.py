import json
import os
import math
import boto3
from urllib.request import urlopen
from urllib.parse import urlencode
from datetime import datetime
from boto3.dynamodb.conditions import Key

ENDPOINT_NAME = os.environ.get("ENDPOINT_NAME", "bitcoin-direction-classifier")
DYNAMODB_TABLE = os.environ.get("DYNAMODB_TABLE", "biti-predictions-dev")
BINANCE_URL = "https://api.binance.us/api/v3/klines"
SYMBOL = "BTCUSDT"
INTERVAL = "5m"
LIMIT = 100

sagemaker_runtime = boto3.client("sagemaker-runtime")
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(DYNAMODB_TABLE)


def feature_engineering(candles):
    """Replicates the 'Pro' features using only built-in math."""
    closes = [float(c[4]) for c in candles]
    opens = [float(c[1]) for c in candles]
    highs = [float(c[2]) for c in candles]
    lows = [float(c[3]) for c in candles]
    volumes = [float(c[5]) for c in candles]
    timestamps = [int(c[0]) for c in candles]

    # Use second-to-last candle (last fully closed candle)
    i = len(candles) - 2

    oc_max = max(opens[i], closes[i])
    oc_min = min(opens[i], closes[i])
    upper_wick = (highs[i] - oc_max) / closes[i]
    lower_wick = (oc_min - lows[i]) / closes[i]

    gains, losses = [], []
    for j in range(len(closes) - 14, len(closes)):
        delta = closes[j] - closes[j - 1]
        gains.append(delta if delta > 0 else 0)
        losses.append(-delta if delta < 0 else 0)
    avg_gain = sum(gains) / 14
    avg_loss = sum(losses) / 14
    rsi = 100 if avg_loss == 0 else 100 - (100 / (1 + avg_gain / avg_loss))

    volume_change = math.log1p(volumes[i]) - math.log1p(volumes[i - 1])

    dt = datetime.utcfromtimestamp(timestamps[i] / 1000)
    hour_sin = math.sin(2 * math.pi * dt.hour / 24)
    hour_cos = math.cos(2 * math.pi * dt.hour / 24)
    day_sin = math.sin(2 * math.pi * dt.weekday() / 7)
    day_cos = math.cos(2 * math.pi * dt.weekday() / 7)

    features = [upper_wick, lower_wick, rsi, volume_change, hour_sin, hour_cos, day_sin, day_cos]
    close = closes[i]
    candle_open_time = datetime.utcfromtimestamp(timestamps[i] / 1000).isoformat()

    return features, close, candle_open_time


def validate_previous_prediction(current_close):
    """Validate the last prediction against the current close price."""
    resp = table.query(
        KeyConditionExpression=Key("symbol").eq(SYMBOL),
        ScanIndexForward=False,
        Limit=1,
    )
    items = resp.get("Items", [])
    if not items:
        return

    prev = items[0]
    prev_close = float(prev["close"])
    actual_direction = "UP" if current_close > prev_close else "DOWN"

    table.update_item(
        Key={"symbol": prev["symbol"], "timestamp": prev["timestamp"]},
        UpdateExpression="SET actual_direction = :ad, prediction_correct = :pc, price_change = :ch",
        ExpressionAttributeValues={
            ":ad": actual_direction,
            ":pc": prev["prediction"] == actual_direction,
            ":ch": str(round(current_close - prev_close, 2)),
        },
    )


def handler(event, context):
    try:
        # 1. Fetch candles from Binance
        params = urlencode({"symbol": SYMBOL, "interval": INTERVAL, "limit": LIMIT})
        with urlopen(f"{BINANCE_URL}?{params}") as resp:
            candles = json.loads(resp.read())

        # 2. Feature engineering
        features, close, candle_open_time = feature_engineering(candles)

        # 3. Validate previous prediction
        validate_previous_prediction(close)

        # 4. Invoke SageMaker endpoint
        payload = ",".join(str(v) for v in features)
        sm_response = sagemaker_runtime.invoke_endpoint(
            EndpointName=ENDPOINT_NAME,
            ContentType="text/csv",
            Body=payload,
        )

        # 5. Parse prediction
        prediction_prob = float(sm_response["Body"].read().decode())
        direction = "UP" if prediction_prob > 0.5 else "DOWN"
        ts = datetime.utcnow().isoformat()

        # 6. Store in DynamoDB
        item = {
            "symbol": SYMBOL,
            "timestamp": ts,
            "candle_open_time": candle_open_time,
            "close": str(close),
            "prediction": direction,
            "probability_up": str(round(prediction_prob, 4)),
        }
        table.put_item(Item=item)

        return {"statusCode": 200, "body": json.dumps(item)}

    except Exception as e:
        print(f"Error: {str(e)}")
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}
