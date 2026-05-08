process MERGE_SAMPLE_STATUS {
    tag "$dataset_id"
    publishDir "${params.outdir}/qc", mode: 'copy'

    input:
    path(status_files, stageAs: 'inputs/*')
    val(dataset_id)

    output:
    path("${dataset_id}.sample_status.tsv")

    script:
    """
    set -euo pipefail
    printf 'sample\tstage\tstatus\tdetail\n' > ${dataset_id}.sample_status.tsv
    if ls inputs/* >/dev/null 2>&1; then
        cat inputs/* | sort -u >> ${dataset_id}.sample_status.tsv
    fi
    """
}
