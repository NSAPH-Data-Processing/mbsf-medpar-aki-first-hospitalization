""" 
Identifies diagnoses of interest and adds them as new variables. 
"""

import sys
import json
import pandas as pd
import numpy as np
from helpers import get_outcomes
import dask.dataframe as dd
from dask.dataframe import from_pandas


def read_admissions(year):
    """ Reads dataset """
    admissions_path = "data/medpar/medpar_" + str(year) + ".csv"
    cols = ['QID','ADATE','YEAR','DIAG1','DIAG2','DIAG3','DIAG4', \
            'DIAG5','DIAG6','DIAG7','DIAG8','DIAG9','DIAG10']
    df = pd.read_csv(admissions_path, usecols=cols)
    return from_pandas(df, npartitions=10)
    

def get_outcomes_set(outcome=None):
    if year < 2015:
        outcomes_set = outcomes[outcome]["icd9"]
    elif year > 2015:
        outcomes_set = outcomes[outcome]["icd10"]
    else:
        outcomes_set = outcomes[outcome]["icd10"] + \
            outcomes[outcome]["icd9"]
    return outcomes_set

        
def get_diags(df, outcome=None, diags=None):
    """ Get primary diagnosis from DIAG1 """
    outcomes_set = get_outcomes_set(outcome)
    return_col = pd.Series([False] * len(df))
    for col in diags:
        return_col = return_col | df[col].isin(outcomes_set)
    return return_col
    

outcomes = get_outcomes("src")
diags = ["DIAG" + str(num) for num in np.arange(1, 11)]
secondary_diags = ["DIAG" + str(num) for num in np.arange(2, 11)]

if __name__ == '__main__':
    arg = sys.argv[1]
    year = 2000 + int(arg)  
        
    admissions = read_admissions(year)
    
    for outcome in outcomes:
        admissions[outcome + "_primary"]=admissions.map_partitions(
            get_diags, outcome=outcome, diags=["DIAG1"], meta=(0,'bool'))
        admissions[outcome + "_secondary"]=admissions.map_partitions(
            get_diags, outcome=outcome,diags=secondary_diags, meta=(0,'bool'))

    admissions = admissions.compute()
        
    # drop rows that are not of interest
    of_interest_cols = [outcome + "_secondary" for outcome in outcomes]
    of_interest_cols = of_interest_cols + [outcome + "_primary" for outcome in outcomes]
    mask = admissions[of_interest_cols].any(axis=1)
    admissions = admissions[mask]
    
    # aki for testing
    admissions["aki_primary_secondary"] = admissions[
        ["aki_primary","aki_secondary"]].any(axis=1)
    
    # aki secondary co_morbidity primary
    co_morbidity = [
        "diabetes", "csd", "ihd", "pneumonia", "hf", "ami", "cerd", "uti"]
    for d in co_morbidity:
        # sets True iff d_primary and aki_secondary are True
        admissions[d + '_primary_aki_secondary'] = admissions[
            [d + "_primary", "aki_secondary"]].all(axis=1)
    
    # drop diag cols
    admissions = admissions.drop(columns=diags)
    OUTPATH = "data/medpar_vars/medpar_"+str(year)+"_sets.parquet"
    admissions.to_parquet(OUTPATH, index = False)

