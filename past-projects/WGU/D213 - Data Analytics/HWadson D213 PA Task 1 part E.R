## Part E

# Summarize your findings and assumptions, including the following points:
#   1.  Discuss the results of your data analysis, including the following:
#   .   the selection of an ARIMA model
#   .   the prediction interval of the forecast
#   .   a justification of the forecast length
#   .   the model evaluation procedure and error metric
# 2.  Provide an annotated visualization of the forecast of the final model 
      # compared to the test set.
# 3.  Recommend a course of action based on your results.



#Autoregressive ARIMA model
df <- medical_time_series
time_series <- as.ts(df$Revenue)
AR_ts <- arima(time_series, order = c(1,0,0))
print(AR_ts)

AR_ts_fitted <- time_series - residuals(AR_ts)
ts.plot(time_series)
points(AR_ts_fitted, type = "l", col = 'red', lty = 2)
#Our AR model explains much of the variation observed in 
#our original time series data


#Forecasting 6 days ahead
predict(AR_ts, n.ahead =6)$pred
predict(AR_ts, n.ahead =6)$se






#Moving average ARIMA model

TS_changes <- diff(time_series)

# Plot the series and sample ACF
#ts.plot(time_series) ; ts.plot(TS_changes)
acf(TS_changes, lag.max = 24)

MA_TS_changes <- arima(TS_changes,
                       order = c(0, 0, 1))
print(MA_TS_changes)


MA_TS_changes_fitted <- TS_changes - residuals(MA_TS_changes)
ts.plot(TS_changes)
points(MA_TS_changes_fitted, type = "l", col = "red", lty = 2)


#Forecasting 6 days ahead
predict(MA_TS_changes, n.ahead =6)$pred
predict(MA_TS_changes, n.ahead =6)$se



# Based on our results we can immediately see that our RA model has a higher 
# AIC value compared to our MA model and is much more robust at delivering 
# accurate predictions. As a result, we would opt to go with that model for our 
# predictions. Our forecast length was limited to 6 days ahead to get a quick overview
# as to how each model performs. We could go with a higher predictive value but the higher 
# it goes the greater the likelihood of bad predictions due to higher Lag. Our error metric 
# was computed using the Standard error output of our prediction functions, our intercept coefficients, 
# and overall Lag and Autocorrelation.




ts.plot(time_series)
points(AR_ts_fitted, type = "l", col = 'red', lty = 2)


# We can see here in our graph of our Autoregressive (AR) model that our 
# function does a great job at falling in line with actual values. 
# Let's see how the MA model compares.



ts.plot(TS_changes)
points(MA_TS_changes_fitted, type = "l", col = "red", lty = 2)


# Here we can see that our MA model does a less adequate job at falling in 
# line with our differences between values and fails to account for large sets 
# of differences. As a result, our RA model has higher predictive accuracy and is 
# much more feasible to answer our objective. 


# Now we can observe our forecasts of our RA model:




#Forecasting 6 days ahead
predict(AR_ts, n.ahead =6)$pred
predict(AR_ts, n.ahead =6)$se



# We can see here that our model predicts revenue of approximately $16 million 
# for the next 6 days beyond the time frame of our original dataset. With a standard 
# error below 1 for most days, we can accept the significance of these results with a 
# high degree of accuracy.

# Based on our findings, we can take our projected revenue to the hospital 
# administration and, first off, let them know that our decline in revenue growth 
# during the second year is cause for concern and might be contributive to readmissions. 
# And second, we can inform them when to keep an eye out for potential upticks in readmission 
# based on projected revenue findings.





#cut and run in separate script
rmarkdown::render("C:/Users/Harris/Desktop/WGU/D213/Performance Assessment/HWadson D213 PA Task 1 Part E.R", "pdf_document")

