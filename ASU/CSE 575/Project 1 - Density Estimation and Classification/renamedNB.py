
# coding: utf-8

# In[19]:


import numpy
import scipy.io
import math
import geneNewData

def main():
    myID='9314'
    geneNewData.geneData(myID)
    Numpyfile0 = scipy.io.loadmat('digit0_stu_train'+myID+'.mat')
    Numpyfile1 = scipy.io.loadmat('digit1_stu_train'+myID+'.mat')
    Numpyfile2 = scipy.io.loadmat('digit0_testset'+'.mat')
    Numpyfile3 = scipy.io.loadmat('digit1_testset'+'.mat')
    train0 = Numpyfile0.get('target_img')
    train1 = Numpyfile1.get('target_img')
    test0 = Numpyfile2.get('target_img')
    test1 = Numpyfile3.get('target_img')
    #print([len(train0),len(train1),len(test0),len(test1)])
    #print('Your trainset and testset are generated successfully!')

    
    
## Manually uploaded data - removed (not needed?)   
#     Numpyfile0 = scipy.io.loadmat("train_0_img.mat")
#     Numpyfile1 = scipy.io.loadmat("train_1_img.mat")
#     Numpyfile2 = scipy.io.loadmat("test_0_img.mat")
#     Numpyfile3 = scipy.io.loadmat("test_1_img.mat")
#     train0 = Numpyfile0.get('target_img')
#     train0 = numpy.reshape(train0, (5923, 28, 28))
#     train1 = Numpyfile1.get('target_img')
#     train1 = numpy.reshape(train1, (6742, 28, 28))
#     test0 = Numpyfile2.get('target_img')
#     test0 = numpy.reshape(test0, (980, 28, 28))
#     test1 = Numpyfile3.get('target_img')
#     test1 = numpy.reshape(test1, (1135, 28, 28))
    
    
    ##Task1  
    Feature1 = numpy.mean(train0, axis=(1,2))
    Feature2 = numpy.std(train0, axis=(1,2))
    train0_Features = numpy.column_stack((Feature1, Feature2))
    Feature3 = numpy.mean(train1, axis=(1,2))
    Feature4 = numpy.std(train1, axis=(1,2))
    train1_Features = numpy.column_stack((Feature3, Feature4))
#     print(train0_Features)
#     print(train1_Features)

    
    ##Task2 
    d0F1_mean = numpy.mean(Feature1)
    d0F1_variance = numpy.var(Feature1)
    d0F2_mean = numpy.mean(Feature2)
    d0F2_variance = numpy.var(Feature2)
    d1F1_mean = numpy.mean(Feature3)
    d1F1_variance = numpy.var(Feature3)
    d1F2_mean = numpy.mean(Feature4)
    d1F2_variance = numpy.var(Feature4)

    print(d0F1_mean, d0F1_variance, d0F2_mean, d0F2_variance, d1F1_mean, d1F1_variance, d1F2_mean, d1F2_variance)
    
    ##Task3 
    test0_F1 = numpy.mean(test0, axis=(1,2))
    test0_F2 = numpy.std(test0, axis=(1,2))
    test0_Features = numpy.column_stack((test0_F1, test0_F2))
    test1_F1 = numpy.mean(test1, axis=(1,2))
    test1_F2 = numpy.std(test1, axis=(1,2))
    test1_Features = numpy.column_stack((test1_F1, test1_F2))    
    
    #print(test0_Features, test1_Features)
    
    from sklearn.naive_bayes import GaussianNB
    
    labels0= numpy.zeros(5000)    #creates array of 5000 0's
    labels1= numpy.ones(5000)     #creates array of 5000 1's
    model0 = GaussianNB()
    model1 = GaussianNB()
    model0.fit(train0_Features, labels0)
    model1.fit(train1_Features, labels1)
    pred0 = model0.predict(test0_Features)
    pred1 = model1.predict(test1_Features)
    
    #print(pred0, pred1)
    
    
    ##Task4 
    labels2= numpy.zeros(980)    #creates array of 980 0's, 100% accuracy
    labels3= numpy.ones(1135)    #creates array of 1135 1's, 100% accuracy
    labels4= numpy.random.randint(0, 2, 980) #creates random integer array of 1's and 0's, 50% accuracy
    labels5= numpy.random.randint(0, 2, 1135) #creates random integer array of 1's and 0's, 52% accuracy
    
    from sklearn.metrics import accuracy_score
    test0_acc = accuracy_score(labels4, pred0)
    test1_acc = accuracy_score(labels5, pred1)
    
    print(test0_acc, test1_acc)
    
    pass


if __name__ == '__main__':
    main()

