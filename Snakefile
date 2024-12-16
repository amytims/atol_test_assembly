#!/usr/bin/env python3

from pathlib import Path
import os
import requests
from jinja2 import Template

#############
# FUNCTIONS #
#############

# This is a hack. Redefine requests.get to include the Authorization header.
# snakemake_storage_plugin_http only supports predifined AuthBase classes, see
# https://github.com/snakemake/snakemake-storage-plugin-http/issues/27
requests_get = requests.get


def requests_get_with_auth_header(url, **kwargs):
    if "headers" not in kwargs:
        kwargs["headers"] = {}
    kwargs["headers"]["Authorization"] = apikey
    return requests_get(url, **kwargs)


requests.get = requests_get_with_auth_header


# Normal functions


def get_apikey():
    apikey = os.getenv("BPI_APIKEY")
    if not apikey:
        raise ValueError(
            "Set the BPI_APIKEY environment variable. "
            "This Snakefile uses a hack to pass the API key to `requests.get`. "
            "See  https://github.com/snakemake/snakemake-storage-plugin-http/issues/27."
        )
    return apikey


def get_hifi_readfiles(wildcards):
    return [
        Path(outdir, "reads", filename)
        for filename, url in data_file_dict.items()
        if filename.endswith(".ccs.bam")
    ]


def get_url(wildcards):
    my_url = data_file_dict[wildcards.readfile]
    return storage.http(my_url)


###########
# GLOBALS #
###########


outdir = Path("output")
logdir = Path(outdir, "logs")

sanger_config_template = Path(
    "data", "sangertol_genomeassembly_params_template.yaml.j2"
)

# hard code for now, config later
dataset_id = "414129_AusARG"
hic_motif = "GATC,GANTC,CTNAG,TTAA"
busco_lineage = "tetrapoda_odb10"
mito_species = "Heteronotia binoei"  # FIXME
mito_min_length = 15000
mito_code = 5

# containers
bbmap = "docker://quay.io/biocontainers/bbmap:39.13--he5f24ec_1"
samtools = "docker://quay.io/biocontainers/samtools:1.21--h96c455f_1"
pigz = "docker://quay.io/biocontainers/pigz:2.8"

########
# MAIN #
########

apikey = get_apikey()

# this is from teh bpa_dataportal_downloads project
# results of a search for query = {"sample_id": '102.100.100/411655'}
data_file_dict = {
    "414129_AusARG_AGRF_DA235386.subreads.bam": "https://data.bioplatforms.com/dataset/bpa-ausarg-pacbio-hifi-414129-da235386/resource/f28fe709744235efc0da895975c68f6f/download/414129_AusARG_AGRF_DA235386.subreads.bam",
    "414129_AusARG_AGRF_DA235386.ccs.bam": "https://data.bioplatforms.com/dataset/bpa-ausarg-pacbio-hifi-414129-da235386/resource/27fc8f6c8fb9e3b462a3cdae002bd5f4/download/414129_AusARG_AGRF_DA235386.ccs.bam",
    "414129_AusARG_AGRF_DA235337.subreads.bam": "https://data.bioplatforms.com/dataset/bpa-ausarg-pacbio-hifi-414129-da235337/resource/303068e96c58206aafd222a2cad04545/download/414129_AusARG_AGRF_DA235337.subreads.bam",
    "414129_AusARG_AGRF_DA235337.ccs.bam": "https://data.bioplatforms.com/dataset/bpa-ausarg-pacbio-hifi-414129-da235337/resource/bdd8b8ba65c217945353138c1ba0d4be/download/414129_AusARG_AGRF_DA235337.ccs.bam",
    "414130_AusARG_BRF_HKWJJDMXY_AAGCATCG_S5_R2_001.fastq.gz": "https://data.bioplatforms.com/dataset/bpa-ausarg-hi-c-414130-hkwjjdmxy/resource/71e2e0c5384d238811bd78e54cbe0111/download/414130_AusARG_BRF_HKWJJDMXY_AAGCATCG_S5_R2_001.fastq.gz",
    "414130_AusARG_BRF_HKWJJDMXY_AAGCATCG_S5_R1_001.fastq.gz": "https://data.bioplatforms.com/dataset/bpa-ausarg-hi-c-414130-hkwjjdmxy/resource/796d9cd507b33eb34b3b31e4200129c7/download/414130_AusARG_BRF_HKWJJDMXY_AAGCATCG_S5_R1_001.fastq.gz",
}


#########
# RULES #
#########

# TARGET IS AT THE END


rule format_config_file:
    input:
        sanger_config_template=sanger_config_template,
        pacbio_reads=Path(outdir, "reads", "ccs_reads.fasta.gz"),
        hic_reads=Path(outdir, "reads", "hic.cram"),
    output:
        Path(outdir, "config", "sangertol_genomeassembly_params.yaml"),
    run:
        with open(input.sanger_config_template) as f:
            template = Template(f.read())
        rendered_yaml = template.render(
            dataset_id=dataset_id,
            hic_motif=hic_motif,
            busco_lineage=busco_lineage,
            mito_species=mito_species,
            mito_min_length=mito_min_length,
            mito_code=mito_code,
            pacbio_reads=[input.pacbio_reads],
            hic_reads=[input.hic_reads],
        )
        with open(output, "w") as f:
            f.write(rendered_yaml)


# TODO: combine Hi-C reads as follows:
# contains the list (-reads) of the HiC reads in the indexed CRAM format.
rule bam_to_cram:
    input:
        Path(outdir, "reads", "hic.bam"),
    output:
        Path(outdir, "reads", "hic.cram"),
    log:
        Path(logdir, "bam_to_cram.log"),
    resources:
        time=120,
    container:
        samtools
    shell:
        "samtools view "
        "-C "
        "-o {output} "
        "- "
        "< {input} "
        "2> {log}"


rule reformat_hic:
    input:
        r1=Path(
            outdir, "reads", "414130_AusARG_BRF_HKWJJDMXY_AAGCATCG_S5_R1_001.fastq.gz"
        ),
        r2=Path(
            outdir, "reads", "414130_AusARG_BRF_HKWJJDMXY_AAGCATCG_S5_R2_001.fastq.gz"
        ),
    output:
        pipe(Path(outdir, "reads", "hic.bam")),
    log:
        Path(logdir, "reformat_hic.log"),
    resources:
        time=120,
    container:
        bbmap
    shell:
        "reformat.sh "
        "in={input.r1} "
        "in2={input.r2} "
        "out=stdout.bam "
        ">> {output} "
        "2> {log}"


# Combine HiFi reads as follows:
# contains the list (-reads) of the HiFi reads in FASTA (or gzipped FASTA)
# format in. The pipeline implementation is based on an assumption that reads
# have gone through adapter/barcode checks.


rule pigz:
    input:
        Path(outdir, "reads", "ccs_reads.fasta"),
    output:
        Path(outdir, "reads", "ccs_reads.fasta.gz"),
    threads: 8
    resources:
        time=120,
    container:
        pigz
    shell:
        "pigz -9 "
        "--processes {threads} "
        "< {input} > {output}"


rule samtools_fasta:
    input:
        get_hifi_readfiles,
    output:
        pipe(Path(outdir, "reads", "ccs_reads.fasta")),
    log:
        Path(logdir, "samtools_fasta.log"),
    resources:
        time=120,
    container:
        samtools
    shell:
        "samtools cat "
        "{input} "
        "| "
        "samtools fasta "
        "- "
        ">> {output} "
        "2> {log}"


rule download_from_bpa:
    input:
        get_url,
    output:
        Path(outdir, "reads", "{readfile}"),
    shell:
        "cp {input} {output}"


###########
# TARGETS #
###########


rule target:
    default_target: True
    input:
        rules.format_config_file.output,
