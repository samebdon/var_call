# Output

The pipeline publishes a small set of organised output folders:

- `fastq/`: trimmed FASTQ files when trimming is enabled
- `bams/`: BAM files produced or updated during alignment and duplicate marking
- `bed/`: callable region BEDs, optional repeat-subtracted BEDs, and filter-failure BEDs
- `vcf/`: filtered and indexed VCF files
- `pipeline_info/`: Nextflow execution report, timeline, trace, and DAG

The current naming is still custom to this project, but the directory grouping is closer to how nf-core pipelines present outputs.
