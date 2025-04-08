library(plyr) #for revalue function

df <- medical_clean

#verify no data is missing
sapply(df,function(x) sum(is.na(x)))

#Readmis to binary values
readmits <- df$ReAdmis
dict <- c("No" = 0, "Yes" = 1)
new_readmits <- revalue(x= readmits, replace = dict)
df$ReAdmis <- as.numeric(new_readmits)

# 1 way ANOVA based on PCA results
anova.out <- aov(ReAdmis ~ VitD_levels + Doc_visits + Population + Income,data=df)
summary(anova.out)
# Population within a one mile radius is the only significant 
# continuous numerical variable in predicting patient readmission


# 1 way ANOVA based on survey data
anova.out2 <- aov(ReAdmis ~ Item1+Item2+Item3+Item4+Item5+Item6+Item7+Item8,data=df)
summary(anova.out2)
#Item1(timely admission) is the only survey indicator that falls 
# within an alpha of .1 and provides marginal correlation with patient readmission.


#testing relevant categorical variables with chi-square
test <- chisq.test(table(df$Item1, df$ReAdmis))
test
test <- chisq.test(table(df$Area, df$ReAdmis))
test
test <- chisq.test(table(df$Age, df$ReAdmis))
test
test <- chisq.test(table(df$Gender, df$ReAdmis))
test
test <- chisq.test(table(df$Initial_admin, df$ReAdmis))
test
test <- chisq.test(table(df$HighBlood, df$ReAdmis))
test
test <- chisq.test(table(df$Stroke, df$ReAdmis))
test
test <- chisq.test(table(df$Complication_risk, df$ReAdmis))
test
test <- chisq.test(table(df$Asthma, df$ReAdmis))
test
#sig @ .1 alpha
test <- chisq.test(table(df$Arthritis, df$ReAdmis))
test
test <- chisq.test(table(df$Diabetes, df$ReAdmis))
test
test <- chisq.test(table(df$Hyperlipidemia, df$ReAdmis))
test
test <- chisq.test(table(df$Reflux_esophagitis, df$ReAdmis))
test
test <- chisq.test(table(df$Services, df$ReAdmis))
test
#sig @ .05 alpha