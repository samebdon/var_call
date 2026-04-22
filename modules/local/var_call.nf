process TRIM_READS {
    tag "$meta"
    publishDir "${params.outdir}/fastq", mode: 'copy'

    cpus 4
    memory '4 GB'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path('fastp/*.fastp.fastq.gz')

    script:
    """
    mkdir -p fastp
    fastp \
        -i ${reads[0]} \
        -I ${reads[1]} \
        -o fastp/${meta}.1.fastp.fastq.gz \
        -O fastp/${meta}.2.fastp.fastq.gz \
        --length_required 33 \
        --cut_front \
        --cut_tail \
        --cut_mean_quality 20 \
        --thread ${task.cpus}
    """
}

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

process BWA_MEM {
    tag "$meta"

    memory '8 GB'

    input:
    path(genome_f)
    path(genome_index)
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("bwamem/${meta}.${genome_f.baseName}.bam")

    script:
    """
    mkdir -p bwamem
    bwa mem \
        -t ${task.cpus} \
        -R "@RG\\tID:${meta}\\tSM:${meta}\\tPL:ILLUMINA\\tPU:${meta}\\tLB:${meta}\\tDS:${meta}" \
        ${genome_f} \
        ${reads[0]} \
        ${reads[1]} | \
    sambamba view -t ${task.cpus} -S -f bam /dev/stdin > bwamem/${meta}.${genome_f.baseName}.bam
    """
}

process BWA_MEM_SE {
    tag "$meta"

    memory '8 GB'

    input:
    path(genome_f)
    path(genome_index)
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("bwamem/${meta}.${genome_f.baseName}.bam")

    script:
    """
    mkdir -p bwamem
    bwa mem \
        -t ${task.cpus} \
        -R "@RG\\tID:${meta}\\tSM:${meta}\\tPL:ILLUMINA\\tPU:${meta}\\tLB:${meta}\\tDS:${meta}" \
        ${genome_f} \
        ${reads} | \
    sambamba view -t ${task.cpus} -S -f bam /dev/stdin > bwamem/${meta}.${genome_f.baseName}.bam
    """
}

process ADD_RGS {
    tag "$meta"
    publishDir "${params.outdir}/bams", mode: 'copy'

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("${meta}.RG.bam")

    script:
    """
    samtools addreplacerg \
        -r "ID:${meta}\\tSM:${meta}\\tLB:${meta}\\tPL:${meta}\\tPU:${meta}" \
        -o ${meta}.RG.bam \
        ${bam}
    """
}

process SORT_BAM_SAMBAMBA {
    tag "$meta"
    publishDir "${params.outdir}/bams", mode: 'copy'

    memory '8 GB'

    input:
    tuple val(meta), path(bam_f)

    output:
    tuple val(meta), path("${bam_f.baseName}.coord_sorted.bam")

    script:
    def avail_mem = (task.memory.mega * 1).intValue()
    """
    sambamba sort -t ${task.cpus} -m ${avail_mem}MB -o ${bam_f.baseName}.coord_sorted.bam ${bam_f}
    """
}

process MARK_DUPES_SAMBAMBA {
    tag "$meta"

    memory '4 GB'

    input:
    tuple val(meta), path(bam_f)

    output:
    tuple val(meta), path("${bam_f.baseName}.deduped.bam"), emit: meta_bam
    path("${bam_f.baseName}.deduped.bam"), emit: bam_only

    script:
    """
    sambamba markdup -t ${task.cpus} ${bam_f} ${bam_f.baseName}.deduped.bam
    """
}

process INDEX_BAM_SAMBAMBA {
    tag "$meta"

    input:
    tuple val(meta), path(bam_f)

    output:
    tuple val(meta), path("${bam_f}.bai")

    script:
    """
    sambamba index -t ${task.cpus} ${bam_f}
    """
}

process MOSDEPTH_CALLABLE {
    tag "$meta"

    memory '15 GB'

    input:
    tuple val(meta), path(bam_f), path(bam_index)
    val(min_depth)

    output:
    path("mosdepth/${bam_f.baseName}.callable.bed")

    script:
    """
    mkdir -p mosdepth
    mosdepth --fast-mode -t ${task.cpus} tmp ${bam_f}
    MAX_DEPTH="\$(max_depth.py -b tmp.per-base.bed.gz)"
    mosdepth -t ${task.cpus} -n --quantize 0:1:${min_depth}:\${MAX_DEPTH}: ${meta} ${bam_f}
    zcat ${meta}.quantized.bed.gz | grep 'CALLABLE' > mosdepth/${bam_f.baseName}.callable.bed
    """
}

process INTERSECT_BEDS {
    tag "$species"
    publishDir "${params.outdir}/bed", mode: 'copy'

    memory '4 GB'

    input:
    path(beds, stageAs: 'inputs/*')
    path(repeat_bed)
    path(genome_index)
    val(species)

    output:
    tuple val(species), path("${species}.callable.all.bed"), emit: all
    tuple val(species), path("${species}.callable.freebayes.norepeats.bed"), emit: freebayes

    script:
    """
    N_FILES="\$(ls inputs/*.bed | wc -l)"
    bedtools multiinter -i inputs/*.bed | cut -f1-5 | bedtools sort -faidx ${genome_index} > ${species}.callable.all.bed
    awk -v var=\$N_FILES '\$4==var' ${species}.callable.all.bed | cut -f1-3 > ${species}.callable.freebayes.bed
    bedtools subtract -a ${species}.callable.freebayes.bed -b ${repeat_bed} | \
        bedtools sort -faidx ${genome_index} | \
        bedtools merge > ${species}.callable.freebayes.norepeats.bed
    """
}

process INTERSECT_BEDS_NO_REPEATS {
    tag "$species"
    publishDir "${params.outdir}/bed", mode: 'copy'

    memory '4 GB'

    input:
    path(beds, stageAs: 'inputs/*')
    path(genome_index)
    val(species)

    output:
    tuple val(species), path("${species}.callable.all.bed"), emit: all
    tuple val(species), path("${species}.callable.freebayes.norepeats.bed"), emit: freebayes

    script:
    """
    N_FILES="\$(ls inputs/*.bed | wc -l)"
    bedtools multiinter -i inputs/*.bed | cut -f1-5 | bedtools sort -faidx ${genome_index} > ${species}.callable.all.bed
    awk -v var=\$N_FILES '\$4==var' ${species}.callable.all.bed | cut -f1-3 | \
        bedtools sort -faidx ${genome_index} | \
        bedtools merge > ${species}.callable.freebayes.norepeats.bed
    """
}

process INTERSECT_BED {
    tag "$species"
    publishDir "${params.outdir}/bed", mode: 'copy'

    memory '4 GB'

    input:
    path(bed)
    path(repeat_bed)
    path(genome_index)
    val(species)

    output:
    tuple val(species), path("${species}.callable.freebayes.norepeats.bed")

    script:
    """
    bedtools subtract -a ${bed} -b ${repeat_bed} | \
        bedtools sort -faidx ${genome_index} | \
        bedtools merge > ${species}.callable.freebayes.norepeats.bed
    """
}

process INTERSECT_BED_NO_REPEATS {
    tag "$species"
    publishDir "${params.outdir}/bed", mode: 'copy'

    memory '4 GB'

    input:
    path(bed)
    path(genome_index)
    val(species)

    output:
    tuple val(species), path("${species}.callable.freebayes.norepeats.bed")

    script:
    """
    bedtools sort -faidx ${genome_index} -i ${bed} | \
        bedtools merge > ${species}.callable.freebayes.norepeats.bed
    """
}

process SAMBAMBA_MERGE {
    tag "$species"

    memory '8 GB'

    input:
    path(bams)
    val(species)

    output:
    tuple val(species), path("${species}.bam"), path("${species}.bam.bai")

    script:
    """
    sambamba merge -t ${task.cpus} ${species}.bam ${bams.join(' ')}
    sambamba index -t ${task.cpus} ${species}.bam
    """
}

process FREEBAYES {
    tag "$meta"

    memory '20 GB'
    cpus 1

    input:
    path(genome_f)
    path(genome_index)
    tuple val(meta), path(bam_f), path(bam_index)
    tuple val(species), path(bed_f)

    output:
    tuple val(species), path("${species}.vcf")

    script:
    """
    freebayes -f ${genome_f} -b ${bam_f} -t ${bed_f} --strict-vcf -v ${species}.vcf -T 0.01 -k -w -j -E 1
    """
}

process BCFTOOLS_FILTER {
    tag "$species"
    publishDir "${params.outdir}/vcf", mode: 'copy'

    input:
    path(genome)
    tuple val(species), path(vcf_f)

    output:
    tuple val(species), path("${vcf_f.baseName}.soft_filtered.vcf.gz")

    script:
    """
    bcftools norm --threads ${task.cpus} -Ov -f ${genome} ${vcf_f} | \
    vcfallelicprimitives --keep-info --keep-geno -t decomposed | \
    bcftools +fill-tags --threads ${task.cpus} -Oz -- -t AN,AC,F_MISSING | \
    bcftools filter --threads ${task.cpus} -Oz -s Qual -m+ -e 'QUAL<10' | \
    bcftools filter --threads ${task.cpus} -Oz -s Balance -m+ -e 'RPL<1 | RPR<1 | SAF<1 | SAR<1' | \
    bcftools filter --threads ${task.cpus} -Oz -m+ -s+ --SnpGap 2 | \
    bcftools filter --threads ${task.cpus} -Oz -e 'TYPE!="snp"' -s NonSnp -m+ > ${vcf_f.baseName}.soft_filtered.vcf.gz
    """
}

process GENERATE_FAIL_BED {
    tag "$species"
    publishDir "${params.outdir}/bed", mode: 'copy'

    memory '4 GB'

    input:
    tuple val(species), path(vcf_f)
    path(genome_index)

    output:
    tuple val(species), path("${species}.vcf_filter_fails.bed")

    script:
    """
    bcftools view --threads ${task.cpus} -H -i "FILTER!='PASS'" ${vcf_f} | \
    perl -lane '\$pad=0; print(\$F[0]."\\t".(\$F[1]-1)."\\t".((\$F[1]-1)+length(\$F[3]))."\\t".\$F[6])' | \
    bedtools sort -faidx ${genome_index} | \
    bedtools merge > ${species}.vcf_filter_fails.bed
    """
}

process GENERATE_PASS_VCF {
    tag "$species"

    input:
    tuple val(species), path(vcf_f)

    output:
    tuple val(species), path("${vcf_f.baseName}.hard_filtered.vcf.gz")

    script:
    """
    bcftools view --threads ${task.cpus} -Oz -f "PASS" ${vcf_f} > ${vcf_f.baseName}.hard_filtered.vcf.gz
    """
}

process BEDTOOLS_SUBTRACT {
    tag "$species"
    publishDir "${params.outdir}/bed", mode: 'copy'

    cpus 1

    input:
    tuple val(species), path(a_bed)
    tuple val(species), path(b_bed)
    path(genome_index)

    output:
    tuple val(species), path("${species}.callable.bed")

    script:
    """
    bedtools subtract -a ${a_bed} -b ${b_bed} | \
        bedtools sort -faidx ${genome_index} | \
        bedtools merge > ${species}.callable.bed
    """
}

process BCFTOOLS_SORT {
    tag "$species"
    publishDir "${params.outdir}/vcf", mode: 'copy'

    cpus 1

    input:
    tuple val(species), path(vcf_f)

    output:
    tuple val(species), path("${species}.hard_filtered.sorted.vcf.gz")

    script:
    """
    bcftools sort -Oz ${vcf_f} > ${species}.hard_filtered.sorted.vcf.gz
    """
}

process BCFTOOLS_INDEX {
    tag "$meta"
    publishDir "${params.outdir}/vcf", mode: 'copy'

    cpus 1

    input:
    tuple val(meta), path(vcf_f)

    output:
    tuple val(meta), path("${vcf_f}.csi")

    script:
    """
    bcftools index -c ${vcf_f} -o ${vcf_f}.csi
    """
}
