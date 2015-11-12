# Cross validation
# Learning approach: Ensemble -> combine predictors
# Did optimal parameter search mostly by hand by comparing auc before/after.
# Used the assumption (which is wrong) that the best performing single models
# will form the best Ensemble.
# The Models should use different approaches to work well in ensembles
# Models used:
# Lasso Regression
# Random Forest
# SVM 
# Bagging
# Weighted them by hand and selected best AUC. Shouldve used four for loops for parameter grid search
# , ranging from 0 to 10

set.seed(123)
# Random Forests
basicRF = randomForest(as.factor(sold) ~ ., data = train, keep.forest=TRUE, ntree = 600)
PredictForest = predict(basicRF, newdata = test, type="prob")
pred = prediction(PredictForest[,2], test$sold)
perf = performance(pred, "tpr", "fpr")
as.numeric(performance(pred, "auc")@y.values)
varImpPlot(basicRF)

# GBM 
# Came to GBM via a talk from Owen Zhang: http://www.slideshare.net/OwenZhang2/winning-data-science-competitions
# Code is from: https://github.com/mlandry22/kaggle/blob/master/GBM_talk_Austin_R_Users_20140724.R
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
gbm1<-gbm(sold ~ ., data=train, distribution = "bernoulli",n.trees = GBM_NTREES,shrinkage = GBM_SHRINKAGE,
          interaction.depth = GBM_DEPTH,n.minobsinnode = GBM_MINOBS, cv.folds=10)
predict.gbm1 <- predict.gbm(object = gbm1,newdata = test,GBM_NTREES, type="response")
pred = prediction(predict.gbm1, test$sold)
perf = performance(pred, "tpr", "fpr")
as.numeric(performance(pred, "auc")@y.values)

# GLMNET with alpha more in the direction of lasso regresssion
# Tricky Stuff here was figuring out how to transform/pass the dataframe in such way, 
# that this approach works. Sold is the y vector, the rest X
test2 = test
test2$sold = NULL
train2 = train
train2$sold = NULL
x = as.matrix(train2)
cv.glmmod<-cv.glmnet(x,y=as.factor(train$sold),alpha=0.8,family='binomial',nfolds=10, type.measure="auc")
glm.pred = predict(object = cv.glmmod, as.matrix(test2), type="response",s=cv.glmmod$lambda.min)
pred = prediction(glm.pred[,1], test$sold)
perf = performance(pred, "tpr", "fpr")
as.numeric(performance(pred, "auc")@y.values)

# SVM with radial kernel
# SVM tuning with e1017 library. Introduced caret later, when this already has been finished.
# Caret implementation of SVM should work here, too
tuned <- tune.svm(as.factor(sold) ~ ., data = train, gamma = 2^(-8:0), cost = 2^(0:8))
# Parameters from tuning used here
svm.cv = svm(as.factor(sold) ~ .,data = train, gamma=0.0078125, cost=64, probability = TRUE, kernel="radial")
cv.eval = predict(svm.cv, newdata = test, probability=TRUE)
cv.eval2 = attr(cv.eval,"probabilities")
# Only sold = 1 is interesting
cv.eval3 = cv.eval2[,2]
pred = prediction(cv.eval3, test$sold)
perf = performance(pred, "tpr", "fpr")
as.numeric(performance(pred, "auc")@y.values)

# Ensemble of all predictors
pred = prediction((predict.gbm1 * 6 + PredictForest[,2] * 2 + cv.eval3 * 4 + glm.pred[,1] * 2 ), test$sold)
perf = performance(pred, "tpr", "fpr")
as.numeric(performance(pred, "auc")@y.values)