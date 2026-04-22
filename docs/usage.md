# Usage

## Minimal run

```bash
nextflow run main.nf   --analysis_mode paired   --input assets/samplesheet.csv   --genome ref/genome.fa   --species species_name   --dataset_id species_reseq_batch1   --outdir results   -profile standard,conda
```

## Cluster run with a params file

```bash
nextflow run main.nf   -profile conda,lsf   -params-file params/afusca_params.json   -work-dir data/workdir/var_call   -resume
```

- `-params-file` is the cleanest way to keep dataset-specific settings outside the main command.
- `-work-dir` is the standard Nextflow option for choosing the working directory location.
- `-resume` reuses completed tasks from the existing work directory.

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
nextflow run main.nf   --analysis_mode paired   --reads 'data/*_{1,2}.fastq.gz'   --genome ref/genome.fa   --species species_name   --outdir results
```

## Optional repeat masking

- Provide `--repeat_bed` when you want callable regions to exclude annotated repeats.
- Omit it when you do not have a repeat annotation yet; the pipeline will keep the callable-bed generation and skip only the repeat subtraction step.

## Reference indexing

- Provide `--genome` only; the pipeline generates the corresponding `.fai` internally with `samtools faidx`.
- This avoids having to pass a separate FASTA index path and reduces the risk of mismatching a FASTA with the wrong index.

## Mosdepth labels

- The pipeline sets `MOSDEPTH_Q0`, `MOSDEPTH_Q1`, `MOSDEPTH_Q2`, and `MOSDEPTH_Q3` automatically for the `MOSDEPTH_CALLABLE` process.
- You do not need to export these manually in your job wrapper unless you want to override the defaults.

## Metadata guidance

- Use the samplesheet `sample` column for per-sample identifiers only.
- Use `--species` for metadata shared across the full run.
- Use `--dataset_id` when you want merged BAM, BED, and VCF outputs named after a project or batch rather than the species label.

## Recommended learning habits

- Put all default values in `nextflow.config`, not inside process scripts.
- Keep entry selection in `main.nf`, not in commented alternative workflows.
- Use `conf/` for environment-specific settings such as local, test, and cluster execution.
- Keep reusable logic in `workflows/` and implementation-heavy processes in `modules/local/`.
- Keep head-job submission details such as `bsub` directives and `module load nextflow/...` in your wrapper script rather than inside the pipeline.

## Practical next steps

- Add tiny test data and a CI syntax test.
- Replace local custom processes with upstream nf-core modules where it makes sense.
