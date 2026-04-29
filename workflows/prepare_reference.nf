include { BWA_INDEX } from '../modules/local/bwa_index'
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
    BWA_INDEX(genome)
    SAMTOOLS_FAIDX(genome)

    emit:
    bwa_index = BWA_INDEX.out
    fasta_index = SAMTOOLS_FAIDX.out
}
