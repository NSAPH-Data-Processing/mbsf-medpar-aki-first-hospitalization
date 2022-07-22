#!/bin/bash

# We assume running this from the script directory
job_directory=$PWD/.job


job_file="${job_directory}/job.job"

echo "#!/bin/bash
#SBATCH --job-name=first_hosp
#SBATCH --output=.out/first_hosp.out
#SBATCH --error=.out/first_hosp.err
#SBATCH -c 30
#SBATCH --time=5-00:00
#SBATCH --mem=250GB
#SBATCH --qos=normal
#SBATCH -p serial_requeue 
#SBATCH --mail-type=END
#SBATCH --mail-user=anatrisovic@g.harvard.edu
module load python/3.8.5-fasrc01

python code/get_first_hosp.py" > $job_file 
sbatch --dependency=$(squeue --noheader --format %i --name make_diags) $job_file  
