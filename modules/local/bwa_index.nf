process BWA_INDEX {
    tag "$genome_f.baseName"

    input:
    path(genome_f)

    output:
    path("${genome_f}.*")

    script:
    """
    bwa index ${genome_f}
    """
}
