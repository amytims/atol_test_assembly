#!/bin/bash

#SBATCH --job-name=atol_test_Heterotonia_binoei
#SBATCH --time=1-00
#SBATCH --cpus-per-task=2
#SBATCH --ntasks=1
#SBATCH --mem=32g
#SBATCH --output=sm.slurm.out
#SBATCH --error=sm.slurm.err

# Dependencies
module load python/3.11.6
module load nextflow/24.04.3
module load singularity/4.1.0-nohost

unset SBATCH_EXPORT

# Application specific commands:
set -eux

source /software/projects/pawsey1132/atims/assembly_testing/venv/bin/activate

printf "TMPDIR: %s\n" "${TMPDIR}"
printf "SLURM_CPUS_ON_NODE: %s\n" "${SLURM_CPUS_ON_NODE}"

if [ -z "${SINGULARITY_CACHEDIR}" ]; then
	export SINGULARITY_CACHEDIR=/software/projects/pawsey1132/tharrop/.singularity
	export APPTAINER_CACHEDIR="${SINGULARITY_CACHEDIR}"
fi

export NXF_APPTAINER_CACHEDIR="${SINGULARITY_CACHEDIR}/library"
export NXF_SINGULARITY_CACHEDIR="${SINGULARITY_CACHEDIR}/library"

snakemake \
	--profile profiles/pawsey_v8 \
	--retries 0 \
	--keep-going \
	--cores 12 \
	--local-cores "${SLURM_CPUS_ON_NODE}" \
	config_target

exit 0

# Pull the containers into the cache before trying to launch the workflow.
# Using the latest commit to dev because of issues with staging from s3 on
# release 0.10.0. See
# https://github.com/sanger-tol/genomeassembly/compare/0.10.0...dev
nextflow inspect \
	-concretize sanger-tol/genomeassembly \
	--input results/sangertol_genomeassembly_params.yaml \
	--outdir s3://pawsey1132.amy.testing/414129_AusARG/results/sanger_tol \
	-profile singularity,pawsey \
	-r 115b833

# Note, it's tempting to use the apptainer profile, but the nf-core (and some
# sanger-tol) pipelines have a conditional `workflow.containerEngine ==
# 'singularity'` that prevents using the right URL with apptainer.
# nextflow \
# 	-log "nextflow_logs/nextflow.$(date +"%Y%m%d%H%M%S").${RANDOM}.log" \
# 	run \
# 	sanger-tol/genomeassembly \
# 	--input results/sangertol_genomeassembly_params.yaml \
# 	--outdir s3://pawsey1132.atol.testassembly/414129_AusARG/results/sanger_tol \
# 	-resume \
# 	-profile singularity,pawsey \
# 	-r 115b833

# currently the assembly output is hard-coded
snakemake \
	--profile profiles/pawsey_v8 \
	--retries 0 \
	--keep-going \
	--cores 12 \
	--local-cores "${SLURM_CPUS_ON_NODE}" \
	rm_all
