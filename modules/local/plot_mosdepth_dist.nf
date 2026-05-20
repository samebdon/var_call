process PLOT_MOSDEPTH_DIST {
    tag "$dataset_id"
    publishDir "${params.outdir}/qc", mode: 'copy'

    input:
    path(dist_files, stageAs: 'inputs/*')
    val(dataset_id)
    val(min_cov)
    val(max_cov)
    val(min_fraction)

    output:
    path("${dataset_id}.mosdepth.global.distro.png")

    script:
    """
    set -euo pipefail
    python ${projectDir}/bin/plot_mosdepth_dist.py \
        --dir inputs \
        --prefix ${dataset_id}.mosdepth \
        --min ${min_cov} \
        --max ${max_cov} \
        --minf ${min_fraction}
    """
}
