library(naivebayes)
library(ROCR) #for ROC curve





#data prep
df = medical_clean

#split data into train/test
df_train <- df[which(df$Stroke=="Yes"),]
df_test <- df[which(df$Stroke=="No"),]


df$Asthma <- as.factor(df$Asthma)
df$ReAdmis <- as.factor(df$ReAdmis)

#copy of cleaned data
write.csv(df,"C:\\Users\\Harris\\Desktop\\Task1Data.csv", row.names = TRUE)

#copy of split data
write.csv(df_train,"C:\\Users\\Harris\\Desktop\\Task1Training.csv", row.names = TRUE)
write.csv(df_test,"C:\\Users\\Harris\\Desktop\\Task1Testing.csv", row.names = TRUE)

# building a Naive Bayes model
model1 <- naive_bayes(ReAdmis ~ Initial_days + Asthma, data = df_train)
model1


# making predictions with Naive Bayes
future_readmis <- predict(model1, df_test, type="class")
table1 <- as.data.frame(future_readmis)
table(table1)
#convert to numerical vector for ROC curve
predvec <- ifelse(table1=="Yes", 1, 0)



#confusion matrix
NBMatrix <- table(future_readmis, df_test$ReAdmis)
NBMatrix

#error rate
1 - sum(diag(NBMatrix)) / sum(NBMatrix)
#around 4.8% error rate

#ROC Curve
#method 1
library(caTools)
colAUC(predvec, df_test$ReAdmis, plotROC = TRUE)

#method 2
library(ROCR)
pred = prediction(predvec, df_test$ReAdmis)
perf = performance(pred,"acc")
roc = performance(pred,"tpr","fpr")
plot(roc, colorize = T, lwd = 2)
abline(a = 0, b = 1)
auc = performance(pred, measure = "auc")
print(auc@y.values)




#look into binning Initial_days