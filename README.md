# var_call

Freebayes variant-calling pipeline for paired-end reads, single-end reads, or BAM inputs.

## Usage

Glob-based FASTQ input:

```bash
nextflow run main.nf   --analysis_mode paired   --reads 'data/*_{1,2}.fastq.gz'   --genome reference/genome.fa   --repeat_bed reference/repeats.bed   --species my_species   --outdir results
```

Paired-end reads:

```bash
nextflow run main.nf   --analysis_mode paired   --input assets/samplesheet.csv   --genome reference/genome.fa   --species my_species   --dataset_id my_species_reseq_2026   --outdir results   -profile standard,conda
```

Params-file cluster run with Conda:

```bash
nextflow run main.nf   -profile conda,lsf   -params-file params/afusca_params.json   -work-dir data/workdir/var_call   -resume
```

BAM input:

```bash
nextflow run main.nf   --analysis_mode bams   --bams 'data/*.bam'   --genome reference/genome.fa   --species my_species   --outdir results   -profile lsf,conda
```

Params-file cluster run with Apptainer:

```bash
nextflow run main.nf   -profile apptainer,lsf   -params-file params/afusca_params.json   --apptainer_container /path/to/var_call.sif   -work-dir data/workdir/var_call   -resume
```

## Analysis modes

- `paired`: one or more paired-end FASTQs
- `single_end`: one or more single-end FASTQs
- `bams`: one or more BAM inputs

## Input notes

- Use `--input` with [assets/samplesheet.csv](/Users/se13/workspace/projects/pipelines/var_call/assets/samplesheet.csv) for paired-end runs.
- Use `--input` with [assets/samplesheet_single_end.csv](/Users/se13/workspace/projects/pipelines/var_call/assets/samplesheet_single_end.csv) for single-end runs.
- `--reads` to point to read files directly.
- `--repeat_bed` is optional. If omitted, callable regions are generated without repeat subtraction.

## Metadata levels

- `sample` in the samplesheet is sample-level metadata.
- `--species` is dataset-level metadata.
- `--dataset_id` is an optional dataset-level analysis label for merged outputs. If omitted, merged outputs fall back to `--species`.

## Software distribution

- `-profile conda` uses the included Conda environment specification.
- `-profile apptainer` uses a prebuilt `.sif` image.
- Set `--apptainer_container /path/to/var_call.sif` when using the Apptainer profile.
- You can optionally set `--apptainer_cache_dir` if your cluster needs the cache somewhere specific.

## Citation

If you use `var_call`, please cite the software release.
Please also cite Nextflow and major underlying tools such as Freebayes where appropriate.

## Notes

See[docs/output.md](/Users/se13/workspace/projects/pipelines/var_call/docs/output.md) for more detail.
