#!/bin/bash

#SBATCH --job-name=atol_test
#SBATCH --time=1-00
#SBATCH --ntasks=2
#SBATCH --mem=8g
#SBATCH --output=sm.slurm.out
#SBATCH --error=sm.slurm.err

# Dependencies
module load Apptainer/1.3.3
module load Nextflow/24.10.2

# Application specific commands:
printf "TMPDIR: %s\n" "${TMPDIR}"

snakemake \
	--profile spartan_v8 \
	--retries 0 \
	--keep-going \
	--cores 12 \
	--local-cores 2 \
	format_config_file

nextflow run \
	sanger-tol/genomeassembly \
	--input output/config/sangertol_genomeassembly_params.yaml \
	--outdir output/sanger_tol \
	-log "nextflow.$(date +"%Y%m%d%H%M%S").${RANDOM}.log" \
	-dump-hashes json \
	-resume \
	-profile apptainer,spartan \
	-r 0.10.0
