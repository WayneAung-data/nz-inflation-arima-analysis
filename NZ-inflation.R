library(tidyverse)
library(tseries)
library(forecast)

df <- consumers_price_index_december_2025_quarter_index_numbers

glimpse(df)
summary(df)

#Inspect Groups for CPI
df %>% distinct (Group)

#Missing or zero values check
missing_data_values <- df %>%
  filter(is.na(Data_value) | Data_value == 0)

#Filter CPI  to All Groups
df_clean <- df %>%
  filter(Group == "CPI All Groups for New Zealand") %>%
  select(Period, Data_value) %>%
  mutate(
    Period = as.character(Period),
    Year = substr(Period, 1, 4),
    Month = substr(Period, 6, 7),
    Date = as.Date(paste0(Year, "-", Month, "-01"))
  ) %>%
  arrange(Date)

#Filter sample period to 1992-2025
df_CPI <- df_clean %>%
  filter(
    Date >= as.Date("1992-03-01"),
    Date <= as.Date("2025-12-01")
  ) %>%
  select(Data_value, Date)

#Log differencing CPI
df_CPI <- df_CPI %>%
  mutate(
    log_CPI = log(Data_value),
    pi_t = log_CPI - lag(log_CPI)
  ) %>%
  filter(!is.na(pi_t))

#Quarterly Inflation Historical Plot
ggplot(df_CPI, aes(x = Date, y = pi_t)) +
  geom_line(color = "#3626A7", size = 0.5) +
  geom_hline(yintercept = 0, color = "grey60", size = 0.3) +
  scale_x_date(
    limits = c(as.Date("1992-06-01"), as.Date("2025-12-01")),
    breaks = seq(as.Date("1992-06-01"), as.Date("2024-06-01"), by = "2 years"),
    date_labels = "%Y"
  ) +
  scale_y_continuous(
    limits = c(-0.01, 0.03),
    breaks = seq(-0.01, 0.03, by = 0.01)
  ) +
  labs(x = "Time", y = "Inflation (log change)") +
  theme_minimal() +
  theme(
    axis.title.y = element_text(size = 11, margin = margin(r = 10)),
    axis.title.x = element_text(size = 11, margin = margin(t = 10))
  )

#Quarterly time series object
inflation_ts <- ts(df_CPI$pi_t, start = c(1992, 2), frequency = 4)

#Augmented Dickey-Fuller (ADF) test for Stationarity
adf.test(inflation_ts)

#ACF and PACF Plots
acf(inflation_ts, main = "ACF of Quarterly Inflation")
pacf(inflation_ts, main = "PACF of Quarterly Inflation")

#Candidate ARIMA models
m_ar1 <- Arima(inflation_ts, order = c(1, 0, 0))
m_ma1 <- Arima(inflation_ts, order = c(0, 0, 1))
m_arma11 <- Arima(inflation_ts, order = c(1, 0, 1))
m_arma21 <- Arima(inflation_ts, order = c(2, 0, 1))

#Auto.arima model selection
m_auto <- auto.arima(inflation_ts, d = 0, seasonal = FALSE)

#Model comparison
model_compare <- tibble(
  Model = c("AR(1)", "MA(1)", "ARMA(1,1)", "ARMA(2,1)", "AUTO"),
  AIC = c(AIC(m_ar1), AIC(m_ma1), AIC(m_arma11), AIC(m_arma21), AIC(m_auto)),
  BIC = c(BIC(m_ar1), BIC(m_ma1), BIC(m_arma11), BIC(m_arma21), BIC(m_auto))
)

model_compare

#Residual diagnostics
checkresiduals(m_ar1)
checkresiduals(m_arma11)

#Select preferred model
m_best <- m_arma11

#Forecast
fc_best <- forecast(m_best, h = 8)

#Forecast data frame for plotting
fc_df <- data.frame(
  Date = seq(as.Date("2026-03-01"), by = "quarter", length.out = 8),
  mean = as.numeric(fc_best$mean),
  lower80 = as.numeric(fc_best$lower[, 1]),
  upper80 = as.numeric(fc_best$upper[, 1]),
  lower95 = as.numeric(fc_best$lower[, 2]),
  upper95 = as.numeric(fc_best$upper[, 2])
)

#Forecast plot
ggplot() +
  geom_line(data = df_CPI, aes(x = Date, y = pi_t), color = "#3626A7", size = 0.5) +
  geom_ribbon(data = fc_df, aes(x = Date, ymin = lower95, ymax = upper95),
              fill = "#8EEDF7", alpha = 0.4) +
  geom_ribbon(data = fc_df, aes(x = Date, ymin = lower80, ymax = upper80),
              fill = "#78E0DC", alpha = 0.6) +
  geom_line(data = fc_df, aes(x = Date, y = mean),
            color = "#3626A7", size = 0.5, linetype = "dashed") +
  geom_hline(yintercept = 0, color = "grey60", size = 0.5) +
  geom_vline(xintercept = as.Date("2026-03-01"),
             linetype = "solid", color = "#2A9D8F", size = 0.5, alpha = 0.7) +
  scale_x_date(
    limits = c(as.Date("1992-06-01"), as.Date("2027-12-01")),
    breaks = seq(as.Date("1992-06-01"), as.Date("2026-06-01"), by = "2 years"),
    date_labels = "%Y"
  ) +
  scale_y_continuous(
    limits = c(-0.01, 0.03),
    breaks = seq(-0.01, 0.03, by = 0.01)
  ) +
  labs(x = "Time", y = "Inflation (log change)") +
  theme_minimal() +
  theme(
    axis.title.y = element_text(size = 11, margin = margin(r = 10)),
    axis.title.x = element_text(size = 11, margin = margin(t = 10)),
    panel.grid.major.x = element_line(color = "grey95")
  )

summary(m_arma11)