process READS_CRAM_TO_FASTQ_SINGLE {
    tag "$meta"
    publishDir "${params.outdir}/fastq", mode: 'copy'

    input:
    tuple val(meta), path(cram_f)

    output:
    tuple val(meta), path("cram_fastq/${meta}.fastq.gz")

    script:
    """
    set -euo pipefail
    mkdir -p cram_fastq
    samtools collate -@ ${task.cpus} -Ou -T ${meta}.collate ${cram_f} \
      | samtools fastq -@ ${task.cpus} -0 cram_fastq/${meta}.fastq.gz -N -
    """
}
