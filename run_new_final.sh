#!/bin/bash

# We assume running this from the script directory
job_directory=$PWD/.job

job_file="${job_directory}/job.job"

echo "#!/bin/bash
#SBATCH --job-name=job_new_fin.job
#SBATCH --output=.out/new_fin.out
#SBATCH --error=.out/new_fin.err
#SBATCH -c 10
#SBATCH --time=5-00:00
#SBATCH --mem=350GB
#SBATCH --qos=normal
#SBATCH -p serial_requeue 
#SBATCH --mail-type=END
#SBATCH --mail-user=anatrisovic@g.harvard.edu
module load python/3.8.5-fasrc01
pip install fastparquet
python src/new_aggregation.py" > $job_file 

# Run this job when first_hosp completes
sbatch --dependency=$(squeue --noheader --format %i --name first_hosp)  $job_file

