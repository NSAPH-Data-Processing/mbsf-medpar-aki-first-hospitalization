#!/bin/bash

# We assume running this from the script directory
job_directory=$PWD/.job


for i in {0..16}; do

    job_file="${job_directory}/job${i}.job"

    echo "#!/bin/bash
#SBATCH --job-name=job_mbsf${i}.job
#SBATCH --output=.out/mbsf${i}.out
#SBATCH --error=.out/mbsf${i}.err
#SBATCH -c 4
#SBATCH --time=5-00:00
#SBATCH --mem=30GB
#SBATCH --qos=normal
#SBATCH -p serial_requeue 
#SBATCH --mail-type=END
#SBATCH --mail-user=anatrisovic@g.harvard.edu
module load R/4.0.5-fasrc01
Rscript src/new_mbsf_csv.R ${i}" > $job_file 
    sbatch $job_file  

done

