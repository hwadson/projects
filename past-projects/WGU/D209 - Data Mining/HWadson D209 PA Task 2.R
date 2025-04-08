
#Advanced Regression for automated feature selection using glmnet

library(caret)
library(glmnet)

df <- medical_clean[,11:50]

#str(df)

# Make a custom trainControl
myControl <- trainControl(
  method = "cv",
  number = 10,
  summaryFunction = twoClassSummary,
  classProbs = TRUE,
  verboseIter = TRUE
)

# Fit a model
set.seed(42)

model2 <- train(
  ReAdmis ~ .,
  df,
  method = "glmnet",
  trControl = myControl
)


model2
# Plot results
plot(model2)
#based on the graph we can see that an alpha of 1 (lasso regression) and a 
min(model2[["results"]]$lambda)
#very low lambda (0.0008201607) returns the highest ROC 

# Print maximum ROC statistic
max(model2[["results"]]$ROC)
#highest ROC is 0.9987974



#full regularization path
plot(model2$finalModel)


df$ReAdmis <- as.factor(df$ReAdmis)

#randomize order
set.seed(86)
rows <- sample(nrow(df))
df2 <- df[rows, ]

#copy of randomized, cleaned data
write.csv(df2,"C:\\Users\\Harris\\Desktop\\Task2Data.csv", row.names = TRUE)

#split data into train/test, 80/20
split <- round(nrow(df2) * 0.80)
df2_train <- df2[1:split, ]
df2_test <- df2[(split + 1):nrow(df2), ]

#copy of split data
write.csv(df2_train,"C:\\Users\\Harris\\Desktop\\Task2Training.csv", row.names = TRUE)
write.csv(df2_test,"C:\\Users\\Harris\\Desktop\\Task2Testing.csv", row.names = TRUE)


lasso_best <- glmnet(df2_train[,-10], df2_train$ReAdmis, alpha = 1, lambda = 0.0008201607, family='binomial')



coef(lasso_best)
#identify features with highest coefficients


LGModel <- glm(factor(ReAdmis) ~ Gender + Initial_admin + Stroke + Complication_risk + Arthritis + Anxiety + Allergic_rhinitis 
               + Reflux_esophagitis + Asthma + Services + Initial_days, data = df2_test, family = binomial(logit))

summary(LGModel)
#AIC 172.39


LGModel2 <- glm(factor(ReAdmis) ~ Initial_admin + Stroke + Anxiety + Asthma + Initial_days, data = df2_test, family = binomial(logit))

summary(LGModel2)
#AIC 178.48


#confusion matrix
LGModelPred <- factor(round(predict(LGModel2, df2_test, type="response")))
#convert to chr vector for matrix
predvec <- ifelse(LGModelPred== 1, "Yes", "No")
LGMatrix <- confusionMatrix(factor(predvec), factor(df2_test[,"ReAdmis"]))
LGMatrix
#Accuracy of 98.2%
#RMSE not used since responses are categorical, not continuous.

#ROC Curve
library(ROCR)
test_pred <- predict(LGModel2, type = "response", newdata = df2_test)
pred = prediction(test_pred, df2_test$ReAdmis)
perf = performance(pred,"acc")
roc = performance(pred,"tpr","fpr")
plot(roc, colorize = T, lwd = 2)
abline(a = 0, b = 1)
auc = performance(pred, measure = "auc")
print(auc@y.values)

#AUC = 0.9988814 which falls in line with max ROC predicted by Lasso regression.






