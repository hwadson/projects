#Time Series Analysis
library(TTR) #for smoothing function



#manually import data and assign
df <- medical_time_series

#first we need to check to make sure our time intervals are evenly spaced
start(df$Day)
end(df$Day)
frequency(df$Day)
deltat(df$Day)
#we can confirm that the sampling frequency of our data has regular, fixed intervals


#time series object
time_series <- as.ts(df$Revenue)


#Trend spotting for data prep
plot(time_series)
#we can see a linear trend and how revenue increases after 200 days dramatically

# checks whether an object is time series
is.ts(df$Revenue)
is.ts(time_series)


#splitting data into train/test
df_train <- df[1:366,]
df_test <- df[366:731,]


#copy of cleaned and split data
write.csv(df_train,"C:\\Users\\Harris\\Desktop\\Task1Training.csv", row.names = TRUE)
write.csv(df_test,"C:\\Users\\Harris\\Desktop\\Task1Testing.csv", row.names = TRUE)



#Model Analysis

#Seasonal component
ts2 <- diff(time_series, s=2)
plot(ts2)
#no seasonal component with cycle length of 2 or 4

#Trend spotting
#log rapid growth
ts3 <- log(time_series)
ts.plot(ts3)


#removing time trend by differencing
ts4 <- diff(time_series)
ts.plot(ts4)  
#by removing long term time trend, we can see amount of change from one observation to the next.


# #Random walk model
# # Generate a RW model using arima.sim
# random_walk <- arima.sim(model = list(order = c(0, 1, 0)), n = 731)
# 
# # Plot random_walk
# ts.plot(random_walk)

#Autocorrelation

#time series plot of train and test sets 

ts.plot(cbind(df_test, df_train))
#we can see that revenue is similar over time

#summary stats between year 1 and 2 of revenue
mean(df_train$Revenue)
sd(df_train$Revenue)


mean(df_test$Revenue)
sd(df_test$Revenue)


#Covariance
cov(df_train$Revenue, df_test$Revenue)


#Correlation
cor(df_train$Revenue, df_test$Revenue)



#Autocorrelation
#correlation of year 1 revenue between beginning and end of year
cor(df_train$Revenue[-366], df_train$Revenue[-1])
#correlation of year 2 revenue between beginning and end of year
cor(df_test$Revenue[-366], df_test$Revenue[-1])


acf(df_train$Revenue, lag.max = 4, plot=F)
acf(df_test$Revenue, lag.max = 4, plot=F)


acf(df_train$Revenue, plot=T)
acf(df_test$Revenue, plot=T)



#Spectral density
ts.plot(time_series) ; acf(time_series)



#Decomposed time series using smoothing
ts5 <- SMA(time_series, n=10)
plot.ts(ts5)


#Confirmation of the lack of trends in the residuals of the decomposed series

ts.plot(cbind(time_series, ts5))
TSlogreturn = diff(log(time_series))
TS5logreturn = diff(log(ts5))
ts.plot(cbind(TSlogreturn, TS5logreturn))


#Autoregressive ARIMA model
AR_ts <- arima(time_series, order = c(1,0,0))
print(AR_ts)

AR_ts_fitted <- time_series - residuals(AR_ts)
ts.plot(time_series)
points(AR_ts_fitted, type = "l", col = 'red', lty = 2)
#Our AR model explains much of the variation observed in our original time series data


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


