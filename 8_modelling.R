library(tidyverse)
library(zoo)
library(censReg)
library(glmmTMB)

# remove all months before the year 2000 (for sensitivity analysis)
id_months <- filter(id_months, month_index > 119)
id_years <- filter(id_years, year > 1999)
id_months$month_index <- id_months$month_index-120


### Tobit models

load("id_months.RData")


# create a new data frame with outliers removed
threshold_aa_meta <- median(id_months$aa_meta[id_months$aa_meta>0]) + 5*IQR(id_months$aa_meta[id_months$aa_meta>0])
id_months_cleaned <- filter(id_months, aa_meta < threshold_aa_meta)


## Without covariates
id_months_cleaned$aa_meta <- as.numeric(id_months_cleaned$aa_meta)
id_months_cleaned$month_index <- as.numeric(id_months_cleaned$month_index)
id_months_cleaned$birth_year <- as.numeric(id_months_cleaned$birth_year)
id_months_cleaned$med_age <- as.numeric(id_months_cleaned$med_age)

basic_m_age <- censReg(aa_meta ~ month_index + birth_year, data = id_months_cleaned)
basic_m_period <- censReg(aa_meta ~ birth_year + med_age, data = id_months_cleaned)
basic_m_cohort <- censReg(aa_meta ~ month_index + med_age, data = id_months_cleaned)


# with polypharmacy

load("id_months.RData")
threshold_aa_meta <- median(id_months$aa_meta[id_months$aa_meta>0]) + 5*IQR(id_months$aa_meta[id_months$aa_meta>0])
threshold_meds_count <- median(id_months$meds_count[id_months$meds_count>0]) + 5*IQR(id_months$meds_count[id_months$meds_count>0])

id_months_cleaned <- filter(id_months, aa_meta < threshold_aa_meta, meds_count < threshold_meds_count)


## Without covariates
id_months_cleaned$aa_meta <- as.numeric(id_months_cleaned$aa_meta)
id_months_cleaned$month_index <- as.numeric(id_months_cleaned$month_index)
id_months_cleaned$birth_year <- as.numeric(id_months_cleaned$birth_year)
id_months_cleaned$med_age <- as.numeric(id_months_cleaned$med_age)
id_months_cleaned$meds_count <- as.numeric(id_months_cleaned$meds_count)

poly_m_age <- censReg(aa_meta ~ month_index + birth_year + meds_count, data = id_months_cleaned)
poly_m_period <- censReg(aa_meta ~ birth_year + med_age + meds_count, data = id_months_cleaned)
poly_m_cohort <- censReg(aa_meta ~ month_index + med_age + meds_count, data = id_months_cleaned)


# number of anticholinergic drugs as an outcome
load("id_months.RData")

threshold_aa_meta <- median(id_months$aa_meta[id_months$aa_meta>0]) + 5*IQR(id_months$aa_meta[id_months$aa_meta>0])

id_months_cleaned <- filter(id_months, aa_meta < threshold_aa_meta)

id_months_cleaned$aa_meta <- as.numeric(id_months_cleaned$aa_meta)
id_months_cleaned$month_index <- as.numeric(id_months_cleaned$month_index)
id_months_cleaned$birth_year <- as.numeric(id_months_cleaned$birth_year)
id_months_cleaned$med_age <- as.numeric(id_months_cleaned$med_age)

id_months_cleaned$aa_number <- id_months_cleaned$aa_1 + id_months_cleaned$aa_2 + id_months_cleaned$aa_3

m_age_number <- censReg(aa_number ~ month_index + birth_year, data = id_months_cleaned)
m_period_number <- censReg(aa_number ~ birth_year + med_age, data = id_months_cleaned)
m_cohort_number <- censReg(aa_number ~ month_index + med_age, data = id_months_cleaned)


## With "stable" covariates
load("id_months.RData")

threshold_aa_meta <- median(id_months$aa_meta[id_months$aa_meta>0]) + 5*IQR(id_months$aa_meta[id_months$aa_meta>0])
id_months_cleaned <- filter(id_months, aa_meta < threshold_aa_meta)

id_months_cleaned$aa_meta <- as.numeric(id_months_cleaned$aa_meta)
id_months_cleaned$month_index <- as.numeric(id_months_cleaned$month_index)
id_months_cleaned$birth_year <- as.numeric(id_months_cleaned$birth_year)
id_months_cleaned$med_age <- as.numeric(id_months_cleaned$med_age)

# run models
cov_m_age <- censReg(aa_meta ~ month_index + birth_year + sex + data_provider + education + deprivation, data = id_months_cleaned)
cov_m_period <- censReg(aa_meta ~ birth_year + med_age + sex + data_provider + education + deprivation, data = id_months_cleaned)
cov_m_cohort <- censReg(aa_meta ~ month_index + med_age + sex + data_provider + education + deprivation, data = id_months_cleaned)


## With all covariates
load("id_months.RData")

threshold_aa_meta <- median(id_months$aa_meta[id_months$aa_meta>0]) + 5*IQR(id_months$aa_meta[id_months$aa_meta>0])
id_months_cleaned <- filter(id_months, aa_meta < threshold_aa_meta)
id_months_cleaned <- filter(id_months_cleaned, bmi < 50 & bmi > 15)

id_months_cleaned$aa_meta <- as.numeric(id_months_cleaned$aa_meta)
id_months_cleaned$month_index <- as.numeric(id_months_cleaned$month_index)
id_months_cleaned$birth_year <- as.numeric(id_months_cleaned$birth_year)
id_months_cleaned$med_age <- as.numeric(id_months_cleaned$med_age)

# run models
cov_plus_m_age <- censReg(aa_meta ~ month_index + birth_year + sex + data_provider + education + deprivation + smoking + alc_freq + activity + bmi, data = id_months_cleaned)
cov_plus_m_period <- censReg(aa_meta ~ birth_year + med_age + sex + data_provider + education + deprivation + smoking + alc_freq + activity + bmi, data = id_months_cleaned)
cov_plus_m_cohort <- censReg(aa_meta ~ month_index + med_age + sex + data_provider + education + deprivation + smoking + alc_freq + activity + bmi, data = id_months_cleaned)




### Mixed effects models


load("id_years.RData")
threshold_aa_meta <- median(id_years$aa_meta[id_years$aa_meta>0]) + 5*IQR(id_years$aa_meta[id_years$aa_meta>0])
id_years_cleaned <- filter(id_years, aa_meta<threshold_aa_meta)

id_years_cleaned$year <- as.numeric(id_years_cleaned$year)
id_years_cleaned$birth_year <- as.factor(id_years_cleaned$birth_year)
basic_m_age <- glmmTMB(aa_meta ~ year + (1+ year|birth_year), zi=~1, data=id_years_cleaned)

id_years_cleaned$med_age <- as.numeric(id_years_cleaned$med_age)
id_years_cleaned$birth_year <- as.factor(id_years_cleaned$birth_year)
basic_m_period <- glmmTMB(aa_meta ~ med_age + (1+ med_age|birth_year), zi=~1, data=id_years_cleaned)

id_years_cleaned$med_age <- as.numeric(id_years_cleaned$med_age)
id_years_cleaned$year <- as.factor(id_years_cleaned$year)
basic_m_cohort <- glmmTMB(aa_meta ~ med_age + (1+ med_age|year), zi=~1, data=id_years_cleaned)




## demographic- and lifestyle factors

# remove the participants who were in the sample for less than a year
ids <- filter(ids, time_in_sample>=12)
# remove outliers for numerical variables
ids <- filter(ids, bmi>15 & bmi<50)
deprivation_min <- median(ids$deprivation,na.rm = TRUE) - 5*IQR(ids$deprivation, na.rm = TRUE)
deprivation_max <- median(ids$deprivation,na.rm = TRUE) + 5*IQR(ids$deprivation, na.rm = TRUE)
ids <- filter(ids, deprivation>deprivation_min & deprivation<deprivation_max)
aa_meta_monthly_max <- median(ids$aa_meta_monthly[ids$aa_meta_monthly>0],na.rm = TRUE) + 5*IQR(ids$aa_meta_monthly[ids$aa_meta_monthly>0], na.rm = TRUE)
ids_cleaned <- filter(ids, aa_meta_monthly<aa_meta_monthly_max)

# models
m_aa <- censReg(aa_meta_monthly ~ age + sex + data_provider + education + deprivation + smoking + alc_freq + activity + bmi, data = ids_cleaned)
m_acid <- censReg(class_acid_disorder_monthly ~ age + sex + data_provider + education + deprivation + smoking + alc_freq + activity + bmi, data = ids_cleaned)
m_analgesic <- censReg(class_analgesic_monthly ~ age + sex + data_provider + education + deprivation + smoking + alc_freq + activity + bmi, data = ids_cleaned)
m_antidepr <- censReg(class_antidepressant_monthly ~ age + sex + data_provider + education + deprivation + smoking + alc_freq + activity + bmi, data = ids_cleaned)
m_antithr <- censReg(class_antithrombotic_monthly ~ age + sex + data_provider + education + deprivation + smoking + alc_freq + activity + bmi, data = ids_cleaned)
m_cardio <- censReg(class_cardiovascular_monthly ~ age + sex + data_provider + education + deprivation + smoking + alc_freq + activity + bmi, data = ids_cleaned)
m_other <- censReg(class_other_monthly ~ age + sex + data_provider + education + deprivation + smoking + alc_freq + activity + bmi, data = ids_cleaned)
m_diabet <- censReg(class_diabetes_monthly ~ age + sex + data_provider + education + deprivation + smoking + alc_freq + activity + bmi, data = ids_cleaned)
m_gastro <- censReg(class_gastrointestinal_monthly ~ age + sex + data_provider + education + deprivation + smoking + alc_freq + activity + bmi, data = ids_cleaned)
m_psycho <- censReg(class_psycholeptic_monthly ~ age + sex + data_provider + education + deprivation + smoking + alc_freq + activity + bmi, data = ids_cleaned)
m_respir <- censReg(class_respiratory_monthly ~ age + sex + data_provider + education + deprivation + smoking + alc_freq + activity + bmi, data = ids_cleaned)
m_uro <- censReg(class_urological_monthly ~ age + sex + data_provider + education + deprivation + smoking + alc_freq + activity + bmi, data = ids_cleaned)
