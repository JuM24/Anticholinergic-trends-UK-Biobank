# -*- coding: utf-8 -*-
"""
Created on Mon Mar 30 15:55:25 2020

@author: jurem

1. Homogenizes discordant drug names across the different anticholinergic scale and creates a single data frame containing all scales.
2. Creates a new scale that averages the scores from previously published scales (except meta-analysis-based scales).
3. Exports a table with drugs as rows and anticholinergic scales as columns; it includes only drugs that were scored with >0 by at least one scale.
"""

import pandas as pd
import numpy as np
import re



## Prepare the data frames

# read in aa-scales
kiesel = (pd.read_csv ('Kiesel.csv').sort_values(by=['aa'], ascending = False))
ancelin = (pd.read_csv ('Ancelin.csv').sort_values(by=['aa'], ascending = False))
boustani = (pd.read_csv ('Boustani.csv').sort_values(by=['aa'], ascending = False))
carnahan = (pd.read_csv ('Carnahan.csv').sort_values(by=['aa'], ascending = False))
cancelli = (pd.read_csv ('Cancelli.csv').sort_values(by=['aa'], ascending = False))
chew = (pd.read_csv ('Chew.csv').sort_values(by=['aa'], ascending = False))
rudolph = (pd.read_csv ('Rudolph.csv').sort_values(by=['aa'], ascending = False))
ehrt = (pd.read_csv ('Ehrt.csv').sort_values(by=['aa'], ascending = False))
han = (pd.read_csv ('Han.csv').sort_values(by=['aa'], ascending = False))
sittironnarit = (pd.read_csv ('Sittironnarit.csv').sort_values(by=['aa'], ascending = False))
duran = (pd.read_csv ('Duran.csv').sort_values(by=['aa'], ascending = False))

# rename the columns
kiesel.columns = ['drug', 'aa_kiesel']
ancelin.columns = ['drug', 'aa_ancelin']
boustani.columns = ['drug', 'aa_boustani']
carnahan.columns = ['drug', 'aa_carnahan']
cancelli.columns = ['drug', 'aa_cancelli']
chew.columns = ['drug', 'aa_chew']
rudolph.columns = ['drug', 'aa_rudolph']
ehrt.columns = ['drug', 'aa_ehrt']
han.columns = ['drug', 'aa_han']
sittironnarit.columns = ['drug', 'aa_sittironnarit']
duran.columns = ['drug', 'aa_duran']

# create a list of scales
scales = [kiesel, ancelin, boustani, carnahan, cancelli, chew, rudolph, ehrt, han, sittironnarit, duran]
scales_names = ['Kiesel', 'Ancelin', 'Boustani', 'Carnahan', 'Cancelli', 'Chew', 'Rudolph', 'Ehrt', 'Han', 'Sittironnarit', 'Duran']

# iterate through the list created above and for all scales:
    # convert drug names to lowercase
for scale in scales:
    scale.loc[:,'drug'] = scale['drug'].str.lower()
    # remove leading and trailing white spaces
for scale in scales:
    scale['drug'] = scale.loc[:,'drug'].apply(str.strip)

# read in the file with generic- and trade names for drugs and check for duplicates
drug_names = pd.read_csv('alternative drug names.csv', header=0, dtype = str, encoding = 'cp1252')
for col in drug_names:
    drug_names.loc[:, col] = drug_names[col].str.lower() # convert to lowercase
    drug_names.loc[~drug_names[col].isna(), col] = drug_names.loc[~drug_names[col].isna(), col].apply(str.strip) # remove left and right white spaces
l = [] # create list
for i in range(len(drug_names)): # iterate over entries in the file
    for j in range(len(drug_names.columns)):
      l.append(drug_names.iloc[i,j])  # append entries to the list
l = pd.DataFrame(l) # transform list to 1-column data frame
l.columns = ['drug_name'] # name columns
l = l[l['drug_name'].notna()] # remove NaN's
counts = l.drug_name.value_counts() # check numbers of counts for each entry




## Replace trade-/alternative names in the scales with generic names

# read in the file with alternative drug names that is formatted as a dictionary with alternative names as keys and proper generic names as values
drug_names = pd.read_csv('alternative drug names_reformatted.csv', header=0, dtype = str, encoding = 'cp1252').sort_values(by=['combination'], ascending = True)
for col in drug_names:
    drug_names.loc[:, col] = drug_names[col].str.lower() # convert to lowercase
    drug_names.loc[~drug_names[col].isna(), col] = drug_names.loc[~drug_names[col].isna(), col].apply(str.strip) # remove left and right white spaces

# create dictionary with alternative-/brand- and generic drug names
name_dict = dict(zip(drug_names['brand'], drug_names['generic']))

# code to find the exact drug name match
def findName(drug_name):
    # Regex: one of the characters in the bracket or start of string or space; drug name; one of the characters in the bracket or space or end of string
    pattern = re.search(r'([+_"&~</]|^|\s)({0})([+_"&~</]|\s|$)'.format(drug), drug_name)
    if pattern:
        return 1
    else: return 0

# execute the replacing algorithm
drug_count = len(name_dict) # the count tracks the loop below
for drug in name_dict:
    print('Substituting ' + drug + ' with ' + str(name_dict[drug]) + '...' + '\n' + 'Drugs left: ' + str(drug_count))
    for scale in scales:
        name_rows = scale.loc[:, 'drug'].apply(lambda x: findName(x)) # find rows with drug
        name_indices = list((name_rows[name_rows==1]).index) # mark the rows/indices of the data frame where the drug was found
        scale.loc[name_indices, 'drug'] = scale.loc[name_indices, 'drug'].str.replace(drug, name_dict[drug], regex=False)
    drug_count -= 1 # track progress




## Remove potential duplicates from each scale

# identify scales with duplicate drug entries
count = 0
for scale in scales:
    if len(set(scale['drug']))!=len(scale):
        duplicates = 'Yes.'
    else:
        duplicates = 'No.'
    print(scales_names[count] + ' duplicates? ' + duplicates)
    count += 1
# remove duplicates
kiesel = kiesel[~kiesel.duplicated(['drug'])]
ancelin = ancelin[~ancelin.duplicated(['drug'])]
boustani = boustani[~boustani.duplicated(['drug'])]
carnahan = carnahan[~carnahan.duplicated(['drug'])]
cancelli = cancelli[~cancelli.duplicated(['drug'])]
chew = chew[~chew.duplicated(['drug'])]
rudolph = rudolph[~rudolph.duplicated(['drug'])]
ehrt = ehrt[~ehrt.duplicated(['drug'])]
han = han[~han.duplicated(['drug'])]
sittironnarit = sittironnarit[~sittironnarit.duplicated(['drug'])]
duran = duran[~duran.duplicated(['drug'])]




## Prepare the new data frame

# change the rating of Ehrt's scale to fit the others
ehrt.loc[ehrt['aa_ehrt']==2, 'aa_ehrt'] = 1
ehrt.loc[ehrt['aa_ehrt']==3, 'aa_ehrt'] = 2
ehrt.loc[ehrt['aa_ehrt']==4, 'aa_ehrt'] = 3

# change the rating of Duran's scale to fit the others
duran.loc[duran['aa_duran']==2, 'aa_duran'] = 3
duran.loc[duran['aa_duran']==1, 'aa_duran'] = 2
duran.loc[duran['aa_duran']==0.5, 'aa_duran'] = 1

# create a data frame that includes only those drugs from Kiesel's and Duran's lists that were not on any other list
# so that we can use those drugs in the development of the new meta-scale
kiesel_add_on = kiesel.loc[(kiesel['drug']=='rotigotine') | (kiesel['drug']=='aclidinium bromide') | (kiesel['drug']=='dimetindene') | (kiesel['drug']=='etoricoxib')]
kiesel_add_on.columns = ['drug', 'aa_kiesel_add_on']
duran_add_on = duran.loc[(duran['drug']=='ketotifen')]
duran_add_on.columns = ['drug', 'aa_duran_add_on']

# merge all scales into one data frame
scales = pd.merge(ancelin, chew, on='drug', how='outer')
scales = pd.merge(scales, cancelli, on='drug', how='outer')
scales = pd.merge(scales, han, on='drug', how='outer')
scales = pd.merge(scales, rudolph, on='drug', how='outer')
scales = pd.merge(scales, ehrt, on='drug', how='outer')
scales = pd.merge(scales, sittironnarit, on='drug', how='outer')
scales = pd.merge(scales, boustani, on='drug', how='outer')
scales = pd.merge(scales, carnahan, on='drug', how='outer')
scales = pd.merge(scales, kiesel_add_on, on='drug', how='outer')
scales = pd.merge(scales, duran_add_on, on='drug', how='outer')

# create columns indicating the number of times that a certain score appears
scales['aa_0'] = np.nan; scales['aa_05'] = np.nan; scales['aa_1'] = np.nan; scales['aa_2'] = np.nan

scales['aa_0'] = (scales['aa_ancelin'] == 0).astype(int) + (scales['aa_chew'] == 0).astype(int) + (scales['aa_cancelli'] == 0).astype(int) \
     + (scales['aa_han'] == 0).astype(int) + (scales['aa_rudolph'] == 0).astype(int) + (scales['aa_ehrt'] == 0).astype(int) + \
     (scales['aa_sittironnarit'] == 0).astype(int) + (scales['aa_boustani'] == 0).astype(int) + (scales['aa_carnahan'] == 0).astype(int) \
     + (scales['aa_kiesel_add_on'] == 0).astype(int) + (scales['aa_duran_add_on'] == 0).astype(int)

scales['aa_05'] = (scales['aa_ancelin'] == 0.5).astype(int) + (scales['aa_chew'] == 0.5).astype(int) + (scales['aa_cancelli'] == 0.5).astype(int) \
     + (scales['aa_han'] == 0.5).astype(int) + (scales['aa_rudolph'] == 0.5).astype(int) + (scales['aa_ehrt'] == 0.5).astype(int) + \
     (scales['aa_sittironnarit'] == 0.5).astype(int) + (scales['aa_boustani'] == 0.5).astype(int) + (scales['aa_carnahan'] == 0.5).astype(int) \
     + (scales['aa_kiesel_add_on'] == 0.5).astype(int) + (scales['aa_duran_add_on'] == 0.5).astype(int)

scales['aa_1'] = (scales['aa_ancelin'] == 1).astype(int) + (scales['aa_chew'] == 1).astype(int) + (scales['aa_cancelli'] == 1).astype(int) \
     + (scales['aa_han'] == 1).astype(int) + (scales['aa_rudolph'] == 1).astype(int) + (scales['aa_ehrt'] == 1).astype(int) + \
     (scales['aa_sittironnarit'] == 1).astype(int) + (scales['aa_boustani'] == 1).astype(int) + (scales['aa_carnahan'] == 1).astype(int) \
     + (scales['aa_kiesel_add_on'] == 1).astype(int) + (scales['aa_duran_add_on'] == 1).astype(int)

scales['aa_2'] = (scales['aa_ancelin'] == 2).astype(int) + (scales['aa_chew'] == 2).astype(int) + (scales['aa_cancelli'] == 2).astype(int) \
     + (scales['aa_han'] == 2).astype(int) + (scales['aa_rudolph'] == 2).astype(int) + (scales['aa_ehrt'] == 2).astype(int) + \
     (scales['aa_sittironnarit'] == 2).astype(int) + (scales['aa_boustani'] == 2).astype(int) + (scales['aa_carnahan'] == 2).astype(int) \
     + (scales['aa_kiesel_add_on'] == 2).astype(int) + (scales['aa_duran_add_on'] == 2).astype(int)

scales['aa_3'] = (scales['aa_ancelin'] == 3).astype(int) + (scales['aa_chew'] == 3).astype(int) + (scales['aa_cancelli'] == 3).astype(int) \
     + (scales['aa_han'] == 3).astype(int) + (scales['aa_rudolph'] == 3).astype(int) + (scales['aa_ehrt'] == 3).astype(int) + \
     (scales['aa_sittironnarit'] == 3).astype(int) + (scales['aa_boustani'] == 3).astype(int) + (scales['aa_carnahan'] == 3).astype(int) \
     + (scales['aa_kiesel_add_on'] == 2).astype(int) + (scales['aa_duran_add_on'] == 2).astype(int)

# create the meta-scale and compute it as the average of all other scales that included the drug in question
scales['aa_meta'] = np.nan
scales['aa_meta'] = (scales['aa_0']*0 + scales['aa_05']*0.5 + scales['aa_1']*1 + scales['aa_2']*2 + scales['aa_3']*3) \
    / (scales['aa_0'] + scales['aa_05'] + scales['aa_1'] + scales['aa_2'] + scales['aa_3'])

# add Duran's and Kiesel's scales to the end of the data frame
scales = pd.merge(scales, kiesel, on='drug', how='outer')
scales = pd.merge(scales, duran, on='drug', how='outer')

# remove drugs that were not scored higher than zero on any scale
scales = scales.fillna(0) # transform NaN to 0
scales = scales.loc[(scales['aa_05']!=0) | (scales['aa_1']!=0) | (scales['aa_2']!=0) | (scales['aa_3']!=0) | (scales['aa_kiesel']!=0) | \
                    (scales['aa_duran']!=0) | (scales['aa_meta']!=0)]

# export
meds = scales.to_csv('aas_combined.csv',index=False, header=True)
