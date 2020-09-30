###
#
#
# Cleans the data to prepare them for transformations.
#
#
###

library(zoo)
library(tidyverse)
library(car)




## read in the files
dems <- read.csv('4_demographics.csv', sep="|", header=TRUE, quote="")
aa_scales <- read.csv('3_aa_scales.csv', sep="|", header=TRUE, quote="")



## remove unnecessary columns
dems$date_1 <- NULL
dems$date_2 <- NULL
dems$date_3 <- NULL
dems$east <- NULL
dems$north <- NULL
dems$month_len <- NULL




## remove invalid dates and duplicate prescriptions
dems$date <- as.Date(dems$date,"%Y-%m-%d") # set date column as class date
dems$date[dems$date=="1901-01-01" | dems$date=="1902-02-02" | dems$date=="1903-03-03" | dems$date=="2037-07-07"] <- NA
dems <- filter(dems, !is.na(date)) # remove entries without a date
dems <- distinct(dems)




## combine the demographics file with aa-scores
aa_scales <- distinct(aa_scales) # remove duplicates so that they aren't re-introduced during merging
aa_scales$date <- as.Date(aa_scales$date,"%d/%m/%Y")
meds <- merge(dems, aa_scales, by=c('id', 'data_provider', 'date', 'quantity', 'prescription', 'prescription_old'), all.x = TRUE) # all.x because 'x' (=dems) is already partially cleaned
meds$month_year <- as.yearmon(format(as.Date(meds$date), "%Y-%m")) # create column for months; use 'yearmon', since Date creates problems if day is not given
rm(dems)
rm(aa_scales)




## add additional columns
# creat new column for month of birth
meds$birth_month <- as.yearmon(format(as.Date(meds$birth_date), "%Y-%m"))

# assign to all topical, ophthalmic, nasal, or otic drugs an anticholinergic value of 0
meds$aa_ancelin[meds$admin_oral==0] <- 0
meds$aa_boustani[meds$admin_oral==0] <- 0
meds$aa_carnahan[meds$admin_oral==0] <- 0
meds$aa_cancelli[meds$admin_oral==0] <- 0
meds$aa_chew[meds$admin_oral==0] <- 0
meds$aa_han[meds$admin_oral==0] <- 0
meds$aa_rudolph[meds$admin_oral==0] <- 0
meds$aa_ehrt[meds$admin_oral==0] <- 0
meds$aa_sittironnarit[meds$admin_oral==0] <- 0
meds$aa_kiesel[meds$admin_oral==0] <- 0
meds$aa_duran[meds$admin_oral==0] <- 0
meds$aa_meta[meds$admin_oral==0] <- 0

# create new columns for class of anticholinergic drug
meds$aa_class <- 0
meds$aa_class[meds$aa_meta>0 & meds$aa_meta<=1] <- 1
meds$aa_class[meds$aa_meta>1 & meds$aa_meta<=2] <- 2
meds$aa_class[meds$aa_meta>2] <- 3
meds$aa_0 <- 0; meds$aa_1 <- 0; meds$aa_2 <- 0; meds$aa_3 <- 0
meds$aa_0[meds$aa_class==0] <- 1
meds$aa_1[meds$aa_class==1] <- 1
meds$aa_2[meds$aa_class==2] <- 1
meds$aa_3[meds$aa_class==3] <- 1
meds$aa_1_value <- 0; meds$aa_2_value <- 0; meds$aa_3_value <- 0
meds$aa_1_value[meds$aa_class==1] <- meds$aa_meta[meds$aa_class==1]
meds$aa_2_value[meds$aa_class==2] <- meds$aa_meta[meds$aa_class==2]
meds$aa_3_value[meds$aa_class==3] <- meds$aa_meta[meds$aa_class==3]
meds$class <- NULL




## remove years and birth years with too few participants
meds$birth_year <- format(as.Date(meds$birth_date), "%Y")
meds <- filter(meds, month_year>'December 1989' & month_year<'Jun 2016')
meds <- filter(meds, birth_year!=1936 & birth_year!=1937 & birth_year!=1970 & birth_year!=1971)




## miscelaneous formatting etc.
meds$birth_year <- format(as.Date(meds$birth_date), "%Y")

meds$id <- as.character(meds$id)
meds$data_provider <- as.factor(meds$data_provider)
meds$date <- as.Date(meds$date,"%d/%m/%Y")
meds$quantity <- as.character(meds$quantity)
meds$prescription <- as.character(meds$prescription)
meds$prescription_old <- as.character(meds$prescription_old)

meds$sex <- as.factor(meds$sex)
meds$month_len <- NULL
meds$remove <- NULL
meds$education <- as.factor(meds$education)
meds$centre <- as.factor(meds$centre)
meds$deprivation <- as.numeric(meds$deprivation)
meds$pack_years <- as.numeric(meds$pack_years)
meds$smoking <- as.factor(meds$smoking)
meds$alc_freq <- as.factor(meds$alc_freq)
meds$activity <- as.factor(meds$activity)
meds$bmi <- as.numeric(meds$bmi)

meds$aa_ancelin <- as.numeric(meds$aa_ancelin)
meds$aa_boustani <- as.numeric(meds$aa_boustani)
meds$aa_carnahan <- as.numeric(meds$aa_carnahan)
meds$aa_cancelli <- as.numeric(meds$aa_cancelli)
meds$aa_chew <- as.numeric(meds$aa_chew)
meds$aa_han <- as.numeric(meds$aa_han)
meds$aa_ehrt <- as.numeric(meds$aa_ehrt)
meds$aa_sittironnarit <- as.numeric(meds$aa_sittironnarit)
meds$aa_kiesel <- as.numeric(meds$aa_kiesel)
meds$aa_duran <- as.numeric(meds$aa_duran)
meds$aa_meta <- as.numeric(meds$aa_meta)
meds$scale_name <- as.character(meds$scale_name)
meds$prescription_1word <- as.character(meds$prescription_1word)




## remove prescriptions that appear after the recorded date of death of the participant
#id_present <- read.csv('id_present.csv', header=TRUE, quote="") #read in file
id_present[id_present==""]  <- NA
# transform to date
id_present$date_first <- as.Date(id_present$date_first,"%Y-%m-%d")
id_present$date_death <- as.Date(id_present$date_death,"%Y-%m-%d")
# if the date of death is later than the last date of the dataset, set the last date of the dataset as the date of death
id_present$date_death[(is.na(id_present$date_death)) | (id_present$date_death > max(meds$date))]  <- max(meds$date)
# if the person was registered before the dataset began, set the starting date as the date when the dataset began
id_present$date_first[(is.na(id_present$date_first)) | (id_present$date_first < min(meds$date))]  <- min(meds$date)
# change column names
colnames(id_present) <- c('id', 'date_first', 'date_last')
# calculate the number of months in the sample
id_present$time_in_sample <- as.numeric((id_present$date_last - id_present$date_first)/365.242*12)
# merge with main dataset
meds <- merge(meds, id_present, by='id', all.x = TRUE)
# remove the prescriptions that received prescriptions after having reportedly died
meds <- filter(meds, time_in_sample>0)
meds$date_first <- NULL
meds$date_last <- NULL
rm(id_present)




## add drug classes
drug_class <- read.csv('drug_groups.csv', header=TRUE)
drug_class <- subset(drug_class, select=c(drug, category))
colnames(drug_class) <- c('scale_name', 'drug_class')
meds <- merge(meds, drug_class, all.x = TRUE)
meds$drug_class[meds$drug_class=='unknown'] <- 'other' # move the un-classified into the "other" category
meds$drug_class <- as.character(meds$drug_class)
meds$drug_class[is.na(meds$drug_class)] <- 'unknown'
# create columns with the anticholinergic burden for each class
meds$class_acid_disorder <- 0; meds$class_acid_disorder[meds$drug_class=='acid disorder' & meds$aa_meta>0] <- meds$aa_meta[meds$drug_class=='acid disorder' & meds$aa_meta>0]
meds$class_analgesic <- 0; meds$class_analgesic[meds$drug_class=='analgesic' & meds$aa_meta>0] <- meds$aa_meta[meds$drug_class=='analgesic' & meds$aa_meta>0]
meds$class_antidepressant <- 0; meds$class_antidepressant[meds$drug_class=='antidepressant' & meds$aa_meta>0] <- meds$aa_meta[meds$drug_class=='antidepressant' & meds$aa_meta>0]
meds$class_antithrombotic <- 0; meds$class_antithrombotic[meds$drug_class=='antithrombotic' & meds$aa_meta>0] <- meds$aa_meta[meds$drug_class=='antithrombotic' & meds$aa_meta>0]
meds$class_cardiovascular <- 0; meds$class_cardiovascular[meds$drug_class=='cardiovascular' & meds$aa_meta>0] <- meds$aa_meta[meds$drug_class=='cardiovascular' & meds$aa_meta>0]
meds$class_diabetes <- 0; meds$class_diabetes[meds$drug_class=='diabetes' & meds$aa_meta>0] <- meds$aa_meta[meds$drug_class=='diabetes' & meds$aa_meta>0]
meds$class_gastrointestinal <- 0; meds$class_gastrointestinal[meds$drug_class=='gastrointestinal' & meds$aa_meta>0] <- meds$aa_meta[meds$drug_class=='gastrointestinal' & meds$aa_meta>0]
meds$class_psycholeptic <- 0; meds$class_psycholeptic[meds$drug_class=='psycholeptic' & meds$aa_meta>0] <- meds$aa_meta[meds$drug_class=='psycholeptic' & meds$aa_meta>0]
meds$class_respiratory <- 0; meds$class_respiratory[meds$drug_class=='respiratory' & meds$aa_meta>0] <- meds$aa_meta[meds$drug_class=='respiratory' & meds$aa_meta>0]
meds$class_urological <- 0; meds$class_urological[meds$drug_class=='urological' & meds$aa_meta>0] <- meds$aa_meta[meds$drug_class=='urological' & meds$aa_meta>0]
meds$class_other <- 0; meds$class_other[meds$drug_class=='other' & meds$aa_meta>0] <- meds$aa_meta[meds$drug_class=='other' & meds$aa_meta>0]
meds$drug_class[meds$drug_class=='unknown'] <- NA




## export
save.image("meds_cleaned.RData")
write.csv(meds, 'meds_cleaned.csv', row.names = FALSE)
