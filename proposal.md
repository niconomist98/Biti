# Machine Learning Engineer Nanodegree

## Capstone Proposal

**Author:** Nicolas Restrepo
**Date:** 31-03-2026

---

## 1. Domain Background

Cryptocurrency markets, particularly Bitcoin (BTC), operate 24/7 and are characterized by extreme volatility, high-frequency trading activity, and sensitivity to global events. Unlike traditional financial markets, Bitcoin lacks centralized regulation and is heavily influenced by market sentiment, whale movements, and macroeconomic indicators, making short-term price prediction a compelling and challenging machine learning problem.

Short-term price forecasting (minutes to hours) falls within the domain of **financial time-series analysis**, a well-researched area in quantitative finance and machine learning. Prior academic work has demonstrated the viability of applying recurrent neural networks (RNNs), Long Short-Term Memory networks (LSTMs), and ensemble methods to cryptocurrency price prediction. Notable studies include:

- **McNally et al. (2018)** — "Predicting the Price of Bitcoin Using Machine Learning," which applied LSTM and Bayesian-optimized RNNs to daily Bitcoin price data, achieving classification accuracies above 50% for directional prediction.
- **Livieris et al. (2020)** — "A CNN-LSTM model for gold price time-series forecasting," demonstrating hybrid deep learning architectures for financial forecasting.
- **Chen et al. (2020)** — Applied XGBoost and LSTM models to minute-level cryptocurrency data, showing that feature engineering on OHLCV data significantly improves short-term prediction accuracy.

This project is personally motivated by an interest in applying machine learning to real-time financial data and deploying predictive models as accessible, consumer-facing products.

---

## 2. Problem Statement

The problem is to **predict the price of Bitcoin (BTC/USDT) at three future time horizons — 5 minutes, 10 minutes, and 1 hour — using minute-level historical OHLCV (Open, High, Low, Close, Volume) data**.

This is a **supervised regression problem** where:

- **Input:** A sliding window of the most recent *n* minutes of OHLCV data, enriched with technical indicators (moving averages, RSI, MACD, Bollinger Bands, etc.).
- **Output:** Three continuous predicted values representing the Bitcoin closing price at *t+5*, *t+10*, and *t+60* minutes from the current time.

The problem is quantifiable (price in USDT), measurable (via standard regression metrics), and replicable (using publicly available API data). The solution will be deployed as a web application that delivers predictions to end users via email and WhatsApp notifications.

---

## 3. Datasets and Inputs

### Primary Data Source: Binance Public API

The project will use the **Binance REST API** (`https://api.binance.com/api/v3/klines`) to collect minute-level Bitcoin candlestick data. This API is:

- **Free and publicly accessible** (no API key required for public market data endpoints).
- **High-frequency:** Supports `interval=1m` for 1-minute OHLCV candles.
- **High-volume:** Returns up to 1,000 data points per request, and historical data spans several years.

**Data fields per candlestick (1-minute interval):**

| Field             | Description                        |
|-------------------|------------------------------------|
| Open Time         | Timestamp of candle open (ms)      |
| Open              | Opening price (USDT)               |
| High              | Highest price in interval (USDT)   |
| Low               | Lowest price in interval (USDT)    |
| Close             | Closing price (USDT)               |
| Volume            | Trading volume (BTC)               |
| Close Time        | Timestamp of candle close (ms)     |
| Quote Asset Volume| Trading volume (USDT)              |
| Number of Trades  | Count of trades in interval        |

**Dataset size:** Approximately 6 months of 1-minute data will be collected (~262,800 rows), split into:
- **Training set:** 70%
- **Validation set:** 15%
- **Test set:** 15%

### Engineered Features (Technical Indicators)

The raw OHLCV data will be augmented with the following technical indicators, computed using the `ta` (Technical Analysis) Python library:

- Simple Moving Average (SMA) — 7, 14, 30 periods
- Exponential Moving Average (EMA) — 7, 14, 30 periods
- Relative Strength Index (RSI) — 14 periods
- Moving Average Convergence Divergence (MACD)
- Bollinger Bands (20 periods, 2 standard deviations)
- Average True Range (ATR)
- Volume Weighted Average Price (VWAP)
- Price rate of change (ROC)

### Supplementary Data Source (Optional)

- **CoinGecko API** (`https://api.coingecko.com/api/v3/`) — for market cap, dominance, and global market sentiment data as additional features.

---

## 4. Solution Statement

The proposed solution is a **multi-output regression model** that takes a sliding window of engineered features from minute-level Bitcoin data and simultaneously predicts the closing price at three horizons: 5 minutes, 10 minutes, and 1 hour.

### Model Architecture

Two model approaches will be developed and compared:

1. **LSTM (Long Short-Term Memory) Network:** A deep learning model well-suited for sequential time-series data. The architecture will consist of:
   - Input layer accepting a window of *w* timesteps (e.g., 60 minutes) × *f* features.
   - Two stacked LSTM layers (128 and 64 units) with dropout regularization (0.2).
   - A dense output layer with 3 neurons (one per prediction horizon).

2. **XGBoost Regressor (Gradient Boosted Trees):** A strong baseline model using flattened feature windows as tabular input. Three separate XGBoost models will be trained (one per horizon) or a single multi-output wrapper will be used.

### Deployment Architecture

The best-performing model will be deployed as a **real-time prediction web application** with the following components:

- **Backend:** Python (Flask or FastAPI) serving predictions via REST API.
- **Data Pipeline:** A scheduled job (every 1 minute) fetches the latest data from Binance API, computes features, and runs inference.
- **Frontend:** A lightweight web dashboard (HTML/CSS/JavaScript or Streamlit) displaying current predictions, historical accuracy, and price charts.
- **Notification System:**
  - **Email:** Using the SendGrid API or Amazon SES to deliver prediction alerts to subscribed users.
  - **WhatsApp:** Using the Twilio WhatsApp API (`twilio.com/whatsapp`) to send prediction messages to subscribed phone numbers.
- **Hosting:** AWS EC2 or AWS Lambda for the backend; Amazon S3 + CloudFront for static frontend assets (alternatively, Heroku or Render for simplicity).

---

## 5. Benchmark Model

To evaluate the effectiveness of the proposed ML models, the following benchmark will be used:

### Naive Persistence Model (Baseline)

The simplest forecasting baseline: **the predicted price at any future horizon is equal to the current price** (i.e., the last known closing price).

- *Prediction at t+5:* P(t+5) = P(t)
- *Prediction at t+10:* P(t+10) = P(t)
- *Prediction at t+60:* P(t+60) = P(t)

This is a standard baseline in time-series forecasting. Any viable ML model must significantly outperform this naive approach. In highly volatile markets, even beating persistence by a small margin is meaningful.

### Secondary Benchmark

A **Simple Moving Average (SMA-20) forecast** — predicting the future price as the 20-period simple moving average of the closing price — will serve as a secondary benchmark to compare against more sophisticated models.

---

## 6. Evaluation Metrics

The following regression metrics will be used to evaluate and compare all models across the three prediction horizons:

### Primary Metrics

1. **Root Mean Squared Error (RMSE)**

$$RMSE = \sqrt{\frac{1}{n}\sum_{i=1}^{n}(y_i - \hat{y}_i)^2}$$

   Measures average prediction error in the same units as the target (USDT). Penalizes large errors more heavily. Lower is better.

2. **Mean Absolute Error (MAE)**

$$MAE = \frac{1}{n}\sum_{i=1}^{n}|y_i - \hat{y}_i|$$

   Measures average absolute deviation. More robust to outliers than RMSE. Lower is better.

3. **Mean Absolute Percentage Error (MAPE)**

$$MAPE = \frac{100}{n}\sum_{i=1}^{n}\left|\frac{y_i - \hat{y}_i}{y_i}\right|$$

   Provides a scale-independent percentage error, useful for comparing performance across different price ranges. Lower is better.

### Secondary Metric

4. **Directional Accuracy (DA)**

$$DA = \frac{1}{n}\sum_{i=1}^{n}\mathbb{1}(\text{sign}(\hat{y}_i - y_{i-1}) = \text{sign}(y_i - y_{i-1}))$$

   Measures the percentage of times the model correctly predicts the direction of price movement (up or down). This is critical for trading applications. Higher is better.

### Success Criteria

The ML model will be considered successful if it:
- Achieves a **MAPE < 1.5%** on the 5-minute horizon.
- Achieves a **MAPE < 3.0%** on the 1-hour horizon.
- Achieves a **Directional Accuracy > 55%** across all horizons.
- **Outperforms the naive persistence baseline** on all primary metrics.

---

## 7. Project Design

The project will be executed in the following phases:

### Phase 1: Data Collection and Storage (Day 1)
- Set up automated data collection from the Binance API (`/api/v3/klines`, `symbol=BTCUSDT`, `interval=1m`).
- Collect 6 months of historical 1-minute OHLCV data.
- Store data in a local SQLite database or CSV files for reproducibility.
- Implement a scheduled script (cron job or APScheduler) to continuously fetch new data every minute.

### Phase 2: Data Exploration and Feature Engineering (day 2)
- Perform exploratory data analysis (EDA): distribution of returns, volatility patterns, autocorrelation analysis.
- Compute technical indicators (SMA, EMA, RSI, MACD, Bollinger Bands, ATR, VWAP, ROC).
- Create target variables: closing price at t+5, t+10, and t+60.
- Handle missing values and normalize/scale features using MinMaxScaler or StandardScaler.
- Create sliding window datasets for LSTM input.

### Phase 3: Model Development and Training (Days 3–4)
- Implement the naive persistence baseline and SMA-20 benchmark.
- Train and tune the XGBoost multi-output regressor with hyperparameter optimization (GridSearchCV or Optuna).
- Train and tune the LSTM model using Keras/TensorFlow with early stopping and learning rate scheduling.
- Evaluate all models on the held-out test set using RMSE, MAE, MAPE, and Directional Accuracy.
- Select the best-performing model.

### Phase 4: Web Application Development (Day 5)
- Build a REST API backend (FastAPI) to serve real-time predictions.
- Develop a frontend dashboard displaying:
  - Current BTC price and predicted prices at 5m, 10m, and 1h.
  - Historical prediction accuracy charts.
  - Subscription form for email/WhatsApp notifications.
- Integrate the real-time data pipeline (fetch → feature engineering → inference → display).

### Phase 5: Notification System Integration (Day 6)
- Integrate **SendGrid API** (or Amazon SES) for email delivery of prediction alerts.
- Integrate **Twilio WhatsApp API** for WhatsApp message delivery.
- Implement user subscription management (subscribe/unsubscribe).
- Set up configurable notification frequency (every 5 min, 10 min, or 1 hour).

### Phase 6: Deployment and Testing (Day 7)
- Deploy the application on **AWS** (EC2 for backend, S3 + CloudFront for frontend) or a PaaS like Heroku/Render.
- Conduct end-to-end testing: data pipeline → model inference → web display → notifications.
- Monitor model performance over live data and document results.

### Phase 7: Documentation and Submission (Day 8)
- Write the final capstone report with methodology, results, and conclusions.
- Prepare visualizations comparing model performance against benchmarks.
- Package all code, data, and documentation for submission.

---

## References

1. McNally, S., Roche, J., & Caton, S. (2018). Predicting the Price of Bitcoin Using Machine Learning. *26th Euromicro International Conference on Parallel, Distributed and Network-based Processing (PDP)*, pp. 339–343.
2. Livieris, I.E., Pintelas, E., & Pintelas, P. (2020). A CNN-LSTM model for gold price time-series forecasting. *Neural Computing and Applications*, 32, 17351–17360.
3. Chen, Z., Li, C., & Sun, W. (2020). Bitcoin price prediction using machine learning: An approach to sample dimension engineering. *Journal of Computational and Applied Mathematics*, 365, 112395.
4. Binance API Documentation. https://binance-docs.github.io/apidocs/spot/en/
5. CoinGecko API Documentation. https://www.coingecko.com/en/api/documentation
6. Twilio WhatsApp API. https://www.twilio.com/docs/whatsapp
7. SendGrid Email API. https://docs.sendgrid.com/

---

*This proposal was prepared as part of the Udacity Machine Learning Engineer Nanodegree Capstone Project.*
