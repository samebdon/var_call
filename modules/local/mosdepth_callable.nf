process MOSDEPTH_CALLABLE {
    tag "$meta"

    memory '15 GB'

    input:
    tuple val(meta), path(bam_f), path(bam_index)
    val(min_depth)

    output:
    path("mosdepth/${bam_f.baseName}.callable.bed")

    script:
    """
    mkdir -p mosdepth
    mosdepth --fast-mode -t ${task.cpus} tmp ${bam_f}
    MAX_DEPTH="\$(callable_upper_depth.py -b tmp.per-base.bed.gz)"
    mosdepth -t ${task.cpus} -n --quantize 0:1:${min_depth}:\${MAX_DEPTH}: ${meta} ${bam_f}
    zcat ${meta}.quantized.bed.gz | grep 'CALLABLE' > mosdepth/${bam_f.baseName}.callable.bed
    """
}
