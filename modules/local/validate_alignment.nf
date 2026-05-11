process VALIDATE_ALIGNMENT {
    tag "$meta"
    publishDir "${params.outdir}/qc", mode: 'copy'

    input:
    tuple val(meta), path(alignment_f), path(index_f)

    output:
    tuple val(meta), path("${alignment_f.name}"), path("${index_f.name}"), emit: valid_alignment, optional: true
    tuple val(meta), path("${meta}.prepared_alignment_status.tsv"), emit: status

    script:
    """
    set -euo pipefail
    if ! samtools quickcheck ${alignment_f} 2>/dev/null; then
        printf '%s\tprepared_alignment\tfailed\tinvalid_alignment\n' '${meta}' > ${meta}.prepared_alignment_status.tsv
        exit 0
    fi

    READ_COUNT="\$(samtools view -c ${alignment_f})"
    if [ "\$READ_COUNT" -eq 0 ]; then
        printf '%s\tprepared_alignment\tfailed\tempty_alignment\n' '${meta}' > ${meta}.prepared_alignment_status.tsv
        exit 0
    fi

    printf '%s\tprepared_alignment\tok\treads=%s\n' '${meta}' "\$READ_COUNT" > ${meta}.prepared_alignment_status.tsv
    """
}
