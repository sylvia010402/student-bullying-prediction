
#rf classification
install.packages("pROC")
library(pROC)



train_imputed <- read.csv("/Users/le/Desktop/pset3_predict_bully/data/train_imputed.csv")
test_imputed <- read.csv("/Users/le/Desktop/pset3_predict_bully/data/test_bully.csv")



#make a binary variable of bully scored 2.5 or above
train_imputed$bully_high <- ifelse(train_imputed$bully >= 2.5, 1, 0)
train_imputed$bully_high <- factor(train_imputed$bully_high, levels = c(0, 1), labels = c("No", "Yes"))

# 
# test_imputed$predicted_bully_level <- predicted_bully_level
# test_imputed$bully_high <- ifelse(test_imputed$predicted_bully_level >= 2.5, 1, 0)
# test_imputed$bully_high <- factor(test_imputed$bully_high, levels = c(0, 1), labels = c("No", "Yes"))


#rf classifier, bully and bully risk

ctrl <- trainControl(
    method = "cv",          # cross-validation
    number = 5,             # 5-fold
    classProbs = TRUE,      # get probabilities for AUC
    summaryFunction = twoClassSummary,  # for ROC
    savePredictions = "final"
)


# Fit the model
rf_bully_class <- train(
    bully_high ~ ., 
    data = train_imputed %>% select(-c(bully, student_id)),     # your cleaned dataset
    method = "rf",
    trControl = ctrl,
    tuneLength = 5,
    metric = "ROC"          # maximize AUC
)

saveRDS(rf_bully_class, file = "/Users/le/Desktop/pset3_predict_bully/data/rf_bully_class.rds")


#########################################################################################################
#plotting ROC and AUC 

# probs = predicted probabilities for the positive class ("Yes")
# actual = actual binary outcome ("No"/"Yes")


rf_bully_class <- read_rds("/Users/le/Desktop/pset3_predict_bully/data/rf_bully_class.rds")
rf_bully_class$results
plot(rf_bully_class) 
abline(v = 24, col = "red", lty = 2 ) 


# Get predicted probabilities
predicted_bully_probs <- predict(rf_bully_class, newdata = train_imputed, type = "prob")[, "Yes"]


# ROC Curve and AUC
roc_obj <- roc(train_imputed$bully_high, predicted_bully_probs)

plot(roc_obj, col = "blue", main = "ROC Curve for Bullying Risk")
abline(a = 0, b = 1, lty = 2, col = "gray")  # diagonal line

# Print AUC
auc(roc_obj)


#Tuning the threshold manually, to get the best sensitivity and specificity cut off
# Get threshold performance stats
roc_coords <- coords(roc_obj, x = "all", input = "threshold", ret = c("threshold", "sensitivity", "specificity"))

# Plot Sensitivity vs. Specificity
plot(roc_coords$threshold, roc_coords$sensitivity, type = "l", col = "darkviolet", ylim = c(0,1),
     xlab = "Threshold", ylab = "Rate", main = "Sensitivity and Specificity vs. Threshold")
lines(roc_coords$threshold, roc_coords$specificity, col = "darkturquoise")
legend("bottomleft", legend = c("Sensitivity", "Specificity"), col = c("darkviolet", "darkturquoise"), lty = 1)
# Add a vertical line at the optimal threshold, make it bold
abline(v = 0.5, col = "red", lty = 2 ) 

#the best threshold is 0.5

#########################################################################################################


# Get predicted classes on train data (using 0.5 threshold)
predicted_bully_probs <- predict(rf_bully_class, newdata = train_imputed, type = "prob")[, "Yes"]

pred_class <- ifelse(predicted_bully_probs >= 0.5, "Yes", "No")

# Actual classes (make sure they're factors with the same levels)
actual <- factor(train_imputed$bully_high, levels = c("No", "Yes"))

# Confusion matrix
conf <- confusionMatrix(factor(pred_class, levels = c("No", "Yes")), actual, positive = "Yes")
print(conf)



# Predict probabilities on test data
test_probs <- predict(rf_bully_class, newdata = test_imputed, type = "prob")[, "Yes"]
test_pred_class <- ifelse(test_probs >= 0.5, "Yes", "No")
# Probabilities for risk prediction
test_imputed$predicted_bully_probs <- test_probs 
test_imputed$predicted_bully_high <- test_pred_class

roc_obj_test <- roc(test_pred_class, test_probs)

plot(roc_obj, col = "blue", main = "ROC Curve for Bullying Risk Train")
abline(a = 0, b = 1, lty = 2, col = "gray")  # diagonal line

############################################################################################################

#assemble for final predictions
final_predictions <- data.frame(
    student_id = test_imputed$student_id,
    predicted_bully_level = test_imputed$predicted_bully_level, 
    predicted_bully_high = test_imputed$predicted_bully_high,
    predicted_bully_risk_percentage = (test_imputed$predicted_bully_probs) * 100
)



write.csv(final_predictions, "Theta_student_predictions.csv", row.names = FALSE)





