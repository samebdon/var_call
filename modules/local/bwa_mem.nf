process BWA_MEM {
    tag "$meta"

    input:
    path(genome_f)
    path(genome_index)
    tuple val(meta), path(read1), path(read2)

    output:
    tuple val(meta), path("bwamem/${meta}.${genome_f.baseName}.bam"), emit: alignment, optional: true
    tuple val(meta), path("${meta}.alignment_status.tsv"), emit: status

    script:
    """
    set -uo pipefail
    mkdir -p bwamem
    if ! bwa mem \
        -t ${task.cpus} \
        -R "@RG\\tID:${meta}\\tSM:${meta}\\tPL:ILLUMINA\\tPU:${meta}\\tLB:${meta}\\tDS:${meta}" \
        ${genome_f} \
        ${read1} \
        ${read2} \
      | sambamba view -t ${task.cpus} -S -f bam /dev/stdin \
      > bwamem/${meta}.${genome_f.baseName}.bam; then
        rm -f bwamem/${meta}.${genome_f.baseName}.bam
        printf '%s\talignment\tfailed\tbwa_mem_failed\n' '${meta}' > ${meta}.alignment_status.tsv
        exit 1
    fi

    if ! samtools quickcheck bwamem/${meta}.${genome_f.baseName}.bam 2>/dev/null; then
        rm -f bwamem/${meta}.${genome_f.baseName}.bam
        printf '%s\talignment\tfailed\tinvalid_bam\n' '${meta}' > ${meta}.alignment_status.tsv
        exit 0
    fi

    READ_COUNT="\$(samtools view -c bwamem/${meta}.${genome_f.baseName}.bam)"
    if [ "\$READ_COUNT" -eq 0 ]; then
        rm -f bwamem/${meta}.${genome_f.baseName}.bam
        printf '%s\talignment\tfailed\tempty_bam\n' '${meta}' > ${meta}.alignment_status.tsv
        exit 0
    fi

    printf '%s\talignment\tok\treads=%s\n' '${meta}' "\$READ_COUNT" > ${meta}.alignment_status.tsv
    """
}
