#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include {
    VAR_CALL_PAIRED
    VAR_CALL_SINGLE_END
    VAR_CALL_ALIGNMENTS
} from './workflows/var_call'

def helpMessage() {
    log.info """
    Variant calling with Freebayes

    Usage:
      nextflow run var_call --analysis_mode paired --input samplesheet.csv --genome genome.fa --outdir results --species my_species --dataset_id my_run

    Cluster example (Conda YAML):
      nextflow run var_call -profile conda,lsf -params-file params/afusca_params.json -work-dir data/workdir/var_call -resume

    Cluster example (existing Conda env):
      nextflow run var_call -profile conda,lsf -params-file params/afusca_params.json --conda_env /path/to/existing/env -work-dir data/workdir/var_call -resume

    Cluster example (Apptainer): IN PROGRESS
      nextflow run var_call -profile apptainer,lsf -params-file params/afusca_params.json --apptainer_container /path/to/var_call.sif -work-dir data/workdir/var_call -resume

    Required parameters:
      --analysis_mode         One of: paired, single_end, alignments
      --genome                Reference genome FASTA
      --outdir                Output directory
      --species               Dataset-wide species label

    Mode-specific parameters:
      --input                 CSV or TSV samplesheet for paired, single_end, or alignments mode
      --reads                 FASTQ glob for paired / single_end
      --alignments            Glob path to BAM or CRAM input files when not using a samplesheet
      --bams                  Legacy alias for --alignments in alignments mode
      --alignment_format      Output alignment format for read-based modes: bam or cram
      --repeat_bed            Optional BED of repeat regions to exclude
      --dataset_id            Optional dataset/run label used for merged outputs
      --bam_rg_mode           Alignment RG policy for alignments mode: preserve or overwrite
      --conda_env             Optional path to an existing Conda environment to use with -profile conda
      --conda_spec            Optional environment spec file to use instead of params/var_call.yaml
      --apptainer_container   Path to a .sif image when using -profile apptainer
      --apptainer_cache_dir   Optional cache directory for Apptainer/Singularity pulls and metadata

    Useful flags:
      --skip_trimming         Skip fastp in paired-read workflows
      --help                  Show this help message

    """.stripIndent()
}

def samplesheetSeparator(samplesheet) {
    def name = samplesheet.toString().toLowerCase()
    if (name.endsWith('.tsv') || name.endsWith('.txt')) {
        return '\t'
    }
    return ','
}

def inferAlignmentFormat(pathLike) {
    def name = pathLike.toString().toLowerCase()
    if (name.endsWith('.cram')) {
        return 'cram'
    }
    if (name.endsWith('.bam')) {
        return 'bam'
    }
    error "Could not infer alignment format from '${pathLike}'. Expected a .bam or .cram file."
}

def pairedSamplesheetChannel(samplesheet) {
    def sep = samplesheetSeparator(samplesheet)
    Channel
        .fromPath(samplesheet, checkIfExists: true)
        .splitCsv(header: true, sep: sep)
        .map { row ->
            if (!row.sample || !row.fastq_1 || !row.fastq_2) {
                error "Paired-end samplesheet rows must contain sample, fastq_1, and fastq_2 columns"
            }
            [ row.sample as String, [ file(row.fastq_1), file(row.fastq_2) ] ]
        }
}

def singleEndSamplesheetChannel(samplesheet) {
    def sep = samplesheetSeparator(samplesheet)
    Channel
        .fromPath(samplesheet, checkIfExists: true)
        .splitCsv(header: true, sep: sep)
        .map { row ->
            if (!row.sample || !row.fastq_1) {
                error "Single-end samplesheet rows must contain sample and fastq_1 columns"
            }
            [ row.sample as String, file(row.fastq_1) ]
        }
}

def alignmentSamplesheetChannel(samplesheet) {
    def sep = samplesheetSeparator(samplesheet)
    Channel
        .fromPath(samplesheet, checkIfExists: true)
        .splitCsv(header: true, sep: sep)
        .map { row ->
            def sample = row.sample as String
            def alignmentPath = row.alignment ?: row.bam ?: row.cram
            if (!sample || !alignmentPath) {
                error "Alignment samplesheet rows must contain sample and one of: alignment, bam, or cram columns"
            }
            def format = row.format ? row.format.toString().toLowerCase() : inferAlignmentFormat(alignmentPath)
            if (!(format in ['bam', 'cram'])) {
                error "Alignment samplesheet format must be bam or cram for sample '${sample}'"
            }
            [ sample, file(alignmentPath), format ]
        }
}

def validateParams() {
    if (params.help) {
        helpMessage()
        System.exit(0)
    }

    def normalizedMode = params.analysis_mode == 'bams' ? 'alignments' : params.analysis_mode
    def required = ['genome', 'outdir', 'species']
    def missing = required.findAll { !params[it] }
    if (missing) {
        error "Missing required parameter(s): ${missing.join(', ')}"
    }

    def validModes = ['paired', 'single_end', 'alignments', 'bams']
    if (!(params.analysis_mode in validModes)) {
        error "Invalid --analysis_mode '${params.analysis_mode}'. Choose one of: paired, single_end, alignments"
    }

    if (normalizedMode == 'alignments' && !params.alignments && !params.bams && !params.input) {
        error "Provide one of --alignments, --bams, or --input when --analysis_mode is 'alignments'"
    }

    if (normalizedMode != 'alignments' && !params.reads && !params.input) {
        error "Provide either --input or --reads when --analysis_mode is '${normalizedMode}'"
    }

    if (normalizedMode == 'alignments' && params.input && (params.alignments || params.bams)) {
        error "Use either --input or an alignment glob (--alignments/--bams) for alignments mode, not both"
    }

    if (!(params.bam_rg_mode in ['preserve', 'overwrite'])) {
        error "Invalid --bam_rg_mode '${params.bam_rg_mode}'. Choose one of: preserve, overwrite"
    }

    if (!(params.alignment_format in ['bam', 'cram'])) {
        error "Invalid --alignment_format '${params.alignment_format}'. Choose one of: bam, cram"
    }

    if (workflow.profile?.tokenize(',')?.contains('apptainer') && !params.apptainer_container) {
        error "Provide --apptainer_container when using -profile apptainer"
    }
}

def logParameters() {
    def normalizedMode = params.analysis_mode == 'bams' ? 'alignments' : params.analysis_mode
    log.info """
        V A R   C A L L
        ============================
        analysis_mode       : ${normalizedMode}
        genome              : ${params.genome}
        input               : ${params.input ?: 'N/A'}
        reads               : ${params.reads ?: 'N/A'}
        alignments          : ${params.alignments ?: params.bams ?: 'N/A'}
        alignment_format    : ${params.alignment_format}
        repeat_bed          : ${params.repeat_bed ?: 'N/A'}
        outdir              : ${params.outdir}
        species             : ${params.species}
        dataset_id          : ${params.dataset_id ?: 'N/A'}
        run_label           : ${params.dataset_id ?: params.species}
        conda_env           : ${params.conda_env ?: 'N/A'}
        conda_spec          : ${params.conda_spec ?: 'N/A'}
        bam_rg_mode         : ${params.bam_rg_mode}
        apptainer_container : ${params.apptainer_container ?: 'N/A'}
        skip_trimming       : ${params.skip_trimming}
    """.stripIndent()
}

workflow {
    validateParams()
    logParameters()

    def normalizedMode = params.analysis_mode == 'bams' ? 'alignments' : params.analysis_mode

    if (normalizedMode == 'paired') {
        read_pairs_ch = params.input ? pairedSamplesheetChannel(params.input) : Channel.fromFilePairs(params.reads, checkIfExists: true)
        VAR_CALL_PAIRED(params.genome, read_pairs_ch, params.repeat_bed, params.species, params.dataset_id ?: params.species, params.skip_trimming, params.alignment_format)
    }

    if (normalizedMode == 'single_end') {
        reads_ch = params.input ? singleEndSamplesheetChannel(params.input) : Channel.fromPath(params.reads, checkIfExists: true).map { read -> [read.baseName, read] }
        VAR_CALL_SINGLE_END(params.genome, reads_ch, params.repeat_bed, params.species, params.dataset_id ?: params.species, params.alignment_format)
    }

    if (normalizedMode == 'alignments') {
        alignment_glob = params.alignments ?: params.bams
        alignment_ch = params.input ? alignmentSamplesheetChannel(params.input) : Channel.fromPath(alignment_glob, checkIfExists: true).map { alignment -> [alignment.baseName.tokenize('.')[0], alignment, inferAlignmentFormat(alignment)] }
        VAR_CALL_ALIGNMENTS(params.genome, alignment_ch, params.repeat_bed, params.species, params.dataset_id ?: params.species)
    }
}
