#!/bin/bash

#SBATCH --job-name=atol_test
#SBATCH --time=0-01
#SBATCH --ntasks=2
#SBATCH --mem=8g
#SBATCH --output=sm.slurm.out
#SBATCH --error=sm.slurm.err

# Dependencies
module load Apptainer/1.3.3

# Application specific commands:
printf "TMPDIR: %s\n" "${TMPDIR}"

snakemake \
	-n \
	--profile spartan_v8 \
	--retries 0 \
	--keep-going \
	--cores 128 \
	--local-cores 2
