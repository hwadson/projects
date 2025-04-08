#D214 Task 2 - MSDA Capstone
library(dplyr) #for infix operator in count function
library(ggplot2) #for histogram grid
library(gridExtra) #for graphs
library(factoextra) #scree plot
library(caret) #for confusion matrix
library(ROCR) #for ROC curve


df <- hotel_bookings


#overview of our variables
summary(df)
# we can see that 'children' column has a few missing values

#first check for any duplicated rows
duplicate_check <- df[duplicated(df),] %>% count()
duplicate_check
#31,994 rows found
df <- df[!duplicated(df),]
#duplicates removed, new sample size is 87,396 observations



#select relevant continuous numeric columns related to 'is_canceled'
df2<- df %>% 
  select(is_canceled, lead_time, adults, children, babies, previous_cancellations, booking_changes, days_in_waiting_list, adr)
#categorical variables were not used

str(df2)
#confirm all variables are numeric

#check for sum of missing values in each column
sapply(df2,function(x) sum(is.na(x)))
#4 missing values in 'children' column

#drop all rows with any missing values
df2<- na.omit(df2)
dim(df2)
#rows with missing values removed, new sample size is 87,392 observations

#visualize variables via histogram grid
lead_time <- ggplot(df2, aes(x=lead_time))+geom_histogram(bins=10)
adults <- ggplot(df2, aes(x=adults))+geom_histogram(bins=10)
children <- ggplot(df2, aes(x=children))+geom_histogram(bins=10)
babies <- ggplot(df2, aes(x=babies))+geom_histogram(bins=10)
prev_can <- ggplot(df2, aes(x=previous_cancellations))+geom_histogram(bins=10)
booking <- ggplot(df2, aes(x=booking_changes))+geom_histogram(bins=10)
days <- ggplot(df2, aes(x=days_in_waiting_list))+geom_histogram(bins=10)
adr <- ggplot(df2, aes(x=adr))+geom_histogram(bins=10)
grid.arrange(lead_time,adults,children,babies,prev_can,booking,days,adr)
#skewed distributions


#boxplots
lead_time_boxplt <- ggplot(df2, aes(y=lead_time)) + geom_boxplot() + coord_flip()
adults_boxplt <- ggplot(df2, aes(y=adults)) + geom_boxplot() + coord_flip()
children_boxplt <- ggplot(df2, aes(y=children)) + geom_boxplot() + coord_flip()
babies_boxplt <- ggplot(df2, aes(y=babies)) + geom_boxplot() + coord_flip()
prev_can_boxplt <- ggplot(df2, aes(y=previous_cancellations)) + geom_boxplot() + coord_flip()
booking_boxplt <- ggplot(df2, aes(y=booking_changes)) + geom_boxplot() + coord_flip()
days_boxplt <- ggplot(df2, aes(y=days_in_waiting_list)) + geom_boxplot() + coord_flip()
adr_boxplt <- ggplot(df2, aes(y=adr)) + geom_boxplot() + coord_flip()
grid.arrange(lead_time_boxplt,adults_boxplt,children_boxplt,babies_boxplt,prev_can_boxplt,booking_boxplt,days_boxplt,adr_boxplt)
#quite a few outliers


#check to see if any outliers need to be removed via z-scores
lead_time_z <- scale(df2$lead_time)
adults_z <- scale(df2$adults)
children_z <- scale(df2$children)
babies_z <- scale(df2$babies)
prev_can_z <- scale(df2$previous_cancellations)
booking_z <- scale(df2$booking_changes)
days_z <- scale(df2$days_in_waiting_list)
adr_z <- scale(df2$adr)

df2[(lead_time_z > 3) | (lead_time_z < -3),] %>% count() #1049 outliers
df2[(adults_z > 3) | (adults_z < -3),] %>% count() #76 outliers
df2[(children_z > 3) | (children_z < -3),] %>% count() #3669 outliers
df2[(babies_z > 3) | (babies_z < -3),] %>% count() #914 outliers
df2[(prev_can_z > 3) | (prev_can_z < -3),] %>% count() #278 outliers
df2[(booking_z > 3) | (booking_z < -3),] %>% count() #1492 outliers
df2[(days_z > 3) | (days_z < -3),] %>% count() #661 outliers
df2[(adr_z > 3) | (adr_z < -3),] %>% count() #628 outliers


#remove outliers
df3 <- df2
df3 <- df3[(lead_time_z <= 3) & (lead_time_z >= -3),]
df3 <- df3[(adults_z <= 3) & (adults_z >= -3),]
df3 <- df3[(children_z <= 3) & (children_z >= -3),]
df3 <- df3[(babies_z <= 3) & (babies_z >= -3),]
df3 <- df3[(prev_can_z <= 3) & (prev_can_z >= -3),]
df3 <- df3[(booking_z <= 3) & (booking_z >= -3),]
df3 <- df3[(days_z <= 3) & (days_z >= -3),]
df3 <- df3[(adr_z <= 3) & (adr_z >= -3),]
df3<- na.omit(df3)
#reduced from 87,392 to to 78,908 observations




#boxplots of cleaned data
lead_time_boxplt <- ggplot(df3, aes(y=lead_time)) + geom_boxplot() + coord_flip()
adults_boxplt <- ggplot(df3, aes(y=adults)) + geom_boxplot() + coord_flip()
children_boxplt <- ggplot(df3, aes(y=children)) + geom_boxplot() + coord_flip()
babies_boxplt <- ggplot(df3, aes(y=babies)) + geom_boxplot() + coord_flip()
prev_can_boxplt <- ggplot(df3, aes(y=previous_cancellations)) + geom_boxplot() + coord_flip()
booking_boxplt <- ggplot(df3, aes(y=booking_changes)) + geom_boxplot() + coord_flip()
days_boxplt <- ggplot(df3, aes(y=days_in_waiting_list)) + geom_boxplot() + coord_flip()
adr_boxplt <- ggplot(df3, aes(y=adr)) + geom_boxplot() + coord_flip()
grid.arrange(lead_time_boxplt,adults_boxplt,children_boxplt,babies_boxplt,prev_can_boxplt,booking_boxplt,days_boxplt,adr_boxplt)



summary(df3)
str(df3)

#copy of cleaned data
#write.csv(df3,"C:\\Users\\Harris\\Desktop\\Task2CleanData.csv", row.names = TRUE)


#normalize numerical data
data_norm <- as.data.frame(scale(df3[2:9]))
str(data_norm)


#PCA
pca <- prcomp(data_norm)
head(pca$x)

#scree plot
fviz_eig(pca, choice = "eigenvalue", addlabels=TRUE)
# fviz_eig(pca, choice = "variance", addlabels=TRUE)

#selecting components
cumsum((pca$sdev)^2*.1)


#creating rotation
rotation <- pca$rotation
rotation

#creating components
data_reduced <- as.data.frame(pca$x)[,1:8]
head(data_reduced)


#Based on scree plot we can see that the eigenvalue falls below 1 when we consider more than 5 dimensions, 
#and therefore that should be our maximum.
#After performing a rotation of our components to output their loadings, 
#we can see that there is more weight for adr, children, adults, and lead time in PC1. 
#Inversely, there is more weight for lead_time, days_in_waiting_list and booking_changes in PC2. 
#Based on this data we can conclude that the most important numerical components of this dataset 
#(from greatest to least) are as follows:
# adr, lead_time, days_in_waiting_list, children, adults, and booking_changes (optional).




#We will now use this information to perform our ANOVA


# 1 way ANOVA based on PCA results
anova.out <- aov(is_canceled ~ adr + lead_time + days_in_waiting_list  + children + adults + booking_changes,data=df3)
summary(anova.out)
# All of our selected numerical variables are highly significant in estimating whether or not a booking is canceled, 
#well within an alpha of 0.05.
# However the most significant seem to be adr, lead_time, and booking_changes





#Bivariate scatterplots to visualize relationships with 'is_canceled'
adr <- ggplot(df3)  + geom_point(aes(x = adr, y = is_canceled))
lead_time <- ggplot(df3)  + geom_point(aes(x = lead_time, y = is_canceled))
days <- ggplot(df3)  + geom_point(aes(x = days_in_waiting_list, y = is_canceled))
children <- ggplot(df3)  + geom_point(aes(x = children, y = is_canceled))
adults <- ggplot(df3)  + geom_point(aes(x = adults, y = is_canceled))
booking <- ggplot(df3)  + geom_point(aes(x = booking_changes, y = is_canceled))
grid.arrange(adr,lead_time,days,children,adults,booking)
#Based on these graphs the biggest thing that stands out is that the likelihood
#of cancellation is much higher for a party of 10 adults or greater.



#correlation matrix of variables
cor(df3)
#We can see that 'adr' and 'lead_time' are the most correlated with 'is_canceled'.



#We will now confirm our findings by building our logistic regression model

#Initial model
formula1 = factor(is_canceled) ~ adr + lead_time + days_in_waiting_list  + children + adults + booking_changes

LGModel <- glm(formula1, data = df3, family = binomial(logit))

summary(LGModel)
#AIC: 86586
#all variables are highly significant, but 'days_in_waiting_list' is least significant so we can try to remove it to see 
#if it improves our model's performance.


#Reduced model
formula2 = factor(is_canceled) ~ adr + lead_time  + children + adults + booking_changes
LGModel2 <- glm(formula2, data = df3, family = binomial(logit))

summary(LGModel2)
#AIC: 86593

#AIC is lower in the initial model, therefore we would prefer to use it for predictions


#confusion matrix
LGModelPred <- factor(round(predict(LGModel, df3, type="response")))
LGMatrix <- confusionMatrix(LGModelPred, factor(df3[,"is_canceled"]))
LGMatrix
#73.47% accuracy, model is able to correctly predict 57,973 out of 78,908 observations
#model has a high rate of sensitivity (true positive rate) but low specificity (true negative rate).




#split data into train and test sets, 50/50 split
split <- round(nrow(df3) * 0.50)
df3_train <- df3[1:split, ]
df3_test <- df3[(split + 1):nrow(df3),]

#copy of split data
#write.csv(df3_train,"C:\\Users\\Harris\\Desktop\\Task2Training.csv", row.names = TRUE)
#write.csv(df3_test,"C:\\Users\\Harris\\Desktop\\Task2Testing.csv", row.names = TRUE)



#run prediction on testing data
test_pred <- predict(LGModel, type = "response", newdata = df3_test)
pred = prediction(test_pred, df3_test$is_canceled)
perf = performance(pred,"acc")
roc = performance(pred,"tpr","fpr")
plot(roc, colorize = T, lwd = 2)
abline(a = 0, b = 1)
auc = performance(pred, measure = "auc")
print(auc@y.values)
#our model is able to predict cancellations with an accuracy of around 67%



