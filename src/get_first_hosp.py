import pandas as pd
import glob
import dask.dataframe as dd
from dask.dataframe import from_pandas
from dask.distributed import Client, LocalCluster, TimeoutError
import numpy as np
import json


def get_outcomes():
    """ Get and return ICD codes """""
    f = open('src/icd_codes.json')
    outcomes_ = json.load(f)
    f.close()
    return json.loads(outcomes_[0])


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


outcomes = get_outcomes()

if __name__ == '__main__':

    all_files = glob.glob('data/medpar_vars/medpar_n20*.csv')
    
    li = []
    
    for filename in all_files:
        df = pd.read_csv(filename, index_col=None, header=0)
        li.append(df)
    
    admissions = pd.concat(li, axis=0, ignore_index=True)
    #dd.read_csv('data/medpar_vars/medpar_a*.csv') #
    admissions['ADATE'] = pd.to_datetime(admissions['ADATE'])
    admissions_len = len(admissions)
    admissions = from_pandas(admissions, npartitions=30)

    first_hosp_dict = dict()

    # aki secondary else primary
    co_morbidity = ["diabetes", "csd", "ihd", "pneumonia", "hf", "ami", "cerd", "uti"]
    for d in co_morbidity:
        # sets True iff d_primary and aki_secondary are True
        admissions[d + '_primary_aki_secondary'] = admissions[
            [d + "_primary", "aki_secondary"]].all(axis=1).compute()


    # correct to get only first hospitalization
    for d in co_morbidity:
        # group by person QID, find index of min year
        ind_list = admissions[admissions[d + "_primary_aki_secondary"]].\
            groupby('QID')['ADATE'].idxmin().compute()
        first_hosp_dict[d + "_primary_aki_secondary_first_hosp"] = ind_list

    # look at diabetes and aki only
    helper_aki = admissions[admissions[
        ['aki_primary', 'aki_secondary', 'diabetes_primary', 'diabetes_secondary']].\
        any(axis=1)].groupby("QID").apply(is_aki_secondary, meta=('x', 'f8')).compute()
    first_hosp_dict['diabeteshosp_prior_aki'] = helper_aki.dropna()
    # look at ckd and aki
    helper_aki = admissions[admissions[
        ['aki_primary', 'aki_secondary', 'ckd_primary', 'ckd_secondary']]. \
        any(axis=1)].groupby("QID").apply(is_aki_secondary, meta=('x', 'f8')).compute()
    first_hosp_dict['ckdhosp_prior_aki'] = helper_aki.dropna()

    # add primary and secondary so that only the first diag counts
    for outcome in outcomes:
        ind_list = admissions[admissions[outcome + "_primary"]].\
            groupby('QID')['ADATE'].idxmin().compute()
        first_hosp_dict[outcome + "_primary_first_hosp"] = ind_list
        ind_list = admissions[admissions[outcome + "_secondary"]]. \
            groupby('QID')['ADATE'].idxmin().compute()
        first_hosp_dict[outcome + "_secondary_first_hosp"] = ind_list

    for col_name in first_hosp_dict:
        # empty temporary list
        temp = pd.Series([False] * admissions_len)
        # set True where at indexes
        temp[first_hosp_dict[col_name]] = True
        # append to df
        admissions[col_name] = temp

    admissions.to_csv("data/medpar_all/medpar.csv", index=False, single_file=True)

