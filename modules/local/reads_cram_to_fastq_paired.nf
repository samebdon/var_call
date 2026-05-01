process READS_CRAM_TO_FASTQ_PAIRED {
    tag "$meta"
    publishDir "${params.outdir}/fastq", mode: 'copy'

    input:
    tuple val(meta), path(cram_f)

    output:
    tuple val(meta), path("cram_fastq/${meta}.1.fastq.gz"), path("cram_fastq/${meta}.2.fastq.gz")

    script:
    """
    set -euo pipefail
    mkdir -p cram_fastq
    samtools collate -@ ${task.cpus} -Ou -T ${meta}.collate ${cram_f} \
      | samtools fastq -@ ${task.cpus} -1 cram_fastq/${meta}.1.fastq.gz -2 cram_fastq/${meta}.2.fastq.gz -0 /dev/null -s /dev/null -n -
    """
}
