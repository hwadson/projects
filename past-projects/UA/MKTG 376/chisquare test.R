##  The Chi-Square Test in R 

#  Files you will need for this script:
#  chisqure test R script R file
#  Finale prepared.csv data file.



# The first test we will look at in R is the chi-square test.  It allows us to look
# at group level frequency data to see whether it lines up with expected frequency distributions.

# First let's install the MASS package and load it so that we can use a data set that comes 
# bundled with the package

#install.packages("MASS")
library(MASS)

# Using the data function, we can activate a data set that is pre-bundled with a package.

data(survey)

# Let's look at the names of the variables in this data set, which is a survey that was given
#to college students about their smoking habits

names(survey)

#Let's view the data to see what we have in this data set

View(survey)

#We can use the levels function to quickly see what the distinct values are for a variable

SmokeLevels <- levels(survey$Smoke)

#For the variable smoke, there are 4 level: heavy, never, occasionally, and regularly.
#Let's create a frequency table to examine this Smoke variable further

SmokeTable <- table(survey$Smoke)
SmokeTable

#We can see that it looks like most people never smoke.  We can test whether the levels of this 
#variable deviate from equal distribution (all levels having the same frequency) 
#by running a chi-square test.

test1Results <- chisq.test(SmokeTable)

#To see the basic results of our test, all we need to do is call our test1Results object
test1Results

#We can see that the test captured our observed and expected results by looking at pieces of 
#our test results object

names(test1Results)
test1Results$observed
test1Results$expected

# Sometimes we don't just want to look at whether frequencies deviate from equal distribution
# In these cases we can set expected probabilities and have the test calculate against those instead

#First, we need to define a set of expected probabilities
#For the smoking example, previous data has found that the probabilities for the four smoking
#categories are 
# Heavy - 4.5%
# Never - 79.5%
# Occas - 8.5%
# Regul - 7.5%

#We need to put these probabilities into a list that we can input into our chisq.test function.
#To make a list, we simply put our set of number inside c() and assign it to an object

smoke.prob <- c(.045, .795, .085, .075)
smoke.prob

#Now we can rerun our chisq.test from above, with one additional argument to specify the probabilities
# We need to tell it that the expected probabilities are in an object called smoke.prob.
# The argument for this specification is p = 'NAME OF EXPECTED PROB OBJECT'

test2Results <- chisq.test(SmokeTable, p = smoke.prob)
test2Results

test2Results$observed
test2Results$expected

#What conclusion would you draw from these new results?

####################################################################################
#  The Chi-squared Test of Independence
#
####################################################################################

#To learn the chi-square test of independence, let's first bring in the finale data
#set we used in an earlier lecture.

finale <- read.csv("C:\\Users\\Trevor\\SkyDrive\\Documents\\teaching materials\\case studies\\finale prepared.csv")

#Let's start by creating a contingency table.  
#This is just like creating a frequency table, but you will specify two variables
#Let's look at whether different stores have customers that use different devices
#to complete their study.

finaleTable <- table(finale$Storecode, finale$Source)
finaleTable

#To run the test of independence, we simply put our contingency table object
#into our chisq.test function.  No secondary arguments need to be specified

finaleChiSquare <- chisq.test(finaleTable)

#We received a warning when we ran this test, let's look at why this happened
# by reviewing our expected probabilities

finaleChiSquare$expected

#Remember that an assumption of the chi-square test is that all cells
#will have an expected probability of at least 5.  We can see that this 
#is not the case in our finale data.  This will call our results into 
#question.  When this happens, we should always note that we had low
#expected frequencies and should collect more data to ensure reliable results.

#Short of that, we can still look at the results we got, but must be cautious
finaleChiSquare

#Are store and Source independent of each other?

#Let's do one more test to avoid the warning we got before
#Let's remove the Brookline store from our dataset, since it has 
#such low response rates

finale2 <- subset(finale, finale$Storecode != "Brookline, MA")
finale2<- droplevels(finale2)

#Now let's rerun our test with just the two remaining stores

finaleTable2<- table(finale2$Storecode, finale2$Source)
finaleTable2

finaleChiSquare2 <- chisq.test(finaleTable2)
finaleChiSquare2
