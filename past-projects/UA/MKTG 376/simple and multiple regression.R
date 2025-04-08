#  This script will take us through the basics of 
#  simple regression and multiple regression analysis

#  For our first example, let's return to the advertising data we used in our correlational analysis.
#  We have data from several ad campaigns
#  and we have Sales data and media level spending for each campaign.  We will use this case to look
#  at the simple case of basic regression, and the more robust multiple regression model.

#  As usual, we start by reading in our data from a csv file.

ad<-read.csv("C:/Users/Trevor/SkyDrive/Documents/teaching materials/case studies/Advertising.csv")
names(ad)
View(ad)

# We saw from the correlation matrix and correlogram that we ran last lecture that 
# our Ad variables are all relatively highly correlated with 
# our Sales variable, with TV being the most highly correlated.

# This gives us a hint that for a simple model, TV might be a good
# predictor of Sales.  Given this starting point, let's conduct a
# simple linear regression where we regress sales on TV spend.

#  To carry out this regression we will use the lm() function.
#  the lm function has 2 arguments:
#   1.  the formula for your regression model.  lm uses the same formula
#       method as t.test.  The general form of the formula is
#       outcome variable ~ predictor variable
#   2.  The data frame that contains your variables.  For our advertising 
#       example, this would be ad if you named your DF the same as I did.

lmod1 <- lm(Sales ~ TV, data = ad)

#One of the first steps that you should take after running a model is
#to look at your model diagnostics.  We don't have time to go over them 
#in depth, but they can be easily reviewed by using plot()and including
#your model inside the parenthesis

plot(lmod1)

ad2 <- ad[-26,]
#This will give you 4 plots that we will discuss in class

#Once you have checked your diagnostics, you are ready to review your model summary.
#  To do this, simply use the summary function with your model inside it

summary(lmod1)

#This summary gives us everything we need to understand our data.
#  the most important part of the summary is the Coefficients
#  This section provides us with an estimate for each component of our model,
#  and also conducts a t test to see if the component is signifiantly different
# than zero.  If a component is significant at the p<.05 level, we determine
# that the component has a significant effect on our outcome variable.
# The estimate itself tells us about the magnitude of this effect.  The estimate
# (for everything except the intercept) is how much a one unit change on that predictor
# will change the outcome variable.  In our case, increasing TV spend by 1 will increase sales
# by .04.
#  The estimate for the intercept is the value of our outcome variable when sales is at 0
#  This is equivalent to saying that the equation for our model is
# Sales = 7.032 + .048*TV

# The next thing to look at is the overall fit of the model, which
# is displayed after the coefficients in the model summary

#  The first thing reported is your Residual Standard Error.
#  In general, a smaller standard error means a tighter fit
#  around the line of your model.  A larger error means the model
#  fits the data less well.

#  The next value to review is your adjusted R-squared.  This value 
#  provides a measure of how well your model fits the data.  This ranges from 
#  0 to 1 and can be converted into a percentage of the outcome 
#  that is accounted for by the predictor.  the closer to 1 the better

#  Lastly, look at your F-test.  This determines whether your model as a whole 
#  is significant.  The p-value for the test determines this.

#  To plot your data you can do the following

plot(ad$TV, ad$Sales)
abline(lmod1,col = "red",lwd =4)
plot(lmod1$fitted.values,ad$Sales)

# You can use the predict function to find out what the model would predict
# for new values

new<- data.frame(TV=seq(0,300,50))
modprediction<- predict(lmod1,new)
modprediction

#Multiple Regression

# Multiple Regression in R is handled much the same as it is in
# simple regression, except that we add more variables to our
# predictor set.

#  We can see this in action by adding radio and newspaper to our simple
#  regression.

lmod2 <- lm(Sales ~ TV + Radio + Newspaper, data = ad )

#  With multiple regression we need to look at the issue of multicolinearity
#  To assess whether it is a problem, we need to use the vif() function in the 
#  car package.
install.packages("pbkrtest")
install.packages("car")
library(car)

#once the car package is loaded, we can run a VIF analysis.  What we are looking 
#for is high values.

vifResults<-vif(lmod2)
vifResultsFinal <- sqrt(vifResults)

#  We worry about variables that have a sqrt of vif greater than 2.  Since
#  We don't have anything above 2, we are good to look at our model summary.

summary(lmod2)
plot(lmod2)

plot(lmod2$fitted.values,ad$Sales)
#  Lastly, we can do a couple quick model comparisons to see how our models compare
#  To compare two models, we can use the anova() function on our two models
#  For instance, we might want to test whether our lmod1 is any better
#  or worse than our second model.  To compare these we put them as two
#  arguments within an anova test.
#  NOTE:  This should only be used for "nested" models.  This means that
#  one of the two models contains all of the values of the other model.
#  In this case, model 2 contains everything (just TV) that is in mod1, 
#  so we are good to go.

anova(lmod1,lmod2)

#  Lastly, we can use a model diagnostic called AIC to compare our two models

AIC(lmod1)
AIC(lmod2)

#  AIC is a measure of overall model fit that corrects for biasing factors
#  (primarily the number of variables in the model)
#  A lower AIC score is a better fitting model.
