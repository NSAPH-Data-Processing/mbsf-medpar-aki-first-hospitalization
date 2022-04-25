import pandas as pd
import dask.dataframe as dd
from dask.dataframe import from_pandas
import numpy as np
import sys
import json


def get_outcomes():
    """ Get and return ICD codes """""
    f = open('src/icd_codes.json')
    outcomes_ = json.load(f)
    f.close()
    return json.loads(outcomes_[0])


def read_admissions(year):
    # read dataset
    admissions_path = "data/medpar/medpar_" + str(year) + ".csv"
    admissions_ = pd.read_csv(admissions_path)
    admissions_['ADATE'] = pd.to_datetime(admissions_['ADATE'], format='%d%b%Y')
    admissions_['DDATE'] = pd.to_datetime(admissions_['DDATE'], format='%d%b%Y')
    return from_pandas(admissions_, npartitions=8)


def primary(row, outcome=None):
    """ Get primary diagnosis from DIAG1 """
    if row["DIAG1"] in outcomes[outcome]["icd9"] and \
            row["DDATE"] < icd_date:
        return True 
    if row["DIAG1"] in outcomes[outcome]["icd10"] and \
            row["DDATE"] >= icd_date:
        return True
    return False


def primary_secondary(row, outcome=None, secondary=False):
    """ Get primary and secondary or secondary from DIAG1-10 """
    start_number = 1
    if secondary:
        # start from DIAG2 if secondary
        start_number = 2
    diags = ["DIAG" + str(num) for num in np.arange(
        start_number, 11)]

    for diag in diags:
        if row[diag] in outcomes[outcome]["icd9"] and \
                row["DDATE"] < icd_date:
            return True
        if row[diag] in outcomes[outcome]["icd10"] and \
                row["DDATE"] >= icd_date:
            return True
    return False 


outcomes = get_outcomes()
icd_date = pd.Timestamp(year=2015, month=10, day=1)


if __name__ == '__main__':
    arg = sys.argv[1]
    import datetime
    year_ = 2000 + int(arg)  
    print(datetime.datetime.now())
    print(year_)
        
    admissions = read_admissions(year_)

    for outcome in outcomes:
        admissions[outcome + "_primary"] = admissions.apply(
            primary, axis=1, outcome=outcome, meta=('bool')).compute()
        #admissions[outcome + "_primarysecondary"] = admissions.apply(
        #    primary_secondary, axis=1, outcome=outcome, meta=('int64')).compute()
        admissions[outcome + "_secondary"] = admissions.apply(
            primary_secondary, axis=1, outcome=outcome, secondary=True, meta=('bool')).compute()

    # drop rows that are not of interest
    of_interest_cols = [outcome + "_secondary" for outcome in outcomes]
    of_interest_cols = of_interest_cols + [outcome + "_primary" for outcome in outcomes]
    mask = admissions[of_interest_cols].any(axis=1)
    admissions = admissions[mask]
    
    # drop diag cols
    diag_cols = ["DIAG" + str(num) for num in range(1, 11)]
    admissions = admissions.drop(columns=diag_cols)
    print(datetime.datetime.now())

    admissions.to_csv("data/medpar_vars/medpar_n"+str(year_)+".csv", index=False, single_file=True)

