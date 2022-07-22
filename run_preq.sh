#!/bin/bash

# We assume running this from the script directory
job_directory=$PWD/.job


job_file="${job_directory}/preq.job"

echo "#!/bin/bash
#SBATCH --job-name=job_preq
#SBATCH --output=.out/preq_%a.out
#SBATCH --error=.out/preq_%a.err
#SBATCH -c 4
#SBATCH --time=5-00:00
#SBATCH --mem=30GB
#SBATCH --qos=normal
#SBATCH -p serial_requeue 
#SBATCH --mail-type=END
#SBATCH --mail-user=anatrisovic@g.harvard.edu

module load R/4.0.5-fasrc01

Rscript code/preq/medpar_to_csv.R \$SLURM_ARRAY_TASK_ID
Rscript code/preq/mbsf_to_csv.R \$SLURM_ARRAY_TASK_ID
Rscript code/preq/confounders_to_csv.R \$SLURM_ARRAY_TASK_ID

" > $job_file 

sbatch --array=0-16 $job_file  
