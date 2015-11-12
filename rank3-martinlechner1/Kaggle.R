# Output model generation
# Is the same as CV, but with the selected parameters

# Random Forest
basic.rf = randomForest(as.factor(sold) ~ ., data = ebayTrainClean, keep.forest=TRUE, ntree = 600)
rf.nonText = predict(basic.rf, newdata = ebayTestClean, type="prob")
rfout = rf.nonText[,2]

## GBM - See https://github.com/mlandry22/kaggle/blob/master/GBM_talk_Austin_R_Users_20140724.R
##	Set up parameters to pass in; there are many more hyper-parameters available, but these are the most common to control
GBM_NTREES = 700
##	400 trees in the model; can scale back later for predictions, if desired or overfitting is suspected
GBM_SHRINKAGE = 0.05
##	shrinkage is a regularization parameter dictating how fast/aggressive the algorithm moves across the loss gradient
##	0.05 is somewhat aggressive; default is 0.001, values below 0.1 tend to produce good results
##		decreasing shrinkage generally improves results, but requires more trees, so the two should be adjusted in tandem
GBM_DEPTH = 6
##	depth 4 means each tree will evaluate four decisions; 
##		will always yield [3*depth + 1] nodes and [2*depth + 1] terminal nodes (depth 4 = 9) 
##		because each decision yields 3 nodes, but each decision will come from a prior node
GBM_MINOBS = 10
##	regularization parameter to dictate how many observations must be present to yield a terminal node
##	higher number means more conservative fit; 30 is fairly high, but good for exploratory fits; default is 10

##	Fit model
gbm1<-gbm(sold ~., data=ebayTrainClean, distribution = "bernoulli",n.trees = GBM_NTREES,shrinkage = GBM_SHRINKAGE,
          interaction.depth = GBM_DEPTH,n.minobsinnode = GBM_MINOBS, cv.folds=10)
gbmout <- predict.gbm(object = gbm1,newdata = ebayTestClean,GBM_NTREES, type="response")

# SVM - Tuning function commented out, because it's only run once at a certain featureset.
#tuned <- tune.svm(as.factor(sold) ~ ., data = ebayTrainClean, gamma = 2^(-8:0), cost = 2^(0:8))
svm.pred = svm(as.factor(sold) ~ .,data = ebayTrainClean, gamma=0.0078125, cost=64, probability = TRUE, kernel="radial")
svm.eval = predict(svm.pred, newdata = ebayTestClean, probability=TRUE)
svm.eval2 = attr(svm.eval,"probabilities")
svmout = svm.eval2[,2]

# GLMNET
# Tricky Stuff here was figuring out how to transform/pass the dataframe, in such way, that this approach works
train2 = ebayTrainClean
train2$sold = NULL
test2 = ebayTestClean
test2$UniqueID = NULL
x = as.matrix(train2)
glmmod<-cv.glmnet(x,y=as.factor(ebayTrainClean$sold),alpha=0.7,family='binomial',nfolds=10, type.measure="auc")
glm.pred = predict(object = glmmod, as.matrix(test2), type="response",s=glmmod$lambda.min)
glmout = glm.pred[,1]

# Ensemble Model using multiple predictors
ensemble = (gbmout * 6 + rfout * 2 + svmout * 4 + glmout * 2)/14
MySubmission = data.frame(UniqueID = ebayTestClean$UniqueID, Probability1 = as.vector(ensemble))
write.csv(MySubmission, "EnsembleFinalNoCOR.csv", row.names=FALSE)
