# -*- coding: utf-8 -*-
"""
Created on Sat Apr 18 08:31:06 2020

@author: jurem

This code creates id-period data frames by:
    - grouping the prescriptions data frame by period and computing the average values for the relevant variables
    - adding covariates to the new data frames

Note that the transformation adds the observations for which the length was zero
"""
import pandas as pd
import numpy as np




## import and prepare dataset

meds = pd.read_csv('meds_cleaned.csv', header=0, dtype = str, encoding = 'cp1252')
# remove unnecessary columns to save memory
meds.drop(['sex','education','deprivation','pack_years','alc_freq','activity','bmi','prescription_old','med_age',\
           'aa_class','centre','prescription_1word','scale_name','birth_date','smoking', 'quantity'], axis=1, inplace=True)

# change the types of the columns to the proper types
meds['date'] = pd.to_datetime(meds['date'], format = '%Y-%m-%d')
meds['month_year'] = meds.date.dt.to_period('M')
meds['birth_month'] = meds.date.dt.to_period('M')
meds['year'] = meds.date.dt.to_period('Y')
meds['data_provider'] = meds['data_provider'].astype(float)
meds['time_in_sample'] = meds['time_in_sample'].astype(float)
meds['aa_ancelin'] = meds['aa_ancelin'].astype(float)
meds['aa_boustani'] = meds['aa_boustani'].astype(float)
meds['aa_carnahan'] = meds['aa_carnahan'].astype(float)
meds['aa_cancelli'] = meds['aa_cancelli'].astype(float)
meds['aa_chew'] = meds['aa_chew'].astype(float)
meds['aa_rudolph'] = meds['aa_rudolph'].astype(float)
meds['aa_ehrt'] = meds['aa_ehrt'].astype(float)
meds['aa_han'] = meds['aa_han'].astype(float)
meds['aa_sittironnarit'] = meds['aa_sittironnarit'].astype(float)
meds['aa_duran'] = meds['aa_duran'].astype(float)
meds['aa_kiesel'] = meds['aa_kiesel'].astype(float)
meds['aa_meta'] = meds['aa_meta'].astype(float)
meds['class_acid_disorder'] = meds['class_acid_disorder'].astype(float)
meds['class_analgesic'] = meds['class_analgesic'].astype(float)
meds['class_antidepressant'] = meds['class_antidepressant'].astype(float)
meds['class_antithrombotic'] = meds['class_antithrombotic'].astype(float)
meds['class_cardiovascular'] = meds['class_cardiovascular'].astype(float)
meds['class_other'] = meds['class_other'].astype(float)
meds['class_diabetes'] = meds['class_diabetes'].astype(float)
meds['class_gastrointestinal'] = meds['class_gastrointestinal'].astype(float)
meds['class_psycholeptic'] = meds['class_psycholeptic'].astype(float)
meds['class_respiratory'] = meds['class_respiratory'].astype(float)
meds['class_urological'] = meds['class_urological'].astype(float)
meds['aa_0'] = meds['aa_0'].astype(float)
meds['aa_1'] = meds['aa_1'].astype(float)
meds['aa_2'] = meds['aa_2'].astype(float)
meds['aa_3'] = meds['aa_3'].astype(float)
meds['aa_1_value'] = meds['aa_1_value'].astype(float)
meds['aa_2_value'] = meds['aa_2_value'].astype(float)
meds['aa_3_value'] = meds['aa_3_value'].astype(float)
meds['drug_class'] = meds['drug_class'].astype(str)




## create data frame with data provider and time in sample to be added later

dat_provs = meds.groupby(['id'], as_index=True).agg(data_provider=('data_provider', 'median'), time_in_sample=('time_in_sample', 'median'))
dat_provs['data_provider'] = round(dat_provs['data_provider'])
dat_provs['id'] = dat_provs.index
dat_provs = dat_provs.reset_index(drop=True)




## transform to id-month format

id_months = meds.groupby(['id','month_year'], as_index=True).agg(meds_count=('prescription','count'), \
                  aa_meta=('aa_meta','sum'), aa_0=('aa_0','sum'), aa_1=('aa_1','sum'), aa_2=('aa_2','sum'), \
                  aa_3=('aa_3','sum'), aa_1_value=('aa_1_value', 'sum'), aa_2_value=('aa_2_value', 'sum'), aa_3_value=('aa_3_value', 'sum'), \
                  class_acid_disorder=('class_acid_disorder','sum'), class_analgesic=('class_analgesic','sum'), class_antidepressant=('class_antidepressant','sum'), \
                  class_antithrombotic=('class_antithrombotic','sum'), class_cardiovascular=('class_cardiovascular','sum'), class_other=('class_other','sum'), \
                  class_diabetes=('class_diabetes','sum'), class_gastrointestinal=('class_gastrointestinal','sum'), class_psycholeptic=('class_psycholeptic','sum'), \
                  class_respiratory=('class_respiratory','sum'), class_urological=('class_urological','sum'))\
                  .unstack(fill_value=0).stack()
# the id's and months are tucked away in a list in the index; create separate columns for them
id_months['id'] = [item[0] for item in list(id_months.index)]
id_months['month_year'] = [item[1] for item in list(id_months.index)]
id_months = id_months.reset_index(drop=True)
id_months['date'] = id_months.month_year.values.astype('datetime64[M]')
# add data provider
id_months = pd.merge(id_months, dat_provs, on='id', how='left')




## transform to id-year format

id_years = meds.groupby(['id','year'], as_index=True).agg(meds_count=('prescription','count'), \
                  aa_meta=('aa_meta','sum'), aa_0=('aa_0','sum'), aa_1=('aa_1','sum'), aa_2=('aa_2','sum'), \
                  aa_3=('aa_3','sum'), aa_1_value=('aa_1_value', 'sum'), aa_2_value=('aa_2_value', 'sum'), aa_3_value=('aa_3_value', 'sum'), \
                  aa_ancelin=('aa_ancelin','sum'), aa_boustani=('aa_boustani','sum'), aa_carnahan=('aa_carnahan','sum'), \
                  aa_cancelli=('aa_cancelli','sum'), aa_chew=('aa_chew','sum'), aa_rudolph=('aa_rudolph','sum'), \
                  aa_ehrt=('aa_ehrt','sum'), aa_han=('aa_han','sum'), aa_sittironnarit=('aa_sittironnarit','sum'), \
                  aa_duran=('aa_duran','sum'), aa_kiesel=('aa_kiesel','sum'), \
                  class_acid_disorder=('class_acid_disorder','sum'), class_analgesic=('class_analgesic','sum'), class_antidepressant=('class_antidepressant','sum'), \
                  class_antithrombotic=('class_antithrombotic','sum'), class_cardiovascular=('class_cardiovascular','sum'), class_other=('class_other','sum'), \
                  class_diabetes=('class_diabetes','sum'), class_gastrointestinal=('class_gastrointestinal','sum'), class_psycholeptic=('class_psycholeptic','sum'), \
                  class_respiratory=('class_respiratory','sum'), class_urological=('class_urological','sum'))\
                  .unstack(fill_value=0).stack()
id_years['id'] = [item[0] for item in list(id_years.index)]
id_years['year'] = [item[1] for item in list(id_years.index)]
id_years = id_years.reset_index(drop=True)
id_years['date'] = id_years.year.values.astype('datetime64[Y]')
# add data provider
id_years = pd.merge(id_years, dat_provs, on='id', how='left')




## add demographic- and lifestyle variables to the new data frames

data_frame = id_months.copy()


# add age and sex
age_sex = pd.read_csv('age_sex.csv') #read in the age-and-sex data
# transform id, birth year, and month to string
age_sex['id'] = age_sex['id'].astype(str)
age_sex['birth_year'] = age_sex['birth_year'].astype(str)
age_sex['birth_month'] = age_sex['birth_month'].astype(str)
# add a column indicating the length of the month-string
age_sex['month_len'] = age_sex.loc[~age_sex['birth_month'].isna(), 'birth_month'].apply(len)
# add a '0' to the front of all 1-digit months so as to harmonize the formatting
age_sex.loc[age_sex['month_len']==1, 'birth_month'] = '0' + age_sex.loc[age_sex['month_len']==1, 'birth_month']
# create a new column with the properly formated month and year
age_sex['birth_date'] = "01" + '/' + age_sex['birth_month'] + '/' + age_sex['birth_year']
age_sex['birth_date'] = pd.to_datetime(age_sex['birth_date'], format = '%d/%m/%Y')
# merge the datasets
data_frame = pd.merge(data_frame, age_sex, on='id', how='left')
# add a column for age at prescription
data_frame['date'] = pd.to_datetime(data_frame['date'], format = '%Y-%m-%d')
data_frame['med_age'] = data_frame['date'] -  data_frame['birth_date']
data_frame['med_age'] = data_frame['med_age'].dt.total_seconds()/(24*3600)/365.242
data_frame.drop(['birth_year','birth_month'], axis=1, inplace=True)
del(age_sex)

# add date of assessment
test_dates = pd.read_csv('test_date.csv') # read in the date of the assessment
test_dates['id'] = test_dates['id'].astype(str)
test_dates.columns = ['id', 'date_1', 'date_2', 'date_3'] #rename the columns
# merge the datasets
data_frame = pd.merge(data_frame, test_dates, on='id', how='left')
# transorm to datetime format
data_frame['date_1'] = pd.to_datetime(data_frame['date_1'], format = '%Y-%m-%d')
data_frame['date_2'] = pd.to_datetime(data_frame['date_2'], format = '%Y-%m-%d')
data_frame['date_3'] = pd.to_datetime(data_frame['date_3'], format = '%Y-%m-%d')
del(test_dates)

# education
# read in education
education = pd.read_csv('education.csv', header=0, sep=",", dtype = str)
# choose only education code columns
education.drop(['age_completed_06-10', 'age_completed_12-13', 'age_completed_14-', 'year_ended'], axis=1, inplace=True)
# change all non-graduate-degree codings into 0
education[(education=='2') | (education=='3') | (education=='4') | (education=='5') | (education=='6') | (education=='-7')] = '0'
# change all non-answers to NaN's
education[(education=='-3')] = np.nan
# remove rows with only NaN's
education = education.dropna(subset=['first_1', 'first_2', 'first_3', 'first_4', 'first_5', 'second_1',
                                     'second_2', 'second_3', 'second_4', 'second_5', 'second_6', 'second_7',
                                     'third_0', 'third_1', 'third_2', 'third_3', 'third_4', 'third_5'], axis='rows', how='all')
# initialize columns
education['education_1'] = np.nan; education['education_2'] = np.nan; education['education_3'] = np.nan
# put college-degree codes found in either one of the columns that refer to a single visit into a single new column
education.loc[(education['first_1']=='0') | (education['first_2']=='0') | (education['first_3']=='0') | (education['first_4']=='0') | (education['first_5']=='0'), 'education_1'] = '0'
education.loc[(education['first_1']=='1') | (education['first_2']=='1') | (education['first_3']=='1') | (education['first_4']=='1') | (education['first_5']=='1'), 'education_1'] = '1'
education.loc[(education['second_1']=='0') | (education['second_2']=='0') | (education['second_3']=='0') | (education['second_4']=='0') | (education['second_5']=='0') | (education['second_6']=='0') | (education['second_7']=='0'), 'education_2'] = '0'
education.loc[(education['second_1']=='1') | (education['second_2']=='1') | (education['second_3']=='1') | (education['second_4']=='1') | (education['second_5']=='1') | (education['second_6']=='1') | (education['second_7']=='1'), 'education_2'] = '1'
education.loc[(education['third_0']=='0') | (education['third_1']=='0') | (education['third_2']=='0') | (education['third_3']=='0') | (education['third_4']=='0') | (education['third_5']=='0'), 'education_3'] = '0'
education.loc[(education['third_0']=='1') | (education['third_1']=='1') | (education['third_2']=='1') | (education['third_3']=='1') | (education['third_4']=='1') | (education['third_5']=='1'), 'education_3'] = '1'
# keep only the relevant columns
education = education[['id','education_1','education_2','education_3']]
# add education to main data frame
data_frame = pd.merge(data_frame, education, on='id', how='left')
# for each prescription, keep only the date of education before the prescription was issued
data_frame['education'] = data_frame['education_1'] # initiate new column
data_frame.loc[data_frame['date'] >= data_frame['date_2'], 'education'] = data_frame['education_2'] # for all the prescriptions issued after date_2, education will correspond to the education at the 2nd visit
data_frame.loc[data_frame['date'] >= data_frame['date_3'], 'education'] = data_frame['education_3'] # same as above, but for date_3 and 3rd visit
# drop unneccesary columns
data_frame.drop(['education_1','education_2','education_3'], axis=1, inplace=True)
del(education)

# deprivation
# read in the Townsend
deprivation = pd.read_csv('deprivation.csv', header=0, dtype = str)
# merge with main data frame
data_frame = pd.merge(data_frame, deprivation, on='id', how='left')
del(deprivation)

# smoking
smoking = pd.read_csv('tobacco.csv', header=0, dtype = str)
smoking['smoking_1'] = smoking.smoking_1.astype(str)
smoking.loc[(smoking['smoking_1'] == '-3') | (smoking['smoking_1'] == 'nan'), 'smoking_1'] = np.nan
# add to the main data frame
data_frame = pd.merge(data_frame, smoking, on='id', how='left')
# update using 2nd and 3rd visits
data_frame['smoking'] = data_frame['smoking_1'] # initiate new column
data_frame.loc[data_frame['date'] >= data_frame['date_2'], 'smoking'] = data_frame['smoking_2'] # for all the prescriptions issued after date_2, smoking will correspond to the smoking at the 2nd visit
data_frame.loc[data_frame['date'] >= data_frame['date_3'], 'smoking'] = data_frame['smoking_3'] # same as above, but for date_3 and 3rd visit
# remove columns
data_frame.drop(['smoking_1', 'smoking_2','smoking_3'], axis=1, inplace=True)
del(smoking)

# alcohol consumption
# read in the data frame
alcohol = pd.read_csv('alcohol.csv', header=0, dtype = str)
# add to the main data frame
data_frame = pd.merge(data_frame, alcohol, on='id', how='left')
# set first assessment visit as default
data_frame.rename({'alc_freq_1': 'alc_freq'}, axis=1, inplace=True)
# for each data point on alcohol consumption frequency, update by using the 2nd and 3rd visits
data_frame.loc[data_frame['date'] >= data_frame['date_2'], 'alc_freq'] = data_frame['alc_freq_2']
data_frame.loc[data_frame['date'] >= data_frame['date_3'], 'alc_freq'] = data_frame['alc_freq_3']
# set unknown data points to NaN
data_frame.loc[data_frame['alc_freq']=='-3', 'alc_freq'] = np.nan
# drop unneccesary columns
data_frame.drop(['alc_freq_2','alc_freq_3'], axis=1, inplace=True)
del(alcohol)

# physical activity
activity_type = pd.read_csv('activity_type.csv', header=0, dtype = str)
# change 'none' or 'prefer not to answer' to NaN
activity_type[(activity_type=='-7') | (activity_type=='-3')] = np.nan
# re-code as found in Hanlon et al. (2020)
activity_type[(activity_type=='1') | (activity_type=='4')] = '1'
activity_type[(activity_type=='2') | (activity_type=='5')] = '2'
# initiate columns for all three visits
activity_type['activity_1'] = np.nan; activity_type['activity_2'] = np.nan; activity_type['activity_3'] = np.nan
# if the higher level of physical activity occurs as a response during any visit, override the lower
activity_type.loc[(activity_type['first_1']=='1') | (activity_type['first_2']=='1') | (activity_type['first_3']=='1') | (activity_type['first_4']=='1') | (activity_type['first_5']=='1'), 'activity_1'] = '1'
activity_type.loc[(activity_type['first_1']=='2') | (activity_type['first_2']=='2') | (activity_type['first_3']=='2') | (activity_type['first_4']=='2') | (activity_type['first_5']=='2'), 'activity_1'] = '2'
activity_type.loc[(activity_type['first_1']=='3') | (activity_type['first_2']=='3') | (activity_type['first_3']=='3') | (activity_type['first_4']=='3') | (activity_type['first_5']=='3'), 'activity_1'] = '3'

activity_type.loc[(activity_type['second_1']=='1') | (activity_type['second_2']=='1') | (activity_type['second_3']=='1') | (activity_type['second_4']=='1') | (activity_type['second_5']=='1'), 'activity_2'] = '1'
activity_type.loc[(activity_type['second_1']=='2') | (activity_type['second_2']=='2') | (activity_type['second_3']=='2') | (activity_type['second_4']=='2') | (activity_type['second_5']=='2'), 'activity_2'] = '2'
activity_type.loc[(activity_type['second_1']=='3') | (activity_type['second_2']=='3') | (activity_type['second_3']=='3') | (activity_type['second_4']=='3') | (activity_type['second_5']=='3'), 'activity_2'] = '3'

activity_type.loc[(activity_type['third_1']=='1') | (activity_type['third_2']=='1') | (activity_type['third_3']=='1') | (activity_type['third_4']=='1') | (activity_type['third_5']=='1'), 'activity_3'] = '1'
activity_type.loc[(activity_type['third_1']=='2') | (activity_type['third_2']=='2') | (activity_type['third_3']=='2') | (activity_type['third_4']=='2') | (activity_type['third_5']=='2'), 'activity_3'] = '2'
activity_type.loc[(activity_type['third_1']=='3') | (activity_type['third_2']=='3') | (activity_type['third_3']=='3') | (activity_type['third_4']=='3') | (activity_type['third_5']=='3'), 'activity_3'] = '3'
# remove unneccesary columns
activity_type = activity_type[['id', 'activity_1', 'activity_2', 'activity_3']]
# add to the main data frame
data_frame = pd.merge(data_frame, activity_type, on='id', how='left')
# set first assessment visit as default
data_frame.rename({'activity_1': 'activity'}, axis=1, inplace=True)
# for each data point on physical activity, update by using the 2nd and 3rd visits
data_frame.loc[data_frame['date'] >= data_frame['date_2'], 'activity'] = data_frame['activity_2']
data_frame.loc[data_frame['date'] >= data_frame['date_3'], 'activity'] = data_frame['activity_3']
# drop unneccesary columns
data_frame.drop(['activity_2','activity_3'], axis=1, inplace=True)
del(activity_type)

# BMI
# read in the data frame
bmi = pd.read_csv('bmi.csv', header=0, dtype = str)
# add to the main data frame
data_frame = pd.merge(data_frame, bmi, on='id', how='left')
# set first assessment visit as default
data_frame.rename({'bmi_1': 'bmi'}, axis=1, inplace=True)
# for each data point on BMI, update by using the 2nd and 3rd visits
data_frame.loc[data_frame['date'] >= data_frame['date_2'], 'bmi'] = data_frame['bmi_2']
data_frame.loc[data_frame['date'] >= data_frame['date_3'], 'bmi'] = data_frame['bmi_3']
# drop unneccesary columns
data_frame.drop(['bmi_2','bmi_3'], axis=1, inplace=True)
del(bmi)

# information on whether when participant was registered in the sample and when they died
# read in the data frame
id_present = pd.read_csv('id_present.csv', header=0, dtype = str)
id_present.loc[id_present['date_death'].isnull(), 'date_death'] = max(data_frame.date)
# add to the main data frame
data_frame = pd.merge(data_frame, id_present, on='id', how='left')
data_frame['date_first'] = pd.to_datetime(data_frame['date_first'], format = '%Y-%m-%d')
data_frame['date_death'] = pd.to_datetime(data_frame['date_death'], format = '%Y-%m-%d')
# for each id, remove entries before the first date and entries after the date of death
data_frame = data_frame.loc[data_frame['date'] >= data_frame['date_first']]
data_frame = data_frame.loc[data_frame['date'] < data_frame['date_death']]
# drop unneccesary columns
data_frame.drop(['date_first', 'date_death'], axis=1, inplace=True)
del(id_present)

# export .csv
prescriptions = data_frame.to_csv('id_months.csv', header=True, sep='|')



## Repeat for id_years...
