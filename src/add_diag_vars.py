""" 
Identifies diagnoses of interest and adds them as new variables. 
"""

import sys
import json
import pandas as pd
import numpy as np


def get_outcomes():
    """ Get and return ICD codes """""
    file = open('src/icd_codes.json')
    outcomes_ = json.load(file)
    file.close()
    return json.loads(outcomes_[0])


def read_admissions(year):
    """ Reads dataset """
    admissions_path = "data/medpar/medpar_" + str(year) + ".csv"
    admissions_ = pd.read_csv(admissions_path)
    admissions_['ADATE'] = pd.to_datetime(admissions_['ADATE'], format='%d%b%Y')
    admissions_['DDATE'] = pd.to_datetime(admissions_['DDATE'], format='%d%b%Y')
    return admissions_


def primary(row, outcome=None):
    """ Get primary diagnosis from DIAG1 """
    if row["DDATE"] < icd_date and \
        row["DIAG1"] in outcomes[outcome]["icd9"]:
        return True 
    if row["DDATE"] >= icd_date and \
        row["DIAG1"] in outcomes[outcome]["icd10"]:
        return True
    return False


def secondary(row, outcome=None):
    """ Check secondary diags - from DIAG2-10 """
    for diag in secondary_diags:
        if row["DDATE"] < icd_date and \
            row[diag] in outcomes[outcome]["icd9"]:
            return True
        if row["DDATE"] >= icd_date and \
            row[diag] in outcomes[outcome]["icd10"]:
            return True
    return False 


def primary_secondary(row, outcome=None):
    """ Check all diags - from DIAG1-10 """
    for diag in diags:
        if row["DDATE"] < icd_date and \
            row[diag] in outcomes[outcome]["icd9"]:
            return True
        if row["DDATE"] >= icd_date and \
            row[diag] in outcomes[outcome]["icd10"]:
            return True
    return False 


outcomes = get_outcomes()
icd_date = pd.Timestamp(year=2015, month=10, day=1)
diags = ["DIAG" + str(num) for num in np.arange(1, 11)]
secondary_diags = ["DIAG" + str(num) for num in np.arange(2, 11)]


if __name__ == '__main__':
    arg = sys.argv[1]
    year_ = 2000 + int(arg)  
        
    admissions = read_admissions(year_)

    for outcome in outcomes:
        admissions[outcome + "_primary"] = admissions.apply(
            primary, axis=1, outcome=outcome)
        admissions[outcome + "_secondary"] = admissions.apply(
            secondary, axis=1, outcome=outcome)
    
    # AKI primary secondary for testing
    admissions["aki_primary_secondary"] = admissions.apply(
        primary_secondary, axis=1, outcome="aki")
    
    # aki secondary co_morbidity primary
    co_morbidity = ["diabetes", "csd", "ihd", "pneumonia", "hf", "ami", "cerd", "uti"]
    for d in co_morbidity:
        # sets True iff d_primary and aki_secondary are True
        admissions[d + '_primary_aki_secondary'] = admissions[
            [d + "_primary", "aki_secondary"]].all(axis=1)
    
    # drop rows that are not of interest
    # of_interest_cols = [outcome + "_secondary" for outcome in outcomes]
    # of_interest_cols = of_interest_cols + [outcome + "_primary" for outcome in outcomes]
    # mask = admissions[of_interest_cols].any(axis=1)
    # admissions = admissions[mask]
    
    # drop diag cols
    admissions = admissions.drop(columns=diags)
    admissions = admissions.drop(columns=['AGE', 'DDATE'])
    OUTPATH = "data/medpar_vars/medpar_"+str(year_)+".parquet"
    #admissions.to_csv(OUTPATH, index = False)
    admissions.to_parquet(OUTPATH, index = False)
