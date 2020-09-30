###
#
#
# Prepares post-Python data frames for analysis and creates an id- data frame
#
#
###

library(tidyverse)
library(zoo) # for yearmon




### 1. id-year combinations



id_years <- read.csv('id_years.csv', sep="|", header=TRUE, quote="")

# change variables' classes
id_years$sex <- as.factor(id_years$sex)
id_years$education <- as.factor(id_years$education)
id_years$data_provider <- as.factor(id_years$data_provider)
id_years$alc_freq <- as.factor(id_years$alc_freq)
id_years$activity <- as.factor(id_years$activity)
id_years$smoking[id_years$smoking==-3] <- NA
id_years$smoking <- as.factor(id_years$smoking)

# create new period variables
id_years$birth_month <- as.yearmon(format(as.Date(id_years$birth_date), "%Y-%m"))
id_years$birth_year <- format(as.Date(id_years$birth_date), "%Y")
id_years$birth_year <- as.numeric(id_years$birth_year)
id_years$year <- as.numeric(format(as.Date(id_years$date), "%Y")) # create new column with year (instead of the whole date) of prescription

# scale the relevant variables (prevents issues with some types of modelling)
id_years$deprivation_scaled <- scale(id_years$deprivation)
id_years$bmi_scaled <- scale(id_years$bmi)

# remove years and birth years with too few individuals or with funky outliers
id_years <- filter(id_years, year < 2016)

# save
save.image("id_years_cleaned.RData")
rm(id_years)



### 2. id-month combinations

id_months <- read.csv('id_months.csv', sep="|", header=TRUE, quote="")

# change variables' classes
id_months$date <- as.Date(id_months$date)
id_months$year <- as.numeric(format(as.Date(id_months$date), "%Y"))
id_months$birth_date <- as.Date(id_months$birth_date)
id_months$birth_year <- format(as.Date(id_months$birth_date), "%Y")
id_months$month_year <- as.yearmon(id_months$month_year)
id_months$data_provider <- as.factor(id_months$data_provider)
id_months$sex <- as.factor(id_months$sex)
id_months$education <- as.factor(id_months$education)
id_months$alc_freq <- as.factor(id_months$alc_freq)
id_months$activity <- as.factor(id_months$activity)
id_months$smoking[id_months$smoking==-3] <- NA
id_months$smoking <- as.factor(id_months$smoking)

# set month indices
id_months <- id_months %>% arrange(month_year)
indices <- cbind(as.data.frame(unique(id_months$month_year)), as.data.frame(seq(length(unique(id_months$month_year)))))
colnames(indices) <- c('month_year', 'month_index')
id_months <- merge(indices, id_months, by='month_year')
id_months$month_index <- id_months$month_index - 1 # set starting index to 0
rm(indices)

# save
save.image("id_months_cleaned.RData")
id_months <- subset(id_months, select=c(aa_meta, month_index, med_age, birth_year, sex, data_provider, education, deprivation, smoking, alc_freq, activity, bmi))
rm(id_months)



### 3. create a participant-based dataset

meds <- read.csv('meds_cleaned.csv', sep="|", header=TRUE, quote="")
# import test date to calculate age at testing
test_dates <- read.csv('test_date.csv', header=TRUE)
colnames(test_dates) <- c('id', 'date_1', 'date_2', 'date_3')
# import dates of birth
birth_dates <- read.csv('age_sex_formatted.csv', sep='|', header=TRUE)
birth_dates <- subset(birth_dates, select=c('id', 'birth_date'))

## prepare data frame which will be used to calculate the number of months for each participant
id_present <- read.csv('id_present.csv', header=TRUE, quote="")
id_present[id_present==""]  <- NA
# transform to date
id_present$date_first <- as.Date(id_present$date_first,"%Y-%m-%d")
id_present$date_death <- as.Date(id_present$date_death,"%Y-%m-%d")
# if the date of death is later than the last date of the dataset, set the last date of the dataset as the date of death
id_present$date_death[(is.na(id_present$date_death)) | (id_present$date_death > max(meds$date))]  <- max(meds$date)
# if the person was registered before the dataset began, set the starting date as the date that the dataset began on
id_present$date_first[(is.na(id_present$date_first)) | (id_present$date_first < min(meds$date))]  <- min(meds$date)
# if the person was registered after the dataset ends, set the starting date as the date when the dataset ends
id_present$date_first[(is.na(id_present$date_first)) | (id_present$date_first > max(meds$date))]  <- max(meds$date)
# transform to yearmon
id_present$date_first <- as.yearmon(format(as.Date(id_present$date_first), "%Y-%m"))
id_present$date_death <- as.yearmon(format(as.Date(id_present$date_death), "%Y-%m"))
colnames(id_present) <- c('id', 'date_first', 'date_last')
# calculate the number of months in the sample
id_present$time_in_sample <- (id_present$date_last - id_present$date_first)*12
id_present$date_first <- NULL
id_present$date_last <- NULL
# remove those with invalid person-time
id_present <- filter(id_present, time_in_sample >= 0)
id_present$id <- as.character(id_present$id)

# change columns to numeric so that the median function below performs normally
meds$birth_year <- as.numeric(meds$birth_year)
meds$birth_month <- as.numeric(meds$birth_month)
meds$sex <- as.numeric(meds$sex)
meds$data_provider <- as.numeric(meds$data_provider)
meds$education <- as.numeric(meds$education)
meds$alc_freq <- as.numeric(meds$alc_freq)
meds$activity <- as.numeric(meds$activity)
meds$smoking[meds$smoking==-3] <- NA
meds$smoking <- as.numeric(meds$smoking)

# create the data-frame
ids <- meds %>% group_by(id) %>% summarize(sex=median(sex,na.rm=TRUE),
                                           data_provider=median(data_provider,na.rm=TRUE), education=median(education,na.rm=TRUE),
                                           deprivation=median(deprivation,na.rm=TRUE), pack_years=median(pack_years,na.rm=TRUE),
                                           alc_freq=median(alc_freq,na.rm=TRUE), activity=median(activity,na.rm=TRUE),
                                           bmi=median(bmi,na.rm=TRUE), birth_year=median(birth_year,na.rm=TRUE),
                                           birth_month=median(birth_month,na.rm=TRUE), meds_count=length(prescription),
                                           aa_meta=sum(aa_meta), aa_1_value=sum(aa_1_value), aa_2_value=sum(aa_2_value), aa_3_value=sum(aa_3_value),
                                           class_acid_disorder=sum(class_acid_disorder), class_analgesic=sum(class_analgesic),
                                           class_antidepressant=sum(class_antidepressant), class_antithrombotic=sum(class_antithrombotic),
                                           class_cardiovascular=sum(class_cardiovascular), class_other=sum(class_other),
                                           class_diabetes=sum(class_diabetes), class_gastrointestinal=sum(class_gastrointestinal),
                                           class_psycholeptic=sum(class_psycholeptic), class_respiratory=sum(class_respiratory),
                                           class_urological=sum(class_urological), smoking=median(smoking, na.rm = TRUE))

# calculate monthly values
ids <- merge(ids, id_present)
ids$aa_meta_monthly <- ids$aa_meta/ids$time_in_sample
ids$aa_1_monthly <- ids$aa_1_value/ids$time_in_sample
ids$aa_2_monthly <- ids$aa_2_value/ids$time_in_sample
ids$aa_3_monthly <- ids$aa_3_value/ids$time_in_sample
ids$meds_count_monthly <- ids$meds_count/ids$time_in_sample
ids$class_acid_disorder_monthly <- ids$class_acid_disorder/ids$time_in_sample
ids$class_analgesic_monthly <- ids$class_analgesic/ids$time_in_sample
ids$class_antidepressant_monthly <- ids$class_antidepressant/ids$time_in_sample
ids$class_antithrombotic_monthly <- ids$class_antithrombotic/ids$time_in_sample
ids$class_cardiovascular_monthly <- ids$class_cardiovascular/ids$time_in_sample
ids$class_other_monthly <- ids$class_other/ids$time_in_sample
ids$class_diabetes_monthly <- ids$class_diabetes/ids$time_in_sample
ids$class_gastrointestinal_monthly <- ids$class_gastrointestinal/ids$time_in_sample
ids$class_psycholeptic_monthly <- ids$class_psycholeptic/ids$time_in_sample
ids$class_respiratory_monthly <- ids$class_respiratory/ids$time_in_sample
ids$class_urological_monthly <- ids$class_urological/ids$time_in_sample
# round numericals that are to be transformed to factors
ids$sex <- ids$sex-1
ids$education <- round(ids$education); ids$education <- ids$education-1
ids$alc_freq <- round(ids$alc_freq)
ids$activity <- round(ids$activity)
ids$smoking <- round(ids$smoking)-2
# transform to proper class
ids$birth_month <- yearmon(ids$birth_month)
ids$sex <- as.factor(ids$sex)
ids$education <- as.factor(ids$education)
ids$alc_freq <- as.factor(ids$alc_freq)
ids$activity <- as.factor(ids$activity)
ids$smoking <- as.factor(ids$smoking)
ids$data_provider <- round(as.numeric(ids$data_provider))
ids$data_provider[ids$data_provider==3] <- 1 # put all England-based data providers into one category
ids$data_provider <- as.factor(ids$data_provider)
ids$deprivation <- as.numeric(ids$deprivation)
ids$pack_years <- as.numeric(ids$pack_years)

# add birth- and testing dates
ids <- merge(ids, test_dates, all.x = TRUE)
ids <- merge(ids, birth_dates, all.x = TRUE)
ids$date_1 <- as.Date(ids$date_1,"%Y-%m-%d")
ids$date_2 <- as.Date(ids$date_2,"%Y-%m-%d")
ids$date_3 <- as.Date(ids$date_3,"%Y-%m-%d")
ids$birth_date <- as.Date(ids$birth_date,"%Y-%m-%d")
ids$age <- as.numeric(difftime(ids$date_1, ids$birth_date, units = 'weeks')/52.25)

# save
rm(birth_dates); rm(id_present); rm(meds); rm(test_dates)
save.image("ids.RData")
