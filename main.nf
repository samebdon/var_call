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

    Cluster example:
      nextflow run main.nf -profile conda,cluster -params-file params/afusca_params.json -work-dir data/workdir/var_call -resume

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

    Notes:
      Use -params-file for dataset-specific run settings.
      Use -work-dir to place the Nextflow working directory on cluster scratch or project storage.
      The pipeline sets MOSDEPTH_Q0-3 automatically for the mosdepth process.
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