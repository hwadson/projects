#!/usr/bin/env python
# coding: utf-8

# # Final Project
# 
# ---
# 
# Congrats on making it to the final project! In this project, you'll take everything you've learned and conduct an experiment on new data and describe your insights. The steps you'll need to complete in their entirety are below, but we'll repeat ourselves as we go through the notebook as well. 
# 
# - Load scikit-learn and all other modules necessary for building a classification model as learned in class.
# - Load the data. Use the `class` column as labels and the `text` column for extracting features that will be used in the model.
# - Apply feature extraction on the text using the CountVectorizer method and experiment with generating 2-grams, stop words removal, and stemming.
# - Split the data into 2/3 for training and 1/3 for testing
# - Apply 5-fold cross validation using the kfold method
# - Build a classification model using the SVM classifier using the training data.
# - Build a classification model using the Random forest classifier using the training data.
# - Test classifier on the test portion of the data
# - Print performance in terms of F-measure, Recall, and Precision for both classifiers.
# 
# **NOTE**: Given the ease of the problem, we expect an F-measure of at least 90%.

# ## Imports

# Start by loading the data munging libraries you'll need, pandas and numpy. You'll also need the CountVectorizer class and cross validation methods from sklearn, along with the models you'll train. You may also benefit from the performance measure functions from sklearn. 

# In[5]:


# your code here
import sys
import os
import numpy as np
import pandas as pd
# import matplotlib
# import matplotlib.pyplot as plt 
import sklearn
# Import the CountVectorizer to create a data matrix
from sklearn.feature_extraction.text import CountVectorizer
# Import function to split the data into training and test
from sklearn.model_selection import train_test_split
# Import decision trees
from sklearn import tree
# Import naive bayes
from sklearn.naive_bayes import GaussianNB as NB
# Import SVM (Support Vector Machines)
from sklearn import svm
# Import Random Forest
from sklearn.ensemble import RandomForestClassifier

from sklearn import metrics
from sklearn.model_selection import KFold

#scoring functions
from sklearn.metrics import f1_score
from sklearn.metrics import precision_score
from sklearn.metrics import recall_score

import nltk
import re


# In[6]:


# Data import test cases


# ## Load the data

# Load the data. Use the `class` column as labels and the `text` column for extracting features that will be used in the model.

# In[12]:


data = None
# your code here
from sklearn.datasets import fetch_20newsgroups
data = pd.read_csv("./data/sample_data.txt", sep="\t" )


# In[13]:


# Data read in test cases


# ## Feature Extraction

# Time for some feature extraction from the text in our dataset. Please use the CountVectorizer class and we ask you to experiment with at least 2 out of these 3: 
# 
# - generating 2-grams
# - stop words removal
# - stemming
# 
# using two different vectorizers: `vect1` and `vect2`. If you want to try stemming, please use the function name `custom_preprocessor`. 

# In[18]:


vect1 = None
custom_preprocessor = None
# your code here
def custom_preprocessor(text):
    text = text.lower()
    text = re.sub("\\W"," ",text)
    text = nltk.PorterStemmer().stem(text)
    return text

vect1 = CountVectorizer (max_df=200, 
                      min_df=0,
                      max_features = 2000, 
#                       ngram_range =(1,2),
#                       stop_words='english')
                      preprocessor = custom_preprocessor
                        )


# In[20]:


vect2 = None
# your code here
vect2 = CountVectorizer (max_df=200, 
                      min_df=0,
                      max_features = 2000, 
#                       ngram_range =(1,2),
                      stop_words='english')


# In[21]:


# Count vectorizing test cases


# In[ ]:





# Upon visual inspection, choose a vectorizer that you think works the best. Set it to `vect`. Use it to transform your data to `tf_matrix`. Create a label np array as well and set it to `t`. 
# 
# Create a pandas dataframe called `full_matrix` from the transformed data with proper column titles. 

# In[23]:


vect = None
tf_matrix = None
t = None

# your code here
vect = vect2
tf_matrix=vect.fit_transform(data['text'])  #sparse matrix
t=np.asarray(data['class']) #true labels


print ("The data has %d rows and %d columns " % (tf_matrix.shape[0], tf_matrix.shape[1]))
print ("The length of the labels vector is ==> %d "  % (t.shape))


# In[24]:


assert tf_matrix.shape[0] == 400
assert type(vect) == CountVectorizer
assert type(t) == np.ndarray


# In[25]:


# create the full_matrix here
full_matrix = None

# your code here
full_matrix = pd.DataFrame(tf_matrix.todense(), columns=vect.get_feature_names())


display(full_matrix[1:4]) 


# In[26]:


# test full_matrix structure 


# ## Create train/test set

# Split the data into 2/3 for training and 1/3 for testing. Prepare the training data to use 5-fold cross validation when training using the KFold class.

# In[29]:


xtrain, xtest, ytrain, ytest = [None] * 4
# your code here
xtrain, xtest, ytrain, ytest = train_test_split(full_matrix,t,random_state=50, train_size=0.66666)


# In[30]:


# check sizes of xtrain, ytrain, xtest, ytest


# In[31]:


# K-fold Cross Validation 
kf = None
# your code here
kf = KFold(n_splits=5,shuffle=True)


# In[32]:


# check kfold creation 


# ## Classify Using SVM
# 
# First, we'll create an SVM classifier. Feel free to play around with the hyperparameters to get the best possible results. All the docs are here: https://scikit-learn.org/stable/modules/generated/sklearn.svm.SVC.html
# 
# We'll train the model using 5-fold cross validation, and then test it on the test set. Make sure to collect and print the precision, recall, and f1 scores for the model. 

# In[36]:


svm_clf = None
# your code here
svm_clf = svm.SVC()
svm_y_pred = svm_clf.fit(xtrain, ytrain).predict(xtest)
svm_error = (svm_y_pred != ytest).sum()


# In[37]:


# check creation of SVM model


# In[ ]:





# In[49]:


# train the model
svm_precisions = []
svm_recalls = []
svm_f1s = []
# your code here
precision = metrics.precision_score(ytest, svm_y_pred)
recall = metrics.recall_score(ytest, svm_y_pred)
f1s = metrics.f1_score(ytest, svm_y_pred)
svm_precisions.append(precision)
svm_recalls.append(recall)
svm_f1s.append(f1s)
print ("\nAverage Precision is  ===> %2.3f" % ( sum(svm_precisions)/len(svm_precisions)))
print ("\nAverage Recall is  ===> %2.3f" % ( sum(svm_recalls)/len(svm_recalls)))
print ("\nAverage F1 is  ===> %2.3f" % ( sum(svm_f1s)/len(svm_f1s)))


# In[50]:


# check properly trained SVM
from sklearn.utils.validation import check_is_fitted


# In[51]:


# check average f1 of 75% 
assert ( sum(svm_f1s)/len(svm_f1s)) > 0.75


# In[52]:


# check average f1 of 90% 
assert ( sum(svm_f1s)/len(svm_f1s)) > 0.9


# # Classify Using Random Forest
# 
# Do the same thing, but with Random Forests. 

# In[80]:


rf_clf = None
# your code here
rf_clf = RandomForestClassifier(max_depth=1000, random_state=1)
rf_y_pred = rf_clf.fit(xtrain, ytrain).predict(xtest)
rf_error = (rf_y_pred != ytest).sum()


# In[81]:


# check creation of RF model


# In[82]:


# train the model
rf_precisions = []
rf_recalls = []
rf_f1s = []
# your code here
precision = metrics.precision_score(ytest, rf_y_pred)
recall = metrics.recall_score(ytest, rf_y_pred)
f1s = metrics.f1_score(ytest, rf_y_pred)
rf_precisions.append(precision)
rf_recalls.append(recall)
rf_f1s.append(f1s)

print ("\nAverage Precision is  ===> %2.3f" % ( sum(rf_precisions)/len(rf_precisions)))
print ("\nAverage Recall is  ===> %2.3f" % ( sum(rf_recalls)/len(rf_recalls)))
print ("\nAverage F1 is  ===> %2.3f" % ( sum(rf_f1s)/len(rf_f1s)))


# In[83]:


# check properly trained RF
from sklearn.utils.validation import check_is_fitted


# In[84]:


# check average f1 of 75% 
assert ( sum(rf_f1s)/len(rf_f1s)) > 0.75


# In[85]:


# check average f1 of 90% 
assert ( sum(rf_f1s)/len(rf_f1s)) > 0.90


# # Write a Short Report

# Write a short report on your findings in the graded quiz on the main Coursera page. What preprocessing of the text worked best, which model worked best, why? etc. 
