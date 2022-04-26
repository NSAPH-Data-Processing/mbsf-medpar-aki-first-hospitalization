import pandas as pd
import sys
from dask.dataframe import from_pandas

if __name__ == '__main__':
    arg = sys.argv[1]
    year = 2000 + int(arg)  
    df_enr = pd.read_csv("data/denom/denom_"+ str(year) +".csv")
    df_conf = pd.read_csv("data/confounders/merged_confounders_"+ str(year) +".csv")
    df_enr = from_pandas(df_enr, npartitions=5)
    df_conf = from_pandas(df_conf, npartitions=5)

    # rename column
    df_conf = df_conf.rename(columns={'ZIP': 'zip'})

    df_enr['sex']=df_enr['sex'].astype(int)
    df_enr['race']=df_enr['race'].astype(int)
    df_enr['dual']=df_enr['dual'].astype(int)
    df_enr['follow_up']=df_enr['follow_up'].astype(int)

    df = df_enr.merge(df_conf, how='left', on=['year', 'zip'])

    # reorder cols:
    cols = ["year", "zip", "race", "sex", "dual", "follow_up", "entry_age_group",
            "zcta", "poverty", "popdensity", "medianhousevalue", "pct_blk",
            "medhouseholdincome", "pct_owner_occ", "hispanic", "education", "population",
            "pct_asian", "pct_native", "pct_white", "smoke_rate", "mean_bmi", "pm25.current_year",
            "ozone.current_year", "no2.current_year", "ozone_summer.current_year", "pm25.one_year_lag",
            "ozone.one_year_lag", "no2.one_year_lag", "ozone_summer.one_year_lag", "ids"
            ]
    df = df[cols]

    df.to_csv("data/mbsf_conf/mbsf_conf"+str(year)+".csv", index=False, single_file=True)

