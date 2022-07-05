""" Finds first diagnosis for all diagnoses of interest. """

import pandas as pd
import numpy as np
from helpers import get_outcomes


def is_aki_secondary(df):
    """ if aki_primarysecondary is first diag then return 0;
    if it's not, the outcome is first, hence return index """
    if len(df) < 1:
        return np.nan
    df_ = df[df['ADATE'] == df['ADATE'].min()].iloc[0]
    min_ind = df['ADATE'].idxmin()
    if df_['aki_primary'] or df_['aki_secondary']:
        return np.nan
    return min_ind


outcomes = get_outcomes("src")
co_morbidity = ["diabetes", "csd", "ihd", "pneumonia", "hf", "ami", "cerd", "uti"]

if __name__ == '__main__':
    li = []
    for year in range(2000, 2017):
        filename = "data/medpar_vars/medpar_" + str(year) + "_sets.parquet"
        df = pd.read_parquet(filename)
        li.append(df)

    admissions = pd.concat(li, axis=0, ignore_index=True)
    admissions['ADATE'] = pd.to_datetime(admissions['ADATE'])
    admissions_len = len(admissions)

    first_hosp_dict = dict()

    # get first hospitalization
    for d in co_morbidity:
        # group by person QID, find index of min admission date
        ind_list = admissions[admissions[d + "_primary_aki_secondary"]].\
            groupby('QID')['ADATE'].idxmin()
        first_hosp_dict[d + "_primary_aki_secondary_first_hosp"] = ind_list

    # aki for testing
    ind_list = admissions[admissions['aki_primary_secondary']].\
        groupby('QID')['ADATE'].idxmin()
    first_hosp_dict["aki_primary_secondary_first_hosp"] = ind_list
    
    # look at diabetes and aki only
    helper_aki = admissions[admissions[
        ['aki_primary', 'aki_secondary', 'diabetes_primary', 'diabetes_secondary']].\
        any(axis=1)].groupby("QID").apply(is_aki_secondary)
    first_hosp_dict['diabeteshosp_prior_aki'] = helper_aki.dropna()

    # look at ckd and aki
    helper_aki = admissions[admissions[
        ['aki_primary', 'aki_secondary', 'ckd_primary', 'ckd_secondary']]. \
        any(axis=1)].groupby("QID").apply(is_aki_secondary)
    first_hosp_dict['ckdhosp_prior_aki'] = helper_aki.dropna()

    # get first hosp for primary and secondary diags for outcome 
    for outcome in outcomes:
        ind_list = admissions[admissions[outcome + "_primary"]].\
            groupby('QID')['ADATE'].idxmin()
        first_hosp_dict[outcome + "_primary_first_hosp"] = ind_list
        ind_list = admissions[admissions[outcome + "_secondary"]]. \
            groupby('QID')['ADATE'].idxmin()
        first_hosp_dict[outcome + "_secondary_first_hosp"] = ind_list

    # delete columns that are no longer needed
    for outcome in outcomes:
        admissions = admissions.drop(columns=[outcome + "_primary", outcome + "_secondary"])

    for col_name in first_hosp_dict:
        # empty temporary list
        temp = pd.Series([False] * admissions_len)
        # set True where at indexes
        temp[first_hosp_dict[col_name]] = True
        # append to df
        admissions[col_name] = temp
        
    admissions.to_parquet('data/medpar_all/medpar_sets.parquet', index=False)
