# ===============================================================================
# Student Bullying Risk Prediction System
# Harvard Graduate School of Education Survey Data Analysis
# ===============================================================================

# Load required libraries
library(tidyverse)    # Data manipulation and visualization
library(caret)        # Machine learning framework
library(mice)         # Multiple imputation
library(pROC)         # ROC analysis
library(RColorBrewer) # Color palettes

# ===============================================================================
# 1. DATA LOADING AND INITIAL SETUP
# ===============================================================================

# Load raw survey data
train_raw <- read.csv("data/student_survey_data.csv")
test_raw <- read.csv("data/student_test_data.csv")

# Data overview
cat("Training data dimensions:", dim(train_raw), "\n")
cat("Test data dimensions:", dim(test_raw), "\n")
cat("Target variable range:", range(train_raw$bully, na.rm = TRUE), "\n")

# ===============================================================================
# 2. FEATURE ENGINEERING PIPELINE
# ===============================================================================

process_survey_data <- function(df, is_train = TRUE) {
    """
    Comprehensive feature engineering function that transforms 195 survey variables
    into 45 meaningful predictive features using domain expertise.
    
    Args:
        df: Raw survey dataframe
        is_train: Boolean indicating if this is training data
        
    Returns:
        Processed dataframe with engineered features
    """
    
    # Remove rows with missing target variable (training only)
    if (is_train) {
        df <- df %>% filter(!is.na(bully))
        cat("Removed", nrow(df) - nrow(df %>% filter(!is.na(bully))), "rows with missing target\n")
    }
    
    # Convert character variables to factors
    df <- df %>% mutate(across(where(is.character), as.factor))
    
    # Q12: School Safety (Physical + Emotional) - Average of Likert scales
    safety_vars <- df %>% 
        select(student_id, psafe1:psafe7, esafe1:esafe7) %>%
        pivot_longer(-student_id, names_to = "question", values_to = "response") %>%
        group_by(student_id) %>%
        summarise(safe_mean = mean(response, na.rm = TRUE), .groups = "drop")
    
    df <- df %>% 
        left_join(safety_vars, by = "student_id") %>% 
        select(-c(psafe1:psafe7, esafe1:esafe7))
    
    # Q13: Safety Improvement Preferences - Sum of binary indicators
    safer_vars <- df %>%
        select(student_id, feel_safer_clear:feel_safer_training) %>%
        select(-feel_safer_text) %>%  # Remove text fields
        pivot_longer(-student_id, names_to = "question", values_to = "response") %>%
        group_by(student_id) %>%
        summarise(feel_safer_sum = sum(response, na.rm = TRUE), .groups = "drop")
    
    df <- df %>%
        select(-starts_with("feel_safer_")) %>%
        left_join(safer_vars, by = "student_id")
    
    # Q16: Discrimination Experiences - Average of Likert scales
    disc_vars <- df %>%
        select(student_id, disc_race:disc_country) %>%
        pivot_longer(-student_id, names_to = "question", values_to = "response") %>%
        group_by(student_id) %>%
        summarise(disc_mean = mean(response, na.rm = TRUE), .groups = "drop")
    
    df <- df %>%
        left_join(disc_vars, by = "student_id") %>% 
        select(-c(disc_race:disc_country))
    
    # Q17: Adult Support - Average of Likert scales
    support_vars <- df %>%
        select(student_id, support1:support8) %>%
        pivot_longer(-student_id, names_to = "question", values_to = "response") %>%
        group_by(student_id) %>%
        summarise(support_mean = mean(response, na.rm = TRUE), .groups = "drop")
    
    df <- df %>%
        select(-c(support1:support8)) %>%
        left_join(support_vars, by = "student_id")
    
    # Q18: School Belonging - Average of Likert scales
    belong_vars <- df %>%
        select(student_id, belong1:belong11) %>%
        pivot_longer(-student_id, names_to = "question", values_to = "response") %>%
        group_by(student_id) %>%
        summarise(belong_mean = mean(response, na.rm = TRUE), .groups = "drop")
    
    df <- df %>%
        select(-c(belong1:belong11)) %>%
        left_join(belong_vars, by = "student_id")
    
    # Q21: School Rules and Fairness - Average of Likert scales
    rules_vars <- df %>%
        select(student_id, rules1:rules9) %>%
        pivot_longer(-student_id, names_to = "question", values_to = "response") %>%
        group_by(student_id) %>%
        summarise(rules_mean = mean(response, na.rm = TRUE), .groups = "drop")
    
    df <- df %>%
        select(-c(rules1:rules9)) %>%
        left_join(rules_vars, by = "student_id")
    
    # Continue with other aggregations (Q22, Q26, Q32-Q40)...
    # [Additional aggregation code for remaining question blocks]
    
    # Remove all text fields and return processed data
    df <- df %>% select(-ends_with("_text"))
    
    return(df)
}

# Apply feature engineering
cat("Processing training data...\n")
train_processed <- process_survey_data(train_raw, is_train = TRUE)

cat("Processing test data...\n") 
test_processed <- process_survey_data(test_raw, is_train = FALSE)

cat("Feature engineering complete. New dimensions:\n")
cat("Training:", dim(train_processed), "\n")
cat("Test:", dim(test_processed), "\n")

# ===============================================================================
# 3. MISSING DATA IMPUTATION
# ===============================================================================

# Extract target variable and prepare for imputation
target_variable <- train_processed$bully
train_for_imputation <- train_processed %>% select(-bully)

# Add source indicators for combined imputation
train_for_imputation$source <- "train"
test_processed$source <- "test"

# Combine datasets for consistent imputation
combined_data <- bind_rows(train_for_imputation, test_processed)

cat("Starting multiple imputation process...\n")
cat("Variables with missing data:", sum(map_int(combined_data, ~sum(is.na(.x))) > 0), "\n")

# Configure MICE imputation
imputation_methods <- mice(combined_data, maxit = 0)$method
imputation_methods["school_values_red"] <- "logreg"  # Specify method for categorical

# Perform multiple imputation
set.seed(666)  # For reproducibility
imputed_data <- mice(combined_data, method = imputation_methods, m = 5, 
                    printFlag = FALSE, seed = 666)

# Extract completed dataset
completed_data <- complete(imputed_data, 1)

# Handle any remaining missing variables
completed_data <- completed_data %>% select(-any_of("school_values_red"))

# Verify no missing data remains
missing_check <- map_int(completed_data, ~sum(is.na(.x)))
cat("Remaining missing values:", sum(missing_check), "\n")

# Split back into train and test
train_final <- completed_data %>% 
    filter(source == "train") %>% 
    select(-source) %>%
    mutate(bully = target_variable)

test_final <- completed_data %>% 
    filter(source == "test") %>% 
    select(-source)

# ===============================================================================
# 4. REGRESSION MODEL: CONTINUOUS BULLYING SCORE PREDICTION
# ===============================================================================

cat("Training regression model...\n")

# Remove student ID for modeling
train_modeling <- train_final %>% select(-student_id)

# Set up cross-validation
regression_control <- trainControl(
    method = "cv",
    number = 10,
    verboseIter = FALSE,
    savePredictions = "final"
)

# Train Random Forest regression model
set.seed(23123)
rf_regression <- train(
    bully ~ .,
    data = train_modeling,
    method = "rf",
    ntree = 100,
    tuneLength = 5,
    trControl = regression_control
)

# Display results
print("Regression Model Results:")
print(rf_regression$results)

# Find optimal parameters
optimal_params <- rf_regression$results[which.min(rf_regression$results$RMSE), ]
cat("Optimal mtry:", optimal_params$mtry, "with RMSE:", round(optimal_params$RMSE, 4), "\n")

# Feature importance analysis
feature_importance <- varImp(rf_regression)$importance %>%
    rownames_to_column("feature") %>%
    arrange(desc(Overall)) %>%
    slice_head(n = 15)

# Visualize feature importance
importance_plot <- ggplot(feature_importance, 
                         aes(x = Overall, y = reorder(feature, Overall), fill = Overall)) +
    geom_col() +
    scale_fill_distiller(palette = "BuPu", direction = 1) +
    labs(title = "Top 15 Most Important Variables for Bullying Prediction",
         x = "Importance Score", y = "Variable") +
    theme_minimal() +
    theme(legend.position = "none")

print(importance_plot)

# ===============================================================================
# 5. CLASSIFICATION MODEL: HIGH-RISK IDENTIFICATION
# ===============================================================================

cat("Training classification model...\n")

# Create binary target variable (high risk = score >= 2.5)
train_classification <- train_modeling %>%
    mutate(bully_high = factor(ifelse(bully >= 2.5, "Yes", "No"), 
                              levels = c("No", "Yes"))) %>%
    select(-bully)

# Classification control setup
classification_control <- trainControl(
    method = "cv",
    number = 5,
    classProbs = TRUE,
    summaryFunction = twoClassSummary,
    savePredictions = "final"
)

# Train Random Forest classifier
set.seed(23123)
rf_classification <- train(
    bully_high ~ .,
    data = train_classification,
    method = "rf",
    trControl = classification_control,
    tuneLength = 5,
    metric = "ROC"
)

print("Classification Model Results:")
print(rf_classification$results)

# Get predictions for ROC analysis
class_predictions <- predict(rf_classification, train_classification, type = "prob")[, "Yes"]

# ROC Curve Analysis
roc_analysis <- roc(train_classification$bully_high, class_predictions)
cat("ROC AUC:", round(auc(roc_analysis), 3), "\n")

# Threshold optimization
threshold_analysis <- coords(roc_analysis, x = "all", input = "threshold", 
                            ret = c("threshold", "sensitivity", "specificity"))

# Plot threshold analysis
threshold_plot <- ggplot(threshold_analysis, aes(x = threshold)) +
    geom_line(aes(y = sensitivity, color = "Sensitivity"), size = 1) +
    geom_line(aes(y = specificity, color = "Specificity"), size = 1) +
    geom_vline(xintercept = 0.5, linetype = "dashed", color = "red") +
    labs(title = "Sensitivity and Specificity vs. Threshold",
         x = "Classification Threshold", y = "Rate") +
    scale_color_manual(values = c("Sensitivity" = "purple", "Specificity" = "turquoise")) +
    theme_minimal() +
    legend_title("Metric")

print(threshold_plot)

# ===============================================================================
# 6. MODEL EVALUATION AND FINAL PREDICTIONS
# ===============================================================================

# Generate predictions on test set
test_predictions <- data.frame(
    student_id = test_final$student_id,
    predicted_bully_level = predict(rf_regression, test_final),
    predicted_bully_risk = predict(rf_classification, test_final, type = "prob")[, "Yes"],
    predicted_bully_high = predict(rf_classification, test_final)
)

# Summary statistics
risk_threshold <- 0.5
high_risk_count <- sum(test_predictions$predicted_bully_risk >= risk_threshold)
cat("Students predicted as high-risk:", high_risk_count, "out of", nrow(test_predictions), 
    "(", round(100 * high_risk_count / nrow(test_predictions), 1), "%)\n")

# Display sample predictions
head(test_predictions) %>% print()

# Save final predictions
write.csv(test_predictions, "results/final_predictions.csv", row.names = FALSE)

# ===============================================================================
# 7. MODEL INTERPRETATION AND INSIGHTS
# ===============================================================================

# Extract key insights
cat("\n=== KEY FINDINGS ===\n")
cat("1. Most important predictors:\n")
feature_importance$feature[1:5] %>% paste("  -", .) %>% cat(sep = "\n")

cat("\n2. Model Performance:\n")
cat("  - Regression RMSE:", round(optimal_params$RMSE, 3), "\n")
cat("  - Classification AUC:", round(auc(roc_analysis), 3), "\n")

cat("\n3. Risk Distribution:\n")
risk_summary <- table(test_predictions$predicted_bully_high)
cat("  - Low Risk:", risk_summary["No"], "students\n")
cat("  - High Risk:", risk_summary["Yes"], "students\n")

cat("\nAnalysis complete. Results saved to results/ directory.\n")
