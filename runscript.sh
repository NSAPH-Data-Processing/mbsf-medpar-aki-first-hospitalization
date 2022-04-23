#!/bin/bash

# We assume running this from the script directory
job_directory=$PWD/.job


for i in {0..16}; do

    job_file="${job_directory}/job${i}.job"

    echo "#!/bin/bash
#SBATCH --job-name=job${i}.job
#SBATCH --output=.out/${i}_.out
#SBATCH --error=.out/${i}_.err
#SBATCH -c 8 
#SBATCH --time=3-00:00
#SBATCH --mem=22000
#SBATCH --qos=normal
#SBATCH -p serial_requeue 
module load python/3.8.5-fasrc01
python src/add_diag_vars.py ${i}" > $job_file 
    sbatch $job_file  


done

### 
### #SBATCH -c 8                # Number of cores (-c)
### #SBATCH --ntasks=8 
### #SBATCH -t 0-05:00          # Runtime in D-HH:MM, minimum of 10 minutes
### #SBATCH -p serial_requeue   # Partition to submit to
### #SBATCH --mem=20000 # Memory pool for all cores (see also --mem-per-cpu)
### #SBATCH -o myoutput_%j.out  # File to which STDOUT will be written, %j inserts jobid
### #SBATCH -e myerrors_%j.err  # File to which STDERR will be written, %j inserts jobid
### module load python/3.8.5-fasrc01
