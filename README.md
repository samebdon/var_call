# var_call

Freebayes variant-calling pipeline for paired-end reads, single-end reads, or BAM inputs.

## Usage

Glob-based FASTQ input:

```bash
nextflow run main.nf   --analysis_mode paired   --reads 'data/*_{1,2}.fastq.gz'   --genome reference/genome.fa   --repeat_bed reference/repeats.bed   --species my_species   --outdir results
```

Paired-end reads from a CSV/TSV samplesheet:

```bash
nextflow run main.nf   --analysis_mode paired   --input assets/samplesheet.csv   --genome reference/genome.fa   --species my_species   --dataset_id my_species_reseq_2026   --outdir results   -profile standard,conda
```

BAM input from a glob:

```bash
nextflow run main.nf   --analysis_mode bams   --bams 'data/*.bam'   --genome reference/genome.fa   --species my_species   --outdir results   -profile lsf,conda
```

BAM input from a CSV/TSV samplesheet:

```bash
nextflow run main.nf   --analysis_mode bams   --input assets/bam_samplesheet.csv   --genome reference/genome.fa   --species my_species   --outdir results   -profile lsf,conda
```

Params-file cluster run with Conda:

```bash
nextflow run main.nf   -profile conda,lsf   -params-file params/afusca_params.json   -work-dir data/workdir/var_call   -resume
```

Params-file cluster run with Apptainer:

```bash
nextflow run main.nf   -profile apptainer,lsf   -params-file params/afusca_params.json   --apptainer_container /path/to/var_call.sif   -work-dir data/workdir/var_call   -resume
```

## Analysis modes

- `paired`: one or more paired-end samples
- `single_end`: one or more single-end FASTQs
- `bams`: one or more BAM inputs

## Input notes

- Use `--input` with [assets/samplesheet.csv](/Users/se13/workspace/projects/pipelines/var_call/assets/samplesheet.csv) for paired-end runs.
- Use `--input` with [assets/samplesheet_single_end.csv](/Users/se13/workspace/projects/pipelines/var_call/assets/samplesheet_single_end.csv) for single-end runs.
- Use `--input` with [assets/bam_samplesheet.csv](/Users/se13/workspace/projects/pipelines/var_call/assets/bam_samplesheet.csv) or [assets/bam_samplesheet.tsv](/Users/se13/workspace/projects/pipelines/var_call/assets/bam_samplesheet.tsv) for BAM mode.
- `--reads` remains available as a simpler legacy option while you are still iterating on the pipeline.
- `--repeat_bed` is optional. If omitted, callable regions are generated without repeat subtraction.
- The pipeline generates the reference FASTA index (`.fai`) internally with `samtools faidx`.
- `MOSDEPTH_CALLABLE` also writes a per-sample `.callable_mb.txt` file giving callable BED size in megabases.

## Metadata levels

- `sample` in the samplesheet is sample-level metadata and should identify individual libraries or individuals.
- `--species` is dataset-level metadata and describes the biology shared by the whole run.
- `--dataset_id` is an optional dataset-level analysis label for merged outputs. If omitted, merged outputs fall back to `--species`.

## Software distribution

- `-profile conda` uses the included Conda environment specification.
- `-profile apptainer` uses a prebuilt `.sif` image.
- Set `--apptainer_container /path/to/var_call.sif` when using the Apptainer profile.
- You can optionally set `--apptainer_cache_dir` if your cluster needs the cache somewhere specific.
- A starter Apptainer recipe is provided in [containers/Apptainer.def](/Users/se13/workspace/projects/pipelines/var_call/containers/Apptainer.def) with notes in [containers/README.md](/Users/se13/workspace/projects/pipelines/var_call/containers/README.md).

## Citation

If you use `var_call`, please cite the software release.

A starter citation file is provided in [CITATION.cff](/Users/se13/workspace/projects/pipelines/var_call/CITATION.cff). Once the repository is on GitHub and linked to Zenodo, update the repository URL and add the Zenodo DOI.

Suggested format:

```text
Ebdon, S. (2026). var_call (v1.0.0) [Software]. GitHub/Zenodo.
```

Please also cite Nextflow and major underlying tools such as Freebayes where appropriate.

## Notes

- Head-job submission details such as `bsub` directives and `module load nextflow/...` are intentionally kept outside the pipeline.
- The Conda environment already includes the tools used by this refactored pipeline, including `bcftools` and `samtools`, so extra tool modules are usually unnecessary when running with `-profile conda`.
- `MOSDEPTH_Q0` to `MOSDEPTH_Q3` are set automatically for the `MOSDEPTH_CALLABLE` process.
- The next step toward closer nf-core alignment would be converting reusable steps to official nf-core modules and adding `nf-test` or small test data.

See [docs/output.md](/Users/se13/workspace/projects/pipelines/var_call/docs/output.md) for more detail.
