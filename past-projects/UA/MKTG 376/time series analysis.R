#install.packages("TTR")
library(TTR)
souvenir <- scan("http://robjhyndman.com/tsdldata/data/fancy.dat")
souvenirtimeseries <- ts(souvenir, frequency=12, start=c(1987,1))
logSouTS<-log(souvenirtimeseries)

souDecomposed <- decompose(logSouTS)

plot(souDecomposed)
names(souDecomposed)
AdjustedSouvenir <- logSouTS - souDecomposed$seasonal
AdjustedSouvenir
