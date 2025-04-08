library(dplyr)
library(ggplot2)
library(gridExtra)
# install.packages("devtools")
# library("devtools")
# install_github("kassambara/factoextra")
library("factoextra")

data <- medical_raw_data

dim(data)
summary(data)

#check for any duplicated rows
data[duplicated(data),] %>% count()

#select relevant continuous numeric columns
df<- data %>% 
  select(Population, Age, Income, Doc_visits, VitD_supp, Initial_days)
#categorical survey questions and total/additional charges not used

str(df)

#check for sum of missing values in each column
sapply(df,function(x) sum(is.na(x)))

#drop all rows with any missing values
df1<- na.omit(df)
dim(df1)


#visualize variables via histogram grid
pop <- ggplot(df1, aes(x=Population))+geom_histogram(bins=10)
age <- ggplot(df1, aes(x=Age))+geom_histogram(bins=10)
income <- ggplot(df1, aes(x=Income))+geom_histogram(bins=10)
visit <- ggplot(df1, aes(x=Doc_visits))+geom_histogram(bins=10)
supp <- ggplot(df1, aes(x=VitD_supp))+geom_histogram(bins=10)
days <- ggplot(df1, aes(x=Initial_days))+geom_histogram(bins=10)
grid.arrange(pop,age,income,visit,supp,days)

# #Readmis binary values
# readmits <- df1$ReAdmis
# dict <- c("No" = 0, "Yes" = 1)
# new_readmits <- revalue(x= readmits, replace = dict)
# df1$ReAdmis <- as.numeric(new_readmits)

#boxplots
pop_boxplt <- ggplot(df1, aes(y=Population)) + geom_boxplot() + coord_flip()
age_boxplt <- ggplot(df1, aes(y=Age)) + geom_boxplot() + coord_flip()
income_boxplt <- ggplot(df1, aes(y=Income)) + geom_boxplot() + coord_flip()
visit_boxplt <- ggplot(df1, aes(y=Doc_visits)) + geom_boxplot() + coord_flip()
supp_boxplt <- ggplot(df1, aes(y=VitD_supp)) + geom_boxplot() + coord_flip()
days_boxplt <- ggplot(df1, aes(y=Initial_days)) + geom_boxplot() + coord_flip()
grid.arrange(pop_boxplt,age_boxplt,income_boxplt,visit_boxplt,supp_boxplt,days_boxplt)





#check to see if any outliers need to be removed via z-scores
pop_z <- scale(df1$Population)
age_z <- scale(df1$Age)
income_z <- scale(df1$Income)
visit_z <- scale(df1$Doc_visits)
supp_z <- scale(df1$VitD_supp)
days_z <- scale(df1$Initial_days)

df1[(pop_z > 3) | (pop_z < -3),] %>% count() #113 outliers
df1[(age_z > 3) | (age_z < -3),] %>% count() #0 outliers
df1[(income_z > 3) | (income_z < -3),] %>% count() #80 outliers
df1[(visit_z > 3) | (visit_z < -3),] %>% count() #6 outliers
df1[(supp_z > 3) | (supp_z < -3),] %>% count() #33 outliers
df1[(days_z > 3) | (days_z < -3),] %>% count() #0 outliers


#remove outliers
df2 <- df1
df2 <- df2[(pop_z <= 3) & (pop_z >= -3),]
df2 <- df2[(income_z <= 3) & (income_z >= -3),]
df2 <- df2[(visit_z <= 3) & (visit_z >= -3),]
df2 <- df2[(supp_z <= 3) & (supp_z >= -3),]
df2<- na.omit(df2)
#reduced from 5127 to 4897

#boxplots of cleaned data
pop_boxplt <- ggplot(df2, aes(y=Population)) + geom_boxplot() + coord_flip()
age_boxplt <- ggplot(df2, aes(y=Age)) + geom_boxplot() + coord_flip()
income_boxplt <- ggplot(df2, aes(y=Income)) + geom_boxplot() + coord_flip()
visit_boxplt <- ggplot(df2, aes(y=Doc_visits)) + geom_boxplot() + coord_flip()
supp_boxplt <- ggplot(df2, aes(y=VitD_supp)) + geom_boxplot() + coord_flip()
days_boxplt <- ggplot(df2, aes(y=Initial_days)) + geom_boxplot() + coord_flip()
grid.arrange(pop_boxplt,age_boxplt,income_boxplt,visit_boxplt,supp_boxplt,days_boxplt)

#normalize data
data_norm <- as.data.frame(scale(df2))
str(data_norm)

summary(df2)

#copy of cleaned data
write.csv(df2,"C:\\Users\\Harris\\Desktop\\MyData.csv", row.names = TRUE)



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
data_reduced <- as.data.frame(pca$x)[,1:6]
head(data_reduced)





