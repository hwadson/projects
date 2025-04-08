#  This script will take us through how to create a correlation matrix, 
#  and how to visualize it using a correlogram 

#  For our first example, let's look at advertising data.  We have data from several ad campaigns
#  and we have Sales data and media level spending for each campaign.  In future lectures
#  we will use this to look at the simple case of basic regression, 
#  and the more robust multiple regression model.

#  As usual, we start by reading in our data from a csv file.

ad<-read.csv("C:/Users/Trevor/SkyDrive/Documents/teaching materials/case studies/Advertising.csv")
names(ad)
View(ad)

# The first step in any regression analysis is to look at the correlations between our variables.  
# We can quickly run a correlation matrix that will provide us the correlations between all variables
# with the cor() function.  We only need to supply two arguments to this function:
#  1. The data frame you are making a correlation matrix for
#  2. a "use" argument that specifies what to do when you have NAs in your data.  
#     For our purposes this will always be use = "pairwise.complete.obs" 


adCorrels <- cor(ad, use = "pairwise.complete.obs")
View(adCorrels)

#  With a correlation matrix the top half and bottom half are identical, 
#  so you only need to review one or the other.  Each row/column combination tells you 
#  the r value for the pair of variables.

# if you are more visually oriented, you might find a correlogram more useful.
# these can be easily created with the corrgram package.

install.packages("corrgram")
library(corrgram)

corrgram(ad, order=FALSE, lower.panel=panel.shade,
         upper.panel=panel.pts, text.panel=panel.txt,
         main="Ad Data Correlogram")

# We can see from our correlation matrix and correlogram that 
# our Ad variables are all relatively highly correlated with 
# our Sales variable, with TV being the most highly correlated.

#We've now seen how to compute and view a correlation matrix, but we haven't attached
#any significance to it.  We could do this one pair of variables at a time using the
#cor.test() function, but for larger datasets, it is useful to carry out multiple significance
#tests all at once.  To do this, we need to use a homemade function called corstars that
#will rerun our correlation matrix, but give us stars at different significance levels.

cor.test(ad$TV, ad$Radio, na.rm=TRUE)

corstars <- function(x){
  require(Hmisc)
  x <- as.matrix(x)
  R <- rcorr(x)$r
  p <- rcorr(x)$P
  mystars <- ifelse(p < .01, "**|", ifelse(p < .05, "* |", "  |"))
  R <- format(round(cbind(rep(-1.111, ncol(x)), R), 3))[,-1]
  Rnew <- matrix(paste(R, mystars, sep=""), ncol=ncol(x))
  diag(Rnew) <- paste(diag(R), "  |", sep="")
  rownames(Rnew) <- colnames(x)
  colnames(Rnew) <- paste(colnames(x), "|", sep="")
  Rnew <- as.data.frame(Rnew)
  return(Rnew)
}

CorSigMatrix <- corstars(ad)
View(CorSigMatrix)

#Variable pairs marked with one star are significant at the p< .05 level,those 
#with 2 stars are significant at the more stingent p < .01 level.
