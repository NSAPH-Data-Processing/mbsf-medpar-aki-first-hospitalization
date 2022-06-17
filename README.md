
# Code workflow 

Generate ICD and retrieve relevant data:

```
get_icd.R
confounders_to_csv.R
mbsf_to_csv.R
medpar_to_csv.R
```

Get primary and secondary diagnosis:
```
add_diag_vars.py
```

Get first hospitalizations:
```
get_first_hosp.py
mbsf_confounders_merge.py
```

Final aggregation:

```
final_aggregation.py        
```

# Output dataset dictionary 

| Column_name        | Source               | Description                                                           |
|--------------------|----------------------|-----------------------------------------------------------------------|
| year               | MBSF                 | Year of enrollment.                                                   |
| sex                | MBSF                 | Beneficiary sex.                                                      |
| race               | MBSF                 | Beneficiary race.                                                     |
| zip                | MBSF                 | ZIP code                                                              |
| dual               | MBSF                 | Should be only 1.                                                     |
| follow_up          | Computed from MBSF   | Follow-up year.                                                       |
| entry_age_group    | Computed from MBSF   | Entry age group.                                                      |
| zcta               | Census               | Annual value.                                                         |
| poverty            | Census               | Annual value.                                                         |
| popdensity         | Census               | Annual value.                                                         |
| medianhousevalue   | Census               | Annual value.                                                         |
| pct_blk            | Census               | Annual value.                                                         |
| medhouseholdincome | Census               | Annual value.                                                         |
| pct_owner_occ      | Census               | Annual value.                                                         |
| hispanic           | Census               | Annual value.                                                         |
| education          | Census               | Annual value.                                                         |
| population         | Census               | Annual value.                                                         |
| pct_asian          | Census               | Annual value.                                                         |
| pct_native         | Census               | Annual value.                                                         |
| pct_white          | Census               | Annual value.                                                         |
| smoke_rate         | BRFSS                |                                                                       |
| mean_bmi           | BRFSS                |                                                                       |
| pm25.current_year  | Exposure             | |
| ozone.current_year | Exposure             | |
| no2.current_year   | Exposure             | |
| ozone_summer.current_year | Exposure      | |
| pm25.one_year_lag  | Exposure             | |
| ozone.one_year_lag | Exposure             | |
| no2.one_year_lag   | Exposure             | |
| ozone_summer.one_year_lag | Exposure      | |
| diabetes_primary_aki_secondary_first_hosp_denom | Computed from MedPar | |
| csd_primary_aki_secondary_first_hosp_denom | Computed from MedPar | |
| ihd_primary_aki_secondary_first_hosp_denom | Computed from MedPar | |
| pneumonia_primary_aki_secondary_first_hosp_denom | Computed from MedPar | |
| hf_primary_aki_secondary_first_hosp_denom | Computed from MedPar | |
| ami_primary_aki_secondary_first_hosp_denom | Computed from MedPar | |
| cerd_primary_aki_secondary_first_hosp_denom | Computed from MedPar | |
| uti_primary_aki_secondary_first_hosp_denom | Computed from MedPar | |
| diabeteshosp_prior_aki_denom | Computed from MedPar | |
| ckdhosp_prior_aki_denom | Computed from MedPar | |
| all_kidney_primary_first_hosp | Computed from MedPar | |
| all_kidney_secondary_first_hosp | Computed from MedPar | |
| ckd_primary_first_hosp | Computed from MedPar | |
| ckd_secondary_first_hosp | Computed from MedPar | |
| aki_primary_first_hosp | Computed from MedPar | |
| aki_secondary_first_hosp | Computed from MedPar | |
| glomerular_primary_first_hosp | Computed from MedPar | |
| glomerular_secondary_first_hosp | Computed from MedPar | |
| diabetes_primary_first_hosp | Computed from MedPar | |
| diabetes_secondary_first_hosp | Computed from MedPar | |
| csd_primary_first_hosp | Computed from MedPar | |
| csd_secondary_first_hosp | Computed from MedPar | |
| ihd_primary_first_hosp | Computed from MedPar | |
| ihd_secondary_first_hosp | Computed from MedPar | |
| pneumonia_primary_first_hosp | Computed from MedPar | |
| pneumonia_secondary_first_hosp | Computed from MedPar | |
| hf_primary_first_hosp | Computed from MedPar | |
| hf_secondary_first_hosp | Computed from MedPar | |
| ami_primary_first_hosp | Computed from MedPar | |
| ami_secondary_first_hosp | Computed from MedPar | |
| cerd_primary_first_hosp | Computed from MedPar | |
| cerd_secondary_first_hosp | Computed from MedPar | |
| uti_primary_first_hosp | Computed from MedPar | |
| uti_secondary_first_hosp | Computed from MedPar | |
| diabetes_primary_aki_secondary_first_hosp | Computed from MedPar | |
| csd_primary_aki_secondary_first_hosp | Computed from MedPar | |
| ihd_primary_aki_secondary_first_hosp | Computed from MedPar | |
| pneumonia_primary_aki_secondary_first_hosp | Computed from MedPar | |
| hf_primary_aki_secondary_first_hosp | Computed from MedPar | |
| ami_primary_aki_secondary_first_hosp | Computed from MedPar | |
| cerd_primary_aki_secondary_first_hosp | Computed from MedPar | |
| uti_primary_aki_secondary_first_hosp | Computed from MedPar | |
| diabeteshosp_prior_aki | Computed from MedPar | |
| ckdhosp_prior_aki | Computed from MedPar | |

