process SAMTOOLS_FAIDX {
    tag "$genome_f.baseName"

    input:
    path(genome_f)

    output:
    path("${genome_f}.fai")

    script:
    """
    samtools faidx ${genome_f}
    """
}
