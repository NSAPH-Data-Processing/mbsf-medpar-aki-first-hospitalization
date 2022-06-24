""" Calculates denominators and does the final merge. """

import pandas as pd
from helpers import get_outcomes


def add_denominator(name, hosp):
    """ Calculates and merges denominator. """""
    global mbsf
    mbsf[name] = True
    for year in range(2001, 2017):
        # remove hospitalized in prior years
        for y in range(2000, year):
            try:
                mbsf[name] = ~(mbsf['qid'].isin(hosp[y]) & \
                    (mbsf['year']==year)) & \
                    mbsf[name]
            except KeyError:
                pass


def get_fin_vars():
    co_morbidity = ["diabetes", "csd", "ihd", "pneumonia", \
                    "hf", "ami", "cerd", "uti"]
    fin_vars_loc = [ 'aki_primary_secondary_first_hosp', \
            'ckdhosp_prior_aki', 'diabeteshosp_prior_aki']
    for mvar in co_morbidity:
        name = mvar + '_primary_aki_secondary_first_hosp'
        fin_vars_loc.append(name)
    return fin_vars_loc


if __name__ == '__main__':
    
    fin_vars = get_fin_vars()
    outcomes = get_outcomes(path='src')
    strata = ['year', 'sex', 'race', 'zip', 'dual', 'follow_up', 'entry_age_group']
    

    # read medPar
    df = pd.read_parquet("data/medpar_all/medpar_sets.parquet")
    df = df[['QID', 'YEAR'] + fin_vars]
    df = df.rename(columns={'YEAR': 'year', 'QID': 'qid'})

    
    # read MBSF
    li = []
    for year in range(2000, 2017):
        filename = "data/denom/qid_denom_" + str(year) + ".csv"
        mbsf_loc = pd.read_csv(filename)
        li.append(mbsf_loc)
        
    mbsf = pd.concat(li, axis=0, ignore_index=True)
    mbsf = mbsf.drop(mbsf.columns[0], axis=1)


    # calculate denominators
    for fin_var in fin_vars:
        add_denominator(
            name=fin_var + '_denom',
            hosp=df[df[fin_var]]
            .groupby('year')['qid'].apply(list).to_dict()
        )
        
    # set types and aggregations
    agg_dict = {}
    var_types = {}
    for fin_var in fin_vars:
        agg_dict[fin_var] = ['sum']
        agg_dict[fin_var + '_denom'] = ['sum']
        var_types[fin_var] = int
        var_types[fin_var + '_denom'] = int

    
    df = df.groupby(["year", "qid"]).sum()
    mbsf = mbsf.join(df, on=["year", "qid"])
    mbsf = mbsf.drop(columns=["qid"])
    mbsf = mbsf.groupby(strata).agg(agg_dict)

    mbsf.columns = mbsf.columns.droplevel(1)
    cols = list(var_types.keys())
    mbsf[cols] = mbsf[cols].fillna(0).astype(var_types)

    li = []
    for year in range(2000, 2017):
        confounders_path = "data/confounders/merged_confounders_"+ str(year) +".csv"
        confounders = pd.read_csv(confounders_path)
        li.append(confounders)
        
    confounders = pd.concat(li, axis=0, ignore_index=True)
    confounders = confounders.drop(confounders.columns[0], axis=1)
    confounders = confounders.rename(columns={'ZIP': 'zip'})
    confounders = confounders.set_index(['year','zip'])
    
    mbsf = mbsf.join(confounders, on=['year', 'zip'])

    mbsf.to_csv("data/final.csv") 
