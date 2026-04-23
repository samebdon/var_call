process ADD_RGS {
    tag "$meta"
    publishDir "${params.outdir}/bams", mode: 'copy'

    input:
    tuple val(meta), path(bam)
    val(bam_rg_mode)

    output:
    tuple val(meta), path("${meta}.RG.bam")

    script:
    def overwrite_flag = bam_rg_mode == 'overwrite' ? '-w' : ''
    """
    if samtools view -H ${bam} | grep -q '^@RG' && [ "${bam_rg_mode}" = "preserve" ]; then
        cp ${bam} ${meta}.RG.bam
    else
        samtools addreplacerg ${overwrite_flag}             -r "ID:${meta}\tSM:${meta}\tLB:${meta}\tPL:${meta}\tPU:${meta}"             -o ${meta}.RG.bam             ${bam}
    fi
    """
}
