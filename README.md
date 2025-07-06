# Making Care Common - Student Bullying Risk Prediction System

## Problem Statement
Bullying affects millions of students and can have severe consequences for academic performance, mental health, and social development. This project develops a data-driven early intervention system to identify students at risk of bullying using survey responses, enabling schools to provide timely support and create safer learning environments.

Making Caring Common is a project at the Harvard Graduate School of Education, that learns about what it’s like to be a student at school. The main goal of the survey is for teachers and leaders to learn what students think about values, safety, support, and relationships at school. The survey will also ask questions about how you use social media, including the kinds of social media students use, who they use it to connect with, and whether and how they think social media affects their interpersonal relationships. 

## Data Source
- **Dataset**: Harvard Graduate School of Education Student Survey (2016-2017)
- **Size**: 8,366 student responses across 195 variables
- **Coverage**: Questions on school safety, belonging, discrimination, social media use, and support systems
- **Target Variable**: Bullying score (continuous) and high-risk classification (binary)

## Key Findings
- **Model Performance**: Random Forest achieved 0.404 RMSE for continuous prediction and 0.883 AUC for risk classification
- **Critical Predictors**: School safety perceptions, discrimination experiences, and sense of belonging are the strongest indicators of bullying risk
- **Policy Impact**: 4.7% of students scored as high-risk (≥2.5), highlighting the need for targeted interventions

## Methodology

### 1. Data Engineering & Feature Creation
- **Dimensionality Reduction**: Compressed 195 survey variables to 45 meaningful features
- **Variable Aggregation**: Created composite scores by combining related Likert scale questions:
  
  **Likert Scale Questions** → **Mean Scores**
  Q12 (Safety): `psafe1:psafe7` + `esafe1:esafe7` → `safe_mean`
  Q16 (Discrimination): `disc_race:disc_country` → `disc_mean`
  Q17 (Support): `support1:support8` → `support_mean`
  Q18 (Belonging): `belong1:belong11` → `belong_mean`
  Q21 (Rules): `rules1:rules9` → `rules_mean`

**Binary Questions** → **Sum Scores**
Q13 (Safety Measures): `feel_safer_*` → `feel_safer_sum`
Q22 (Social Media Use): `sm_facebook:sm_none` → `sm_sum`
Q35 (Negative SM Experiences): `sm_ever_*` → `sm_ever_sum`

- **Missing Data Handling**: Used multiple imputation (MICE) to preserve data integrity
- **Domain Expertise**: Applied education survey methodology to create interpretable features

### 2. Predictive Modeling
**Regression Task**: Predict continuous bullying scores
- Random Forest with 10-fold cross-validation
- Optimal performance at mtry=47 with RMSE=0.404
- Feature importance analysis revealed safety and belonging as key factors

**Classification Task**: Identify high-risk students (score ≥2.5)
- Binary classification with threshold optimization
- Achieved 0.883 AUC with high sensitivity (99.7%) 
- Prioritized catching at-risk students over false positive reduction

### 3. Model Interpretation & Validation
- **Feature Importance**: School safety, discrimination, and belonging emerged as top predictors
- **Threshold Tuning**: Selected 0.5 threshold to balance sensitivity and specificity
- **Cross-validation**: Used robust validation to ensure generalizability

## Business Impact

### For Schools & Educators
- **Early Detection**: Identify at-risk students before bullying escalates
- **Resource Allocation**: Target counseling and support services effectively
- **Climate Monitoring**: Use safety and belonging metrics to assess school environment

### For Policymakers
- **Evidence-Based Interventions**: Focus anti-bullying efforts on safety perceptions and inclusive practices
- **Equity Insights**: Address discrimination patterns that contribute to bullying risk
- **System-Level Changes**: Implement policies that strengthen school community and belonging

### For Ed-Tech Companies
- **Platform Features**: Integrate risk monitoring into student management systems
- **Engagement Analytics**: Use belonging and safety metrics to improve online learning environments
- **Automated Alerts**: Flag concerning patterns for counselor follow-up

## Technical Implementation

### Tools & Technologies
- **Programming**: R with tidyverse ecosystem
- **Machine Learning**: caret package for model training and validation
- **Missing Data**: mice package for multiple imputation
- **Visualization**: ggplot2 for results presentation
- **Model Evaluation**: pROC for performance assessment

### Repository Structure
```
├── README.md
├── code/
│   ├── 1_data_cleaning.R        # Feature engineering pipeline
│   ├── 2_regression_model.R     # Continuous score prediction
│   └── 3_classification_model.R # Risk classification
├── data/
│   ├── survey_codebook.xlsx     # Variable definitions
│   └── sample_predictions.csv   # Model outputs (anonymized)
├── results/
│   ├── feature_importance.png   # Variable importance plot
│   ├── model_performance.png    # ROC curves and metrics
│   └── writeup.pdf             # Complete analysis report
└── docs/
    └── methodology.md          # Detailed technical approach
```

## Key Results

### Model Performance
| Metric | Regression | Classification |
|--------|------------|----------------|
| RMSE | 0.404 | - |
| AUC | - | 0.883 |
| Sensitivity | - | 99.7% |
| Specificity | - | 10.8% |

### Most Important Predictors
1. **School Safety** (`safe_mean`): Physical and emotional safety perceptions
2. **Discrimination** (`disc_mean`): Experiences of bias and exclusion  
3. **Belonging** (`belong_mean`): Sense of connection and respect at school
4. **Rules & Fairness** (`rules_mean`): Perceptions of fair treatment
5. **Adult Support** (`support_mean`): Access to trusted adults

## Ethical Considerations

### Model Limitations
- **High False Positive Rate**: May flag students who don't need intervention
- **Sensitive Variables**: Discrimination metrics require careful handling
- **Privacy Concerns**: Survey responses contain personal information

### Recommended Usage
- **Screening Tool Only**: Supplement, don't replace, human judgment
- **Confidential Implementation**: Protect student privacy in all applications
- **Regular Validation**: Monitor for bias and update models as needed
- **Transparent Process**: Explain methodology to stakeholders

## Next Steps

### Model Improvements
- Incorporate longitudinal data to track changes over time
- Test ensemble methods to improve classification performance
- Develop separate models for different grade levels or school contexts

### Implementation Research
- Pilot intervention programs with identified high-risk students
- Measure impact of early identification on student outcomes
- Study optimal threshold settings across different school environments

## Files in This Repository
- **Code**: Well-documented R scripts for complete analysis pipeline
- **Documentation**: Comprehensive writeup with methodology and discussion
- **Results**: Visualizations and performance metrics
- **Data Dictionary**: Survey variable definitions and feature engineering logic

## Contact
For questions about methodology, implementation, or collaboration opportunities, please reach out via LinkedIn or email.
