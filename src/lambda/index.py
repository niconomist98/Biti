import json
import os
import boto3
from datetime import datetime, timedelta
from urllib.request import urlopen

s3 = boto3.client("s3")
BUCKET = os.environ.get("S3_BUCKET", "biti-data-dev")
BINANCE_URL = "https://api.binance.us/api/v3/klines"
SYMBOL = "BTCUSDT"
INTERVAL = "5m"
DAYS = 7
LIMIT = 1000


def fetch_klines(start_ms, end_ms):
    all_klines = []
    current = start_ms

    while current < end_ms:
        url = f"{BINANCE_URL}?symbol={SYMBOL}&interval={INTERVAL}&startTime={current}&endTime={end_ms}&limit={LIMIT}"
        with urlopen(url) as resp:
            batch = json.loads(resp.read())

        if not batch:
            break

        all_klines.extend(batch)
        current = batch[-1][6] + 1  # close_time + 1ms

    return all_klines


def parse_klines(raw):
    return [
        {
            "open_time": k[0],
            "open": float(k[1]),
            "high": float(k[2]),
            "low": float(k[3]),
            "close": float(k[4]),
            "volume": float(k[5]),
            "close_time": k[6],
            "quote_volume": float(k[7]),
            "trades": k[8]
        }
        for k in raw
    ]


def handler(event, context):
    now = datetime.utcnow()
    end_ms = int(now.timestamp() * 1000)
    start_ms = int((now - timedelta(days=DAYS)).timestamp() * 1000)

    raw = fetch_klines(start_ms, end_ms)
    klines = parse_klines(raw)

    record = {
        "symbol": SYMBOL,
        "interval": INTERVAL,
        "days": DAYS,
        "data_points": len(klines),
        "start": datetime.utcfromtimestamp(start_ms / 1000).isoformat() + "Z",
        "end": datetime.utcfromtimestamp(end_ms / 1000).isoformat() + "Z",
        "fetched_at": now.isoformat() + "Z",
        "source": "binance",
        "klines": klines
    }

    key = f"bitcoin/klines/{INTERVAL}/{now.strftime('%Y/%m/%d/%H%M%S')}-{context.aws_request_id}.json"

    s3.put_object(
        Bucket=BUCKET,
        Key=key,
        Body=json.dumps(record),
        ContentType="application/json"
    )

    return {
        "statusCode": 200,
        "body": json.dumps({
            "bucket": BUCKET,
            "key": key,
            "data_points": len(klines),
            "start": record["start"],
            "end": record["end"]
        })
    }
