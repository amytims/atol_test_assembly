#!/bin/bash

#SBATCH --job-name=atol_test
#SBATCH --time=1-00
#SBATCH --ntasks=2
#SBATCH --mem=8g
#SBATCH --output=sm.slurm.out
#SBATCH --error=sm.slurm.err

# Dependencies
module load Apptainer/1.3.3
module load Nextflow/23.04.2
module load Miniconda3/23.10.0-1

# Application specific commands:
printf "TMPDIR: %s\n" "${TMPDIR}"

snakemake \
	--profile spartan_v8 \
	--retries 0 \
	--keep-going \
	--cores 12 \
	--local-cores 2
