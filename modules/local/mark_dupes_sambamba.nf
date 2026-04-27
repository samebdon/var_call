process MARK_DUPES_SAMBAMBA {
    tag "$meta"

    memory '4 GB'

    input:
    tuple val(meta), path(bam_f)

    output:
    tuple val(meta), path("${bam_f.baseName}.deduped.bam"), path("${bam_f.baseName}.deduped.bam.bai"), emit: bam

    script:
    """
    sambamba markdup -t ${task.cpus} ${bam_f} ${bam_f.baseName}.deduped.bam
    sambamba index -t ${task.cpus} ${bam_f.baseName}.deduped.bam
    """
}
