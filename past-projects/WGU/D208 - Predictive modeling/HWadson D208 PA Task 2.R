library(plyr) #revalue function
library(gridExtra) #for grid.arrange
library(ROCR) #for ROC curve
library(caret) #for confusion matrix

#assign raw data to df
df <- medical_clean
# df$ReAdmis <- as.factor(df$ReAdmis)


#isolate data
df1 <- df[, c(20,11,16,17,21,22,40)]

#Readmis to binary values for correlation matrix
readmits <- df1$ReAdmis
dict <- c("No" = 0, "Yes" = 1)
new_readmits <- revalue(x= readmits, replace = dict)
df1$ReAdmis <- as.numeric(new_readmits)

#copy of new data
write.csv(df1,"C:\\Users\\Harris\\Desktop\\Task2Data.csv", row.names = TRUE)

#scatterplots
plot(df1)

#Univariate histograms
readmis <- ggplot(df1, aes(x=ReAdmis))+geom_bar()
pop <- ggplot(df1, aes(x=Population))+geom_histogram(bins=10)
age <- ggplot(df1, aes(x=Age))+geom_histogram(bins=10)
income <- ggplot(df1, aes(x=Income))+geom_histogram(bins=10)
visit <- ggplot(df1, aes(x=Doc_visits))+geom_histogram(bins=10)
vitD <- ggplot(df1, aes(x=VitD_levels))+geom_histogram(bins=10)
days <- ggplot(df1, aes(x=Initial_days))+geom_histogram(bins=10)
grid.arrange(readmis,pop,age,income,visit,vitD,days)

#Bivariate scatterplots
pop <- ggplot(df1)  + geom_point(aes(x = Population, y = ReAdmis))
age <- ggplot(df1)  + geom_point(aes(x = Age, y = ReAdmis))
income <- ggplot(df1)  + geom_point(aes(x = Income, y = ReAdmis))
visit <- ggplot(df1)  + geom_point(aes(x = Doc_visits, y = ReAdmis))
vitD <- ggplot(df1)  + geom_point(aes(x = VitD_levels, y = ReAdmis))
days <- ggplot(df1)  + geom_point(aes(x = Initial_days, y = ReAdmis))
grid.arrange(pop,age,income,visit,vitD,days)


#correlation matrix of variables
cor(df1[,1:7])
#Initial_days is highly correlated to ReAdmis


#Initial model
formula1 = factor(ReAdmis) ~ Population + Age + Income + VitD_levels + Doc_visits + Initial_days

LGModel <- glm(formula1, data = df1, family = binomial(logit))

summary(LGModel)


#Reduced model
LGModel2 <- glm(factor(ReAdmis) ~ Initial_days, data = df1, family = binomial(logit))

summary(LGModel2)
#AIC is lower in the second model, therefore we would prefer to use it for predictions


#confusion matrix
LGModel2Pred <- factor(round(predict(LGModel2, df, type="response")))
LGMatrix <- confusionMatrix(LGModel2Pred, factor(df1[,"ReAdmis"]))
LGMatrix



#split data into train and test sets based on Stroke
ggplot(df, aes(x=Stroke))+geom_bar()
df_train <- df[which(df$Stroke=="Yes"),]
df_test <- df[which(df$Stroke=="No"),]

#run prediction
test_pred <- predict(LGModel2, type = "response", newdata = df_test)
pred = prediction(test_pred, df_test$ReAdmis)
perf = performance(pred,"acc")
roc = performance(pred,"tpr","fpr")
plot(roc, colorize = T, lwd = 2)
abline(a = 0, b = 1)
auc = performance(pred, measure = "auc")
print(auc@y.values)

