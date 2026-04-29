process MOSDEPTH_CALLABLE {
    tag "$meta"
    publishDir "${params.outdir}/bed", mode: 'copy'
    
    input:
    tuple val(meta), path(bam_f), path(bam_index)
    val(min_depth)

    output:
    tuple val(meta), path("mosdepth/${bam_f.baseName}.callable.bed"), emit: callable_bed
    tuple val(meta), path("mosdepth/${bam_f.baseName}.callable_mb.txt"), emit: callable_size_mb
    tuple val(meta), path("mosdepth/${bam_f.baseName}.sample_name.txt"), emit: sample_name
    tuple val(meta), path("mosdepth/${bam_f.baseName}.depth_thresholds.tsv"), emit: depth_thresholds

    script:
    """
    mkdir -p mosdepth
    mosdepth --fast-mode -t ${task.cpus} tmp ${bam_f}
    MAX_DEPTH="\$(callable_upper_depth.py -b tmp.per-base.bed.gz)"

    mapfile -t SAMPLE_NAME_ARRAY < <(
        samtools view -H ${bam_f} \
            | perl -ne 'if (/^@RG/ && /\\tSM:([^\\t\\n]+)/) { print \$1, qq(\\n) }' \
            | sort -u
    )
    N_SAMPLE_NAMES="\${#SAMPLE_NAME_ARRAY[@]}"

    if [ "\$N_SAMPLE_NAMES" -eq 0 ]; then
        SAMPLE_NAME='${meta}'
    elif [ "\$N_SAMPLE_NAMES" -eq 1 ]; then
        SAMPLE_NAME="\${SAMPLE_NAME_ARRAY[0]}"
    else
        echo "Multiple distinct SM tags detected in ${bam_f}:" >&2
        printf '%s\\n' "\${SAMPLE_NAME_ARRAY[@]}" >&2
        exit 1
    fi

    mosdepth -t ${task.cpus} -n --quantize 0:1:${min_depth}:\${MAX_DEPTH}: ${meta} ${bam_f}
    zcat ${meta}.quantized.bed.gz | grep "${min_depth}:\$MAX_DEPTH" > mosdepth/${bam_f.baseName}.callable.bed
    awk '{SUM += \$3-\$2} END {printf "%.3f", SUM/1000000}' mosdepth/${bam_f.baseName}.callable.bed > mosdepth/${bam_f.baseName}.callable_mb.txt
    printf '%s\\n' "\$SAMPLE_NAME" > mosdepth/${bam_f.baseName}.sample_name.txt
    printf '%s\\t%s\\t%s\\n' "\$SAMPLE_NAME" "${min_depth}" "\$MAX_DEPTH" > mosdepth/${bam_f.baseName}.depth_thresholds.tsv
    """
}
