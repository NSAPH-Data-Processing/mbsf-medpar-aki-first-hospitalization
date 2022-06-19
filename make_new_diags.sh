#!/bin/bash

# We assume running this from the script directory
job_directory=$PWD/.job


for i in {0..16}; do

    job_file="${job_directory}/job${i}.job"

    echo "#!/bin/bash
#SBATCH --job-name=make_diags
#SBATCH --output=.out/diag${i}.out
#SBATCH --error=.out/diag${i}.err
#SBATCH -c 4
#SBATCH --time=5-00:00
#SBATCH --mem=30GB
#SBATCH --qos=normal
#SBATCH -p serial_requeue 
#SBATCH --mail-type=END
#SBATCH --mail-user=anatrisovic@g.harvard.edu
module load python/3.8.5-fasrc01
pip install fastparquet
python src/add_diag_vars.py ${i}" > $job_file 
    sbatch $job_file  

done
