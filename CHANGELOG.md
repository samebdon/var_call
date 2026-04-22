# Changelog

## 1.0.0 - 2026-04-20

- Reorganised the pipeline into `main.nf`, `workflows/`, and `modules/local/`.
- Replaced commented workflow toggles with `--analysis_mode`.
- Added layered configuration under `conf/`.
- Added starter docs, parameter schema, and example assets for learning.
- Added optional samplesheet-driven FASTQ input via `--input`.
- Made `repeat_bed` optional by branching callable-region generation.
- Added optional `--dataset_id` to separate dataset-level output naming from sample-level metadata.
- Added mosdepth environment labels in config and improved cluster-oriented run documentation for `-profile`, `-params-file`, and `-work-dir`.
- FASTA `.fai` generation is now handled inside the pipeline with `samtools faidx` instead of requiring a separate input parameter.
- Added an Apptainer-friendly profile using a user-supplied `.sif` image path for more reproducible HPC distribution.
- Added a starter Apptainer definition file and container build notes under `containers/`.
