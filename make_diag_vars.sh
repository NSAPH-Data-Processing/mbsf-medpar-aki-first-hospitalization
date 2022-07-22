#!/bin/bash

# We assume running this from the script directory
job_directory=$PWD/.job

job_file="${job_directory}/make_diags.job"

echo "#!/bin/bash
#SBATCH --job-name=make_diags
#SBATCH -c 4 
#SBATCH -p serial_requeue 
#SBATCH --mem=10GB
#SBATCH --time=1-00:00
#SBATCH --output=.out/diag_%a.out
#SBATCH --error=.out/diag_%a.err
#SBATCH --qos=normal

#SBATCH --mail-type=END
#SBATCH --mail-user=anatrisovic@g.harvard.edu

module load python/3.8.5-fasrc01

python code/add_diag_vars.py \${SLURM_ARRAY_TASK_ID}" > $job_file 
    
sbatch --array=0-16 --dependency=$(squeue --noheader --format %i --name job_preq) $job_file  

