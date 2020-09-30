# -*- coding: utf-8 -*-
"""
Created on Fri Apr 17 10:59:15 2020

@author: jurem


This code creates id_present: A data frame that indicates dates in which any id was first registered in the sample and when it was dropped from the sample (i.e., when the person died).
It is used to help more accurately assessing in which months an individual never visited the GP, despite already being registered in the system.

"""

import pandas as pd



meds = pd.read_csv('2_prescriptions_readv2.csv', header=0, sep="|", dtype = str, encoding = 'cp1252')

# remove invalid dates
meds['date'] = pd.to_datetime(meds['date'], format = '%d/%m/%Y')
meds=meds.sort_values(by=['date'])
meds = meds.loc[(meds['date']!='1901-01-01') & (meds['date']!='1902-02-02') & (meds['date']!='1903-03-03') & (meds['date']!='2037-07-07')] # removed 158 prescriptions
# flag duplicated id's
meds['occurred_before'] = meds.duplicated(['id'], keep='first')
# subset the rows with first occurrences of an id
first_occurrence = meds.loc[meds['occurred_before']==False]
first_occurrence.drop(['data_provider', 'prescription_old', 'quantity', 'prescription', 'occurred_before'], axis=1, inplace=True)
first_occurrence.columns = ['id', 'date_first']
first_occurrence['date_first'] = pd.to_datetime(first_occurrence['date_first'], format = '%Y-%m-%d')

# import mortality data frame
mortality = pd.read_csv('mortality.csv', header=0, dtype = str)
mortality = mortality[['id', 'X40000.0.0']]
mortality.columns = (['id', 'date_death'])
mortality = mortality.loc[~mortality['date_death'].isna()] # subset the ones that have died

# merge the data frames
id_present = pd.merge(first_occurrence, mortality, on='id', how='left')
prescriptions = id_present.to_csv('id_present.csv',index=False, header=True)
