library(mice)
library(tidyverse)
library(dplyr)
library(caret)

train <- read.csv("/Users/le/Desktop/pset3_predict_bully/data/student_survey_data.csv")
test <- read.csv("/Users/le/Desktop/pset3_predict_bully/data/student_test_data.csv")


# Define a cleaning + feature engineering function
process_survey_data <- function(df, is_train = TRUE) {
    
    # Remove rows with missing 'bully' ONLY for training
    if (is_train) {
        df <- df %>% filter(!is.na(bully))
    }
    
    # 3. Convert characters to factors
    df <- df %>%
        mutate(across(where(is.character), as.factor))
    
    # Aggregate similar questions together, if it is a likert scale, then find the avg, if it is a binary, find the sum
    # Q12
    Q12_safe_mean <- df %>% 
        select(student_id, psafe1:psafe7, esafe1:esafe7) %>%
        pivot_longer(-student_id) %>%
        group_by(student_id) %>%
        summarise(safe_mean = mean(value, na.rm = TRUE))
    
    df <- df %>% left_join(Q12_safe_mean, by = "student_id") %>% 
        select(-c(psafe1:psafe7, esafe1:esafe7))
    

    # Q13
    Q13_feel_safer_sum <- df %>%
        select(student_id, feel_safer_clear : feel_safer_training) %>%
        pivot_longer(-c(student_id, feel_safer_text)) %>%
        group_by(student_id) %>%
        summarise(feel_safer_sum = sum(value))
    df <- df %>%
        select(-starts_with("feel_safer_")) %>%
        left_join(Q13_feel_safer_sum, by = "student_id")

    
    # Q16
    Q16_disc_mean <- df %>%
        select(student_id, disc_race:disc_country) %>%
        pivot_longer(-student_id) %>%
        group_by(student_id) %>%
        summarise(disc_mean = mean(value, na.rm = TRUE))
    
    df <- df %>%
        left_join(Q16_disc_mean, by = "student_id") %>% 
        select(-c(disc_race:disc_country))
    
    # Q17: support
    Q17_support_mean <- df %>%
        select(student_id, support1:support8) %>%
        pivot_longer(-student_id) %>%
        group_by(student_id) %>%
        summarise(support_mean = mean(value, na.rm = TRUE))
    
    df <- df %>%
        select(-c(support1:support8)) %>%
        left_join(Q17_support_mean, by = "student_id")
    
    # Q18: belong
    Q18_belong_mean <- df %>%
        select(student_id, belong1:belong11) %>%
        pivot_longer(-student_id) %>%
        group_by(student_id) %>%
        summarise(belong_mean = mean(value, na.rm = TRUE))
    
    df <- df %>%
        select(-c(belong1:belong11)) %>%
        left_join(Q18_belong_mean, by = "student_id")
    
    # Q21: rules
    Q21_rules_mean <- df %>%
        select(student_id, rules1:rules9) %>%
        pivot_longer(-student_id) %>%
        group_by(student_id) %>%
        summarise(rules_mean = mean(value, na.rm = TRUE))
    
    df <- df %>%
        select(-c(rules1:rules9)) %>%
        left_join(Q21_rules_mean, by = "student_id")
    
    # Q22: sm_
    Q22_sm_sum <- df %>%
        select(student_id, sm_facebook:sm_none) %>%
        pivot_longer(-c(student_id, sm_text)) %>%
        group_by(student_id) %>%
        summarise(sm_sum = sum(value, na.rm = TRUE))
    
    df <- df %>%
        select(-c(sm_facebook:sm_none)) %>%
        left_join(Q22_sm_sum, by = "student_id")
    
    # Q26: talk
    Q26_talk_mean <- df %>%
        select(student_id, talk_appropriate:talk_connect) %>%
        pivot_longer(-student_id) %>%
        group_by(student_id) %>%
        summarise(talk_mean = mean(value, na.rm = TRUE))
    
    df <- df %>%
        select(-c(talk_appropriate:talk_connect)) %>%
        left_join(Q26_talk_mean, by = "student_id")
    
    # Q32: use_sm
    Q32_use_sm_sum <- df %>%
        select(student_id, use_sm_close_friends:use_sm_give_help) %>%
        pivot_longer(-c(student_id, use_sm_text)) %>%
        group_by(student_id) %>%
        summarise(use_sm_sum = sum(value, na.rm = TRUE))
    
    df <- df %>%
        select(-c(use_sm_close_friends:use_sm_give_help)) %>%
        left_join(Q32_use_sm_sum, by = "student_id")
    
    # Q33: sm_help
    Q33_sm_help_mean <- df %>%
        select(student_id, sm_help_connect:sm_help_reach_out) %>%
        pivot_longer(-student_id) %>%
        group_by(student_id) %>%
        summarise(sm_help_mean = mean(value, na.rm = TRUE))
    
    df <- df %>%
        select(-c(sm_help_connect:sm_help_reach_out)) %>%
        left_join(Q33_sm_help_mean, by = "student_id")
    
    # Q34: sm_concern
    Q34_sm_concern_mean <- df %>%
        select(student_id, sm_concern_left_out:sm_concern_stalk) %>%
        pivot_longer(-student_id) %>%
        group_by(student_id) %>%
        summarise(sm_concern_mean = mean(value, na.rm = TRUE))
    
    df <- df %>%
        select(-c(sm_concern_left_out:sm_concern_stalk)) %>%
        left_join(Q34_sm_concern_mean, by = "student_id")
    
    # Q35: sm_ever
    Q35_sm_ever_sum <- df %>%
        select(student_id, sm_ever_made_mean:sm_ever_stalked) %>%
        pivot_longer(-student_id) %>%
        group_by(student_id) %>%
        summarise(sm_ever_sum = sum(value, na.rm = TRUE))
    
    df <- df %>%
        select(-c(sm_ever_made_mean:sm_ever_stalked)) %>%
        left_join(Q35_sm_ever_sum, by = "student_id")
    
    # Q36: sm_relation
    Q36_sm_relation_mean <- df %>%
        select(student_id, sm_less_real:sm_more_open) %>%
        pivot_longer(-student_id) %>%
        group_by(student_id) %>%
        summarise(sm_relation_mean = mean(value, na.rm = TRUE))
    
    df <- df %>%
        select(-c(sm_less_real:sm_more_open)) %>%
        left_join(Q36_sm_relation_mean, by = "student_id")
    
    # Q39: school
    Q39_school_mean <- df %>%
        select(student_id, school_appropriate:school_connect) %>%
        pivot_longer(-student_id) %>%
        group_by(student_id) %>%
        summarise(school_mean = mean(value, na.rm = TRUE))
    
    df <- df %>%
        select(-c(school_appropriate:school_connect)) %>%
        left_join(Q39_school_mean, by = "student_id")
    
    # Q40: tell
    Q40_tell_sum <- df %>%
        select(student_id, tell_friend:tell_text) %>%
        pivot_longer(-student_id) %>%
        group_by(student_id) %>%
        summarise(tell_sum = sum(value, na.rm = TRUE))
    
    df <- df %>%
        select(-c(tell_friend:tell_text)) %>%
        left_join(Q40_tell_sum, by = "student_id")
    
    # Remove *_text columns
    df <- df %>% select(-ends_with("_text"))
    
    return(df)
}


test_cleaned <- process_survey_data(test, is_train = FALSE)
train_cleaned <- process_survey_data(train, is_train = TRUE)




# Convert sm_age to numeric
train_cleaned$sm_age <- as.numeric(str_extract(train_cleaned$sm_age, "\\d+\\.?\\d*"))
test_cleaned$sm_age  <- as.numeric(str_extract(test_cleaned$sm_age, "\\d+\\.?\\d*"))
summary(train_cleaned$sm_age)
summary(test_cleaned$sm_age)



#Imputation

# Save and remove bully label from training data
bully <- train_cleaned$bully

train_cleaned <- train_cleaned %>% select(-bully)
train_cleaned$source <- "train"
test_cleaned$source <- "test"



# Combine
combined <- bind_rows(train_cleaned, test_cleaned)



#impute combined
# Initialize mice to get the method template
ini <- mice(combined, maxit = 0)
meth <- ini$method


#set method for school_value_red
meth["school_values_red"] <- "logreg"
meth

imp <- mice(combined, method = meth, m = 5, seed = 666)

# Extract the completed data
combined_imputed <- complete(imp, 1)

#check missingness
map_int(combined_imputed, ~sum(is.na(.x)))

#remove the one missing variable
combined_imputed <- combined_imputed %>% select(-school_values_red)

write.csv(combined_imputed, "/Users/le/Desktop/pset3_predict_bully/data/combined_imputed.csv", row.names = FALSE)

combined_imputed <- read.csv("/Users/le/Desktop/pset3_predict_bully/data/combined_imputed.csv")

# Re-split
train_imputed <- combined_imputed %>% filter(source == "train") %>% select(-source)
test_imputed <- combined_imputed %>% filter(source == "test") %>% select(-source)

#put bully back
train_imputed$bully <- bully


#check for missingness in imputed data (no missing)
train_imputed%>%
    summarise(across(everything(), ~ sum(is.na(.)))) %>%
    pivot_longer(
        everything(),
        names_to = "variable",
        values_to = "missing_count"
    ) %>%
    arrange(desc(missing_count)) %>%
    print(n = Inf)

test_imputed%>%
    summarise(across(everything(), ~ sum(is.na(.)))) %>%
    pivot_longer(
        everything(),
        names_to = "variable",
        values_to = "missing_count"
    ) %>%
    arrange(desc(missing_count)) %>%
    print(n = Inf)


write.csv(train_imputed, "/Users/le/Desktop/pset3_predict_bully/data/train_imputed.csv", row.names = FALSE)
write.csv(test_imputed, "/Users/le/Desktop/pset3_predict_bully/data/test_imputed.csv", row.names = FALSE)

#calculate the percentage of bully >= 2.5
train_imputed %>% 
    summarise(bully = mean(bully >= 2.5)) %>%
    mutate(percentage = bully * 100)

train_imputed %>% filter(bully >= 2.5) %>% count()


summary(train_imputed$bully)



