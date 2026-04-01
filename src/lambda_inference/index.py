import json
import boto3
import pandas as pd
import numpy as np
import requests
from datetime import datetime

# --- Configuration ---
ENDPOINT_NAME = "bitcoin-direction-classifier-v1"
BINANCE_URL = "https://api.binance.us/api/v3/klines"
SYMBOL = "BTCUSDT"
INTERVAL = "5m"
LIMIT = 100  # We need at least 20-30 for RSI stability

runtime = boto3.client('sagemaker-runtime')

def feature_engineering(df):
    """Replicates the 'Pro' features used during XGBoost training"""
    df['open_time'] = pd.to_datetime(df['open_time'], unit='ms')
    df = df.sort_values('open_time')
    
    # Cast numeric columns
    for col in ['open', 'high', 'low', 'close', 'volume']:
        df[col] = df[col].astype(float)

    # 1. Wicks
    oc_max = df[['open', 'close']].max(axis=1)
    oc_min = df[['open', 'close']].min(axis=1)
    df['upper_wick'] = (df['high'] - oc_max) / df['close']
    df['lower_wick'] = (oc_min - df['low']) / df['close']
    
    # 2. RSI (Relative Strength Index)
    delta = df['close'].diff()
    gain = (delta.where(delta > 0, 0)).rolling(window=14).mean()
    loss = (-delta.where(delta < 0, 0)).rolling(window=14).mean()
    df['rsi'] = 100 - (100 / (1 + (gain / loss)))
    
    # 3. Volume Change
    df['volume_change'] = np.log1p(df['volume']).diff()
    
    # 4. Cyclical Time Features
    df['hour_sin'] = np.sin(2 * np.pi * df['open_time'].dt.hour / 24)
    df['hour_cos'] = np.cos(2 * np.pi * df['open_time'].dt.hour / 24)
    df['day_sin'] = np.sin(2 * np.pi * df['open_time'].dt.dayofweek / 7)
    df['day_cos'] = np.cos(2 * np.pi * df['open_time'].dt.dayofweek / 7)

    # Return only the final row in the specific order the model expects
    feature_cols = [
        'upper_wick', 'lower_wick', 'rsi', 'volume_change', 
        'hour_sin', 'hour_cos', 'day_sin', 'day_cos'
    ]
    return df[feature_cols].tail(1)

def lambda_handler(event, context):
    try:
        # 1. Get latest Data from Binance
        params = {'symbol': SYMBOL, 'interval': INTERVAL, 'limit': LIMIT}
        response = requests.get(BINANCE_URL, params=params)
        raw_data = response.json()
        
        # 2. Parse to DataFrame
        # Binance columns: [OpenTime, Open, High, Low, Close, Volume, CloseTime, ...]
        df = pd.DataFrame(raw_data).iloc[:, :6]
        df.columns = ['open_time', 'open', 'high', 'low', 'close', 'volume']
        
        # 3. Transform to 'Pro' Features
        inference_row = feature_engineering(df)
        
        # 4. Invoke SageMaker Endpoint
        # Convert row to CSV string: "val1,val2,val3..."
        payload = inference_row.to_csv(header=False, index=False).strip()
        
        sm_response = runtime.invoke_endpoint(
            EndpointName=ENDPOINT_NAME,
            ContentType='text/csv',
            Body=payload
        )
        
        # 5. Parse Prediction
        prediction_prob = float(sm_response['Body'].read().decode())
        direction = "UP" if prediction_prob > 0.5 else "DOWN"
        
        result = {
            "symbol": SYMBOL,
            "timestamp": str(datetime.now()),
            "probability_up": round(prediction_prob, 4),
            "prediction": direction
        }
        
        print(f"Inference Result: {result}")
        
        return {
            'statusCode': 200,
            'body': json.dumps(result)
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({"error": str(e)})
        }