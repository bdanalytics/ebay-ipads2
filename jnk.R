logStr <- sprintf("echo '[%.0f] caret_nominalTrainWorkflow.R: bgn parallel processing for result...' >> parallel.log", proc.time()["elapsed"])
system(logStr)

myglm.fit <- function (x, y, weights = rep(1, nobs), start = NULL, etastart = NULL,
          mustart = NULL, offset = rep(0, nobs), family = gaussian(),
          control = list(), intercept = TRUE)
{
    logStr <- sprintf("echo '[%.0f] myglm.fit: ...' >> parallel.log", proc.time()["elapsed"])
    system(logStr)

    control <- do.call("glm.control", control)
    x <- as.matrix(x)
    xnames <- dimnames(x)[[2L]]
    ynames <- if (is.matrix(y))
        rownames(y)
    else names(y)
    conv <- FALSE
    nobs <- NROW(y)
    nvars <- ncol(x)
    EMPTY <- nvars == 0
    if (is.null(weights))
        weights <- rep.int(1, nobs)
    if (is.null(offset))
        offset <- rep.int(0, nobs)
    variance <- family$variance
    linkinv <- family$linkinv
    if (!is.function(variance) || !is.function(linkinv))
        stop("'family' argument seems not to be a valid family object",
             call. = FALSE)
    dev.resids <- family$dev.resids
    aic <- family$aic
    mu.eta <- family$mu.eta
    unless.null <- function(x, if.null) if (is.null(x))
        if.null
    else x
    valideta <- unless.null(family$valideta, function(eta) TRUE)
    validmu <- unless.null(family$validmu, function(mu) TRUE)
    if (is.null(mustart)) {
        eval(family$initialize)
    }
    else {
        mukeep <- mustart
        eval(family$initialize)
        mustart <- mukeep
    }
    if (EMPTY) {
        eta <- rep.int(0, nobs) + offset
        if (!valideta(eta))
            stop("invalid linear predictor values in empty model",
                 call. = FALSE)
        mu <- linkinv(eta)
        if (!validmu(mu))
            stop("invalid fitted means in empty model", call. = FALSE)
        dev <- sum(dev.resids(y, mu, weights))
        w <- ((weights * mu.eta(eta)^2)/variance(mu))^0.5
        residuals <- (y - mu)/mu.eta(eta)
        good <- rep_len(TRUE, length(residuals))
        boundary <- conv <- TRUE
        coef <- numeric()
        iter <- 0L
    }
    else {
        coefold <- NULL
        eta <- if (!is.null(etastart))
            etastart
        else if (!is.null(start))
            if (length(start) != nvars)
                stop(gettextf("length of 'start' should equal %d and correspond to initial coefs for %s",
                              nvars, paste(deparse(xnames), collapse = ", ")),
                     domain = NA)
        else {
            coefold <- start
            offset + as.vector(if (NCOL(x) == 1L)
                x * start
                else x %*% start)
        }
        else family$linkfun(mustart)
        mu <- linkinv(eta)
        if (!(validmu(mu) && valideta(eta)))
            stop("cannot find valid starting values: please specify some",
                 call. = FALSE)
        devold <- sum(dev.resids(y, mu, weights))
        boundary <- conv <- FALSE
        for (iter in 1L:control$maxit) {
            good <- weights > 0
            varmu <- variance(mu)[good]
            if (anyNA(varmu))
                stop("NAs in V(mu)")
            if (any(varmu == 0))
                stop("0s in V(mu)")
            mu.eta.val <- mu.eta(eta)
            if (any(is.na(mu.eta.val[good])))
                stop("NAs in d(mu)/d(eta)")
            good <- (weights > 0) & (mu.eta.val != 0)
            if (all(!good)) {
                conv <- FALSE
                warning(gettextf("no observations informative at iteration %d",
                                 iter), domain = NA)
                break
            }
            z <- (eta - offset)[good] + (y - mu)[good]/mu.eta.val[good]
            w <- sqrt((weights[good] * mu.eta.val[good]^2)/variance(mu)[good])
            fit <- .Call(C_Cdqrls, x[good, , drop = FALSE] *
                             w, z * w, min(1e-07, control$epsilon/1000), check = FALSE)
            if (any(!is.finite(fit$coefficients))) {
                conv <- FALSE
                warning(gettextf("non-finite coefficients at iteration %d",
                                 iter), domain = NA)
                break
            }
            if (nobs < fit$rank)
                stop(sprintf(ngettext(nobs, "X matrix has rank %d, but only %d observation",
                                      "X matrix has rank %d, but only %d observations"),
                             fit$rank, nobs), domain = NA)
            start[fit$pivot] <- fit$coefficients
            eta <- drop(x %*% start)
            mu <- linkinv(eta <- eta + offset)
            dev <- sum(dev.resids(y, mu, weights))
            if (control$trace)
                cat("Deviance = ", dev, " Iterations - ", iter,
                    "\n", sep = "")
            boundary <- FALSE
            if (!is.finite(dev)) {
                if (is.null(coefold))
                    stop("no valid set of coefficients has been found: please supply starting values",
                         call. = FALSE)
                warning("step size truncated due to divergence",
                        call. = FALSE)
                ii <- 1
                while (!is.finite(dev)) {
                    if (ii > control$maxit)
                        stop("inner loop 1; cannot correct step size",
                             call. = FALSE)
                    ii <- ii + 1
                    start <- (start + coefold)/2
                    eta <- drop(x %*% start)
                    mu <- linkinv(eta <- eta + offset)
                    dev <- sum(dev.resids(y, mu, weights))
                }
                boundary <- TRUE
                if (control$trace)
                    cat("Step halved: new deviance = ", dev, "\n",
                        sep = "")
            }
            if (!(valideta(eta) && validmu(mu))) {
                if (is.null(coefold))
                    stop("no valid set of coefficients has been found: please supply starting values",
                         call. = FALSE)
                warning("step size truncated: out of bounds",
                        call. = FALSE)
                ii <- 1
                while (!(valideta(eta) && validmu(mu))) {
                    if (ii > control$maxit)
                        stop("inner loop 2; cannot correct step size",
                             call. = FALSE)
                    ii <- ii + 1
                    start <- (start + coefold)/2
                    eta <- drop(x %*% start)
                    mu <- linkinv(eta <- eta + offset)
                }
                boundary <- TRUE
                dev <- sum(dev.resids(y, mu, weights))
                if (control$trace)
                    cat("Step halved: new deviance = ", dev, "\n",
                        sep = "")
            }
            if (abs(dev - devold)/(0.1 + abs(dev)) < control$epsilon) {
                conv <- TRUE
                coef <- start
                break
            }
            else {
                devold <- dev
                coef <- coefold <- start
            }
        }
        if (!conv)
            warning("glm.fit: algorithm did not converge", call. = FALSE)
        if (boundary)
            warning("glm.fit: algorithm stopped at boundary value",
                    call. = FALSE)
        eps <- 10 * .Machine$double.eps
        if (family$family == "binomial") {
            if (any(mu > 1 - eps) || any(mu < eps))
                warning("glm.fit: fitted probabilities numerically 0 or 1 occurred",
                        call. = FALSE)
        }
        if (family$family == "poisson") {
            if (any(mu < eps))
                warning("glm.fit: fitted rates numerically 0 occurred",
                        call. = FALSE)
        }
        if (fit$rank < nvars)
            coef[fit$pivot][seq.int(fit$rank + 1, nvars)] <- NA
        xxnames <- xnames[fit$pivot]
        residuals <- (y - mu)/mu.eta(eta)
        fit$qr <- as.matrix(fit$qr)
        nr <- min(sum(good), nvars)
        if (nr < nvars) {
            Rmat <- diag(nvars)
            Rmat[1L:nr, 1L:nvars] <- fit$qr[1L:nr, 1L:nvars]
        }
        else Rmat <- fit$qr[1L:nvars, 1L:nvars]
        Rmat <- as.matrix(Rmat)
        Rmat[row(Rmat) > col(Rmat)] <- 0
        names(coef) <- xnames
        colnames(fit$qr) <- xxnames
        dimnames(Rmat) <- list(xxnames, xxnames)
    }
    names(residuals) <- ynames
    names(mu) <- ynames
    names(eta) <- ynames
    wt <- rep.int(0, nobs)
    wt[good] <- w^2
    names(wt) <- ynames
    names(weights) <- ynames
    names(y) <- ynames
    if (!EMPTY)
        names(fit$effects) <- c(xxnames[seq_len(fit$rank)], rep.int("",
                                                                    sum(good) - fit$rank))
    wtdmu <- if (intercept)
        sum(weights * y)/sum(weights)
    else linkinv(offset)
    nulldev <- sum(dev.resids(y, wtdmu, weights))
    n.ok <- nobs - sum(weights == 0)
    nulldf <- n.ok - as.integer(intercept)
    rank <- if (EMPTY)
        0
    else fit$rank
    resdf <- n.ok - rank
    aic.model <- aic(y, n, mu, weights, dev) + 2 * rank

    myretVal <-
    list(coefficients = coef, residuals = residuals, fitted.values = mu,
         effects = if (!EMPTY) fit$effects, R = if (!EMPTY) Rmat,
         rank = rank, qr = if (!EMPTY) structure(fit[c("qr", "rank",
                                                       "qraux", "pivot", "tol")], class = "qr"), family = family,
         linear.predictors = eta, deviance = dev, aic = aic.model,
         null.deviance = nulldev, iter = iter, weights = wt, prior.weights = weights,
         df.residual = resdf, df.null = nulldf, y = y, converged = conv,
         boundary = boundary)

    logStr <- sprintf("echo '[%.0f] myglm.fit: class(myretVal): %s...' >> parallel.log", proc.time()["elapsed"],
                      paste0(class(myretVal), collapse = ","))
    system(logStr)

}

myglm <- function (formula, family = gaussian, data, weights, subset,
          na.action, start = NULL, etastart, mustart, offset, control = list(...),
          model = TRUE, method = "glm.fit", x = FALSE, y = TRUE, contrasts = NULL,
          ...)
{
    logStr <- sprintf("echo '[%.0f] caret_nominalTrainWorkflow.R: entering myglm...' >> parallel.log", proc.time()["elapsed"])
    system(logStr)

    call <- match.call()
    if (is.character(family))
        family <- get(family, mode = "function", envir = parent.frame())
    if (is.function(family))
        family <- family()
    if (is.null(family$family)) {
        print(family)
        stop("'family' not recognized")
    }
    if (missing(data))
        data <- environment(formula)
    mf <- match.call(expand.dots = FALSE)
    m <- match(c("formula", "data", "subset", "weights", "na.action",
                 "etastart", "mustart", "offset"), names(mf), 0L)
    mf <- mf[c(1L, m)]
    mf$drop.unused.levels <- TRUE
    mf[[1L]] <- quote(stats::model.frame)
    mf <- eval(mf, parent.frame())
    if (identical(method, "model.frame"))
        return(mf)
    if (!is.character(method) && !is.function(method))
        stop("invalid 'method' argument")
    if (identical(method, "glm.fit"))
        control <- do.call("glm.control", control)
    mt <- attr(mf, "terms")
    Y <- model.response(mf, "any")
    if (length(dim(Y)) == 1L) {
        nm <- rownames(Y)
        dim(Y) <- NULL
        if (!is.null(nm))
            names(Y) <- nm
    }
    X <- if (!is.empty.model(mt))
        model.matrix(mt, mf, contrasts)
    else matrix(, NROW(Y), 0L)
    weights <- as.vector(model.weights(mf))
    if (!is.null(weights) && !is.numeric(weights))
        stop("'weights' must be a numeric vector")
    if (!is.null(weights) && any(weights < 0))
        stop("negative weights not allowed")
    offset <- as.vector(model.offset(mf))
    if (!is.null(offset)) {
        if (length(offset) != NROW(Y))
            stop(gettextf("number of offsets is %d should equal %d (number of observations)",
                          length(offset), NROW(Y)), domain = NA)
    }
    mustart <- model.extract(mf, "mustart")
    etastart <- model.extract(mf, "etastart")

    logStr <- sprintf("echo '[%.0f] myglm: building fit[1]...' >> parallel.log", proc.time()["elapsed"])
    system(logStr)
    mycond <- (is.function(method))
    logStr <- sprintf("echo '[%.0f] myglm: mycond: %s' >> parallel.log", proc.time()["elapsed"],
                      ifelse(mycond, "TRUE", "FALSE"))
    system(logStr)
    logStr <- sprintf("echo '[%.0f] myglm: method: %s' >> parallel.log", proc.time()["elapsed"],
                      method)
    system(logStr)

    #fit <- eval(call(if (is.function(method)) "method" else method,
    fit <- eval(call("myglm.fit",
                     x = X, y = Y, weights = weights, start = start, etastart = etastart,
                     mustart = mustart, offset = offset, family = family,
                     control = control, intercept = attr(mt, "intercept") >
                         0L))

    logStr <- sprintf("echo '[%.0f] caret_nominalTrainWorkflow.R: class(fit)[1]: %s' >> parallel.log", proc.time()["elapsed"],
                      paste0(class(fit), collapse = ","))
    system(logStr)

    if (length(offset) && attr(mt, "intercept") > 0L) {
        fit2 <- eval(call(if (is.function(method)) "method" else method,
                          x = X[, "(Intercept)", drop = FALSE], y = Y, weights = weights,
                          offset = offset, family = family, control = control,
                          intercept = TRUE))
        if (!fit2$converged)
            warning("fitting to calculate the null deviance did not converge -- increase 'maxit'?")
        fit$null.deviance <- fit2$deviance
    }
    if (model)
        fit$model <- mf
    fit$na.action <- attr(mf, "na.action")
    if (x)
        fit$x <- X
    if (!y)
        fit$y <- NULL
    fit <- c(fit, list(call = call, formula = formula, terms = mt,
                       data = data, offset = offset, control = control, method = method,
                       contrasts = attr(X, "contrasts"), xlevels = .getXlevels(mt,
                                                                               mf)))
    class(fit) <- c(fit$class, c("glm", "lm"))

    logStr <- sprintf("echo '[%.0f] caret_nominalTrainWorkflow.R: class(fit): %s' >> parallel.log", proc.time()["elapsed"],
                      paste0(class(fit), collapse = ","))
    system(logStr)

    fit
}

mymethodfit <- function(x, y, wts, param, lev, last, classProbs, ...) {
    logStr <- sprintf("echo '[%.0f] caret_nominalTrainWorkflow.R: entering mymethodfit...' >> parallel.log", proc.time()["elapsed"])
    system(logStr)

    dat <- if(is.data.frame(x)) x else as.data.frame(x)
    dat$.outcome <- y
    if(length(levels(y)) > 2) stop("glm models can only use 2-class outcomes")

    theDots <- list(...)
    if(!any(names(theDots) == "family"))
    {
        theDots$family <- if(is.factor(y)) binomial() else gaussian()
    }

    ## pass in any model weights
    if(!is.null(wts)) theDots$weights <- wts

    modelArgs <- c(list(formula = as.formula(".outcome ~ ."), data = dat), theDots)

    logStr <- sprintf("echo '[%.0f] caret_nominalTrainWorkflow.R: calling glm...' >> parallel.log", proc.time()["elapsed"])
    system(logStr)

    out <- do.call("myglm", modelArgs)
    ## When we use do.call(), the call infformation can contain a ton of
    ## information. Inlcuding the contenst of the data. We eliminate it.
    out$call <- NULL

    logStr <- sprintf("echo '[%.0f] caret_nominalTrainWorkflow.R: class(out): %s' >> parallel.log", proc.time()["elapsed"],
                      paste0(class(out), collapse = ","))
    system(logStr)

    out
}

mycreateModel <- function (x, y, wts, method, tuneValue, obsLevels, pp, last, sampling, classProbs, ...) {
    logStr <- sprintf("echo '[%.0f] caret_nominalTrainWorkflow.R: entering mycreateModel...' >> parallel.log", proc.time()["elapsed"])
    system(logStr)

    cond1 <- (!is.null(sampling) && sampling$first)
    cond2 <- (!is.null(pp$options))
    cond3 <- (!is.null(sampling) && !sampling$first)
    logStr <- sprintf("echo '[%.0f] caret_nominalTrainWorkflow.R: cond1: %s; cond2: %s; cond3: %s' >> parallel.log", proc.time()["elapsed"],
                      ifelse(cond1, "TRUE", "FALSE"),
                      ifelse(cond2, "TRUE", "FALSE"),
                      ifelse(cond3, "TRUE", "FALSE"))
    system(logStr)

    ppObj <- NULL # if cond2 == FALSE
    logStr <- sprintf("echo '[%.0f] caret_nominalTrainWorkflow.R: calling %s$fit...' >> parallel.log", proc.time()["elapsed"],
                      method$label)
    system(logStr)

    # modelFit <- method$fit(x = x, y = y, wts = wts, param = tuneValue,
    modelFit <- mymethodfit(x = x, y = y, wts = wts, param = tuneValue,
                           lev = obsLevels, last = last, classProbs = classProbs,
                           ...)

    logStr <- sprintf("echo '[%.0f] caret_nominalTrainWorkflow.R: class(modelFit): %s' >> parallel.log", proc.time()["elapsed"],
                      paste0(class(modelFit), collapse = ","))
    system(logStr)

    retVal <- createModel(x, y, wts, method, tuneValue, obsLevels, pp, last, sampling, classProbs, ...)

    logStr <- sprintf("echo '[%.0f] caret_nominalTrainWorkflow.R: exiting mycreateModel...' >> parallel.log", proc.time()["elapsed"])
    system(logStr)

    return(retVal)
}

# Run this in the caret internal version of nominalTrainWorkflow
# cat("entering debug version of nominalTrainWorkflow...\n")
# loadNamespace("caret")
# ppp <- list(options = ppOpts)
# ppp <- c(ppp, ctrl$preProcOptions)
#
# printed <- format(info$loop, digits = 4)
# colnames(printed) <- gsub("^\\.", "", colnames(printed))
#
# ## For 632 estimator, add an element to the index of zeros to trick it into
# ## fitting and predicting the full data set.
#
# resampleIndex <- ctrl$index
# if (ctrl$method %in% c("boot632"))
# {
#     resampleIndex <- c(list(AllData = rep(0, nrow(x))), resampleIndex)
#     ctrl$indexOut <- c(list(AllData = rep(0, nrow(x))), ctrl$indexOut)
# }
# `%op%` <- getOper(ctrl$allowParallel && getDoParWorkers() > 1)
#
# pkgs <- c("methods", "caret")
# if (!is.null(method$library)) pkgs <- c(pkgs, method$library)
#
result <- foreach(iter = seq(along = resampleIndex), .combine = "c",
                  .verbose = TRUE, .packages = pkgs, .errorhandling = "stop") %:%
    foreach(parm = 1:nrow(info$loop), .combine = "c", .verbose = TRUE,
            .packages = pkgs, .errorhandling = "stop") %op%
            {
                logStr <- sprintf("echo '[%.0f] caret_nominalTrainWorkflow.R: iter: %d; parm: %d; processing...' >> parallel.log", proc.time()["elapsed"], iter, parm)
                system(logStr)

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

                logStr <- sprintf("echo '[%.0f] caret_nominalTrainWorkflow.R: iter: %d; parm: %d; calling createModel...' >> parallel.log", proc.time()["elapsed"], iter, parm)
                system(logStr)

                mod <- try(
                    mycreateModel(x = x[modelIndex,,drop = FALSE],
                                y = y[modelIndex],
                                wts = wts[modelIndex],
                                method = method,
                                tuneValue = info$loop[parm,,drop = FALSE],
                                obsLevels = lev,
                                pp = ppp,
                                classProbs = ctrl$classProbs,
                                sampling = ctrl$sampling,
                                ...),
                    silent = FALSE)

                logStr <- sprintf("echo '[%.0f] caret_nominalTrainWorkflow.R: iter: %d; parm: %d; class(.Last.value): %s; ended createModel...' >> parallel.log", proc.time()["elapsed"], iter, parm, class(.Last.value))
                system(logStr)
                logStr <- sprintf("echo '[%.0f] caret_nominalTrainWorkflow.R: iter: %d; parm: %d; names(mod$fit$model)[1:5]: %s; ended createModel...' >> parallel.log", proc.time()["elapsed"], iter, parm, paste0(names(mod$fit$model)[1:5], collapse = ","))
                system(logStr)

                if (class(mod)[1] != "try-error")
                {
                    predicted <- try(
                        predictionFunction(method = method,
                                           modelFit = mod$fit,
                                           newdata = x[holdoutIndex,, drop = FALSE],
                                           preProc = mod$preProc,
                                           param = submod),
                        silent = FALSE)

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

                logStr <- sprintf("echo '[%.0f] caret_nominalTrainWorkflow.R: iter: %d; parm: %d; thisResample$Resample: %s; thisResample$parameter: %s; thisResample$Accuracy: %0.4f; constructed...' >> parallel.log", proc.time()["elapsed"], iter, parm, thisResample$Resample, thisResample$parameter, thisResample$Accuracy)
                system(logStr)
                logStr <- sprintf("echo '[%.0f] caret_nominalTrainWorkflow.R: iter: %d; parm: %d; ending...' >> parallel.log", proc.time()["elapsed"], iter, parm)
                system(logStr)

                list(resamples = thisResample, pred = tmpPred)
            }