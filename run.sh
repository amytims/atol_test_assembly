#!/bin/bash

#SBATCH --job-name=atol_test
#SBATCH --time=2-00
#SBATCH --ntasks=2
#SBATCH --mem=8g
#SBATCH --output=sm.slurm.out
#SBATCH --error=sm.slurm.err
#SBATCH --partition=interactive

# Dependencies
module load Apptainer/1.3.3

# Application specific commands:
printenv

exit 1


printf "JOBDIR: %s\n" "${JOBDIR}"
printf "LOCALDIR: %s\n" "${LOCALDIR}"
printf "MEMDIR: %s\n" "${MEMDIR}"
printf "TMPDIR: %s\n" "${TMPDIR}"

snakemake \
	--profile petrichor_tmp \
	--retries 0 \
	--keep-going \
	--cores 128 \
	--local-cores 2
