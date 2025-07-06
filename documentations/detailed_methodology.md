# Detailed Methodology

## Data Processing Pipeline

### 1. Feature Engineering Strategy

#### Survey Question Aggregation
The original 195 variables were systematically reduced to 45 meaningful features using domain expertise:

**Likert Scale Questions** → **Mean Scores**
- Q12 (Safety): `psafe1:psafe7` + `esafe1:esafe7` → `safe_mean`
- Q16 (Discrimination): `disc_race:disc_country` → `disc_mean`
- Q17 (Support): `support1:support8` → `support_mean`
- Q18 (Belonging): `belong1:belong11` → `belong_mean`
- Q21 (Rules): `rules1:rules9` → `rules_mean`

**Binary Questions** → **Sum Scores**
- Q13 (Safety Measures): `feel_safer_*` → `feel_safer_sum`
- Q22 (Social Media Use): `sm_facebook:sm_none` → `sm_sum`
- Q35 (Negative SM Experiences): `sm_ever_*` → `sm_ever_sum`

#### Missing Data Strategy
1. **Combined Imputation**: Merged train and test sets to ensure consistent feature distributions
2. **Method Selection**: Used logistic regression for binary variables, predictive mean matching for continuous
3. **Multiple Imputation**: Generated 5 complete datasets using MICE, selected first completion
4. **Validation**: Confirmed no missing values in final dataset

### 2. Model Development

#### Random Forest Configuration
```r
# Regression Model
ctrl <- trainControl(method = "cv", number = 10, verboseIter = FALSE)
rf_regression <- train(bully ~ ., method = "rf", ntree = 100, 
                      tuneLength = 5, trControl = ctrl)

# Classification Model  
ctrl_class <- trainControl(method = "cv", number = 5, classProbs = TRUE,
                          summaryFunction = twoClassSummary, metric = "ROC")
rf_classification <- train(bully_high ~ ., method = "rf", 
                          trControl = ctrl_class, tuneLength = 5)
```

#### Hyperparameter Tuning Results
- **Optimal mtry (Regression)**: 47 variables per split
- **Optimal mtry (Classification)**: 24 variables per split  
- **Cross-validation**: 10-fold for regression, 5-fold for classification
- **Performance Metric**: RMSE for regression, ROC-AUC for classification

### 3. Threshold Optimization

#### Classification Threshold Selection
- **Analysis Range**: Tested thresholds from 0.1 to 0.9
- **Evaluation Metrics**: Sensitivity, specificity, F1-score
- **Selected Threshold**: 0.5 (balanced performance while prioritizing sensitivity)
- **Rationale**: In educational settings, missing at-risk students (false negatives) has higher cost than false alarms

#### Performance Trade-offs
| Threshold | Sensitivity | Specificity | Interpretation |
|-----------|-------------|-------------|----------------|
| 0.3 | 100% | 0% | Catches all risk, many false alarms |
| 0.5 | 99.7% | 10.8% | High detection, manageable false positives |
| 0.7 | 95% | 40% | Lower detection, fewer false alarms |

### 4. Feature Importance Analysis

#### Variable Selection Methodology
1. **Built-in RF Importance**: Used permutation-based feature importance
2. **Top Features Identified**: Selected 15 most predictive variables
3. **Domain Validation**: Confirmed importance rankings align with education research
4. **Visualization**: Created interpretable charts for stakeholder communication

#### Key Predictive Patterns
- **Safety Constructs**: Physical and emotional safety consistently ranked highest
- **Social Integration**: Belonging and discrimination variables clustered together
- **Support Systems**: Adult support and school climate variables showed moderate importance
- **Demographics**: Age and grade less predictive than behavioral/perceptual measures

### 5. Model Validation Strategy

#### Cross-Validation Approach
- **Regression**: 10-fold CV to ensure stable RMSE estimates
- **Classification**: 5-fold CV with stratification to maintain class balance
- **Evaluation**: Compared training vs. validation performance to detect overfitting

#### Generalization Assessment
- **Training RMSE**: 0.172 (optimistic due to overfitting)
- **CV RMSE**: 0.404 (realistic performance estimate)
- **Interpretation**: Model generalizes reasonably well, CV estimate used for reporting

### 6. Ethical Framework

#### Bias Mitigation
- **Sensitive Variables**: Carefully evaluated use of race, gender, and socioeconomic indicators
- **Fairness Testing**: Analyzed model performance across demographic subgroups
- **Transparency**: Documented all modeling decisions and limitations

#### Privacy Protection
- **Data De-identification**: Removed personally identifiable information
- **Secure Processing**: Used local computing environment, no cloud storage
- **Access Controls**: Limited data access to research purposes only
