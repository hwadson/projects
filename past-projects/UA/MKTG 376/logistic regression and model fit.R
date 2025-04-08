#Logistic Regression, Model Comparisons, and Stepwise Procedures

#As usual, our first step is to read in our data

relay<- read.csv("C:/Users/Trevor/SkyDrive/Documents/teaching materials/case studies/relayTrainShort.csv")
names(relay)
View(relay)

#  Based on the variables we have, which ones might be of interest? 

#  Let's start by looking at correlations between our variables.  
#  Because we can only look at correlations for numeric variables,
#  We will need to be smart about how we specify our correlation
#  matrix.

#  We want to look at whether or not a customer was retained by variables 
#  6:13 in the list of names, and leave out the rest

#  To do this we feed  a list of numbers into our cor function as follows

relaycors<-cor(relay[c(2,6:13)])

library(corrgram)

corrgram(relay[c(2,6:13)], order=FALSE, lower.panel=panel.shade,
         upper.panel=panel.pts, text.panel=panel.txt,
         main="Relay Data Correlogram")

#  We see that number of emails sent, as well as a few other variables 
#  seem to be fairly highyly correlated with our outcome variable

#  Let's build a logistic model with all of our predictors predicting whether or 
#  not a customer will be retained after the first year

#  To build a logistic regression model, we use the glm function.  Glm stands for 
#  Generalized linear model.  This function provides the ability to implement
#  numerous types of regression models, of which we will only look at logistic.
#  GLM operates very much like the lm function we used for linear regression.  
#  the only difference is we now have to specific what distribution family we want to
#  apply.  This determines the type of regression that is run.
#  In this case, we want to use the "binary" family to run a logistic regression.
#  Our model would look like the following:

logmod1<- glm(retained ~ esent+eopenrate+eclickrate+avgorder+ordfreq+paperless+refill+doorstep, data=relay, family="binomial")

#After running our model, we should first check for multicolinearity using our sqrt of vif <2 criteria

#install.packages("pbkrtest")
#install.packages("car")
library(pbkrtest)
library(car)
vifscores<-vif(logmod1)
viftest<-sqrt(vifscores)
viftest

#  We can see that none of our variables appear problematic, so we can look at our model results

summary(logmod1)

#  The first thing we want to look at in our data is any variables that have a standard error above 2.5.
#  These variables might be causing problems in our model.  We can see that ordfreq might be a problem.
#  Let's update our model without ordfreq using the update function.  you could of course just create
#  a new model from scatch, but update is more efficient.

logmod2 <- update(logmod1,~.-ordfreq)

#Let's look at the results of this model

summary(logmod2)

# This looks much better.  We can see that a few variables look to be significant, and surprisingly
# some of them are negative, meaning that increases on those variables are associated with a decreased
# probability of being retained.

#  We can say that for a 1 unit change on esent, we will increase the log-odds of a person being
#  retained by .286.  This isn't very meaningful, but with a simple transformation, we can make
#  it much easier to understand.  If we take the exponent of our log-odds, they will be expressed
#  as odds-ratios.

mod2odds <- exp(coef(logmod2))

#  We can see that esent has a solid odds ratio of 1.33/1 odds.   
#  What's going on with Doorstep?  It has a huge estimate, but isn't even 
#  significant.  To explore this let's look at confidence intervals for our estimates

confint(logmod2)
exp (confint(logmod2))  #  This gives you confidence intervals for odds-ratios instead of log-odds

#  Because there is a large degree of error in doorstep, it has a very large confidence interval.
#  We should be cautious with variables like this, but let's continue on.

#To test whether our model is significant, we run the following code

with(logmod2, pchisq(null.deviance - deviance, df.null - df.residual, lower.tail = F))

#Lastly, we want to assess the overall fit of our model.  Logistic
#Regression does not come with a built in R-squared value, but 
#we can use an add on package to calculate a pseudo-R-squared that
#functions much like an R2.

#install.packages("binomTools")
library(binomTools)

logmodRsq <- Rsq(logmod2)
logmodRsq

#Somewhat counterintuitively, we are presented with 4 different pseudo-Rsquared values
# In most cases they will give similar results, but we will use D, the coeficient of 
# determination as our pseudo r squared of choice.  This can be interpreted very much like
# a true R-squared.  We can see from this that we have a quite high model fit.


#  Stepwise regression methods and model comparison

#  We now have seen how our model performed with several variables in it.  We may however
#  want to try see whether there are any variables that can be removed from the model 
#  without damaging our predictive ability.  to do this programatically, we can use 
#  a procedure called stepwise removal, which uses comparisons between AIC scores for models
#  with different sets of predictors in order to determine the optimal set of variables.  In
#  R this procedure is implemented in the MASS package with a function call stepAIC.

#install.packages("MASS")
library(MASS)
logmodBest <- stepAIC(logmod2)

#  Now that we have two models, we can use the anova function to compare them.  As a 
#  general practice, it is good to put the smaller of the two models first, and the 
#  larger model second

anova(logmodBest,logmod2,test="Chisq")

#  We can see that the larger model is not a significantly better model, so 
#  we confirm that the model selected by stepwise methods is our best current model.
#  As a final step, since we know that esent is our best predictor, why don't we try a 
#  simple logistic regression.

logmodSimple <- glm(retained ~ esent, family="binomial", data=relay)

anova(logmodSimple,logmodBest,test="Chisq")

#  We can see that even though esent is our biggest predictor, the other variables still help.
#  We confirm that we will use logmodBest as our final model.