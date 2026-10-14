process MINIBWA_INDEX {
    tag "$genome_f.baseName"

    input:
    path(genome_f)

    output:
    path("${genome_f}.{l2b,mbw}")

    script:
    """
    minibwa index -t ${task.cpus} ${genome_f}
    """
}
