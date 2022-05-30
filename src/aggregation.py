import pandas as pd
import json

hospitalized = set()
year_included_in_hosp = 0


def reset_hospitalized():
    global hospitalized
    hospitalized.clear()
    global year_included_in_hosp
    year_included_in_hosp = 0


def denom(x, hosp=None):
    year = x['year']
    
    # if it's the first year, just count enrolled
    if year == 2000:
        return len(set(x['ids'].split(", ")))
    
    # get hosp in previous year
    year = year - 1
    global year_included_in_hosp
    if year != year_included_in_hosp:
        try:
            new_hospitalized = hosp.loc(axis=0)[year]
            # add to global set hospitalized:
            global hospitalized
            hospitalized.update(new_hospitalized)
            year_included_in_hosp = year
        except KeyError as ke:
            pass
        
    # get enrolled_ids
    enrolled_ids = x['ids'].split(", ")
    res = len(set(enrolled_ids) - hospitalized)
    return res


def get_outcomes(path=None):
    """ Get and return ICD codes """""
    f = open(path+'/icd_codes.json')
    outcomes_ = json.load(f)
    f.close()
    return json.loads(outcomes_[0])


if __name__ == '__main__':
    df = pd.read_csv("data/medpar_all/medpar.csv")
    df = df.drop(columns=['AGE', 'ADATE', 'DDATE'])
    df = df.rename(columns={'YEAR': 'year', 'SEX': 'sex', 'RACE': 'race', 'Dual': 'dual', 'ZIP': 'zip'})

    outcomes = get_outcomes(path='src')

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

    var_types = {'diabeteshosp_prior_aki':int, 'ckdhosp_prior_aki':int, 
             'diabeteshosp_prior_aki_denom':int, 'ckdhosp_prior_aki_denom':int}
    for d in co_morbidity:
        reset_hospitalized()
        hosp = df[df[d + '_primary_aki_secondary_first_hosp'] == True].groupby('year')['QID'].apply(list)
        mbsf[d + '_primary_aki_secondary_first_hosp_denom'] = \
            mbsf.apply(denom, hosp=hosp, axis=1)
        var_types[d + '_primary_aki_secondary_first_hosp']=int
        var_types[d + '_primary_aki_secondary_first_hosp_denom']=int

    reset_hospitalized()
    hosp = df[df['diabeteshosp_prior_aki'] == True].groupby('year')['QID'].apply(list)
    mbsf['diabeteshosp_prior_aki_denom'] = mbsf.apply(denom, hosp=hosp, axis=1)

    reset_hospitalized()
    hosp = df[df['ckdhosp_prior_aki'] == True].groupby('year')['QID'].apply(list)
    mbsf['ckdhosp_prior_aki_denom'] = mbsf.apply(denom, hosp=hosp, axis=1)
    
    mbsf = mbsf.drop(columns=["ids"])
    df = df.drop(columns=["QID"])

    # aggregate mbsf and medpar
    mbsf = mbsf.groupby(strata).first()
    df = df.groupby(strata).agg(agg_dict)
    df.columns = df.columns.droplevel(1)

    # merge on strata
    f = mbsf.join(df)
    f = f[var_types.keys()].fillna(0).astype(var_types).reset_index()
    f.to_csv("data/final.csv", index=False)


