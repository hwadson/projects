#Market Basket Analysis (Association Rule Mining)

library(arules) # for data transformation and apriori function



df <- medical_market_basket

dim(df)
summary(df)

#check for sum of missing values in each column
sapply(df,function(x) sum(is.na(x)))
#no missing values


#data cleaning

toDelete <- seq(1, nrow(df), by=2) #remove empty rows

df <-  df[-toDelete, ]

row.names(df) <- NULL #reset index


table(df$Presc01)
#most medications are repeated and every patient has atleast 1 Rx

#new column with # of Rx for each patient
df$Rx_count <- rowSums(!df == "")

#new column to be used as TID column
df$index <- 1:nrow(df)


# Transform new columns into a factor
df$Rx_count = factor(df$Rx_count)
df$index = factor(df$index)


#copy of cleaned data
write.csv(df,"C:\\Users\\Harris\\Desktop\\Task3Data.csv", row.names = TRUE)


# Split into groups
data_list = split(df$Presc01, df$Rx_count)


# Transform to transactional dataset
data_trx = as(data_list,"transactions")

# Inspect transactions
inspect(data_trx)

summary(data_trx)
#most common medications among all patients listed here

#Plotting Rx Matrix
image(data_trx)


# apriori for Frequent itemsets
supp.cw = apriori(data_trx, # the transactional dataset
                  # Parameter list
                  parameter=list(
                    # Minimum Support
                    supp=0.2,
                    # Minimum Confidence
                    conf=0.4,
                    # Minimum length
                    minlen=2,
                    # Target
                    target="frequent itemsets"),
                  # Appearence argument
                  appearance = list(
                    items = c("amlodipine","methylprednisone"))
)



# apriori function for Rules
rules.rhs = apriori(data_trx, # the transactional dataset
                      # Parameter list
                      parameter=list(
                        # Minimum Support
                        supp=0.4,
                        # Minimum Confidence
                        conf=0.4,
                        # Minimum length
                        minlen=2,
                        # Target
                        target="rules"),
                      # Appearance argument
                      appearance = list(
                        rhs = "methylprednisone",
                        default = "lhs")
)








#retrieve frequent itemsets

supp.all = apriori(data_trx,
                   parameter=list(supp=3/7,
                                  target="frequent itemsets"))


inspect(head(sort(supp.all,by="support"),6))




# retrieve Rules with "methylprednisone" on rhs
# rules.b.rhs = apriori(data_trx,
#                       parameter=list(
#                         minlen=2,
#                         target="rules"),
#                       appearance = list(
#                         rhs="methylprednisone",
#                         default = "lhs")
# )

# inspect(head(sort(rules.b.rhs,by="lift")), 5)


# retrieve Rules
rules.all = apriori(data_trx,
                    parameter = list(supp=5/7, conf=0.6, minlen=2),
                    control = list(verbose=F)
)
# min supp of 3/7 or 4/7 does not work

inspect(head(sort(rules.all, by= 'confidence')))
