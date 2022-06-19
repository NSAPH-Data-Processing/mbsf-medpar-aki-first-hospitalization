""" Calculates denominators and does the final merge. """

import json
import pandas as pd

co_morbidity = ["diabetes", "csd", "ihd", "pneumonia", "hf", "ami", "cerd", "uti"]
strata = ['year', 'sex', 'race', 'zip', 'dual', 'follow_up', 'entry_age_group']

def get_outcomes(path=None):
    """ Get and return ICD codes """""
    f = open(path+'/icd_codes.json')
    outcomes_ = json.load(f)
    f.close()
    return json.loads(outcomes_[0])

def set_aggregations():
    """ Sets funcs for final aggregation. """
    agg_dict = {}
    global df
    for outcome in outcomes:
        agg_dict[outcome + "_primary_first_hosp"] = ["sum"]
        agg_dict[outcome + "_secondary_first_hosp"] = ["sum"]

    var_types = {'diabeteshosp_prior_aki':int, 'ckdhosp_prior_aki':int,
         'diabeteshosp_prior_aki_denom':int, 'ckdhosp_prior_aki_denom':int,
         'aki_primary_secondary_denom':int, 'aki_primary_secondary_first_hosp':int}
    
    for d in co_morbidity:
        df = df.drop(columns=[d + "_primary_aki_secondary"])
        agg_dict[d + '_primary_aki_secondary_first_hosp'] = ['sum']
        var_types[d + '_primary_aki_secondary_first_hosp']=int
        var_types[d + '_primary_aki_secondary_first_hosp_denom']=int

    agg_dict['diabeteshosp_prior_aki'] = ['sum']
    agg_dict['ckdhosp_prior_aki'] = ['sum']
    agg_dict['aki_primary_secondary'] = ['sum']
    agg_dict['aki_primary_secondary_first_hosp'] = ['sum']
    return agg_dict, var_types

def counts(x):
    """ Counts the number of enrolled per strata. """
    return len(set(x['ids'].split(", ")))

def add_denominator(name, hosp):
    """ Calculates and merges denominator. """""
    li = []
    global mbsf
    for year in range(2001, 2017):
        tdf = mbsf_dict[year]
        # get hospitalized in prior years
        for y in range(2000, year):
            try:
                hosp_in_y = hosp[y]
                # filter out if hospitalized in prior years
                tdf = tdf[~tdf.qid.isin(hosp_in_y)]
            except KeyError:
                pass
        li.append(tdf.groupby(strata).size().to_frame(name))

    denom = pd.concat(li, axis=0)
    # joins denominator to the main MBSF
    mbsf = mbsf.join(denom)


outcomes = get_outcomes(path='src')

# read medPar
df = pd.read_parquet("data/medpar_all/medpar.parquet")
df = df.rename(columns={'YEAR': 'year', 'SEX': 'sex', 'RACE': 'race', 'Dual': 'dual', 'ZIP': 'zip'})

# read stratified MBSF
li = []
for year in range(2000, 2017):
    file_name = "data/mbsf_conf/mbsf_conf" + str(year) + ".csv"
    mbsf_ = pd.read_csv(file_name, index_col=None, header=0)
    li.append(mbsf_)
mbsf = pd.concat(li, axis=0, ignore_index=True)
mbsf['total'] = mbsf.apply(counts, axis=1)

# MBSF here is already groupped so this will just create the index
mbsf = mbsf.groupby(strata).first()
mbsf = mbsf.drop(columns=["ids"])

# read individual MBSF
mbsf_dict = {}
for year in range(2001, 2017):
    filename = "data/denom/qid_denom_" + str(year) + ".csv"
    mbsf_dict[year] = pd.read_csv(filename, index_col=None)

# calculate denominators
for d in co_morbidity:
    add_denominator(
        name=d+'_primary_aki_secondary_first_hosp_denom',
        hosp=df[df[d + '_primary_aki_secondary_first_hosp']]
        .groupby('year')['QID'].apply(list).to_dict()
    )

# calculate denominators for diabetes and ckd
add_denominator(
    name='diabeteshosp_prior_aki_denom',
    hosp=df[df['diabeteshosp_prior_aki']]
    .groupby('year')['QID'].apply(list).to_dict()
)
add_denominator(
    name='ckdhosp_prior_aki_denom',
    hosp=df[df['ckdhosp_prior_aki']]
    .groupby('year')['QID'].apply(list).to_dict()
)

# denom for AKI for testing
add_denominator(
    name='aki_primary_secondary_denom',
    hosp=df[df['aki_primary_secondary_first_hosp']]
    .groupby('year')['QID'].apply(list).to_dict()
)

# aggregate mbsf and medpar
agg_dict, var_types = set_aggregations()
df = df.drop(columns=["QID"])
df = df.groupby(strata).agg(agg_dict)
df.columns = df.columns.droplevel(1)

# merge on strata
f = mbsf.join(df)

cols = list(var_types.keys())
f[cols] = f[cols].fillna(0).astype(var_types)
f = f.reset_index()

f.to_csv("data/final_no_dask.csv", index=False)

