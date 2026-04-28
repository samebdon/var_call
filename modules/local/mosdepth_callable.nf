process MOSDEPTH_CALLABLE {
    tag "$meta"
    publishDir "${params.outdir}/bed", mode: 'copy'
    
    input:
    tuple val(meta), path(bam_f), path(bam_index)
    val(min_depth)

    output:
    tuple val(meta), path("mosdepth/${bam_f.baseName}.callable.bed"), emit: callable_bed
    tuple val(meta), path("mosdepth/${bam_f.baseName}.callable_mb.txt"), emit: callable_size_mb

    script:
    """
    mkdir -p mosdepth
    mosdepth --fast-mode -t ${task.cpus} tmp ${bam_f}
    MAX_DEPTH="\$(callable_upper_depth.py -b tmp.per-base.bed.gz)"
    mosdepth -t ${task.cpus} -n --quantize 0:1:${min_depth}:\${MAX_DEPTH}: ${meta} ${bam_f}
    zcat ${meta}.quantized.bed.gz | grep "${min_depth}:\$MAX_DEPTH" > mosdepth/${bam_f.baseName}.callable.bed
    awk '{SUM += \$3-\$2} END {printf "%.3f", SUM/1000000}' mosdepth/${bam_f.baseName}.callable.bed > mosdepth/${bam_f.baseName}.callable_mb.txt
    """
}
