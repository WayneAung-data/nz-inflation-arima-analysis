# NZ Inflation ARIMA Analysis

A baseline time series analysis of quarterly inflation in New Zealand using an ARIMA framework, including forecasting, diagnostics, and a summary infographic.

---

## Overview
This project applies a univariate ARIMA model to quarterly CPI inflation in New Zealand (1992–2025) to examine inflation dynamics and generate short-term forecasts.

The analysis follows a standard time series workflow:
- Stationarity testing (ADF)
- Model identification (ACF/PACF)
- Model selection (AIC/BIC)
- Residual diagnostics
- Forecasting

---

## Repository Structure
- `report/` – full report (PDF)
- `code/` – R script for data preparation, modelling, and forecasting
- `infographic/` – one-page summary of key insights

---

## Key Insights
- Inflation shows short-term persistence  
- The series exhibits periods of elevated volatility  
- Shocks have diminishing effects over time  
- Inflation fluctuates around ~2.3% annually  
- Inflation tends to revert toward its historical average  
- Forecasts indicate high uncertainty over the horizon  

---

## Tools
- R  
- tidyverse  
- forecast  
- tseries  
