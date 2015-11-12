# kaggle-ipad

My code for achieving third place in MIT's "The analytics edge" summer 2015 Kaggle competition.

Proof: https://inclass.kaggle.com/c/15-071x-the-analytics-edge-summer-2015/leaderboard

# Approach

### Features (109):

* One hot encoding of categorical features
* Add frequent words as features

### Feature selection (47):

* RFE with Caret package (Random Forest, repeatedcv)
* Remove highly correlated features ( > 0.7)

### Model selection/tuning:

* 70/30 split
* Random Forest (only tried some ntree values)
* GBM (tuned parameters by hand)
* SVM (used tune here)
* GLMNET (alpha = 0.8) tuned alpha here with trial of values to improve AUC
* Ensemble of all four with weighting

# Summary

The modelling looks fancy, but my biggest improvement was proper feature selection. My private AUC is very close to the AUC I managed to achieve in training (0.8825496) on the 70/30 split. There is a lot of luck involved (most underrated factor).