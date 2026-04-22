## Build

```bash
cd /Users/se13/workspace/projects/pipelines/var_call
apptainer build var_call.sif containers/Apptainer.def
```

## Run

```bash
nextflow run main.nf \
  -profile apptainer,lsf \
  -params-file params/afusca_params.json \
  --apptainer_container /path/to/var_call.sif \
  -work-dir data/workdir/var_call \
  -resume
```