# K-means clustering
library(dplyr) #mutate function
library(ggplot2) #scree plot

df <- medical_clean


df1 <- df[, c("Initial_days", "TotalCharge")]

write.csv(df1,"C:\\Users\\Harris\\Desktop\\Task1data.csv", row.names = TRUE)


#split data into train/test, 80/20
split <- round(nrow(df1) * 0.80)
df1_train <- df1[1:split, ]
df1_test <- df1[(split + 1):nrow(df1), ]

#copy of split data
write.csv(df1_train,"C:\\Users\\Harris\\Desktop\\Task1Training.csv", row.names = TRUE)
write.csv(df1_test,"C:\\Users\\Harris\\Desktop\\Task1Testing.csv", row.names = TRUE)


#K means model on training data
model <- kmeans(df1_train, centers = 2)

#assigning clusters
print(model$cluster)

#segment data
df1_clustered <- mutate(df1_train, cluster = model$cluster)
print(df1_clustered)

# Calculate the size of each cluster
count(df1_clustered, cluster)


# Calculate the mean for each category
df1_clustered %>% 
  group_by(cluster) %>% 
  summarise_all(funs(mean(.)))



model$tot.withinss

library(purrr) # for map double function

#calculate total within sum of squares
tot_withinss <- map_dbl(1:10, function(k){
  model <- kmeans(x = df1_train, centers = k)
  model$tot.withinss
})
elbow_df <- data.frame(
  k = 1:10,
  tot_withinss = tot_withinss
)
print(elbow_df)

#scree plot with training data
ggplot(elbow_df, aes(x = k, y = tot_withinss)) +
  geom_line() +
  scale_x_continuous(breaks = 1:10)
#cutoff is at k=2






#testing accuracy with silhouette analysis on testing data

library(cluster) # for pam function, similar to kmeans

pam_k2 <- pam(df1_test, k = 2)
pam_k2$silinfo$widths

pam_k2$silinfo$avg.width
#0.585 means values are mostly well matched to each cluster


