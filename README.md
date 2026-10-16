# STQS3113: US Electricity Generation from Natural Gas — Time Series Forecasting

An empirical time series analysis and forecasting project evaluating **Dynamic Regression with ARIMA Errors** and **Box-Jenkins Seasonal ARIMA (SARIMA)** modeling on monthly US electricity generation from natural gas ($1973 - 2023$).

---

## 📌 Project Overview

This project models 50 years of monthly US natural gas electricity generation to predict out-of-sample energy generation for the 12 months of $2023$. The primary goal is to compare deterministic trend/seasonal dummy regression models against stochastic differencing (SARIMA) methods under empirical forecast accuracy metrics ($\text{RMSE}$, $\text{MAE}$, $\text{MAPE}$).

### Key Results
* **Winning Model:** $\text{SARIMA}(1,1,1)(0,1,1)_{12}$
* **Accuracy:** Reached an out-of-sample $\text{MAPE}$ of **$2.12\%$** on the 2023 test set, outperforming dynamic regression models ($\text{MAPE} \approx 4.32\% - 4.44\%$).
* **Core Takeaway:** Stochastic differencing ($d=1, D=1$) adapts dynamically to localized structural shifts, avoiding the fixed extrapolation errors caused by deterministic log-cubic polynomial trends ($t^3$).

---

## 📊 Dataset & Preprocessing

* **Dataset Source:** Monthly Electricity Generation from Natural Gas in the United States ($612$ observations).
* **Training Set:** Jan $1973$ – Dec $2022$ ($n = 600$ observations, $50$ years).
* **Test Set:** Jan $2023$ – Dec $2023$ ($12$ out-of-sample test points).
* **Transformation:** Natural log transformation ($\ln(Y_t)$) was applied to stabilize expanding seasonal variance over time.
* **Bias Adjustment:** Explicit bias adjustment (`biasadj = TRUE`) was applied during back-transformation exponentiation ($E[e^X] \ge e^{E[X]}$) to prevent log-median forecast bias.

---

## ⚙️ Methodology & Models

### 1. Approach 1: Dynamic Time Series Regression
Modeled deterministic trend and monthly indicator seasonality with autocorrelated errors:
* **Deterministic Terms:** Log-cubic polynomial trend ($t, t^2, t^3$) + 11 monthly indicator variables ($M_2 \dots M_{12}$ with January as reference).
* **OLS Residual Diagnostic:** Durbin-Watson statistic $DW = 0.4555$ ($p < 2.2 \times 10^{-16}$) confirmed severe positive serial correlation in raw OLS residuals.
* **Dynamic Noise Structures:**
  * **Model 1A:** Manual $AR(2)$ error specification ($\text{AICc} = -1416.40, \text{BIC} = -1338.43$).
  * **Model 1B:** Automated $\text{ARIMA}(4,0,1)$ error specification ($\text{AICc} = -1424.26, \text{BIC} = -1333.52$).

### 2. Approach 2: Box-Jenkins SARIMA Methodology
Modeled stochastic trend and seasonal patterns on double-differenced stationary series $\nabla \nabla_{12} \ln(Y_t)$:
* **Stationarity Test:** Augmented Dickey-Fuller test on $\nabla \nabla_{12} \ln(Y_t)$ yielded $DF = -10.424$ ($p = 0.01$), confirming stationarity.
* **Model Selection:** `auto.arima()` grid search identified $\text{SARIMA}(1,1,1)(0,1,1)_{12}$ as the optimal specification ($\text{AICc} = -1420.36, \text{BIC} = -1402.93$).

---

## 📈 Out-of-Sample Performance Comparison (2023 Test Set)

| Model Specification | RMSE (Wh) | MAE (Wh) | MAPE (%) | BIC | Parameters |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Regression + $AR(2)$** | $9,246.29$ | $6,325.43$ | $4.44\%$ | $-1,338.43$ | $16$ |
| **Regression + $\text{ARIMA}(4,0,1)$** | $8,272.72$ | $6,284.74$ | $4.32\%$ | $-1,333.52$ | $19$ |
| **$\mathbf{\text{SARIMA}(1,1,1)(0,1,1)_{12}}$** | **$3,416.35$** | **$3,097.34$** | **$2.12\%$** | **$-1,402.93$** | **$3$** |

### Insights
1. **Model Parsimony:** SARIMA achieved the best (lowest) $\text{BIC}$ score ($-1,402.93$) because it requires only **3 estimated parameters**, whereas dynamic regression requires **19 parameters**.
2. **Forecast Error:** SARIMA cut the forecast error ($\text{MAPE}$) in half relative to dynamic regression ($2.12\%$ vs. $4.32\%$).
3. **Trend Extrapolation:** Dynamic regression underpredicted December 2023 generation ($121,443\text{ Wh}$ vs actual $146,174\text{ Wh}$, a $\sim 16.9\%$ error) due to cubic trend curvature.

---

## 🛠️ Prerequisites & Installation

Required R packages:

```R
install.packages(c("readxl", "forecast", "lmtest", "tseries"))
```

---

## 🚀 How to Run

1. Place your dataset (`Copy of Datasets.xlsx`) in the working directory or update the file path in `main.R`.
2. Run the main R script:

```R
source("main.R")
```

The script will automatically fit all candidate models, calculate residual statistics, generate out-of-sample predictions with bias adjustment, render accuracy tables, and produce a forecast plot.
