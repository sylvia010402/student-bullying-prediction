# Code Directory



## Files

- **`01_data_cleaning.R`** - Feature engineering (195 → 45 variables) and missing data imputation
- **`02_regression_model.R`** - Random Forest regression for continuous bullying scores  
- **`03_classification_model.R`** - Binary classification for high-risk identification
- **`complete_analusis_pipeline.R`** is a more concise version for analysis pipeline for Student Bullying Risk Prediction System that can be ran throughout.

## Prerequisites
```r
install.packages(c("tidyverse", "caret", "mice", "pROC", "RColorBrewer"))
```

## Usage
Run scripts in order (1 → 2 → 3). Each script saves outputs for the next step.

**Note**: Update file paths to match your directory structure before running.
