process TRIM_READS {
    tag "$meta"
    publishDir "${params.outdir}/fastq", mode: 'copy'

    cpus 4
    memory '4 GB'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path('fastp/*.fastp.fastq.gz')

    script:
    """
    mkdir -p fastp
    fastp         -i ${reads[0]}         -I ${reads[1]}         -o fastp/${meta}.1.fastp.fastq.gz         -O fastp/${meta}.2.fastp.fastq.gz         --length_required 33         --cut_front         --cut_tail         --cut_mean_quality 20         --thread ${task.cpus}
    """
}
