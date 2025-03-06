#!/usr/bin/env nextflow

nextflow.enable.dsl=2

WorkflowMain.initialise(workflow, params, log)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PIPELINE WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { pipex_preprocessing } from './modules/local/tmp_preproc/main.nf'
include { pipex_segmentation } from './modules/local/tmp_seg/main.nf'

def parse_csv(csv_file_path) {
    channel
        .fromPath(csv_file_path)
        .splitCsv(header: true)
        .map { row ->
            return [
                row.image,           // Path to image
            ]
        }
}

workflow {
    input_ch = parse_csv(params.input)
    grouped_input = input_ch.groupTuple()
    pipex_preprocessing(grouped_input)
    pipex_segmentation(pipex_preprocessing.out)
}
