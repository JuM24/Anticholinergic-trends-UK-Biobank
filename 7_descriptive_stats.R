library(tidyverse)
library(zoo)
library(gridExtra)


load("meds_cleaned.RData")
load("ids.RData")
load("id_years_cleaned.RData")
load("id_months_cleaned.RData")

meds$year <- as.numeric(format(as.Date(meds$date), "%Y"))
meds$age_round <- round(meds$med_age)

## Characteristics of the sample
# check numbers of individuals in each birth year
table(ids$birth_year); round(prop.table(table(ids$birth_year)), 2)

s_start <- filter(id_years, year==1990)
s_end <- filter(id_years, year==2015)
s_start <- s_start %>% group_by(id) %>% summarize(age=median(med_age, na.rm=TRUE))
s_end <- s_end %>% group_by(id) %>% summarize(age=median(med_age, na.rm=TRUE))
median(s_start$age); min(s_start$age); max(s_start$age)
median(s_end$age); min(s_end$age); max(s_end$age)

# general demographic
table(ids$sex); prop.table(table(ids$sex))
table(ids$education); prop.table(table(ids$education))
median(ids$deprivation, na.rm = TRUE); IQR(ids$deprivation, na.rm = TRUE)
table(ids$alc_freq); prop.table(table(ids$alc_freq))
table(ids$smoking); prop.table(table(ids$smoking))
table(ids$activity); prop.table(table(ids$activity))
median(ids$bmi, na.rm = TRUE); IQR(ids$bmi, na.rm = TRUE)






## Anticholinergic prescribing
# import drug classes
drug_class <- read.csv('drug_groups.csv', header=TRUE) #read in file
drug_class <- subset(drug_class, select=c(drug, category))
colnames(drug_class) <- c('drug', 'drug_class')

# how many drugs from the aa list were found in the sample and what % did they constitute
length(unique(drug_class$drug))
length(unique(meds$scale_name[meds$scale_name!='unknown']))
length(unique(meds$scale_name[meds$aa_meta>0]))/length(unique(drug_class$drug))
nrow(filter(meds, aa_meta>0))/nrow(meds)
# repeat for all other aa-scales...

# how many drugs from a list were assigned an anticholinergic value
meds$burden_sum <- 0
meds$burden_sum <- meds$aa_ancelin+meds$aa_boustani+meds$aa_cancelli+meds$aa_carnahan+meds$aa_chew+meds$aa_duran+
  meds$aa_ehrt+meds$aa_han+meds$aa_kiesel+meds$aa_meta+meds$aa_rudolph+meds$aa_sittironnarit
meds$scale_name[meds$burden_sum==0] <- NA # set scale name to NA for all prescriptions that had a burden of 0 (due to route of administration)

# repeat below for all aa-scales
scale <- read.csv('anticholinergic burden scales/Han/Han.csv', header=TRUE, quote="") # import list
scale <- filter(scale, aa>0) # retain aa>0
sum(tolower(trimws(scale$drug)) %in% meds$scale_name) # remove white spaces, convert to lower case, and count the drugs that were found in the sample

# how many people were prescribed at least one aa in the sample
sum(ids$aa_meta>0)/nrow(ids)

# how many people were prescribed at least one aa every year
id_years$aa_count <- id_years$aa_1 + id_years$aa_2 + id_years$aa_3
id_years$aa_binary <- 0
id_years$aa_binary[id_years$aa_count>0] <- 1
ids_yearly <- id_years %>% group_by(id) %>% summarise(years_prescribed=sum(aa_binary), person_time=length(unique(year)))
ids_yearly$every_year <- ids_yearly$person_time - ids_yearly$years_prescribed
ids_yearly$every_year <- 0; ids_yearly$every_year[ids_yearly$person_time == ids_yearly$years_prescribed] <- 1
table(ids_yearly$every_year); prop.table(table(ids_yearly$every_year))

# numbers and proportions of different drug classes among anticholinergic drugs
meds$drug_class[meds$drug_class=='unknown'] <- NA
table(meds$drug_class); prop.table(table(meds$drug_class))*100

# mean anticholinergic burden per drug in each class and % of total anticholinergic burden
class_means <- data.frame(table(meds$drug_class)); colnames(class_means) <- c('drug_class', 'frequency')
class_means$aa_meta <- c(sum(meds$class_acid_disorder), sum(meds$class_analgesic), sum(meds$class_antidepressant),
                         sum(meds$class_antithrombotic), sum(meds$class_cardiovascular), sum(meds$class_diabetes),
                         sum(meds$class_gastrointestinal), sum(meds$class_other), sum(meds$class_psycholeptic),
                         sum(meds$class_respiratory), sum(meds$class_urological))
class_means$aa_avg <- class_means$aa_meta/class_means$frequency
class_means$aa_prop <- class_means$aa_meta/sum(class_means$aa_meta)

# number of drugs in each drug class
drug_class <- filter(drug_class, drug %in% unique(meds$scale_name))
table(drug_class$drug_class)

# % increase in burden from 1990 to 2015 (repeat for each scale)
mean(id_years_cleaned$aa_meta[id_years_cleaned$year==1990], na.rm = TRUE)
mean(id_years_cleaned$aa_meta[id_years_cleaned$year==2015], na.rm = TRUE)
mean(id_years_cleaned$aa_meta[id_years_cleaned$year==2015], na.rm = TRUE)/mean(id_years_cleaned$aa_meta[id_years_cleaned$year==1990], na.rm = TRUE)
