#Principal Component Analysis
library(dplyr)
library(factoextra)

df <- medical_clean


dim(df)
summary(df)

#check for any duplicated rows
df[duplicated(df),] %>% count()
#none found

#select relevant continuous numeric columns
df1<- df %>% 
  select(Population, Age, Income, Doc_visits, Initial_days, TotalCharge)
#categorical survey questions not used

#check for sum of missing values in each column
sapply(df1,function(x) sum(is.na(x)))
#no missing values

#check to see if any outliers need to be removed via z-scores
pop_z <- scale(df1$Population)
age_z <- scale(df1$Age)
income_z <- scale(df1$Income)
visit_z <- scale(df1$Doc_visits)
charge_z <- scale(df1$TotalCharge)
days_z <- scale(df1$Initial_days)

df1[(pop_z > 3) | (pop_z < -3),] %>% count() #218 outliers
df1[(age_z > 3) | (age_z < -3),] %>% count() #0 outliers
df1[(income_z > 3) | (income_z < -3),] %>% count() #143 outliers
df1[(visit_z > 3) | (visit_z < -3),] %>% count() #8 outliers
df1[(charge_z > 3) | (charge_z < -3),] %>% count() #0 outliers
df1[(days_z > 3) | (days_z < -3),] %>% count() #0 outliers


#remove outliers
df2 <- df1
df2 <- df2[(pop_z <= 3) & (pop_z >= -3),]
df2 <- df2[(income_z <= 3) & (income_z >= -3),]
df2 <- df2[(visit_z <= 3) & (visit_z >= -3),]
df2<- na.omit(df2)
#reduced from 10000 to 9632 observations

#standardize data
data_norm <- as.data.frame(scale(df2))
str(data_norm)

summary(df2)

#copy of cleaned data
write.csv(df2,"C:\\Users\\Harris\\Desktop\\Task2Data.csv", row.names = TRUE)




#PCA
pca <- prcomp(data_norm, scale=F, center=T)
head(pca$x)

#scree plot
# fviz_eig(pca, choice = "eigenvalue", addlabels=TRUE)
fviz_eig(pca, choice = "variance", addlabels=TRUE)


#selecting components
cumsum((pca$sdev)^2*.1)


#creating rotation
rotation <- pca$rotation
rotation

#creating components
data_reduced <- as.data.frame(pca$x)[,1:6]
head(data_reduced)

