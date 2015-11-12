# Different ranks
rank03_df <- read.csv("Rank03/ebayipads_txt2_n15_out_1.csv")
rank13_df <- read.csv("Rank13/ebayipads_txt_n15_out_1.csv")

glb_id_var <- "UniqueID"
obscmpDF <- merge(rank03_df, rank13_df, by = glb_id_var, suffixes = c("r03", "r13"))
obscmpDF$r03.class.fctr <- relevel(as.factor(ifelse(obscmpDF$Probability1r03 >= 0.5, "Y03", "N03")), ref = "N03")
obscmpDF$r13.class.fctr <- relevel(as.factor(ifelse(obscmpDF$Probability1r13 >= 0.5, "Y13", "N13")), ref = "N13")
obscmpDF$r03r13.class.fctr <- as.factor(paste0(as.character(obscmpDF$r03.class.fctr), as.character(obscmpDF$r13.class.fctr)))
obscmpDF$r03r13.diff <- obscmpDF$Probability1r03 - obscmpDF$Probability1r13
obscmpDF$r03r13.diff.cut.fctr <- cut(obscmpDF$r03r13.diff, 5)

obscmpDF <- merge(obscmpDF, glb_newobs_df[, c(glb_id_var, "biddable")],
                  by = glb_id_var, all.x = TRUE)

myplot_histogram(obscmpDF, "r03r13.diff") + facet_grid(r13.class.fctr ~ r03.class.fctr)
myplot_scatter(obscmpDF, "Probability1r13", "Probability1r03", colorcol_name = "r03r13.diff.cut.fctr", jitter = TRUE) + facet_grid(r13.class.fctr ~ r03.class.fctr)

myplot_scatter(obscmpDF, "Probability1r13", "Probability1r03", colorcol_name = "r03r13.class.fctr") + geom_point(aes(size = abs(r03r13.diff), shape = as.factor(biddable))) + facet_wrap(~biddable)

# Same ranks
runA_df <- read.csv("Rank03/ebayipads_txt2_n15_out_1.csv")
runB_df <- read.csv("ebayipads_selmdl2_RFE_out_1.csv")

glb_id_var <- "UniqueID"
obscmpDF <- merge(runA_df, runB_df, by = glb_id_var, suffixes = c("rA", "rB"))
obscmpDF$rA.class.fctr <- relevel(as.factor(ifelse(obscmpDF$Probability1rA >= 0.5, "YA", "NA")), ref = "NA")
obscmpDF$rB.class.fctr <- relevel(as.factor(ifelse(obscmpDF$Probability1rB >= 0.5, "YB", "NB")), ref = "NB")
obscmpDF$rArB.class.fctr <- as.factor(paste0(as.character(obscmpDF$rA.class.fctr), as.character(obscmpDF$rB.class.fctr)))
obscmpDF$rArB.diff <- obscmpDF$Probability1rA - obscmpDF$Probability1rB
obscmpDF$rArB.diff.cut.fctr <- cut(obscmpDF$rArB.diff, 5)

obscmpDF <- merge(obscmpDF, glb_newobs_df[, c(glb_id_var, "biddable")],
                  by = glb_id_var, all.x = TRUE)

myplot_scatter(obscmpDF, "Probability1rA", "Probability1rB", colorcol_name = "rArB.class.fctr") + geom_point(aes(size = abs(rArB.diff), shape = as.factor(biddable))) + facet_wrap(~biddable)
myplot_histogram(obscmpDF, "rArB.diff") + facet_grid(rA.class.fctr ~ rB.class.fctr)
