library(caret) #for VIF
library(gridExtra) #for graphs



#assign raw data to df
df <- medical_clean


# categoricals as factors
df$asthma_dummy <- factor(df$Asthma)
df$asthma_dummy <- relevel(asthma_dummy, "No")
df$services_dummy <- factor(df$Services)



str(df)

#Univariate histograms
pop <- ggplot(df, aes(x=Population))+geom_histogram(bins=10)
age <- ggplot(df, aes(x=Age))+geom_histogram(bins=10)
income <- ggplot(df, aes(x=Income))+geom_histogram(bins=10)
visit <- ggplot(df, aes(x=Doc_visits))+geom_histogram(bins=10)
vitD <- ggplot(df, aes(x=VitD_levels))+geom_histogram(bins=10)
asthma <- ggplot(df, aes(x=asthma_dummy))+geom_bar()
services <- ggplot(df, aes(x=services_dummy))+geom_bar()
grid.arrange(pop,age,income,visit,vitD,asthma,services)

#Bivariate scatterplots
pop <- ggplot(df)  + geom_point(aes(x = Population, y = Initial_days))
age <- ggplot(df)  + geom_point(aes(x = Age, y = Initial_days))
income <- ggplot(df)  + geom_point(aes(x = Income, y = Initial_days))
visit <- ggplot(df)  + geom_point(aes(x = Doc_visits, y = Initial_days))
vitD <- ggplot(df)  + geom_point(aes(x = VitD_levels, y = Initial_days))
asthma <- ggplot(df)  + geom_point(aes(x = asthma_dummy, y = Initial_days))
services <-  ggplot(df)  + geom_point(aes(x = services_dummy, y = Initial_days))
grid.arrange(pop,age,income,visit,vitD,asthma,services)


#copy of cleaned data
df1 <- df[, c(11,16,17,21,22,40,51,52)]
write.csv(df1,"C:\\Users\\Harris\\Desktop\\Task1Data.csv", row.names = TRUE)

#test for multicollinearity on numerical variables
df2 <- df[, c(11,16,17,21,22,40)]
#correlation matrix
res <- cor(df2)
round(res, 2)
#no evidence of multicollinearity b/w numerical variables.



#develop estimated multiple regression equation
#initial model
lm1 = lm(Initial_days ~ Population + Age + Income + VitD_levels + Doc_visits + asthma_dummy + services_dummy, data = df)
summary(lm1)

#r^2 is .00029 so this model explains around .03% of the variation
#in days spent in the hospital based on these 5 variables.

#VIF
car::vif(lm1)
#no evidence of multicollinearity




#Test H0: No relationship b/w initial days and predictors.
pop_mlr <- plot(df$Population, lm1$residuals, pch=16, col="red")
age_mlr <- plot(df$Age, lm1$residuals, pch=16, col="red")
income_mlr <- plot(df$Income, lm1$residuals, pch=16, col="red")
vitD_mlr <- plot(df$VitD_levels, lm1$residuals, pch=16, col="red")
doc_mlr <- plot(df$Doc_visits, lm1$residuals, pch=16, col="red")
asthma_mlr <- plot(asthma_dummy, lm1$residuals, pch=16, col="red")
services_mlr <- plot(services_dummy, lm1$residuals, pch=16, col="red")


par(mfrow=c(2,2))
plot(lm1)



#reduced MLR
lm2 = lm(Initial_days ~ Population + Age + Income + asthma_dummy, data = df1)
summary(lm2)

# #predict values using MLR model
# Pred <- predict(lm2)
# #compare actual values against predicted
# plot(df1[,5],Pred,
#      xlab="Actual",ylab="Predicted")
# abline(a=0,b=1)

par(mfrow=c(2,2))
plot(lm2)


# not used, disregard
# pch.list <- as.numeric(df$ReAdmis)
# plot(df$Income, df$Population, pch=c(pch.list), col=c("black","red"))

