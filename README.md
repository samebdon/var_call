# var_call

Freebayes variant-calling pipeline for paired-end reads, single-end reads, or BAM inputs.

The current workflow uses `freebayes-parallel` and passes per-sample alignment files directly rather than merging them into a single BAM. Variants are now called before the joint callable mask is applied; per-sample genotypes are masked post-call with `bcftools filter -S .` using mosdepth-derived sample depth thresholds, and repeat regions are removed during hard filtering rather than pre-call region selection.

## Usage

Glob FASTQ input:

```bash
nextflow run main.nf   --analysis_mode paired   --reads 'data/*_{1,2}.fastq.gz'   --genome reference/genome.fa   --repeat_bed reference/repeats.bed   --species my_species   --outdir results
```

Paired-end reads from a CSV/TSV samplesheet:

```bash
nextflow run main.nf   --analysis_mode paired   --input assets/samplesheet.csv   --genome reference/genome.fa   --species my_species   --dataset_id my_species_reseq_2026   --outdir results   -profile standard,conda
```

BAM input from a CSV/TSV samplesheet:

```bash
nextflow run main.nf   --analysis_mode bams   --input assets/bam_samplesheet.csv   --genome reference/genome.fa   --species my_species   --outdir results   -profile lsf,conda
```

Params-file cluster run with Conda YAML:

```bash
nextflow run main.nf   -profile conda,lsf   -params-file params/afusca_params.json   -work-dir data/workdir/var_call   -resume
```

Params-file cluster run with an existing Conda env:

```bash
nextflow run main.nf   -profile conda,lsf   -params-file params/afusca_params.json   --conda_env /path/to/existing/env   -work-dir data/workdir/var_call   -resume
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
- Use `--input` with [assets/bam_samplesheet.csv](/Users/se13/workspace/projects/pipelines/var_call/assets/bam_samplesheet.csv) for BAM mode.
- `--reads` or '--bams' can be pointed to directly instead of using an input table.
- `--repeat_bed` is optional. If omitted, callable regions are generated without repeat subtraction.
- `MOSDEPTH_CALLABLE` also writes a per-sample `.callable_mb.txt` file giving callable BED size in megabases.

## Software distribution

- `-profile conda` uses the included Conda environment specification by default.
- Set `--conda_env /path/to/existing/env` to reuse an existing Conda environment instead of solving from YAML.
- Set `--conda_spec /path/to/env.yaml` if you want to override the default environment file.
- Advanced users can still use raw Nextflow `-with-conda` options directly if they prefer.
- `-profile apptainer` uses a prebuilt `.sif` image.
- Set `--apptainer_container /path/to/var_call.sif` when using the Apptainer profile.
- You can optionally set `--apptainer_cache_dir` if your cluster needs the cache somewhere specific.
- A starter Apptainer recipe is provided in [containers/Apptainer.def](/Users/se13/workspace/projects/pipelines/var_call/containers/Apptainer.def) with notes in [containers/README.md](/Users/se13/workspace/projects/pipelines/var_call/containers/README.md).

## Citation

If you use `var_call`, please cite the software release.

Suggested format:

```text
Ebdon, S. (2026). var_call (v1.0.0) [Software]. GitHub/Zenodo.
```

Please also cite Nextflow and major underlying tools such as Freebayes where appropriate.

## Notes

See [docs/output.md](/Users/se13/workspace/projects/pipelines/var_call/docs/output.md) for more detail.
