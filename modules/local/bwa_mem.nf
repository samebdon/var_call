process BWA_MEM {
    tag "$meta"

    memory '8 GB'

    input:
    path(genome_f)
    path(genome_index)
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("bwamem/${meta}.${genome_f.baseName}.bam")

    script:
    """
    mkdir -p bwamem
    bwa mem         -t ${task.cpus}         -R "@RG\tID:${meta}\tSM:${meta}\tPL:ILLUMINA\tPU:${meta}\tLB:${meta}\tDS:${meta}"         ${genome_f}         ${reads[0]}         ${reads[1]} |     sambamba view -t ${task.cpus} -S -f bam /dev/stdin > bwamem/${meta}.${genome_f.baseName}.bam
    """
}
