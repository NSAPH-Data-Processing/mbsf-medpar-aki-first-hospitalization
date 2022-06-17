#!/bin/bash

# We assume running this from the script directory
job_directory=$PWD/.job


job_file="${job_directory}/job${i}.job"

echo "#!/bin/bash
#SBATCH --job-name=job${i}.job
#SBATCH --output=.out/${i}first_hosp.out
#SBATCH --error=.out/${i}first_hosp.err
#SBATCH -c 30
#SBATCH --time=5-00:00
#SBATCH --mem=200GB
#SBATCH --qos=normal
#SBATCH -p serial_requeue 
module load python/3.8.5-fasrc01
python src/get_first_hosp.py" > $job_file 
sbatch $job_file  


