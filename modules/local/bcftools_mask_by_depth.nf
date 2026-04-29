process BCFTOOLS_MASK_BY_DEPTH {
    tag "$species"

    input:
    tuple val(species), path(vcf_f)
    path(threshold_files, stageAs: 'thresholds/*')

    output:
    tuple val(species), path("${vcf_f.baseName}.depth_masked.vcf.gz")

    script:
    """
    declare -A MIN_DEPTH_BY_SAMPLE
    declare -A MAX_DEPTH_BY_SAMPLE
    TAB="\$(printf '\\t')"

    while IFS="\$TAB" read -r sample_name min_depth max_depth; do
        [ -n "\$sample_name" ] || continue
        MIN_DEPTH_BY_SAMPLE["\$sample_name"]="\$min_depth"
        MAX_DEPTH_BY_SAMPLE["\$sample_name"]="\$max_depth"
    done < <(cat thresholds/*)

    mapfile -t VCF_SAMPLES < <(bcftools query -l ${vcf_f})

    FILTER_PARTS=()
    N_INTERSECTION=0
    for idx in "\${!VCF_SAMPLES[@]}"; do
        sample_name="\${VCF_SAMPLES[\$idx]}"
        if [[ -n "\${MIN_DEPTH_BY_SAMPLE[\$sample_name]:-}" && -n "\${MAX_DEPTH_BY_SAMPLE[\$sample_name]:-}" ]]; then
            FILTER_PARTS+=("(FMT/DP[\$idx]<\${MIN_DEPTH_BY_SAMPLE[\$sample_name]} | FMT/DP[\$idx]>\${MAX_DEPTH_BY_SAMPLE[\$sample_name]})")
            N_INTERSECTION=\$((N_INTERSECTION + 1))
        fi
    done

    if [ "\$N_INTERSECTION" -eq 0 ]; then
        echo "Sample ID mismatch between VCF samples and mosdepth thresholds" >&2
        echo "VCF samples:" >&2
        printf '%s\\n' "\${VCF_SAMPLES[@]}" >&2
        echo "Threshold samples:" >&2
        printf '%s\\n' "\${!MIN_DEPTH_BY_SAMPLE[@]}" | sort >&2
        exit 1
    fi

    FILTER_STRING="\$(printf ' | %s' "\${FILTER_PARTS[@]}")"
    FILTER_STRING="\${FILTER_STRING# | }"

    bcftools filter --threads ${task.cpus} -Oz -S . -e "\$FILTER_STRING" ${vcf_f} > ${vcf_f.baseName}.depth_masked.vcf.gz
    """
}
