# Feature selection
# We don't want to have sold in our feature selection
ebayTrainCleanMinusSold = ebayTrainClean
ebayTrainCleanMinusSold$sold = NULL

# Using Caret Package, run RFE to select a good feature set. This uses Random Forests. Tried SVM here too, but got errors
rfFuncs$summary <- twoClassSummary
trainctrl <- trainControl(classProbs= TRUE,
                          summaryFunction = twoClassSummary)
control <- rfeControl(functions=rfFuncs, method="repeatedcv", number=10, repeats = 5, verbose=TRUE)
results <- rfe(ebayTrainCleanMinusSold, as.factor(ebayTrainClean$sold), sizes=c(4,8,10,16,20,22,24,26,28,32,34,38,42,48,50,54,56,60,80), rfeControl=control,metric="ROC", trControl = trainctrl)

# summarize the results
print(results)
# list the chosen features
predictors(results)
# plot the results
plot(results, type=c("g", "o"))
# Transform Dataset to remove discarded features
ebayTrainClean = ebayTrainClean[c(predictors(results), "sold")]
ebayTestClean = ebayTestClean[c(predictors(results), "UniqueID")]

# Remove highly correlated features
correlationMatrix <- cor(ebayTrainClean)
highlyCorrelated <- findCorrelation(correlationMatrix, cutoff=0.7)
ebayTrainClean = ebayTrainClean[,-c(highlyCorrelated)]
ebayTestClean = ebayTestClean[,-c(highlyCorrelated)]

# Create Train/Test set for CV
split = sample.split(ebayTrainClean, SplitRatio = 0.7)
train = subset(ebayTrainClean, split==TRUE)
test = subset(ebayTrainClean, split==FALSE)