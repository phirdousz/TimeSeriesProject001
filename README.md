# US Electricity Generation Forecasting from Natural Gas (1973–2023)

![R](https://img.shields.io/badge/R-4.x-blue.svg)
![Topic](https://img.shields.io/badge/Topic-Time%20Series%20Forecasting-green.svg)
![Course](https://img.shields.io/badge/Course-STQS3113-orange.svg)

An empirical time series analysis and forecasting project comparing **Dynamic Time Series Regression** against **Box-Jenkins Seasonal ARIMA (SARIMA)** modeling for monthly US electricity generation from natural gas over a 50-year horizon (1973–2023).

---

## Executive Summary

The objective of this project is to model long-term trends and seasonal fluctuations in monthly US electricity generation from natural gas and evaluate out-of-sample forecast accuracy for the year 2023 ($H = 12$ months).

* **Winning Model:** **$\text{SARIMA}(1,1,1)(0,1,1)_{12}$**
* **Key Finding:** Stochastic differencing ($d=1, D=1$) in SARIMA outperforms fixed deterministic polynomial trends by adapting dynamically to recent structural level shifts, reducing out-of-sample forecast error ($\text{MAPE}$) by more than **$50\%$** compared to dynamic regression models.

---

## Visualizing the Time Series

<p align="center">
  <img src="Time Series - Pictures/US Electricity Generation Graph.png" width="85%" alt="US Electricity Generation Graph">
</p>

* **Data Scope:** $612$ monthly observations (Jan 1973 – Dec 2023).
* **Training Window:** Jan 1973 – Dec 2022 ($n = 600$, 50 years).
* **Testing Window:** Jan 2023 – Dec 2023 ($12$ out-of-sample evaluation points).
* **Transformation:** Natural logarithm ($\ln Y_t$) was applied to stabilize expanding variance over time.

---

## Methodology & Diagnostics

### 1. Dynamic Time Series Regression
Modeled deterministic trend and monthly indicator seasonality with autocorrelated errors:
* **Deterministic Component:** Log-cubic trend ($t, t^2, t^3$) + 11 monthly indicator dummies ($M_2 \dots M_{12}$).
* **Residual Diagnostics:**

<p align="center">
  <img src="Time Series - Pictures/ARIMA(2,0,0).png" width="48%" alt="ARIMA(2,0,0) Residuals">
  <img src="Time Series - Pictures/ARIMA(4,0,1).png" width="48%" alt="ARIMA(4,0,1) Residuals">
</p>

---

### 2. Box-Jenkins SARIMA Methodology
Modeled stochastic trend and seasonality on the double-differenced series $\nabla \nabla_{12} \ln(Y_t)$:
* **Stationarity Verification:** ADF test statistic = $-10.424$ ($p < 0.01$).

<p align="center">
  <img src="Time Series - Pictures/ACF.png" width="48%" alt="ACF Plot">
  <img src="Time Series - Pictures/PACF.png" width="48%" alt="PACF Plot">
</p>

* **Order Selection:** Grid search via `auto.arima()` confirmed **$\text{SARIMA}(1,1,1)(0,1,1)_{12}$** as optimal ($\text{AICc} = -1420.36, \text{BIC} = -1402.93$).

<p align="center">
  <img src="Time Series - Pictures/SARIMA(1,1,1)(0,1,1)[12].png" width="85%" alt="SARIMA Model Residuals">
</p>

---

## Out-of-Sample Forecast Results (2023)

<p align="center">
  <img src="Time Series - Pictures/Actual vs Forecast.png" width="85%" alt="Actual vs Forecast Comparison">
</p>

### Accuracy Evaluation Table

| Model | RMSE (Wh) | MAE (Wh) | MAPE (%) | BIC | Parameters |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Regression + $\text{AR}(2)$** | $9,246.29$ | $6,325.43$ | $4.44\%$ | $-1338.43$ | 16 |
| **Regression + $\text{ARIMA}(4,0,1)$** | $8,272.72$ | $6,284.74$ | $4.32\%$ | $-1333.52$ | 19 |
| **$\mathbf{\text{SARIMA}(1,1,1)(0,1,1)_{12}}$** | **$3,416.35$** | **$3,097.34$** | **$2.12\%$** | **$-1402.93$** | **3** |

---

## File Structure

```text
.
├── Datasets.xlsx                           # Source dataset
├── main.R                                  # Complete R execution script
├── README.md                               # Project documentation
└── Time Series - Pictures/                 # Image assets directory
    ├── ACF.png
    ├── PACF.png
    ├── ARIMA(2,0,0).png
    ├── ARIMA(4,0,1).png
    ├── ARIMA(1,1,1)(0,1,1)[12].png
    ├── US Electricity Generation Graph.png
    └── Actual vs Forecast.png
