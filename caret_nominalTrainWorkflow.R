# caret v '6.0.57'
nominalTrainWorkflow <- function(x, y, wts, info, method, ppOpts, ctrl, lev, testing = FALSE, ...)
{
    cat("entering debug version of nominalTrainWorkflow...\n")
    loadNamespace("caret")
    ppp <- list(options = ppOpts)
    ppp <- c(ppp, ctrl$preProcOptions)

    printed <- format(info$loop, digits = 4)
    colnames(printed) <- gsub("^\\.", "", colnames(printed))

    ## For 632 estimator, add an element to the index of zeros to trick it into
    ## fitting and predicting the full data set.

    resampleIndex <- ctrl$index
    if (ctrl$method %in% c("boot632"))
    {
        resampleIndex <- c(list(AllData = rep(0, nrow(x))), resampleIndex)
        ctrl$indexOut <- c(list(AllData = rep(0, nrow(x))), ctrl$indexOut)
    }
    `%op%` <- getOper(ctrl$allowParallel && getDoParWorkers() > 1)

    pkgs <- c("methods", "caret")
    if (!is.null(method$library)) pkgs <- c(pkgs, method$library)

    result <- foreach(iter = seq(along = resampleIndex), .combine = "c",
                      .verbose = FALSE, .packages = pkgs, .errorhandling = "stop") %:%
        foreach(parm = 1:nrow(info$loop), .combine = "c", .verbose = FALSE,
                .packages = pkgs, .errorhandling = "stop") %op%
        {
            testing <- FALSE
            if (!(length(ctrl$seeds) == 1 && is.na(ctrl$seeds)))
                set.seed(ctrl$seeds[[iter]][parm])

            loadNamespace("caret")
            if (ctrl$verboseIter)
                progress(printed[parm, ,drop = FALSE], names(resampleIndex), iter)

            if (names(resampleIndex)[iter] != "AllData")
            {
                modelIndex <- resampleIndex[[iter]]
                holdoutIndex <- ctrl$indexOut[[iter]]
            } else {
                modelIndex <- 1:nrow(x)
                holdoutIndex <- modelIndex
            }

            if (testing) cat("pre-model\n")

            if (is.null(info$submodels[[parm]]) || nrow(info$submodels[[parm]]) > 0) {
                submod <- info$submodels[[parm]]
            } else submod <- NULL

            mod <- try(
                createModel(x = x[modelIndex,,drop = FALSE],
                            y = y[modelIndex],
                            wts = wts[modelIndex],
                            method = method,
                            tuneValue = info$loop[parm,,drop = FALSE],
                            obsLevels = lev,
                            pp = ppp,
                            classProbs = ctrl$classProbs,
                            sampling = ctrl$sampling,
                            ...),
                silent = TRUE)

            if (class(mod)[1] != "try-error")
            {
                predicted <- try(
                    predictionFunction(method = method,
                                       modelFit = mod$fit,
                                       newdata = x[holdoutIndex,, drop = FALSE],
                                       preProc = mod$preProc,
                                       param = submod),
                    silent = TRUE)

                if (class(predicted)[1] == "try-error")
                {
                    wrn <- paste(colnames(printed[parm,,drop = FALSE]),
                                 printed[parm,,drop = FALSE],
                                 sep = "=",
                                 collapse = ", ")
                    wrn <- paste("predictions failed for ", names(resampleIndex)[iter],
                                 ": ", wrn, " ", as.character(predicted), sep = "")
                    if (ctrl$verboseIter) cat(wrn, "\n")
                    warning(wrn)
                    rm(wrn)

                    ## setup a dummy results with NA values for all predictions
                    nPred <- length(holdoutIndex)
                    if (!is.null(lev))
                    {
                        predicted <- rep("", nPred)
                        predicted[seq(along = predicted)] <- NA
                    } else {
                        predicted <- rep(NA, nPred)
                    }
                    if (!is.null(submod))
                    {
                        tmp <- predicted
                        predicted <- vector(mode = "list", length = nrow(info$submodels[[parm]]) + 1)
                        for (i in seq(along = predicted)) predicted[[i]] <- tmp
                        rm(tmp)
                    }
                }
            } else {
                wrn <- paste(colnames(printed[parm,,drop = FALSE]),
                             printed[parm,,drop = FALSE],
                             sep = "=",
                             collapse = ", ")
                wrn <- paste("model fit failed for ", names(resampleIndex)[iter],
                             ": ", wrn, " ", as.character(mod), sep = "")
                if (ctrl$verboseIter) cat(wrn, "\n")
                warning(wrn)
                rm(wrn)

                ## setup a dummy results with NA values for all predictions
                nPred <- length(holdoutIndex)
                if (!is.null(lev))
                {
                    predicted <- rep("", nPred)
                    predicted[seq(along = predicted)] <- NA
                } else {
                    predicted <- rep(NA, nPred)
                }
                if (!is.null(submod))
                {
                    tmp <- predicted
                    predicted <- vector(mode = "list", length = nrow(info$submodels[[parm]]) + 1)
                    for (i in seq(along = predicted)) predicted[[i]] <- tmp
                    rm(tmp)
                }
            }

            if (testing) print(head(predicted))
            if (ctrl$classProbs)
            {
                if (class(mod)[1] != "try-error")
                {
                    probValues <- probFunction(method = method,
                                               modelFit = mod$fit,
                                               newdata = x[holdoutIndex,, drop = FALSE],
                                               preProc = mod$preProc,
                                               param = submod)
                } else {
                    probValues <- as.data.frame(matrix(NA, nrow = nPred, ncol = length(lev)))
                    colnames(probValues) <- lev
                    if (!is.null(submod))
                    {
                        tmp <- probValues
                        probValues <- vector(mode = "list", length = nrow(info$submodels[[parm]]) + 1)
                        for (i in seq(along = probValues)) probValues[[i]] <- tmp
                        rm(tmp)
                    }
                }
                if (testing) print(head(probValues))
            }

            ##################################

            if (is.numeric(y)) {
                if (is.logical(ctrl$predictionBounds) && any(ctrl$predictionBounds)) {
                    if (is.list(predicted)) {
                        predicted <- lapply(predicted, trimPredictions,
                                            mod_type = "Regression",
                                            bounds = ctrl$predictionBounds,
                                            limits = ctrl$yLimits)
                    } else {
                        predicted <- trimPredictions(mod_type = "Regression",
                                                     bounds = ctrl$predictionBounds,
                                                     limits = ctrl$yLimit,
                                                     pred = predicted)
                    }
                } else {
                    if (is.numeric(ctrl$predictionBounds) && any(!is.na(ctrl$predictionBounds))) {
                        if (is.list(predicted)) {
                            predicted <- lapply(predicted, trimPredictions,
                                                mod_type = "Regression",
                                                bounds = ctrl$predictionBounds,
                                                limits = ctrl$yLimits)
                        } else {
                            predicted <- trimPredictions(mod_type = "Regression",
                                                         bounds = ctrl$predictionBounds,
                                                         limits = ctrl$yLimit,
                                                         pred = predicted)
                        }
                    }
                }
            }

            if (!is.null(submod))
            {
                ## merge the fixed and seq parameter values together
                allParam <- expandParameters(info$loop[parm,,drop = FALSE], info$submodels[[parm]])
                allParam <- allParam[complete.cases(allParam),, drop = FALSE]

                ## collate the predicitons across all the sub-models
                predicted <- lapply(predicted,
                                    function(x, y, wts, lv, rows) {
                                        if (!is.factor(x) & is.character(x))
                                            x <- factor(as.character(x), levels = lv)
                                        out <- data.frame(pred = x, obs = y, stringsAsFactors = FALSE)
                                        if (!is.null(wts)) out$weights <- wts
                                        out$rowIndex <- rows
                                        out
                                    },
                                    y = y[holdoutIndex],
                                    wts = wts[holdoutIndex],
                                    lv = lev,
                                    rows = holdoutIndex)
                if (testing) print(head(predicted))

                ## same for the class probabilities
                if (ctrl$classProbs)
                {
                    for (k in seq(along = predicted))
                        predicted[[k]] <- cbind(predicted[[k]], probValues[[k]])
                }

                if (ctrl$savePredictions)
                {
                    tmpPred <- predicted
                    for (modIndex in seq(along = tmpPred))
                    {
                        tmpPred[[modIndex]]$rowIndex <- holdoutIndex
                        tmpPred[[modIndex]] <- merge(tmpPred[[modIndex]],
                                                     allParam[modIndex,,drop = FALSE],
                                                     all = TRUE)
                    }
                    tmpPred <- rbind.fill(tmpPred)
                    tmpPred$Resample <- names(resampleIndex)[iter]
                } else tmpPred <- NULL

                ## get the performance for this resample for each sub-model
                thisResample <- lapply(predicted,
                                       ctrl$summaryFunction,
                                       lev = lev,
                                       model = method)
                if (testing) print(head(thisResample))
                ## for classification, add the cell counts
                if (length(lev) > 1)
                {
                    cells <- lapply(predicted,
                                    function(x) flatTable(x$pred, x$obs))
                    for (ind in seq(along = cells))
                        thisResample[[ind]] <- c(thisResample[[ind]], cells[[ind]])
                }
                thisResample <- do.call("rbind", thisResample)
                thisResample <- cbind(allParam, thisResample)
            } else {
                if (is.factor(y))
                    predicted <- factor(as.character(predicted), levels = lev)
                tmp <- data.frame(pred = predicted,
                                  obs = y[holdoutIndex],
                                  stringsAsFactors = FALSE)
                ## Sometimes the code above does not coerce the first
                ## columnn to be named "pred" so force it
                names(tmp)[1] <- "pred"
                if (!is.null(wts)) tmp$weights <- wts[holdoutIndex]
                if (ctrl$classProbs) tmp <- cbind(tmp, probValues)
                tmp$rowIndex <- holdoutIndex

                if (ctrl$savePredictions)
                {
                    tmpPred <- tmp
                    tmpPred$rowIndex <- holdoutIndex
                    tmpPred <- merge(tmpPred, info$loop[parm,,drop = FALSE], all = TRUE)
                    tmpPred$Resample <- names(resampleIndex)[iter]
                } else tmpPred <- NULL

                ##################################

                thisResample <- ctrl$summaryFunction(tmp,
                                                     lev = lev,
                                                     model = method)

                ## if classification, get the confusion matrix
                if (length(lev) > 1)
                    thisResample <- c(thisResample, flatTable(tmp$pred, tmp$obs))
                thisResample <- as.data.frame(t(thisResample))
                thisResample <- cbind(thisResample, info$loop[parm,,drop = FALSE])
            }
            thisResample$Resample <- names(resampleIndex)[iter]

            if (ctrl$verboseIter)
                progress(printed[parm,,drop = FALSE], names(resampleIndex), iter, FALSE)
            list(resamples = thisResample, pred = tmpPred)
        }

    resamples <- rbind.fill(result[names(result) == "resamples"])
    pred <- if (ctrl$savePredictions) rbind.fill(result[names(result) == "pred"]) else NULL
    if (ctrl$method %in% c("boot632"))
    {
        perfNames <- names(ctrl$summaryFunction(data.frame(obs = y, pred = sample(y), weights = 1),
                                                lev = lev, model = method))
        apparent <- subset(resamples, Resample == "AllData")
        apparent <- apparent[, !grepl("^\\.cell|Resample", colnames(apparent)), drop = FALSE]
        names(apparent)[which(names(apparent) %in% perfNames)] <-
            paste(names(apparent)[which(names(apparent) %in% perfNames)], "Apparent", sep = "")
        names(apparent) <- gsub("^\\.", "", names(apparent))
        if (any(!complete.cases(apparent[, !grepl("^cell|Resample", colnames(apparent)), drop = FALSE])))
        {
            warning("There were missing values in the apparent performance measures.")
        }
        resamples <- subset(resamples, Resample != "AllData")
    }
    names(resamples) <- gsub("^\\.", "", names(resamples))

    if (any(!complete.cases(resamples[, !grepl("^cell|Resample", colnames(resamples)), drop = FALSE])))
    {
        warning("There were missing values in resampled performance measures.")
    }

    out <- ddply(resamples[, !grepl("^cell|Resample", colnames(resamples)), drop = FALSE],
                 ## TODO check this for seq models
                 gsub("^\\.", "", colnames(info$loop)),
                 MeanSD,
                 exclude = gsub("^\\.", "", colnames(info$loop)))

    if (ctrl$method %in% c("boot632"))
    {
        out <- merge(out, apparent)
        for (p in seq(along = perfNames))
        {
            const <- 1 - exp(-1)
            out[, perfNames[p]] <- (const * out[, perfNames[p]]) +
                ((1 - const) * out[, paste(perfNames[p], "Apparent", sep = "")])
        }
    }

    list(performance = out, resamples = resamples,
        predictions = if (ctrl$savePredictions) pred else NULL)
}

train.default <-
function (x, y, method = "rf", preProcess = NULL, ..., weights = NULL,
          metric = ifelse(is.factor(y), "Accuracy", "RMSE"), maximize = ifelse(metric %in%
                                                                                   c("RMSE", "logLoss"), FALSE, TRUE), trControl = trainControl(),
          tuneGrid = NULL, tuneLength = 3)
{
    print("entering local version of train.default...")
    startTime <- proc.time()
    if (is.list(method)) {
        minNames <- c("library", "type", "parameters", "grid",
                      "fit", "predict", "prob")
        nameCheck <- minNames %in% names(method)
        if (!all(nameCheck))
            stop(paste("some required components are missing:",
                       paste(minNames[!nameCheck], collapse = ", ")))
        models <- method
        method <- "custom"
    }
    else {
        models <- getModelInfo(method, regex = FALSE)[[1]]
        if (length(models) == 0)
            stop(paste("Model", method, "is not in caret's built-in library"))
    }
    checkInstall(models$library)
    for (i in seq(along = models$library)) do.call("require",
                                                   list(package = models$library[i]))
    paramNames <- as.character(models$parameters$parameter)
    funcCall <- match.call(expand.dots = TRUE)
    modelType <- get_model_type(y)
    if (!(modelType %in% models$type))
        stop(paste("wrong model type for", tolower(modelType)))
    if (grepl("^svm", method) & grepl("String$", method)) {
        if (is.vector(x) && is.character(x)) {
            stop("'x' should be a character matrix with a single column for string kernel methods")
        }
        if (is.matrix(x) && is.numeric(x)) {
            stop("'x' should be a character matrix with a single column for string kernel methods")
        }
        if (is.data.frame(x)) {
            stop("'x' should be a character matrix with a single column for string kernel methods")
        }
    }
    if (modelType == "Regression" & length(unique(y)) == 2)
        warning(paste("You are trying to do regression and your outcome only has",
                      "two possible values Are you trying to do classification?",
                      "If so, use a 2 level factor as your outcome column."))
    if (modelType != "Classification" & !is.null(trControl$sampling))
        stop("sampling methods are only implemented for classification problems")
    if (!is.null(trControl$sampling)) {
        trControl$sampling <- parse_sampling(trControl$sampling)
    }
    if (any(class(x) == "data.table"))
        x <- as.data.frame(x)
    check_dims(x = x, y = y)
    n <- if (class(y)[1] == "Surv")
        nrow(y)
    else length(y)
    if (any(search() == "package:doMC") && getDoParRegistered() &&
        "RWeka" %in% models$library)
        warning("Models using Weka will not work with parallel processing with multicore/doMC")
    flush.console()
    if (!is.null(preProcess) && !(all(preProcess %in% ppMethods)))
        stop(paste("pre-processing methods are limited to:",
                   paste(ppMethods, collapse = ", ")))
    if (modelType == "Classification") {
        classLevels <- levels(y)
        if (trControl$classProbs && any(classLevels != make.names(classLevels))) {
            stop(paste("At least one of the class levels is not a valid R variable name;",
                       "This will cause errors when class probabilities are generated because",
                       "the variables names will be converted to ",
                       paste(make.names(classLevels), collapse = ", "),
                       ". Please use factor levels that can be used as valid R variable names",
                       " (see ?make.names for help)."))
        }
        if (metric %in% c("RMSE", "Rsquared"))
            stop(paste("Metric", metric, "not applicable for classification models"))
        if (!trControl$classProbs && metric == "ROC")
            stop(paste("Class probabilities are needed to score models using the",
                       "area under the ROC curve. Set `classProbs = TRUE`",
                       "in the trainControl() function."))
        if (trControl$classProbs) {
            if (!is.function(models$prob)) {
                warning("Class probabilities were requested for a model that does not implement them")
                trControl$classProbs <- FALSE
            }
        }
    }
    else {
        if (metric %in% c("Accuracy", "Kappa"))
            stop(paste("Metric", metric, "not applicable for regression models"))
        classLevels <- NA
        if (trControl$classProbs) {
            warning("cannnot compute class probabilities for regression")
            trControl$classProbs <- FALSE
        }
    }
    if (trControl$method == "oob" & is.null(models$oob))
        stop("Out of bag estimates are not implemented for this model")
    if (is.null(trControl$index)) {
        if (trControl$method == "custom")
            stop("'custom' resampling is appropriate when the `trControl` argument `index` is used")
        trControl$index <- switch(tolower(trControl$method),
                                  oob = NULL, none = list(seq(along = y)), alt_cv = ,
                                  cv = createFolds(y, trControl$number, returnTrain = TRUE),
                                  repeatedcv = , adaptive_cv = createMultiFolds(y,
                                                                                trControl$number, trControl$repeats), loocv = createFolds(y,
                                                                                                                                          n, returnTrain = TRUE), boot = , boot632 = ,
                                  adaptive_boot = createResample(y, trControl$number),
                                  test = createDataPartition(y, 1, trControl$p), adaptive_lgocv = ,
                                  lgocv = createDataPartition(y, trControl$number,
                                                              trControl$p), timeslice = createTimeSlices(seq(along = y),
                                                                                                         initialWindow = trControl$initialWindow, horizon = trControl$horizon,
                                                                                                         fixedWindow = trControl$fixedWindow)$train, subsemble = subsemble_index(y,
                                                                                                                                                                                 V = trControl$number, J = trControl$repeats))
    }
    else {
        index_types <- unlist(lapply(trControl$index, is.integer))
        if (!isTRUE(all(index_types)))
            stop("`index` should be lists of integers.")
        if (!is.null(trControl$indexOut)) {
            index_types <- unlist(lapply(trControl$indexOut,
                                         is.integer))
            if (!isTRUE(all(index_types)))
                stop("`indexOut` should be lists of integers.")
        }
    }
    if (trControl$method == "subsemble") {
        if (!trControl$savePredictions)
            trControl$savePredictions <- TRUE
        trControl$indexOut <- trControl$index$holdout
        trControl$index <- trControl$index$model
    }
    if (is.null(trControl$indexOut) & trControl$method != "oob") {
        if (tolower(trControl$method) != "timeslice") {
            y_index <- if (class(y)[1] == "Surv")
                1:nrow(y)
            else seq(along = y)
            trControl$indexOut <- lapply(trControl$index, function(training,
                                                                   allSamples) allSamples[-unique(training)], allSamples = y_index)
            names(trControl$indexOut) <- prettySeq(trControl$indexOut)
        }
        else {
            trControl$indexOut <- createTimeSlices(seq(along = y),
                                                   initialWindow = trControl$initialWindow, horizon = trControl$horizon,
                                                   fixedWindow = trControl$fixedWindow)$test
        }
    }
    if (trControl$method != "oob" & is.null(trControl$index))
        names(trControl$index) <- prettySeq(trControl$index)
    if (trControl$method != "oob" & is.null(names(trControl$index)))
        names(trControl$index) <- prettySeq(trControl$index)
    if (trControl$method != "oob" & is.null(names(trControl$indexOut)))
        names(trControl$indexOut) <- prettySeq(trControl$indexOut)
    if (!is.null(preProcess)) {
        ppOpt <- list(options = preProcess)
        if (length(trControl$preProcOptions) > 0)
            ppOpt <- c(ppOpt, trControl$preProcOptions)
    }
    else ppOpt <- NULL
    if (is.null(tuneGrid)) {
        if (!is.null(ppOpt) && length(models$parameters$parameter) >
            1 && as.character(models$parameters$parameter) !=
            "parameter") {
            pp <- list(method = ppOpt$options)
            if ("ica" %in% pp$method)
                pp$n.comp <- ppOpt$ICAcomp
            if ("pca" %in% pp$method)
                pp$thresh <- ppOpt$thresh
            if ("knnImpute" %in% pp$method)
                pp$k <- ppOpt$k
            pp$x <- x
            ppObj <- do.call("preProcess", pp)
            tuneGrid <- models$grid(x = predict(ppObj, x), y = y,
                                    len = tuneLength, search = trControl$search)
            rm(ppObj, pp)
        }
        else tuneGrid <- models$grid(x = x, y = y, len = tuneLength,
                                     search = trControl$search)
    }
    dotNames <- hasDots(tuneGrid, models)
    if (dotNames)
        colnames(tuneGrid) <- gsub("^\\.", "", colnames(tuneGrid))
    tuneNames <- as.character(models$parameters$parameter)
    goodNames <- all.equal(sort(tuneNames), sort(names(tuneGrid)))
    if (!is.logical(goodNames) || !goodNames) {
        stop(paste("The tuning parameter grid should have columns",
                   paste(tuneNames, collapse = ", ", sep = "")))
    }
    if (trControl$method == "none" && nrow(tuneGrid) != 1)
        stop("Only one model should be specified in tuneGrid with no resampling")
    trControl$yLimits <- if (is.numeric(y))
        get_range(y)
    else NULL
    if (trControl$method != "none") {
        if (is.function(models$loop) && nrow(tuneGrid) > 1) {
            trainInfo <- models$loop(tuneGrid)
            if (!all(c("loop", "submodels") %in% names(trainInfo)))
                stop("The 'loop' function should produce a list with elements 'loop' and 'submodels'")
            lengths <- unlist(lapply(trainInfo$submodels, nrow))
            if (all(lengths == 0))
                trainInfo$submodels <- NULL
        }
        else trainInfo <- list(loop = tuneGrid)
        if (is.null(trControl$seeds)) {
            seeds <- vector(mode = "list", length = length(trControl$index))
            seeds <- lapply(seeds, function(x) sample.int(n = 1e+06,
                                                          size = nrow(trainInfo$loop)))
            seeds[[length(trControl$index) + 1]] <- sample.int(n = 1e+06,
                                                               size = 1)
            trControl$seeds <- seeds
        }
        else {
            if (!(length(trControl$seeds) == 1 && is.na(trControl$seeds))) {
                numSeeds <- unlist(lapply(trControl$seeds, length))
                badSeed <- (length(trControl$seeds) < length(trControl$index) +
                                1) || (any(numSeeds[-length(numSeeds)] < nrow(trainInfo$loop)))
                if (badSeed)
                    stop(paste("Bad seeds: the seed object should be a list of length",
                               length(trControl$index) + 1, "with", length(trControl$index),
                               "integer vectors of size", nrow(trainInfo$loop),
                               "and the last list element having a", "single integer"))
            }
        }
        if (trControl$method == "oob") {
            perfNames <- metric
        }
        else {
            testSummary <- evalSummaryFunction(y, wts = weights,
                                               ctrl = trControl, lev = classLevels, metric = metric,
                                               method = method)
            perfNames <- names(testSummary)
        }
        if (!(metric %in% perfNames)) {
            oldMetric <- metric
            metric <- perfNames[1]
            warning(paste("The metric \"", oldMetric, "\" was not in ",
                          "the result set. ", metric, " will be used instead.",
                          sep = ""))
        }
        if (trControl$method == "oob") {
            tmp <- oobTrainWorkflow(x = x, y = y, wts = weights,
                                    info = trainInfo, method = models, ppOpts = preProcess,
                                    ctrl = trControl, lev = classLevels, ...)
            performance <- tmp
            perfNames <- colnames(performance)
            perfNames <- perfNames[!(perfNames %in% as.character(models$parameters$parameter))]
            if (!(metric %in% perfNames)) {
                oldMetric <- metric
                metric <- perfNames[1]
                warning(paste("The metric \"", oldMetric, "\" was not in ",
                              "the result set. ", metric, " will be used instead.",
                              sep = ""))
            }
        }
        else {
            if (trControl$method == "LOOCV") {
                tmp <- looTrainWorkflow(x = x, y = y, wts = weights,
                                        info = trainInfo, method = models, ppOpts = preProcess,
                                        ctrl = trControl, lev = classLevels, ...)
                performance <- tmp$performance
            }
            else {
                if (!grepl("adapt", trControl$method)) {
                    tmp <- nominalTrainWorkflow(x = x, y = y, wts = weights,
                                                info = trainInfo, method = models, ppOpts = preProcess,
                                                ctrl = trControl, lev = classLevels, ...)
                    performance <- tmp$performance
                    resampleResults <- tmp$resample
                }
                else {
                    tmp <- adaptiveWorkflow(x = x, y = y, wts = weights,
                                            info = trainInfo, method = models, ppOpts = preProcess,
                                            ctrl = trControl, lev = classLevels, metric = metric,
                                            maximize = maximize, ...)
                    performance <- tmp$performance
                    resampleResults <- tmp$resample
                }
            }
        }
        if (!(trControl$method %in% c("LOOCV", "oob"))) {
            if (modelType == "Classification" && length(grep("^\\cell",
                                                             colnames(resampleResults))) > 0) {
                resampledCM <- resampleResults[, !(names(resampleResults) %in%
                                                       perfNames)]
                resampleResults <- resampleResults[, -grep("^\\cell",
                                                           colnames(resampleResults))]
            }
            else resampledCM <- NULL
        }
        else resampledCM <- NULL
        if (trControl$verboseIter) {
            cat("Aggregating results\n")
            flush.console()
        }
        perfCols <- names(performance)
        perfCols <- perfCols[!(perfCols %in% paramNames)]
        if (all(is.na(performance[, metric]))) {
            cat(paste("Something is wrong; all the", metric,
                      "metric values are missing:\n"))
            print(summary(performance[, perfCols[!grepl("SD$",
                                                        perfCols)], drop = FALSE]))
            stop("Stopping")
        }
        if (!is.null(models$sort))
            performance <- models$sort(performance)
        if (any(is.na(performance[, metric])))
            warning("missing values found in aggregated results")
        if (trControl$verboseIter && nrow(performance) > 1) {
            cat("Selecting tuning parameters\n")
            flush.console()
        }
        selectClass <- class(trControl$selectionFunction)[1]
        if (grepl("adapt", trControl$method)) {
            perf_check <- subset(performance, .B == max(performance$.B))
        }
        else perf_check <- performance
        if (selectClass == "function") {
            bestIter <- trControl$selectionFunction(x = perf_check,
                                                    metric = metric, maximize = maximize)
        }
        else {
            if (trControl$selectionFunction == "oneSE") {
                bestIter <- oneSE(perf_check, metric, length(trControl$index),
                                  maximize)
            }
            else {
                bestIter <- do.call(trControl$selectionFunction,
                                    list(x = perf_check, metric = metric, maximize = maximize))
            }
        }
        if (is.na(bestIter) || length(bestIter) != 1)
            stop("final tuning parameters could not be determined")
        if (grepl("adapt", trControl$method)) {
            best_perf <- perf_check[bestIter, as.character(models$parameters$parameter),
                                    drop = FALSE]
            performance$order <- 1:nrow(performance)
            bestIter <- merge(performance, best_perf)$order
            performance$order <- NULL
        }
        bestTune <- performance[bestIter, paramNames, drop = FALSE]
    }
    else {
        bestTune <- tuneGrid
        performance <- evalSummaryFunction(y, wts = weights,
                                           ctrl = trControl, lev = classLevels, metric = metric,
                                           method = method)
        perfNames <- names(performance)
        performance <- as.data.frame(t(performance))
        performance <- cbind(performance, tuneGrid)
        performance <- performance[-1, , drop = FALSE]
        tmp <- resampledCM <- NULL
    }
    if (!(trControl$method %in% c("LOOCV", "oob", "none"))) {
        byResample <- switch(trControl$returnResamp, none = NULL,
                             all = {
                                 out <- resampleResults
                                 colnames(out) <- gsub("^\\.", "", colnames(out))
                                 out
                             }, final = {
                                 out <- merge(bestTune, resampleResults)
                                 out <- out[, !(names(out) %in% names(tuneGrid)),
                                            drop = FALSE]
                                 out
                             })
    }
    else {
        byResample <- NULL
    }
    orderList <- list()
    for (i in seq(along = paramNames)) orderList[[i]] <- performance[,
                                                                     paramNames[i]]
    names(orderList) <- paramNames
    performance <- performance[do.call("order", orderList), ]
    if (trControl$verboseIter) {
        bestText <- paste(paste(names(bestTune), "=", format(bestTune,
                                                             digits = 3)), collapse = ", ")
        if (nrow(performance) == 1)
            bestText <- "final model"
        cat("Fitting", bestText, "on full training set\n")
        flush.console()
    }
    if (!(length(trControl$seeds) == 1 && is.na(trControl$seeds)))
        set.seed(trControl$seeds[[length(trControl$seeds)]][1])
    finalTime <- system.time(finalModel <- createModel(x = x,
                                                       y = y, wts = weights, method = models, tuneValue = bestTune,
                                                       obsLevels = classLevels, pp = ppOpt, last = TRUE, classProbs = trControl$classProbs,
                                                       sampling = trControl$sampling, ...))
    if (trControl$trim && !is.null(models$trim)) {
        if (trControl$verboseIter)
            old_size <- object.size(finalModel$fit)
        finalModel$fit <- models$trim(finalModel$fit)
        if (trControl$verboseIter) {
            new_size <- object.size(finalModel$fit)
            reduction <- format(old_size - new_size, units = "Mb")
            if (reduction == "0 Mb")
                reduction <- "< 0 Mb"
            p_reduction <- (unclass(old_size) - unclass(new_size))/unclass(old_size) *
                100
            p_reduction <- if (p_reduction < 1)
                "< 1%"
            else paste0(round(p_reduction, 0), "%")
            cat("Final model footprint reduced by", reduction,
                "or", p_reduction, "\n")
        }
    }
    pp <- finalModel$preProc
    finalModel <- finalModel$fit
    if (method == "pls")
        finalModel$bestIter <- bestTune
    if (method == "glmnet")
        finalModel$lambdaOpt <- bestTune$lambda
    if (trControl$returnData) {
        outData <- if (!is.data.frame(x))
            try(as.data.frame(x), silent = TRUE)
        else x
        if (class(outData)[1] == "try-error") {
            warning("The training data could not be converted to a data frame for saving")
            outData <- NULL
        }
        else {
            outData$.outcome <- y
            if (!is.null(weights))
                outData$.weights <- weights
        }
    }
    else outData <- NULL
    if (trControl$returnData & method == "pam") {
        finalModel$xData <- x
        finalModel$yData <- y
    }
    endTime <- proc.time()
    times <- list(everything = endTime - startTime, final = finalTime)
    out <- structure(list(method = method, modelInfo = models,
                          modelType = modelType, results = performance, pred = tmp$predictions,
                          bestTune = bestTune, call = funcCall, dots = list(...),
                          metric = metric, control = trControl, finalModel = finalModel,
                          preProcess = pp, trainingData = outData, resample = byResample,
                          resampledCM = resampledCM, perfNames = perfNames, maximize = maximize,
                          yLimits = trControl$yLimits, times = times), class = "train")
    trControl$yLimits <- NULL
    if (trControl$timingSamps > 0) {
        pData <- lapply(x, function(x, n) sample(x, n, replace = TRUE),
                        n = trControl$timingSamps)
        pData <- as.data.frame(pData)
        out$times$prediction <- system.time(predict(out, pData))
    }
    else out$times$prediction <- rep(NA, 3)
    out
}