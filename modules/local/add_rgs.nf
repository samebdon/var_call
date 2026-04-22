process ADD_RGS {
    tag "$meta"
    publishDir "${params.outdir}/bams", mode: 'copy'

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("${meta}.RG.bam")

    script:
    """
    samtools addreplacerg         -r "ID:${meta}\tSM:${meta}\tLB:${meta}\tPL:${meta}\tPU:${meta}"         -o ${meta}.RG.bam         ${bam}
    """
}
