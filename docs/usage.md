# Usage

## Minimal run

```bash
nextflow run main.nf \
  --analysis_mode paired \
  --input assets/samplesheet.csv \
  --genome ref/genome.fa \
  --genome_index ref/genome.fa.fai \
  --species species_name \
  --dataset_id species_reseq_batch1 \
  --outdir results \
  -profile standard,conda
```

## Samplesheet formats

Paired-end:

```csv
sample,fastq_1,fastq_2
sample1,/path/sample1_R1.fastq.gz,/path/sample1_R2.fastq.gz
```

Single-end:

```csv
sample,fastq_1
sample1,/path/sample1.fastq.gz
```

## Legacy input mode

You can still run with `--reads` while the pipeline is mid-refactor:

```bash
nextflow run main.nf \
  --analysis_mode paired \
  --reads 'data/*_{1,2}.fastq.gz' \
  --genome ref/genome.fa \
  --genome_index ref/genome.fa.fai \
  --species species_name \
  --outdir results
```

## Optional repeat masking

- Provide `--repeat_bed` when you want callable regions to exclude annotated repeats.
- Omit it when you do not have a repeat annotation yet; the pipeline will keep the callable-bed generation and skip only the repeat subtraction step.

## Metadata guidance

- Use the samplesheet `sample` column for per-sample identifiers only.
- Use `--species` for metadata shared across the full run.
- Use `--dataset_id` when you want merged BAM, BED, and VCF outputs named after a project or batch rather than the species label.

## Recommended learning habits

- Put all default values in `nextflow.config`, not inside process scripts.
- Keep entry selection in `main.nf`, not in commented alternative workflows.
- Use `conf/` for environment-specific settings such as local, test, and cluster execution.
- Keep reusable logic in `workflows/` and implementation-heavy processes in `modules/local/`.

## Practical next steps

- Convert raw FASTQ handling to a samplesheet-driven input channel.
- Add tiny test data and a CI syntax test.
- Replace local custom processes with upstream nf-core modules where it makes sense.
