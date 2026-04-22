# var_call

This repository is a learning-oriented cleanup of a custom Nextflow variant-calling pipeline, organised to resemble nf-core conventions without aiming for a formal nf-core submission.

## What changed

- The entrypoint now uses explicit `--analysis_mode` values instead of commenting and uncommenting whole workflows.
- FASTQ-based modes can be driven by a small CSV samplesheet with an nf-core-like feel.
- Pipeline logic is split into `main.nf`, `workflows/`, and `modules/local/`.
- Config is layered into reusable files under `conf/`.
- Basic project metadata, docs, and parameter schema are included to make the repository easier to understand and extend.
- `repeat_bed` is optional, with callable-region generation branching accordingly.

## Repository layout

```text
.
├── main.nf
├── nextflow.config
├── conf/
├── modules/local/
├── workflows/
├── params/
├── assets/
└── docs/
```

## Usage

Paired-end reads:

```bash
nextflow run main.nf \
  --analysis_mode paired \
  --input assets/samplesheet.csv \
  --genome reference/genome.fa \
  --genome_index reference/genome.fa.fai \
  --species my_species \
  --dataset_id my_species_reseq_2026 \
  --outdir results \
  -profile standard,conda
```

BAM input:

```bash
nextflow run main.nf \
  --analysis_mode bams \
  --bams 'data/*.bam' \
  --genome reference/genome.fa \
  --genome_index reference/genome.fa.fai \
  --species my_species \
  --outdir results \
  -profile cluster,conda
```

Params-file driven cluster run:

```bash
nextflow run main.nf \
  -profile conda,cluster \
  -params-file params/afusca_params.json \
  -work-dir data/workdir/var_call \
  -resume
```

Legacy glob-based FASTQ input still works:

```bash
nextflow run main.nf \
  --analysis_mode paired \
  --reads 'data/*_{1,2}.fastq.gz' \
  --genome reference/genome.fa \
  --genome_index reference/genome.fa.fai \
  --repeat_bed reference/repeats.bed \
  --species my_species \
  --outdir results
```

## Analysis modes

- `paired`: multiple paired-end samples from FASTQ pairs
- `single_paired`: one paired-end sample
- `single_end`: one or more single-end FASTQs
- `bams`: start from BAM files

## Input notes

- Use `--input` with [assets/samplesheet.csv](/Users/se13/Documents/Codex/2026-04-20-files-mentioned-by-the-user-var/var_call/assets/samplesheet.csv) for paired-end runs.
- Use `--input` with [assets/samplesheet_single_end.csv](/Users/se13/Documents/Codex/2026-04-20-files-mentioned-by-the-user-var/var_call/assets/samplesheet_single_end.csv) for single-end runs.
- `--reads` remains available as a simpler legacy option while you are still iterating on the pipeline.
- `--repeat_bed` is optional. If omitted, callable regions are generated without repeat subtraction.

## Metadata levels

- `sample` in the samplesheet is sample-level metadata and should identify individual libraries or individuals.
- `--species` is dataset-level metadata and describes the biology shared by the whole run.
- `--dataset_id` is an optional dataset-level analysis label for merged outputs. If omitted, merged outputs fall back to `--species`.

## Notes

- This cleanup keeps the original custom processes together in `modules/local/var_call.nf` because that is a practical intermediate step when learning nf-core organisation.
- Head-job submission details such as `bsub` directives and `module load nextflow/...` are intentionally kept outside the pipeline.
- The Conda environment already includes the tools used by this refactored pipeline, including `bcftools` and `samtools`, so extra tool modules are usually unnecessary when running with `-profile conda`.
- `MOSDEPTH_Q0` to `MOSDEPTH_Q3` are set automatically for the `MOSDEPTH_CALLABLE` process.
- The next step toward closer nf-core alignment would be converting reusable steps to official nf-core modules and adding `nf-test` or small test data.

See [docs/usage.md](/Users/se13/Documents/Codex/2026-04-20-files-mentioned-by-the-user-var/var_call/docs/usage.md) and [docs/output.md](/Users/se13/Documents/Codex/2026-04-20-files-mentioned-by-the-user-var/var_call/docs/output.md) for more detail.