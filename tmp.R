split.sample:
prdline.my          .n.Tst .n.OOB .freqRatio.Tst .freqRatio.OOB
2            iPad 2    154    138     0.19298246    0.157175399
7         iPad mini    114    144     0.14285714    0.164009112
1            iPad 1     89    105     0.11152882    0.119589977
11          Unknown     87     93     0.10902256    0.105922551
5          iPad Air     75     77     0.09398496    0.087699317
4            iPad 4     68     78     0.08521303    0.088838269
6        iPad Air 2     62     79     0.07769424    0.089977221
8       iPad mini 2     56     54     0.07017544    0.061503417
3            iPad 3     55     72     0.06892231    0.082004556
9       iPad mini 3     38     34     0.04761905    0.038724374
10 iPad mini Retina     NA      4             NA    0.004555809

strata:
prdline.my          .n.Tst .n.OOB .freqRatio.Tst .freqRatio.OOB
2            iPad 2    154    122     0.19298246    0.136771300
8         iPad mini    114    132     0.14285714    0.147982063
1            iPad 1     89    113     0.11152882    0.126681614
12          Unknown     87     94     0.10902256    0.105381166
6          iPad Air     75     92     0.09398496    0.103139013
4            iPad 4     68     81     0.08521303    0.090807175
7        iPad Air 2     62     82     0.07769424    0.091928251
9       iPad mini 2     56     57     0.07017544    0.063901345
3            iPad 3     55     68     0.06892231    0.076233184
10      iPad mini 3     38     46     0.04761905    0.051569507
11 iPad mini Retina     NA      4             NA    0.004484305
5            iPad 5     NA      1             NA    0.001121076

as.numeric(performance(prediction(
    glb_OOBobs_df[, "sold.fctr.predict.All.Interact.X.gbm.prob"],
    glb_OOBobs_df[, glb_rsp_var]), "auc")@y.values)

print(myplot_prediction_classification(
    df=subset(glb_OOBobs_df, (prdl.my.descr.fctr == "iPadAir#0") & (biddable == 0)),
    feat_x="startprice.diff",
    feat_y="idseq.my",
    rsp_var=glb_rsp_var,
    rsp_var_out=paste0(glb_rsp_var_out, glb_sel_mdl_id),
    id_vars=glb_id_var,
    prob_threshold=0.5)
      #               + geom_hline(yintercept=<divider_val>, linetype = "dotted")
)
require(GGally)
ggparcoord(data=subset(glb_OOBobs_df, (prdl.my.descr.fctr == "iPadAir#0") & (biddable == 0)),
           columns = 1:4,
           groupColumn = paste0(glb_rsp_var_out, glb_sel_mdl_id, ".accurate"))
grep(paste0(glb_rsp_var_out, glb_sel_mdl_id, ".accurate"), names(glb_allobs_df), fixed=TRUE)
df=subset(glb_OOBobs_df, (prdl.my.descr.fctr == "iPadAir#0") & (biddable == 0))[,
                                                                            c(175, 28:32)]
ggparcoord(data=df,
           columns = 2:6,
           groupColumn = 1)

> myget_feats_importance(glb_models_lst[["All.X.no.rnorm.rf"]])
importance
biddable                                         100.00000000
idseq.my                                          98.00292371
startprice.unit9                                  34.31130220
prdl.my.descr.fctriPadAir#0                       18.10984741
D.ratio.sum.TfIdf.nwrds                           15.23549621
color.fctrUnknown                                 14.05520993
D.TfIdf.sum.stem.stop.Ratio                       13.00884673
D.ratio.nstopwrds.nwrds                           10.51165302

"avNNet"

dsp_feats <- plt_feats_df[
    which(plt_feats_df[, paste("min", rsp_var_out, clss, sep=".")] <
              plt_feats_df[, paste("min", glb_rsp_var, clss, sep=".")]), "id"]
if (length(dsp_feats) > 0) {
    #         if (any(plt_feats_df[, paste("min", rsp_var_out, clss, sep=".")] <
    #                 plt_feats_df[, paste("min", glb_rsp_var, clss, sep=".")])) {
    #             dsp_feats <- plt_feats_df[
    #                 which(plt_feats_df[, paste("min", rsp_var_out, clss, sep=".")] <
    #                       plt_feats_df[, paste("min", glb_rsp_var, clss, sep=".")]), "id"]
    ths_ids <- c(NULL)
    for (feat in dsp_feats)
        ths_ids <- union(ths_ids,
                         glb_newobs_df[(glb_newobs_df[, rsp_var_out] == clss) &
                                           (glb_newobs_df[, feat] <
                                                plt_feats_df[plt_feats_df$id == feat, paste("min", glb_rsp_var, clss, sep=".")]),
                                       glb_id_var])

    tmp_newobs_df <- glb_newobs_df[glb_newobs_df[, glb_id_var] %in% ths_ids,
                                   c(glb_id_var, rsp_var_out, dsp_feats)]
    print(sprintf("New obs %s %s: min < min of Train range: %d",
                  rsp_var_out, clss, nrow(tmp_newobs_df)))
    myprint_df(tmp_newobs_df)
    print(subset(plt_feats_df, id %in% dsp_feats))

    range_outlier_ids <- union(range_outlier_ids, ths_ids)
}

mdl_id="Max.cor.Y.lm";
mdl_id="Low.cor.X.lm";
mdl_id="All.X.lm";
mdl_id="Interact.High.cor.Y.lm";
mdl_id="MFO.lm";
mdl_id="All.Interact.X.lm";
mdl_id="All.X.glmnet";
models_df <- subset(glb_models_df, model_id == mdl_id); mdl <- glb_models_lst[[mdl_id]]
1.0 - ((1.0 - models_df$max.R.sq.fit) *
                                         (nrow(fit_df) - 1) /
                                         (nrow(fit_df) - nrow(myget_feats_importance(mdl)) - 1))

myplot_scatter(glb_fitobs_df, "idseq.my", "startprice", colorcol_name="biddable", smooth=TRUE) +
    facet_wrap(~biddable)
myplot_scatter(glb_fitobs_df, "idseq.my", "startprice.sqrt", colorcol_name="biddable", smooth=TRUE) +
    facet_wrap(~biddable)
myplot_scatter(glb_allobs_df, "idseq.my", "startprice", colorcol_name="biddable", smooth=TRUE) +
    facet_grid(.src ~ biddable)

tmp_fitobs_df <- glb_fitobs_df[, c("UniqueID", "startprice")]
tmp_fitobs_df$startprice.log10 <- log10(tmp_fitobs_df$startprice)
tmp_fitobs_df$startprice.exp <- exp(0 - tmp_fitobs_df$startprice)
tmp_fitobs_df$startprice.sqrt <- tmp_fitobs_df$startprice ^ 0.5
plt_fitobs_df <- tmp_fitobs_df %>%
                    gather(key, value, contains("startprice."))
head(plt_fitobs_df)
ggplot(plt_fitobs_df, aes(x=startprice, y=value)) + geom_point() + facet_wrap(~ key, scales="free")

if (model_id_pfx == "All.Interact.X") {
    # The operations are applied in this order:
    #   Box-Cox/Yeo-Johnson transformation, centering, scaling, range, imputation, PCA, ICA then spatial sign.
    preProcess_methods <- union(preProcess_methods,
                                c("YeoJohnson", "center.scale",
                                  # crashes with train: all the RMSE metric values are missing
                                  #   probably due to interaction vars
                                  # "range",   "pca", "ica",
                                  "spatialSign"))
}
print(dsp_models_df <- orderBy(model_sel_frmla <- get_model_sel_frmla(),
                               glb_models_df)[, c("model_id", glb_model_evl_criteria)])
dsp_models_df[1, "model_id"]
indep_vars_vctr <-
    trim(unlist(strsplit(glb_models_df[glb_models_df$model_id ==
                                           glb_sel_mdl_id
                                       , "feats"], "[,]")))

nzv_df <- nearZeroVar(glb_trnobs_df[, setdiff(names(glb_trnobs_df),
                                       c(glb_rsp_var, myfind_chr_cols_df(glb_trnobs_df)))],
                      saveMetrics=TRUE)
nzv_df$id <- row.names(nzv_df)
subset(nzv_df, nzv == TRUE)

zeroVar <- (lunique == 1) | apply(x, 2, function(data) all(is.na(data)))
freqCut = 95/5
uniqueCut = 10
nzv = (freqRatio > freqCut & percentUnique <= uniqueCut) | zeroVar

# custom cosine calculation
table(clusterGroups)
# tmp_allobs_df=ctgry_allobs_df[1:5, ]
# tmp_allobs_df=ctgry_allobs_df[clusterGroups == 4, ]
#tmp_allobs_df=ctgry_allobs_df[base::sample.int(nrow(ctgry_allobs_df), 5), ]
# tmp_allobs_df=ctgry_allobs_df[base::sample.int(nrow(ctgry_allobs_df), 5), ]
tmp_allobs_df=ctgry_allobs_df[row.names(ctgry_allobs_df) %in% c(2383, 2245, 2033, 1844, 426), ]
summary(tmp_allobs_df[, cluster_vars])
tmp_vars=c("D.T.condit", "D.T.screen", "D.T.great") #, "D.T.item", "D.T.will", "D.T.work")
print(tmp_ntv_mtrx <- as.matrix(proxy::dist(tmp_allobs_df[, tmp_vars], method = "cosine")))
# x=tmp_allobs_df[2, tmp_vars]; y=tmp_allobs_df[3, tmp_vars]
# x=tmp_allobs_df[2, tmp_vars]; y=tmp_allobs_df[4, tmp_vars]
# x=tmp_allobs_df[3, tmp_vars]; y=tmp_allobs_df[4, tmp_vars]
# x=tmp_allobs_df[4, tmp_vars]; y=tmp_allobs_df[2, tmp_vars]
mycosine_pair_dist <- function(x, y) {
    if (sqrt(sum(x ^ 2) * sum(y ^ 2)) == 0) return (1)

    return(1 - (sum(x * y) / sqrt(sum(x ^ 2) * sum(y ^ 2))))
}
mycosine_pair_dist(tmp_allobs_df[2, tmp_vars], tmp_allobs_df[3, tmp_vars])
mycosine_pair_dist(tmp_allobs_df[2, tmp_vars], tmp_allobs_df[4, tmp_vars])
mycosine_pair_dist(tmp_allobs_df[3, tmp_vars], tmp_allobs_df[4, tmp_vars])

mycosine_pair_dist(tmp_allobs_df[2, tmp_vars], tmp_allobs_df[2, tmp_vars])
mycosine_pair_dist(tmp_allobs_df[1, tmp_vars], tmp_allobs_df[2, tmp_vars])

mycosine_dist <- function(x, y=NULL) {
    if (!inherits(x, "matrix"))
        x <- as.matrix(x)
    xsqsum <- as.matrix(rowSums(x ^ 2), byrow=FALSE)
    denom <- sqrt(xsqsum %*% t(xsqsum))
    #if (denom == 0) return (1)

    ret_mtrx <- 1 - ((x %*% t(x)) / denom)
    ret_mtrx[is.nan(ret_mtrx)] <- 1
    diag(ret_mtrx) <- 0
    return(ret_mtrx)
}
print(tmp_csm_mtrx <- mycosine_dist(x=tmp_allobs_df[, tmp_vars]))
pr_DB$get_entry("cosine")

mywgtdcosine_dist <- function(x, y=NULL, weights=NULL) {
    if (!inherits(x, "matrix"))
        x <- as.matrix(x)

    if (is.null(weights))
        weights <- rep(1, ncol(x))

    wgtsx <- matrix(rep(weights / sum(weights), nrow(x)), nrow=nrow(x), byrow=TRUE)
    wgtdx <- x * wgtsx

    wgtdxsqsum <- as.matrix(rowSums((x ^ 2) * wgtsx), byrow=FALSE)
    denom <- sqrt(wgtdxsqsum %*% t(wgtdxsqsum))

    ret_mtrx <- 1 - ((sum(weights) ^ 1) * (wgtdx %*% t(wgtdx)) / denom)
    ret_mtrx[is.nan(ret_mtrx)] <- 1
    diag(ret_mtrx) <- 0
    return(ret_mtrx)
}
print(tmp_csw_mtrx <- mywgtdcosine_dist(x=tmp_allobs_df[, tmp_vars]))
all.equal(tmp_ntv_mtrx, tmp_csw_mtrx)
print(tmp_csw_mtrx <- mywgtdcosine_dist(x=tmp_allobs_df[, tmp_vars], weights=c(1,1,1)))
all.equal(tmp_ntv_mtrx, tmp_csw_mtrx)

print(tmp_ntv2_mtrx <- as.matrix(proxy::dist(tmp_allobs_df[, head(tmp_vars, -1)], method = "cosine")))
# print(tmp_ntv2_mtrx <- as.matrix(proxy::dist(cbind(tmp_allobs_df[, head(tmp_vars, -1)], data.frame(zero=rep(0, nrow(tmp_allobs_df)))), method = "cosine")))
print(tmp_csw2_mtrx <- mywgtdcosine_dist(x=tmp_allobs_df[, tmp_vars], weights=c(1,1,0)))
all.equal(tmp_ntv2_mtrx, tmp_csw2_mtrx)

# print(tmp_csw2o_mtrx <- mywgtdcosine_dist(x=tmp_allobs_df[, head(tmp_vars, -1)]))
# all.equal(tmp_ntv2_mtrx, tmp_csw2o_mtrx)

pr_DB$delete_entry("mywgtdcosine"); pr_DB$set_entry(FUN = mywgtdcosine_dist, names = c("mywgtdcosine"))
#pr_DB$modify_entry(names="mycosine", type="metric")
pr_DB$modify_entry(names="mywgtdcosine", type="metric", loop=FALSE)
pr_DB$get_entry("mywgtdcosine")

all.equal(pr_DB$get_entry("cosine"), pr_DB$get_entry("mycosine"))
tmp_csw_crossdist <- proxy::dist(tmp_allobs_df[, tmp_vars], method = "mywgtdcosine")
print(tmp_csw_mtrx <- matrix(as.vector(tmp_csw_crossdist), nrow=attr(tmp_csw_crossdist, "dim")[1], dimnames=attr(tmp_csw_crossdist, "dimnames")))
all.equal(tmp_ntv_mtrx, tmp_csw_mtrx)

tmp_csw2_crossdist <- proxy::dist(tmp_allobs_df[, tmp_vars], method = "mywgtdcosine",
                                  weights=c(1,1,0))
print(tmp_csw2_mtrx <- matrix(as.vector(tmp_csw2_crossdist), nrow=attr(tmp_csw2_crossdist, "dim")[1], dimnames=attr(tmp_csw2_crossdist, "dimnames")))
all.equal(tmp_ntv2_mtrx, tmp_csw2_mtrx)

tmp_trnobs_mtrx <- model.matrix(reformulate(c(0, "prdl.descr.my.fctr:.clusterid.fctr")), rfe_trnobs_df)

termFreq(glb_corpus_lst[[txt_var]][[1431]], control=list(weighting="weightTf"))

terms_mtrx <- as.matrix(TermDocumentMatrix(txt_corpus, control=list(weighting=weightTf)))
terms_df <- orderBy(~ -Tf, data.frame(term=dimnames(terms_mtrx)$Terms,
                                      Tf=rowSums(terms_mtrx)))

tmp.lm <- lm(reformulate(c("prdl.descr.my.fctr","D.weight.sum.stem.stop.Ratio","prdl.descr.my.fctr:.clusterid.fctr"), glb_rsp_var), data=glb_fitobs_df)

outlierTest(glb_models_lst[["RFE.X.glm"]]$finalModel)
glb_fitobs_df[which(row.names(glb_fitobs_df) %in% c("1442", "1573", "1575")), c(glb_id_var, glb_rsp_var, glb_rsp_var_raw, "sold", glb_category_var)]

num_fit_mtrx <- data.matrix(fit_df); print(num_fit_mtrx[1:5, 1:5])

cntrscl_pr <- preProcess(num_fit_mtrx, method=c("center", "scale"))
cntrscl_fit_mtrx <- predict(cntrscl_pr, num_fit_mtrx); print(cntrscl_fit_mtrx[1:5, 1:5])
print(na_cntrscl_fit_mtrx <- cntrscl_fit_mtrx[is.na(cntrscl_fit_mtrx)])

rng_pr <- preProcess(num_fit_mtrx, method=c("range"))
rng_fit_mtrx <- predict(rng_pr, num_fit_mtrx); print(rng_fit_mtrx[1:5, 1:5])
na_rng_fit_mtrx <- rng_fit_mtrx[is.na(rng_fit_mtrx)]; print(na_rng_fit_mtrx)

print(freq_df <- mycreate_sqlxtab_df(obs_df, union(var, ".src")))
var=vars[1]

print(myplot_hbar(df=freq_df, xcol_name=".src", ycol_names=".n", colorcol_name="startprice.cut.fctr"))
print(myplot_bar(df=freq_df, xcol_name=".src", ycol_names=".n", colorcol_name="startprice.cut.fctr", facet_spec=NULL, xlabel_formatter=NULL))
sum_df <- mycompute_stats_df(df, xcol_name)
df <- df[order(df[, ycol_names], decreasing=TRUE), ]
sum_df$.n <- sum_df$.n.sum

g <- ggplot(df, aes_string(x=paste0("reorder(", xcol_name, ", ", ycol_names, ")"), y=ycol_names)) +
    geom_bar(aes_string(fill=colorcol_name), stat="identity") +
    xlab(xcol_name) + ylab(ycol_names)
aes_str <- paste0("x=", xcol_name,
                  ", y=", ycol_names, ".sum * 1.05",
                  ", label=myformat_number(round(", ycol_names, ".sum))")
aes_mapping <- eval(parse(text = paste("aes(", aes_str, ")")))
g <- g + geom_text(mapping=aes_mapping, data=sum_df)

g <- ggplot(df, aes_string(x=paste0("reorder(", xcol_name, ", ", ycol_names, ")"), y=ycol_names)) +
    geom_bar(aes_string(fill=colorcol_name), stat="identity") +
    xlab(xcol_name) + ylab(ycol_names)
g <- g + geom_text(mapping=aes(x=.src, y=.n.sum*1.05, label=.n.sum), data=sum_df)

g <- ggplot(df, aes_string(x=paste0("reorder(", xcol_name, ", ", ycol_names, ")"), y=ycol_names)) +
    geom_bar(aes_string(fill=colorcol_name), stat="identity") +
    xlab(xcol_name) + ylab(ycol_names)
g <- g + geom_text(mapping=aes(x=.src, y=.n.sum*1.05, label=.src), data=sum_df)

# No interaction features apart from user-specified in glb_interaction_only_feats_lst
                        min.RMSE.fit max.Adj.R.sq.fit max.R.sq.fit
RFE.X.glmnet            0.6164891     0.5940573881  0.628758934
All.X.glmnet            0.6260497     0.4974337085  0.620643509
CSM.X.glmnet            0.6260660     0.5557812466  0.629578878
RFE.X.Interact.glmnet   0.6277709     0.5471574216  0.631152416

# RMSE up with keeping condition.fctr & cellular.fctr:condition.fctr in the model
id                      min.RMSE.fit max.Adj.R.sq.fit max.R.sq.fit
RFE.X.glmnet            0.6164891     0.5940573881  0.628758934
All.X.glmnet            0.6260497     0.4974337085  0.620643509
CSM.X.glmnet            0.6268044     0.5470195355  0.629578878
RFE.X.Interact.glmnet   0.6277709     0.5471574216  0.631152416

# RMSE & R.sq up with removing condition.fctr & keeping cellular.fctr:condition.fctr in the model
id                      min.RMSE.fit max.Adj.R.sq.fit max.R.sq.fit
RFE.X.glmnet            0.6164891     0.5940573881  0.628758934
All.X.glmnet            0.6260497     0.4974337085  0.620643509
CSM.X.glmnet            0.6268890     0.5503971234  0.632340874
RFE.X.Interact.glmnet   0.6277709     0.5471574216  0.631152416

# RMSE & R.sq up with removing condition.fctr & keeping cellular.fctr:D.ratio.weight.sum.wrds.n in the model
id                      min.RMSE.fit max.Adj.R.sq.fit max.R.sq.fit
RFE.X.glmnet            0.6164891     0.5940573881  0.628758934
All.X.glmnet            0.6260497     0.4974337085  0.620643509
RFE.X.Interact.glmnet   0.6277709     0.5471574216  0.631152416
CSM.X.glmnet            0.6316956     0.5565291376  0.631633074

mdlId <- "Max.cor.Y.rcv.3X3.glmnet"
tmp_fitobs_df <- glb_fitobs_df
tmp_fitobs_df$sold.fctr.predict <-
    predict(glb_models_lst[[mdlId]], glb_fitobs_df, type = "raw")
tmp_fitobs_df$sold.fctr.predict.prob <-
    predict(glb_models_lst[[mdlId]], glb_fitobs_df, type = "prob")[, 2]
tmp_fitobs_df$sold.fctr.predict.ordered <-
    ordered(tmp_fitobs_df$sold.fctr.predict,
            levels = levels(tmp_fitobs_df$sold.fctr))
pROC.AUC.fit <- pROC::roc(tmp_fitobs_df$sold.fctr, tmp_fitobs_df$sold.fctr.predict.ordered)$auc

ROCRpred <- ROCR::prediction(tmp_fitobs_df$sold.fctr.predict.prob, tmp_fitobs_df$sold.fctr)
ROCR.auc.fit <- as.numeric(performance(ROCRpred, "auc")@y.values)

print(myplot_line(thresholds_df, "threshold", "f.score") + geom_point(data = subset(thresholds_df, threshold == prob_threshold), mapping = aes(x = threshold, y = f.score), shape = 5, color = "red", size = 4))

library(wordcloud)
m <- glb_post_stem_words_terms_mtrx_lst[["descr.my"]]
# calculate the frequency of words
v <- sort(colSums(m), decreasing=TRUE)
myNames <- names(v)
d <- data.frame(word=myNames, freq=v)
wordcloud(d$word, d$freq, min.freq=3)

tdm <- TermDocumentMatrix(glb_txt_corpus_lst[[txt_var]])
plot(tdm, terms = findFreqTerms(tdm, lowfreq = 6)[1:25], corThreshold = 0.5)

warning("Resetting warnings")
set.seed(111)
tmp_vars <- sort(indep_vars)[17:17]
#tmp_vars <- sort(indep_vars)[18:18]
#tmp_vars <- sort(indep_vars)[16:16]
#tmp_vars <- sort(indep_vars)[16:18]
#tmp_vars <- sort(indep_vars)[16:20]
#tmp_vars <- sort(indep_vars)[16:23]
mdl <- train(reformulate(tmp_vars, response=rsp_var), data=fit_df
             #mdl <- train(reformulate(".", response=rsp_var), data=fit_df
             , method=mdl_specs_lst[["train.method"]]
             , preProcess=mdl_specs_lst[["train.preProcess"]]
             , metric=mdl_specs_lst[["train.metric"]]
             , maximize=mdl_specs_lst[["train.maximize"]]
             , trControl=mdl_specs_lst[["trainControl"]]
             , tuneGrid=mdl_specs_lst[["train.tuneGrid"]]
             , tuneLength=mdl_specs_lst[["train.tuneLength"]])

mdl.lda <- lda(reformulate(indep_vars, response = glb_rsp_var), data = glb_fitobs_df)
plot(mdl.lda)
lcl_mdl$call$formula <- mdl$call$form
lcl_mdl$call$data <- mdl$call$data
lcl_mdl$call$formula==reformulate(sort(indep_vars), response = rsp_var)
lcl_mdl$call$data==fit_df
xname <- expression(fit_df[, indep_vars])
xname <- x$call$x; X <- eval.parent(xname)
gname <- x$call[[3L]]; g <- eval.parent(gname)
lcl_mdl$call$x <- expression(mdl$trainingData[, -1])
lcl_mdl$call$grouping <- expression(mdl$trainingData[, 1])
lcl_mdl$call$x <- expression(lclTrainingData[, dimnames(lcl_mdl$means)[[2]]])

trace("plot", quote(browser(skipCalls = 4)), exit = quote(browser(skipCalls = 4)))
trace(plot, exit = recover, where = kernlab)

result <- foreach(iter = seq(along = resampleIndex), .combine = "c",
                  .verbose = FALSE, .packages = pkgs, .errorhandling = "stop") %:%
    foreach(parm = 1:nrow(info$loop), .combine = "c", .verbose = FALSE,
            .packages = pkgs, .errorhandling = "stop") %op% {
                testing <- FALSE
                if (!(length(ctrl$seeds) == 1 && is.na(ctrl$seeds)))
                    set.seed(ctrl$seeds[[iter]][parm])
                loadNamespace("caret")
                if (ctrl$verboseIter)
                    progress(printed[parm, , drop = FALSE], names(resampleIndex),
                             iter)
                if (names(resampleIndex)[iter] != "AllData") {
                    modelIndex <- resampleIndex[[iter]]
                    holdoutIndex <- ctrl$indexOut[[iter]]
                }
                else {
                    modelIndex <- 1:nrow(x)
                    holdoutIndex <- modelIndex
                }
                if (testing)
                    cat("pre-model\n")
                if (is.null(info$submodels[[parm]]) || nrow(info$submodels[[parm]]) >
                    0) {
                    submod <- info$submodels[[parm]]
                }
                else submod <- NULL
                mod <- try(createModel(x = x[modelIndex, , drop = FALSE],
                                       y = y[modelIndex], wts = wts[modelIndex], method = method,
                                       tuneValue = info$loop[parm, , drop = FALSE], obsLevels = lev,
                                       pp = ppp, classProbs = ctrl$classProbs, sampling = ctrl$sampling,
                                       ...), silent = TRUE)
                if (class(mod)[1] != "try-error") {
                    predicted <- try(predictionFunction(method = method,
                                                        modelFit = mod$fit, newdata = x[holdoutIndex,
                                                                                        , drop = FALSE], preProc = mod$preProc, param = submod),
                                     silent = TRUE)
                    if (class(predicted)[1] == "try-error") {
                        wrn <- paste(colnames(printed[parm, , drop = FALSE]),
                                     printed[parm, , drop = FALSE], sep = "=", collapse = ", ")
                        wrn <- paste("predictions failed for ", names(resampleIndex)[iter],
                                     ": ", wrn, " ", as.character(predicted), sep = "")
                        if (ctrl$verboseIter)
                            cat(wrn, "\n")
                        warning(wrn)
                        rm(wrn)
                        nPred <- length(holdoutIndex)
                        if (!is.null(lev)) {
                            predicted <- rep("", nPred)
                            predicted[seq(along = predicted)] <- NA
                        }
                        else {
                            predicted <- rep(NA, nPred)
                        }
                        if (!is.null(submod)) {
                            tmp <- predicted
                            predicted <- vector(mode = "list", length = nrow(info$submodels[[parm]]) +
                                                    1)
                            for (i in seq(along = predicted)) predicted[[i]] <- tmp
                            rm(tmp)
                        }
                    }
                }
                else {
                    wrn <- paste(colnames(printed[parm, , drop = FALSE]),
                                 printed[parm, , drop = FALSE], sep = "=", collapse = ", ")
                    wrn <- paste("model fit failed for ", names(resampleIndex)[iter],
                                 ": ", wrn, " ", as.character(mod), sep = "")
                    if (ctrl$verboseIter)
                        cat(wrn, "\n")
                    warning(wrn)
                    rm(wrn)
                    nPred <- length(holdoutIndex)
                    if (!is.null(lev)) {
                        predicted <- rep("", nPred)
                        predicted[seq(along = predicted)] <- NA
                    }
                    else {
                        predicted <- rep(NA, nPred)
                    }
                    if (!is.null(submod)) {
                        tmp <- predicted
                        predicted <- vector(mode = "list", length = nrow(info$submodels[[parm]]) +
                                                1)
                        for (i in seq(along = predicted)) predicted[[i]] <- tmp
                        rm(tmp)
                    }
                }
                if (testing)
                    print(head(predicted))
                if (ctrl$classProbs) {
                    if (class(mod)[1] != "try-error") {
                        probValues <- probFunction(method = method, modelFit = mod$fit,
                                                   newdata = x[holdoutIndex, , drop = FALSE],
                                                   preProc = mod$preProc, param = submod)
                    }
                    else {
                        probValues <- as.data.frame(matrix(NA, nrow = nPred,
                                                           ncol = length(lev)))
                        colnames(probValues) <- lev
                        if (!is.null(submod)) {
                            tmp <- probValues
                            probValues <- vector(mode = "list", length = nrow(info$submodels[[parm]]) +
                                                     1)
                            for (i in seq(along = probValues)) probValues[[i]] <- tmp
                            rm(tmp)
                        }
                    }
                    if (testing)
                        print(head(probValues))
                }
                if (is.numeric(y)) {
                    if (is.logical(ctrl$predictionBounds) && any(ctrl$predictionBounds)) {
                        if (is.list(predicted)) {
                            predicted <- lapply(predicted, trimPredictions,
                                                mod_type = "Regression", bounds = ctrl$predictionBounds,
                                                limits = ctrl$yLimits)
                        }
                        else {
                            predicted <- trimPredictions(mod_type = "Regression",
                                                         bounds = ctrl$predictionBounds, limits = ctrl$yLimit,
                                                         pred = predicted)
                        }
                    }
                    else {
                        if (is.numeric(ctrl$predictionBounds) && any(!is.na(ctrl$predictionBounds))) {
                            if (is.list(predicted)) {
                                predicted <- lapply(predicted, trimPredictions,
                                                    mod_type = "Regression", bounds = ctrl$predictionBounds,
                                                    limits = ctrl$yLimits)
                            }
                            else {
                                predicted <- trimPredictions(mod_type = "Regression",
                                                             bounds = ctrl$predictionBounds, limits = ctrl$yLimit,
                                                             pred = predicted)
                            }
                        }
                    }
                }
                if (!is.null(submod)) {
                    allParam <- expandParameters(info$loop[parm, , drop = FALSE],
                                                 info$submodels[[parm]])
                    allParam <- allParam[complete.cases(allParam), ,
                                         drop = FALSE]
                    predicted <- lapply(predicted, function(x, y, wts,
                                                            lv, rows) {
                        if (!is.factor(x) & is.character(x))
                            x <- factor(as.character(x), levels = lv)
                        out <- data.frame(pred = x, obs = y, stringsAsFactors = FALSE)
                        if (!is.null(wts))
                            out$weights <- wts
                        out$rowIndex <- rows
                        out
                    }, y = y[holdoutIndex], wts = wts[holdoutIndex],
                    lv = lev, rows = holdoutIndex)
                    if (testing)
                        print(head(predicted))
                    if (ctrl$classProbs) {
                        for (k in seq(along = predicted)) predicted[[k]] <- cbind(predicted[[k]],
                                                                                  probValues[[k]])
                    }
                    if (ctrl$savePredictions) {
                        tmpPred <- predicted
                        for (modIndex in seq(along = tmpPred)) {
                            tmpPred[[modIndex]]$rowIndex <- holdoutIndex
                            tmpPred[[modIndex]] <- merge(tmpPred[[modIndex]],
                                                         allParam[modIndex, , drop = FALSE], all = TRUE)
                        }
                        tmpPred <- rbind.fill(tmpPred)
                        tmpPred$Resample <- names(resampleIndex)[iter]
                    }
                    else tmpPred <- NULL
                    thisResample <- lapply(predicted, ctrl$summaryFunction,
                                           lev = lev, model = method)
                    if (testing)
                        print(head(thisResample))
                    if (length(lev) > 1) {
                        cells <- lapply(predicted, function(x) flatTable(x$pred,
                                                                         x$obs))
                        for (ind in seq(along = cells)) thisResample[[ind]] <- c(thisResample[[ind]],
                                                                                 cells[[ind]])
                    }
                    thisResample <- do.call("rbind", thisResample)
                    thisResample <- cbind(allParam, thisResample)
                }
                else {
                    if (is.factor(y))
                        predicted <- factor(as.character(predicted),
                                            levels = lev)
                    tmp <- data.frame(pred = predicted, obs = y[holdoutIndex],
                                      stringsAsFactors = FALSE)
                    names(tmp)[1] <- "pred"
                    if (!is.null(wts))
                        tmp$weights <- wts[holdoutIndex]
                    if (ctrl$classProbs)
                        tmp <- cbind(tmp, probValues)
                    tmp$rowIndex <- holdoutIndex
                    if (ctrl$savePredictions) {
                        tmpPred <- tmp
                        tmpPred$rowIndex <- holdoutIndex
                        tmpPred <- merge(tmpPred, info$loop[parm, , drop = FALSE],
                                         all = TRUE)
                        tmpPred$Resample <- names(resampleIndex)[iter]
                    }
                    else tmpPred <- NULL
                    thisResample <- ctrl$summaryFunction(tmp, lev = lev,
                                                         model = method)
                    if (length(lev) > 1)
                        thisResample <- c(thisResample, flatTable(tmp$pred,
                                                                  tmp$obs))
                    thisResample <- as.data.frame(t(thisResample))
                    thisResample <- cbind(thisResample, info$loop[parm,
                                                                  , drop = FALSE])
                }
                thisResample$Resample <- names(resampleIndex)[iter]
                if (ctrl$verboseIter)
                    progress(printed[parm, , drop = FALSE], names(resampleIndex),
                             iter, FALSE)
                list(resamples = thisResample, pred = tmpPred)
            }
