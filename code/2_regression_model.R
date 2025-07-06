library(ggplot2)
library(dplyr)
library(caret)
library(varImp)

train_imputed <- read.csv("/Users/le/Desktop/pset3_predict_bully/data/train_imputed.csv")
test_imputed <- read.csv("/Users/le/Desktop/pset3_predict_bully/data/test_imputed.csv")

#remove student id 
student_id_train <- train_imputed$student_id

train_imputed <- train_imputed %>% select(-student_id)



#random forest

#1. regression 
#TRAIN
set.seed(23123)

ctrl <- trainControl(
    method = "cv",
    number = 10,
    verboseIter = FALSE
)

rf_bully_reg <- train(
    bully ~ .,
    data = train_imputed,
    method = "rf",
    ntree = 100,
    tuneLength = 5,
    trControl = ctrl,
)



saveRDS(rf_bully_reg, file = "/Users/le/Desktop/pset3_predict_bully/data/rf_bully_reg.rds")


rf_bully_reg = readRDS("/Users/le/Desktop/pset3_predict_bully/data/rf_bully_reg.rds")


summary(rf_bully_reg)
rf_bully_reg$results

plot(rf_bully_reg)

#find the lowest train rmse, we know that mtry = 47, gives a minimum rmse of 0.404
rf_bully_reg$results %>% 
    filter(RMSE == min(RMSE)) %>%
    select(mtry, RMSE)

class(rf_bully_reg)

#retrieve importance 
reg_imp <- caret::varImp(rf_bully_reg)
reg_imp <- reg_imp$importance
reg_imp <- reg_imp %>%
    rownames_to_column("feature") %>%
    arrange(desc(Overall)) %>% 
    slice_head(n = 15)


library(RColorBrewer)

ggplot(reg_imp, aes(x = Overall, y = reorder(feature, Overall), fill = Overall)) +
    geom_col() +
    scale_fill_distiller(palette = "BuPu", direction = 1) +
    labs(
        title = "Top 15 Most Important Variables for Bully Level Prediction",
        x = "Importance",
        y = "Variable"
    ) +
    theme_minimal() +
    theme(legend.position = "none")




#TRAIN rmse

str(train_imputed$sm_age)
summary(train_imputed$sm_age)

train_imputed <- train_imputed %>% mutate(rf_pred = predict(rf_bully_reg, newdata = train_imputed))
RMSE(train_imputed$rf_pred, train_imputed$bully) #rmse = 0.172


#TEST rmse, predict bully level

test_imputed <- test_imputed %>%
    mutate(predicted_bully_level = predict(rf_bully_reg, newdata = test_imputed))

# # #insert back student id
# test_imputed$student_id <- student_id_test


write.csv(test_imputed, "/Users/le/Desktop/pset3_predict_bully/data/test_bully.csv", row.names = FALSE)


