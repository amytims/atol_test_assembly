# atol_test_assembly

Test an assembly using the sanger-tol pipeline. Basically download the reads,
reformat them to suit the pipeline, and generate the YAML file.

## Notes

- We can register Acacia using the Snakemake [S3
  plugin](https://snakemake.github.io/snakemake-plugin-catalog/plugins/storage/s3.html).
  This will be useful for the process that downloads the read files.
- We should be able to load the files directly from Acacia into the DToL
  workflow by configuring [S3 in
  Nexflow](https://www.nextflow.io/docs/latest/amazons3.html#s3-compatible-storage).