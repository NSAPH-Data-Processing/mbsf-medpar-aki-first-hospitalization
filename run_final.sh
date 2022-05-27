#!/bin/bash

# We assume running this from the script directory
job_directory=$PWD/.job


for i in {0..0}; do

    job_file="${job_directory}/job${i}.job"

    echo "#!/bin/bash
#SBATCH --job-name=job${i}.job
#SBATCH --output=.out/${i}fin.out
#SBATCH --error=.out/${i}fin.err
#SBATCH -c 10
#SBATCH --time=5-00:00
#SBATCH --mem=350GB
#SBATCH --qos=normal
#SBATCH -p serial_requeue 
#SBATCH --mail-type=END
#SBATCH --mail-user=anatrisovic@g.harvard.edu
module load python/3.8.5-fasrc01
python src/aggregation.py" > $job_file 
    sbatch $job_file  


done

