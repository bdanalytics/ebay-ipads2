#Libraries
library(tm)
library(e1071)
library(caTools)
library(ROCR)
library(randomForest)
library(gbm)
library(glmnet)
library(caret)
library(mlbench)
library(pROC)

#Just random
set.seed(232)
eBayiPadTrain <- read.csv("~/Projects/mooc-analytics-edge/Kaggle/eBayiPadTrain.csv", stringsAsFactors=FALSE)
eBayiPadTest <- read.csv("~/Projects/mooc-analytics-edge/Kaggle/eBayiPadTest.csv", stringsAsFactors=FALSE)
# Remove dirty data
eBayiPadTrain = subset(eBayiPadTrain, productline != "iPad 5")
eBayiPadTrain = subset(eBayiPadTrain, productline != "iPad mini Retina")

# Text Mining - My approach was: add all kind of frequent words, then do feature selection
# This part is: add all frequent words
eBayTrain = eBayiPadTrain
eBayTest = eBayiPadTest
CorpusDescription = Corpus(VectorSource(c(eBayTrain$description, eBayTest$description)))
CorpusDescription = tm_map(CorpusDescription, content_transformer(tolower), lazy=TRUE)
CorpusDescription = tm_map(CorpusDescription, PlainTextDocument, lazy=TRUE)
CorpusDescription = tm_map(CorpusDescription, removePunctuation, lazy=TRUE)
CorpusDescription = tm_map(CorpusDescription, removeWords, stopwords("english"), lazy=TRUE)
# This has to be run multiple times due to some bug i assume. X100 is some Pen for ipad. Removing apple, ipad and item, since they
# provide no information gain
CorpusDescription = tm_map(CorpusDescription, removeWords, c("X100", "x100", "appl", "apple", "ipad", "item"), lazy=TRUE)
CorpusDescription = tm_map(CorpusDescription, stemDocument, lazy=TRUE)
dtm = DocumentTermMatrix(CorpusDescription)
sparse = removeSparseTerms(dtm, 0.990)
DescriptionWords = as.data.frame(as.matrix(sparse))
colnames(DescriptionWords) = make.names(colnames(DescriptionWords))
DescriptionWordsTrain = head(DescriptionWords, nrow(eBayiPadTrain))
DescriptionWordsTest = tail(DescriptionWords, nrow(eBayiPadTest))

# Preprocess other data
eBayiPadTrain$condition = as.factor(eBayiPadTrain$condition)
eBayiPadTrain$cellular = as.factor(eBayiPadTrain$cellular)
eBayiPadTrain$carrier = as.factor(eBayiPadTrain$carrier)
eBayiPadTrain$color = as.factor(eBayiPadTrain$color)
eBayiPadTrain$storage = as.factor(eBayiPadTrain$storage)
eBayiPadTrain$productline = as.factor(eBayiPadTrain$productline)
# One hot encoding of categorial features
eBayiPadTrain = cbind(eBayiPadTrain[-grep("condition", colnames(eBayiPadTrain))], model.matrix( ~ 0 + condition, eBayiPadTrain))
eBayiPadTrain = cbind(eBayiPadTrain[-grep("productline", colnames(eBayiPadTrain))], model.matrix( ~ 0 + productline, eBayiPadTrain))
eBayiPadTrain = cbind(eBayiPadTrain[-grep("carrier", colnames(eBayiPadTrain))], model.matrix( ~ 0 + carrier, eBayiPadTrain))
eBayiPadTrain = cbind(eBayiPadTrain[-grep("color", colnames(eBayiPadTrain))], model.matrix( ~ 0 + color, eBayiPadTrain))
eBayiPadTrain = cbind(eBayiPadTrain[-grep("storage", colnames(eBayiPadTrain))], model.matrix( ~ 0 + storage, eBayiPadTrain))
eBayiPadTrain = cbind(eBayiPadTrain[-grep("cellular", colnames(eBayiPadTrain))], model.matrix( ~ 0 + cellular, eBayiPadTrain))
# Add words
eBayiPadTrain = cbind(eBayiPadTrain, DescriptionWordsTrain)

#Same process for test data
ebayTrainClean = eBayiPadTrain
ebayTrainClean$description = NULL
ebayTrainClean$UniqueID = NULL
names(ebayTrainClean) = make.names(names(ebayTrainClean), unique=TRUE)
eBayiPadTest$biddable = eBayiPadTest$biddable
eBayiPadTest$condition = as.factor(eBayiPadTest$condition)
eBayiPadTest$cellular = as.factor(eBayiPadTest$cellular)
eBayiPadTest$carrier = as.factor(eBayiPadTest$carrier)
eBayiPadTest$color = as.factor(eBayiPadTest$color)
eBayiPadTest$storage = as.factor(eBayiPadTest$storage)
eBayiPadTest$productline = as.factor(eBayiPadTest$productline)
eBayiPadTest = cbind(eBayiPadTest[-grep("condition", colnames(eBayiPadTest))], model.matrix( ~ 0 + condition, eBayiPadTest))
eBayiPadTest = cbind(eBayiPadTest[-grep("productline", colnames(eBayiPadTest))], model.matrix( ~ 0 + productline, eBayiPadTest))
eBayiPadTest = cbind(eBayiPadTest[-grep("carrier", colnames(eBayiPadTest))], model.matrix( ~ 0 + carrier, eBayiPadTest))
eBayiPadTest = cbind(eBayiPadTest[-grep("color", colnames(eBayiPadTest))], model.matrix( ~ 0 + color, eBayiPadTest))
eBayiPadTest = cbind(eBayiPadTest[-grep("storage", colnames(eBayiPadTest))], model.matrix( ~ 0 + storage, eBayiPadTest))
eBayiPadTest = cbind(eBayiPadTest[-grep("cellular", colnames(eBayiPadTest))], model.matrix( ~ 0 + cellular, eBayiPadTest))
eBayiPadTest = cbind(eBayiPadTest, DescriptionWordsTest)

ebayTestClean = eBayiPadTest
ebayTestClean$description = NULL
names(ebayTestClean) = make.names(names(ebayTestClean), unique=TRUE)
