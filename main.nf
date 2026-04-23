#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include {
    VAR_CALL_PAIRED
    VAR_CALL_SINGLE_END
    VAR_CALL_BAMS
} from './workflows/var_call'

def helpMessage() {
    log.info """
    Variant calling with Freebayes

    Usage:
      nextflow run var_call --analysis_mode paired --input samplesheet.csv --genome genome.fa --outdir results --species my_species --dataset_id my_run

    Cluster example (Conda):
      nextflow run var_call -profile conda,lsf -params-file params/afusca_params.json -work-dir data/workdir/var_call -resume

    Cluster example (Apptainer): IN PROGRESS
      nextflow run var_call -profile apptainer,lsf -params-file params/afusca_params.json --apptainer_container /path/to/var_call.sif -work-dir data/workdir/var_call -resume

    Required parameters:
      --analysis_mode         One of: paired, single_end, bams
      --genome                Reference genome FASTA
      --outdir                Output directory
      --species               Dataset-wide species label

    Mode-specific parameters:
      --input                 CSV or TSV samplesheet for paired, single_end, or bams mode
      --reads                 FASTQ glob for paired / single_end
      --bams                  Input BAM glob for bams mode
      --repeat_bed            Optional BED of repeat regions to exclude
      --dataset_id            Optional dataset/run label used for merged outputs
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
        return '	'
    }
    return ','
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

def bamSamplesheetChannel(samplesheet) {
    def sep = samplesheetSeparator(samplesheet)
    Channel
        .fromPath(samplesheet, checkIfExists: true)
        .splitCsv(header: true, sep: sep)
        .map { row ->
            if (!row.sample || !row.bam) {
                error "BAM samplesheet rows must contain sample and bam columns"
            }
            [ row.sample as String, file(row.bam) ]
        }
}

def validateParams() {
    if (params.help) {
        helpMessage()
        System.exit(0)
    }

    def required = ['analysis_mode', 'genome', 'outdir', 'species']
    def missing = required.findAll { !params[it] }
    if (missing) {
        error "Missing required parameter(s): ${missing.join(', ')}"
    }

    def validModes = ['paired', 'single_end', 'bams']
    if (!(params.analysis_mode in validModes)) {
        error "Invalid --analysis_mode '${params.analysis_mode}'. Choose one of: ${validModes.join(', ')}"
    }

    if (params.analysis_mode == 'bams' && !params.bams && !params.input) {
        error "Provide either --bams or --input when --analysis_mode is 'bams'"
    }

    if (params.analysis_mode != 'bams' && !params.reads && !params.input) {
        error "Provide either --input or --reads when --analysis_mode is '${params.analysis_mode}'"
    }

    if (params.analysis_mode == 'bams' && params.bams && params.input) {
        error "Use either --bams or --input for bams mode, not both"
    }

    if (workflow.profile?.tokenize(',')?.contains('apptainer') && !params.apptainer_container) {
        error "Provide --apptainer_container when using -profile apptainer"
    }
}

def logParameters() {
    log.info """
        V A R   C A L L
        ============================
        analysis_mode       : ${params.analysis_mode}
        genome              : ${params.genome}
        input               : ${params.input ?: 'N/A'}
        reads               : ${params.reads ?: 'N/A'}
        bams                : ${params.bams ?: 'N/A'}
        repeat_bed          : ${params.repeat_bed ?: 'N/A'}
        outdir              : ${params.outdir}
        species             : ${params.species}
        dataset_id          : ${params.dataset_id ?: 'N/A'}
        run_label           : ${params.dataset_id ?: params.species}
        apptainer_container : ${params.apptainer_container ?: 'N/A'}
        skip_trimming       : ${params.skip_trimming}
    """.stripIndent()
}

workflow {
    validateParams()
    logParameters()

    if (params.analysis_mode == 'paired') {
        read_pairs_ch = params.input ? pairedSamplesheetChannel(params.input) : Channel.fromFilePairs(params.reads, checkIfExists: true)
        VAR_CALL_PAIRED(params.genome, read_pairs_ch, params.repeat_bed, params.species, params.dataset_id ?: params.species, params.skip_trimming)
    }

    if (params.analysis_mode == 'single_end') {
        reads_ch = params.input ? singleEndSamplesheetChannel(params.input) : Channel.fromPath(params.reads, checkIfExists: true).map { read -> [read.baseName, read] }
        VAR_CALL_SINGLE_END(params.genome, reads_ch, params.repeat_bed, params.species, params.dataset_id ?: params.species)
    }

    if (params.analysis_mode == 'bams') {
        bam_ch = params.input ? bamSamplesheetChannel(params.input) : Channel.fromPath(params.bams, checkIfExists: true).map { bam -> [bam.baseName.tokenize('.')[0], bam] }
        VAR_CALL_BAMS(params.genome, bam_ch, params.repeat_bed, params.species, params.dataset_id ?: params.species)
    }
}
