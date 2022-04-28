import pandas as pd
import json

hospitalized = set()
hosp = pd.DataFrame()


def denom(x):
    group = (
        x['year'], x['sex'], x.race,
        x['zip'], x.dual, x.follow_up,
        x.entry_age_group
    )
    try:
        # check if anyone is hosp in group
        new_hospitalized = hosp.loc(axis=0)[group]
        # add to global set hospitalized:
        global hospitalized
        hospitalized.update(new_hospitalized)
    except KeyError as ke:
        pass
    # get enrolled_ids
    enrolled_ids = x['ids'].split(", ")
    res = len(set(enrolled_ids) - hospitalized)
    return res


def get_outcomes():
    """ Get and return ICD codes """""
    f = open('src/icd_codes.json')
    outcomes_ = json.load(f)
    f.close()
    return json.loads(outcomes_[0])


if __name__ == '__main__':
    df = pd.read_csv("data/medpar_all/medpar.csv")
    df = df.drop(columns=['AGE', 'ADATE', 'DDATE'])
    df = df.rename(columns={'YEAR': 'year', 'SEX': 'sex', 'RACE': 'race', 'Dual': 'dual', 'ZIP': 'zip'})

    outcomes = get_outcomes()

    # aggregation definitions per variable
    agg_dict = {}
    for outcome in outcomes:
        df = df.drop(columns=[outcome + "_primary", outcome + "_secondary"])
        agg_dict[outcome + "_primary_first_hosp"] = ["sum"]
        agg_dict[outcome + "_secondary_first_hosp"] = ["sum"]

    co_morbidity = ["diabetes", "csd", "ihd", "pneumonia", "hf", "ami", "cerd", "uti"]
    for d in co_morbidity:
        # reset the hosp set
        df = df.drop(columns=[d + "_primary_aki_secondary"])
        agg_dict[d + '_primary_aki_secondary_first_hosp'] = ['sum']

    agg_dict['diabeteshosp_prior_aki'] = ['sum']
    agg_dict['ckdhosp_prior_aki'] = ['sum']

    strata = ['year', 'sex', 'race', 'zip', 'dual', 'follow_up', 'entry_age_group']

    # read MBSF
    li = []
    for year in range(2000, 2017):
        filename = "data/mbsf_conf/mbsf_conf" + str(year) + ".csv"
        mbsf_ = pd.read_csv(filename, index_col=None, header=0)
        li.append(mbsf_)

    mbsf = pd.concat(li, axis=0, ignore_index=True)

    for d in co_morbidity:
        hospitalized = set()
        hosp = df[df[d + '_primary_aki_secondary_first_hosp']].groupby(strata)['QID'].apply(list)
        mbsf[d + '_primary_aki_secondary_first_hosp_denom'] = \
            mbsf.apply(denom, axis=1)

    hospitalized = set()
    hosp = df[df['diabeteshosp_prior_aki']].groupby(strata)['QID'].apply(list)
    mbsf['diabeteshosp_prior_aki_denom'] = mbsf.apply(denom, axis=1)
    hospitalized = set()
    hosp = df[df['diabeteshosp_prior_aki']].groupby(strata)['QID'].apply(list)
    mbsf['diabeteshosp_prior_aki_denom'] = mbsf.apply(denom, axis=1)

    mbsf = mbsf.drop(columns=["ids"])
    df = df.drop(columns=["QID"])

    # aggregate mbsf and medpar
    mbsf = mbsf.groupby(strata).first()
    df = df.groupby(strata).agg(agg_dict)
    df.columns = df.columns.droplevel(1)

    # merge on strata
    f = mbsf.join(df)
    f.reset_index().to_csv("data/final.csv")


