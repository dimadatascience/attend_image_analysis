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

workflow preprocessing {
    take: 
    input_ch

    main: 
    preprocessed = pipex_preprocessing(input_ch)

    emit:
    preprocessed
}

workflow {
    input_ch = parse_csv(params.input).collect()

    // input_ch.view()

    if (params.preprocessing) {
        updated_input_ch = preprocessing(input_ch)
    } else {
        updated_input_ch = input_ch
    }

    updated_input_ch.view()
    
    pipex_segmentation(updated_input_ch)
}
