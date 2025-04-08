#The first step, as always, is to download the data file
AdData<-read.csv("c:/users/trevor/desktop/adCampaignData.csv")


##################################################################################
##################################################################################
#Now we will look at how to calculate a t-test using the functions built into R
#First, let's look at our data frame to understand it a bit better
View(AdData)

#Looking at the data frame, you can see that we have sales data from 400 stores,
#200 of which are marked as "exposed" to our campaign, and 200 of which are "unexposed"

#In this example,we want to know if being exposed vs unexposed predicts anything about 
#a store's sales.  We call "adExposure" a predictor variable and "sales" an outcome variable.
#Because our predictor variable has two levels, and our outcome is numeric, the t-test is a good
#choice for this data set.

#Now that we've decided on a test, the first step is to do some descriptive analysis
#so that we understand our data a little before starting our testing

#The first descriptive step is to look at the frequencies of the levels of our predictor.
#We have done this several times now.  Use table() to create a frequency table of adExposure.

predTable<-table(AdData$adExposure)
predTable

#We can see that we have exactly the same number of stores in each condition: 200

#Next, let's look at the average sales in each level of our predictor. This will require
#a new function called tapply()
#tapply can be used to look at different descriptive stats broken out by predictor variables
#In this case we will use it to look at the mean sales in our two groups: exposed and unexposed

#tapply has three arguments 
#1.  The variable you want to apply a statistical function to.  In this case we want to apply
#    The means function to the sales variable
#2.  The variable we will be splitting the data by.  In this case we want seperate means
#   for each level of the adExposure variable
#3.  The function we want to apply.  In this case, that is mean.

meansTable <- tapply(AdData$sales, AdData$adExposure, mean)
meansTable

#  to visualize your means table you can use the function barplot on the meansTable object you just created.
barplot(meansTable)

#We can see that the average sales for the exposed group is 852 and for the unexposed group
# is 463. Given these large differences, it seems likely there is a significant difference.  
#A T-test will tell us for sure.

#the t-test is run using the t.test() function.  It has three arguments  to it.
#1.  the formula we are testing.  If this case, we will be testing sales predicted by exposure.
#2.  var.equal=TRUE.  This argument tells the software to assume equal variances between groups
#3.  The data frame we are using.  In this case AdData.

tTestResults <- t.test(sales ~ adExposure, var.equal = TRUE, data = AdData)
tTestResults

#From these results we can see that our t-stat is 37.25, with 398 degrees of freedom, and 
#a p-value well below p<.05.  Because of this, we would reject our null hypothesis and 
#say that there is an effect of ad Exposure on sales.



