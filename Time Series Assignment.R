# ==============================================================================
# STQS3113 Time Series Analysis & Forecasting
# US Electricity Generation from Natural Gas (Jan 1973 - Dec 2023)
# ==============================================================================

# 1. LOAD REQUIRED LIBRARIES
library(readxl)
library(forecast)
library(lmtest)
library(tseries)

# 2. DATA IMPORT & TRAIN/TEST SPLIT
file_path <- "C:/Users/muham/Desktop/Copy of Datasets.xlsx"
raw <- read_excel(file_path, sheet = 1, skip = 2, col_names = FALSE)

# Convert raw data to monthly time series (frequency = 12)
y_all <- ts(as.numeric(raw[[3]]), start = c(1973, 1), frequency = 12)

# Partition into Training (1973–2022) and Testing (2023) sets
train <- window(y_all, end = c(2022, 12))
test  <- window(y_all, start = c(2023, 1)) # 12 out-of-sample test points

# Visual Exploration of Time Series
plot(y_all, xlab = "Time (Year)", ylab = "Monthly Energy Generation (Wh)",
     main = "US Electricity Generation from Natural Gas (1973 - 2023)")
lines(test, col = "red", lwd = 2)
legend("topleft", legend = c("Train (1973-2022)", "Test (2023)"), 
       col = c("black", "red"), lty = 1, lwd = c(1, 2), bty = "n")

# 3. TRANSFORMATION & HELPER FUNCTIONS
# Log-transform training data to stabilize multiplicative variance
ltrain <- log(train)

# Helper function to compute RMSE, MAE, and MAPE
acc <- function(actual, forecast) {
  c(
    RMSE = sqrt(mean((actual - forecast)^2)),
    MAE  = mean(abs(actual - forecast)),
    MAPE = mean(abs((actual - forecast) / actual)) * 100
  )
}

# ==============================================================================
# APPROACH 1: TIME SERIES REGRESSION WITH DYNAMIC ERRORS
# ==============================================================================

# Construct Regressors Matrix (Log-cubic trend + 11 Monthly Dummies)
n  <- length(train)
t  <- 1:n
tn <- (n + 1):(n + length(test))

make_xreg <- function(tt, mon) {
  cbind(
    t  = tt / 600,
    t2 = (tt / 600)^2,
    t3 = (tt / 600)^3,
    model.matrix(~ factor(mon, levels = 1:12))[, -1]
  )
}

mon_tr <- cycle(train)
mon_te <- cycle(test)

Xtr <- make_xreg(t, mon_tr)
Xte <- make_xreg(tn, mon_te)
colnames(Xtr) <- colnames(Xte) <- c("t", "t2", "t3", paste0("M", 2:12))

# --- 1A. OLS Baseline Model ---
ols <- lm(ltrain ~ Xtr)
summary(ols)
dwtest(ols) # DW ~ 0.46 indicates significant positive serial correlation

# --- 1B. Compare AR(p) Noise Orders via AIC/BIC ---
for (p in 0:4) {
  m <- Arima(ltrain, order = c(p, 0, 0), xreg = Xtr)
  cat("AR(", p, ")  AIC =", m$aic, " BIC =", m$bic, "\n")
}

# Model 1A: Regression + Manual AR(2) Errors
reg_ar2 <- Arima(ltrain, order = c(2, 0, 0), xreg = Xtr, include.mean = TRUE)
summary(reg_ar2)
checkresiduals(reg_ar2)
fc_reg_ar2 <- exp(forecast(reg_ar2, xreg = Xte, biasadj = TRUE)$mean)

# Model 1B: Regression + Auto ARIMA(4,0,1) Errors
reg_auto <- auto.arima(
  ltrain,
  xreg = Xtr,
  seasonal = FALSE,     # Seasonality is captured by Xtr dummies
  stepwise = FALSE,     # Full non-seasonal grid search
  approximation = FALSE,
  trace = FALSE
)
summary(reg_auto)
checkresiduals(reg_auto)
fc_reg_auto <- exp(forecast(reg_auto, xreg = Xte, biasadj = TRUE)$mean)

# ==============================================================================
# APPROACH 2: BOX-JENKINS SARIMA METHODOLOGY
# ==============================================================================

# --- 2A. Stationarity Diagnostics ---
# ADF test on double-differenced log series
adf.test(diff(diff(ltrain, 12)))
acf(diff(diff(ltrain, 12)), 36)
pacf(diff(diff(ltrain, 12)), 36)

# --- 2B. Automated SARIMA Order Identification ---
fit_auto <- auto.arima(
  ltrain,
  seasonal = TRUE,
  stepwise = FALSE,
  approximation = FALSE,
  trace = FALSE
)
summary(fit_auto)

# Model 2: Selected SARIMA(1,1,1)(0,1,1)[12]
bj <- Arima(
  ltrain,
  order = c(1, 1, 1),
  seasonal = list(order = c(0, 1, 1), period = 12)
)
summary(bj)
checkresiduals(bj)
fc_bj <- exp(forecast(bj, h = length(test), biasadj = TRUE)$mean)

# ==============================================================================
# MODEL COMPARISON & ACCURACY EVALUATION
# ==============================================================================

# 1. Out-of-Sample Forecast Accuracy Table (2023)
accuracy_table <- data.frame(
  RMSE = c(acc(test, fc_reg_ar2)["RMSE"], acc(test, fc_reg_auto)["RMSE"], acc(test, fc_bj)["RMSE"]),
  MAE  = c(acc(test, fc_reg_ar2)["MAE"],  acc(test, fc_reg_auto)["MAE"],  acc(test, fc_bj)["MAE"]),
  MAPE = c(acc(test, fc_reg_ar2)["MAPE"], acc(test, fc_reg_auto)["MAPE"], acc(test, fc_bj)["MAPE"]),
  row.names = c("Regression + AR(2)", "Regression + ARIMA(4,0,1)", "SARIMA(1,1,1)(0,1,1)[12]")
)

cat("\n=======================================================\n")
cat("          OUT-OF-SAMPLE ACCURACY (2023 TEST SET)       \n")
cat("=======================================================\n")
print(round(accuracy_table, 2))

# 2. Monthly Actuals vs. Forecasted Values Table
monthly_comparison <- cbind(
  Actual                  = test,
  `Regression + AR(2)`    = fc_reg_ar2,
  `Regression + ARIMA`   = fc_reg_auto,
  `SARIMA(1,1,1)(0,1,1)`  = fc_bj
)

cat("\n=======================================================\n")
cat("            MONTHLY FORECAST COMPARISON (Wh)           \n")
cat("=======================================================\n")
print(round(monthly_comparison, 1))

# ==============================================================================
# VISUAL FORECAST COMPARISON PLOT
# ==============================================================================

# Expand y-axis limits to prevent legend overlap with seasonal peaks
y_min <- min(test, fc_reg_ar2, fc_reg_auto, fc_bj)
y_max <- max(test, fc_reg_ar2, fc_reg_auto, fc_bj)
ylim_range <- c(y_min * 0.98, y_max * 1.18)

# Plot Actuals and Forecast Lines
plot(test, xlab = "Time (Year)", ylab = "Monthly Energy Generation (Wh)",
     type = "o", pch = 16, col = "black", lwd = 2, ylim = ylim_range,
     main = "Actual vs Forecast Comparison (2023 Test Set)")

lines(fc_reg_ar2,  col = "blue",      type = "o", pch = 17, lty = 2, lwd = 2)
lines(fc_reg_auto, col = "darkgreen", type = "o", pch = 15, lty = 2, lwd = 2)
lines(fc_bj,       col = "red",       type = "o", pch = 18, lty = 1, lwd = 2)

legend("topleft",
       legend = c("Actual", "Regression + AR(2)", "Regression + ARIMA(4,0,1)", "SARIMA(1,1,1)(0,1,1)[12]"),
       col    = c("black", "blue", "darkgreen", "red"),
       pch    = c(16, 17, 15, 18),
       lty    = c(1, 2, 2, 1),
       lwd    = 2,
       bty    = "n",
       cex    = 0.85)