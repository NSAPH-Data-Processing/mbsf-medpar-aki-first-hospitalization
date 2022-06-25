import pandas as pd
import numpy as np
import sys
import json

def get_fin_vars():
    co_morbidity = ["diabetes", "csd", "ihd", "pneumonia", \
                    "hf", "ami", "cerd", "uti"]
    fin_vars_loc = [ 'aki_primary_secondary_first_hosp', \
            'ckdhosp_prior_aki', 'diabeteshosp_prior_aki']
    for mvar in co_morbidity:
        name = mvar + '_primary_aki_secondary_first_hosp'
        fin_vars_loc.append(name)
    return fin_vars_loc

df = pd.read_csv("data/final.csv")

grouped = df.groupby('year').sum()
totals = df.sum()

fin_vars = get_fin_vars()

f = open('final_sums.txt', 'a+')
for fin_var in fin_vars:
    fin_var_denom = fin_var + '_denom'
    f.write("\n== Per year ==\n")
    f.write(str(grouped[[fin_var, fin_var_denom]]))
    f.write("\n== Total ==\n")
    f.write(str(totals[[fin_var, fin_var_denom]]))
f.close()