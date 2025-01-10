# atol_test_assembly

Test an assembly using the sanger-tol pipeline. Basically download the reads,
reformat them to suit the pipeline, and generate the YAML file.

## To do:

1. Check the hashes of the downloaded files

## Findings so far

We download the reads from BPA, process them, and generate a config file on
Pawsey using a Snakemake workflow. We chose Snakemake because the BPA API uses
ckan, which has bindings in python.

The workflow then automatically uploads the processed reads and config file to
the S3 bucket on Acacia specified in `config.yaml`. A system for naming and
creating the S3 buckets will be needed, along the lines of
`{pawsey_project}.atol.{unique_identifier}`.

The DToL workflow can retrieve the files from Acacia and publish its results to
Acacia.

See https://github.com/TomHarrop/atol-test-profiles for examples of how the
workflow managers are configured to use Acacia.

## Notes

- We can register Acacia using the Snakemake [S3
  plugin](https://snakemake.github.io/snakemake-plugin-catalog/plugins/storage/s3.html).
  This will be useful for the process that downloads the read files.
- We should be able to load the files directly from Acacia into the DToL
  workflow by configuring [S3 in
  Nexflow](https://www.nextflow.io/docs/latest/amazons3.html#s3-compatible-storage).
- See WIP at https://github.com/TomHarrop/atol-test-profiles.

