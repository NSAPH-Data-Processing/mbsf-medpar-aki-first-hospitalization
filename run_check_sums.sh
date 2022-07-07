#!/bin/bash

# We assume running this from the script directory
job_directory=$PWD/.job

job_file="${job_directory}/job.job"

echo "#!/bin/bash
#SBATCH --job-name=job_sums.job
#SBATCH --output=.out/job_sums.out
#SBATCH --error=.out/job_sums.err
#SBATCH -c 10
#SBATCH --time=5-00:00
#SBATCH --mem=350GB
#SBATCH --qos=normal
#SBATCH -p serial_requeue 
#SBATCH --mail-type=END
#SBATCH --mail-user=anatrisovic@g.harvard.edu
module load python/3.8.5-fasrc01
python src/final_check.py" > $job_file 

# Run this job when final completes
sbatch --dependency=afterok:179059 $job_file

#--dependency=$(squeue --noheader --format %i --name first_hosp)  $job_file


