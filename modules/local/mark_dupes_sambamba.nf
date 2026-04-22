process MARK_DUPES_SAMBAMBA {
    tag "$meta"

    memory '4 GB'

    input:
    tuple val(meta), path(bam_f)

    output:
    tuple val(meta), path("${bam_f.baseName}.deduped.bam"), emit: meta_bam
    path("${bam_f.baseName}.deduped.bam"), emit: bam_only

    script:
    """
    sambamba markdup -t ${task.cpus} ${bam_f} ${bam_f.baseName}.deduped.bam
    """
}
