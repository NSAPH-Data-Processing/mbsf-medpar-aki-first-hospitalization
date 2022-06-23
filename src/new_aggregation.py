""" Calculates denominators and does the final merge. """

import pandas as pd
from helpers import get_outcomes

strata = ['year', 'sex', 'race', 'zip', 'dual', 'follow_up', 'entry_age_group']
co_morbidity = ["diabetes", "csd", "ihd", "pneumonia", "hf", "ami", "cerd", "uti"]


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


def add_denominator(name, hosp):
    """ Calculates and merges denominator. """""
    li = []
    global mbsf
    for year in range(2001, 2017):
        tdf = mbsf_dict[year]
        # get hospitalized in prior years
        for y in range(2000, year):
            try:
                hosp_in_year = hosp[y]
                # filter out if hospitalized in prior years
                tdf = tdf[~tdf['qid'].isin(hosp_in_year)]
            except KeyError:
                pass
        li.append(tdf.groupby(["year", "qid"]).size().to_frame(name))

    denom = pd.concat(li, axis=0)
    mbsf = mbsf.join(denom)


outcomes = get_outcomes(path='src')

# read medPar
df = pd.read_parquet("data/medpar_all/medpar_sets.parquet")
df = df.drop(columns=['SEX', 'RACE', 'ADATE', 'ZIP', 'Dual',
       'follow_up', 'entry_age_group'])
df = df.rename(columns={'YEAR': 'year'})

# read MBSF
mbsf_dict = {}
li = []

for year in range(2001, 2017):
    filename = "data/denom/qid_denom_" + str(year) + ".csv"
    mbsf_dict[year] = pd.read_csv(filename, index_col=None)
    li.append(mbsf_dict[year])
    
mbsf = pd.concat(li, axis=0, ignore_index=True)
mbsf = mbsf.groupby(["year", "qid"]).first()
    
    
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


df = df.rename(columns={'QID': 'qid'})
df = df.groupby(["year", "qid"]).sum()

f = mbsf.join(df)
cols = list(var_types.keys())
f[cols] = f[cols].fillna(0).astype(var_types)
f = f.reset_index()

f = f.drop(columns=["qid"])
f = f.groupby(strata).agg(agg_dict)
f.columns = f.columns.droplevel(1)
f = f.reset_index()

f.to_csv("data/final.csv", index=False)

