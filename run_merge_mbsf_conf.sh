#!/bin/bash

job_directory=$PWD/.job


for i in {0..16}; do

    job_file="${job_directory}/job${i}.job"

    echo "#!/bin/bash
#SBATCH --job-name=job${i}n.job
#SBATCH --output=.out/${i}n_.out
#SBATCH --error=.out/${i}n_.err
#SBATCH -p serial_requeue 
#SBATCH -n 10
#SBATCH --time=3-00:00
#SBATCH --mem-per-cpu=5GB
#SBATCH --qos=normal
module load python/3.8.5-fasrc01
python src/mbsf_confounders_merge.py ${i}" > $job_file 
    sbatch $job_file  

done

