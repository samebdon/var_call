#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include {
    VAR_CALL_PAIRED
    VAR_CALL_SINGLE_PAIRED
    VAR_CALL_SINGLE_END
    VAR_CALL_BAMS
} from './workflows/var_call'

def helpMessage() {
    log.info """
    nf-core style learning pipeline: var_call

    Usage:
      nextflow run main.nf --analysis_mode paired --input samplesheet.csv --genome genome.fa --genome_index genome.fa.fai --outdir results --species my_species --dataset_id my_run

    Required parameters:
      --analysis_mode         One of: paired, single_paired, single_end, bams
      --genome                Reference genome FASTA
      --genome_index          FASTA index (.fai)
      --outdir                Output directory
      --species               Dataset-wide species label

    Mode-specific parameters:
      --input                 CSV samplesheet for FASTQ-based modes
      --reads                 Legacy FASTQ glob for paired / single_paired / single_end
      --bams                  Input BAM glob for bams mode
      --repeat_bed            Optional BED of repeat regions to exclude
      --dataset_id            Optional dataset/run label used for merged outputs
    Useful flags:
      --skip_trimming         Skip fastp in paired-read modes
      --help                  Show this help message
    """.stripIndent()
}

def pairedSamplesheetChannel(samplesheet) {
    Channel
        .fromPath(samplesheet, checkIfExists: true)
        .splitCsv(header: true)
        .map { row ->
            if (!row.sample || !row.fastq_1 || !row.fastq_2) {
                error "Paired-end samplesheet rows must contain sample, fastq_1, and fastq_2 columns"
            }
            [ row.sample as String, [ file(row.fastq_1), file(row.fastq_2) ] ]
        }
}

def singleEndSamplesheetChannel(samplesheet) {
    Channel
        .fromPath(samplesheet, checkIfExists: true)
        .splitCsv(header: true)
        .map { row ->
            if (!row.sample || !row.fastq_1) {
                error "Single-end samplesheet rows must contain sample and fastq_1 columns"
            }
            [ row.sample as String, file(row.fastq_1) ]
        }
}

def validateParams() {
    if (params.help) {
        helpMessage()
        System.exit(0)
    }

    def required = ['analysis_mode', 'genome', 'genome_index', 'outdir', 'species']
    def missing = required.findAll { !params[it] }
    if (missing) {
        error "Missing required parameter(s): ${missing.join(', ')}"
    }

    def validModes = ['paired', 'single_paired', 'single_end', 'bams']
    if (!(params.analysis_mode in validModes)) {
        error "Invalid --analysis_mode '${params.analysis_mode}'. Choose one of: ${validModes.join(', ')}"
    }

    if (params.analysis_mode == 'bams' && !params.bams) {
        error "Parameter --bams is required when --analysis_mode is 'bams'"
    }

    if (params.analysis_mode != 'bams' && !params.reads && !params.input) {
        error "Provide either --input or --reads when --analysis_mode is '${params.analysis_mode}'"
    }

    if (params.analysis_mode == 'bams' && params.input) {
        error "Parameter --input is only supported for FASTQ-based analysis modes"
    }
}

def logParameters() {
    log.info """
        V A R   C A L L
        ============================
        analysis_mode : ${params.analysis_mode}
        genome        : ${params.genome}
        genome_index  : ${params.genome_index}
        input         : ${params.input ?: 'N/A'}
        reads         : ${params.reads ?: 'N/A'}
        bams          : ${params.bams ?: 'N/A'}
        repeat_bed    : ${params.repeat_bed ?: 'N/A'}
        outdir        : ${params.outdir}
        species       : ${params.species}
        dataset_id    : ${params.dataset_id ?: 'N/A'}
        run_label     : ${params.dataset_id ?: params.species}
        skip_trimming : ${params.skip_trimming}
    """.stripIndent()
}

workflow {
    validateParams()
    logParameters()

    if (params.analysis_mode == 'paired') {
        read_pairs_ch = params.input ? pairedSamplesheetChannel(params.input) : Channel.fromFilePairs(params.reads, checkIfExists: true)
        VAR_CALL_PAIRED(params.genome, params.genome_index, read_pairs_ch, params.repeat_bed, params.species, params.dataset_id ?: params.species, params.skip_trimming)
    }

    if (params.analysis_mode == 'single_paired') {
        read_pairs_ch = params.input ? pairedSamplesheetChannel(params.input) : Channel.fromFilePairs(params.reads, checkIfExists: true)
        VAR_CALL_SINGLE_PAIRED(params.genome, params.genome_index, read_pairs_ch, params.repeat_bed, params.species, params.dataset_id ?: params.species, params.skip_trimming)
    }

    if (params.analysis_mode == 'single_end') {
        reads_ch = params.input ? singleEndSamplesheetChannel(params.input) : Channel.fromPath(params.reads, checkIfExists: true).map { read -> [read.baseName, read] }
        VAR_CALL_SINGLE_END(params.genome, params.genome_index, reads_ch, params.repeat_bed, params.species, params.dataset_id ?: params.species)
    }

    if (params.analysis_mode == 'bams') {
        bam_ch = Channel.fromPath(params.bams, checkIfExists: true)
        VAR_CALL_BAMS(params.genome, params.genome_index, bam_ch, params.repeat_bed, params.species, params.dataset_id ?: params.species)
    }
}
