process BWA_MEM {
    tag "$meta"
    label 'align_reads'

    memory '8 GB'

    input:
    path(genome_f)
    path(genome_index)
    tuple val(meta), path(read1), path(read2)

    output:
    tuple val(meta), path("bwamem/${meta}.${genome_f.baseName}.bam")

    script:
    """
    set -euo pipefail
    mkdir -p bwamem
    bwa mem \
        -t ${task.cpus} \
        -R "@RG\tID:${meta}\tSM:${meta}\tPL:ILLUMINA\tPU:${meta}\tLB:${meta}\tDS:${meta}" \
        ${genome_f} \
        ${read1} \
        ${read2} \
      | sambamba view -t ${task.cpus} -S -f bam /dev/stdin \
      > bwamem/${meta}.${genome_f.baseName}.bam
    """
}
