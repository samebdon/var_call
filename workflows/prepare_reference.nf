include { MINIBWA_INDEX } from '../modules/local/minibwa_index'
include { SAMTOOLS_FAIDX } from '../modules/local/samtools_faidx'

workflow PREPARE_REFERENCE {
    take:
    genome

    main:
    SAMTOOLS_FAIDX(genome)

    emit:
    fasta_index = SAMTOOLS_FAIDX.out
}

workflow PREPARE_ALIGNMENT_REFERENCE {
    take:
    genome

    main:
    MINIBWA_INDEX(genome)
    SAMTOOLS_FAIDX(genome)

    emit:
    minibwa_index = MINIBWA_INDEX.out
    fasta_index = SAMTOOLS_FAIDX.out
}
