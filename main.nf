#!/usr/bin/env nextflow

nextflow.enable.dsl=2

WorkflowMain.initialise(workflow, params, log)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PIPELINE WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { split_channels } from './modules/local/split_channels/main.nf'
include { crop_channels } from './modules/local/crop_channels/main.nf'
include { reconstruct_channels } from './modules/local/reconstruct_channels/main.nf'
include { collect_channels } from './modules/local/collect_channels/main.nf'
include { get_padding } from './modules/local/image_padding/main.nf'
include { get_metadata } from './modules/local/image_metadata/main.nf'
include { apply_padding } from './modules/local/image_padding/main.nf'
include { affine } from './modules/local/image_registration/main.nf' 
include { diffeomorphic} from './modules/local/image_registration/main.nf'
include { stitching } from './modules/local/image_stitching/main.nf'
include { stacking } from './modules/local/image_stacking/main.nf'
include { conversion } from './modules/local/image_conversion/main.nf'
include { quality_control } from './modules/local/quality_control/main.nf'
include { check_new_channels } from './modules/local/check_new_channels/main.nf'
include { pipex_preprocessing } from './modules/local/preprocessing/main.nf'
include { pipex_membrane_segmentation } from './modules/local/segmentation/main.nf'
include { pipex_nuclei_segmentation } from './modules/local/segmentation/main.nf'
include { preprocess_dapi } from './modules/local/segmentation/main.nf'
include { deduplicate_files } from './modules/local/deduplicate_files/main.nf'
include { create_membrane_channel } from './modules/local/create_membrane_channel/main.nf'
include { segmentation_quality_control as nuclei_segmentation_quality_control } from './modules/local/quality_control/main.nf'
include { segmentation_quality_control as membrane_segmentation_quality_control } from './modules/local/quality_control/main.nf'


def parse_conf_csv(csv_file_path) {
    channel
        .fromPath(csv_file_path)
        .splitCsv(header: true)
        .map { row ->
            return [
                row.membrane_diameter,
                row.membrane_compactness,
                row.nuclei_expansion
            ]
        }
}


def parse_csv(csv_file_path) {
    channel
        .fromPath(csv_file_path)
        .splitCsv(header: true)
        .map { row ->
            return [
                row.patient_id,      // Patient identifier
                row.image,           // Path to image
            ]
        }
}


workflow {

    conf_ch = parse_conf_csv(params.conf_file)    

    // conf_ch.view()
    
    membrane_diameter_ch = conf_ch.map { it ->
        def membrane_diameter = it[0]
        return [membrane_diameter]
    }

    membrane_compactness_ch = conf_ch.map { it ->
        def membrane_compactness = it[1]
        return [membrane_compactness]
    }

    nuclei_expansion_ch = conf_ch.map { it ->
        def nuclei_expansion = it[2]
        return [nuclei_expansion]
    }

    // membr_diam_ch = parse_csv_membrane(params.membrane_diameter)
    // nuclei_exp_ch = parse_csv_nuclei(params.nuclei_expansion)

    parsed_csv_ch = parse_csv(params.input)

    create_membrane_channel_input = parsed_csv_ch.groupTuple()

    // create_membrane_channel_input.view()

    create_membrane_channel(create_membrane_channel_input)

    // create_membrane_channel.out.view()

    preprocess_dapi_input = create_membrane_channel.out.map{ it -> 
        def patient_id = it[0]
        def markers = it[1]
        def membrane_marker = it[2]        

        return [patient_id, [markers, membrane_marker].flatten()]
    }

    preprocess_dapi(preprocess_dapi_input)

    pipex_segmentation_input = preprocess_dapi.out.combine(membrane_diameter_ch).combine(membrane_compactness_ch).combine(nuclei_expansion_ch)

    // pipex_segmentation_input.view()

    pipex_membrane_segmentation(pipex_segmentation_input)
    pipex_nuclei_segmentation(preprocess_dapi.out)

    membrane_segmentation_quality_control_input = pipex_membrane_segmentation.out.map { it ->
            def patient_id = it[0]
            def dapi = it[1]
            def cell_data = it[2]
            def quality_control = it[3]
            def segmentation_binary_mask  = it[4]
            def segmentation_data  = it[5]
            def segmentation_mask  = it[6]
            def segmentation_mask_show = it[7]
            def type = 'membrane'
            def membrane_diameter = it[8]
            def membrane_compactness = it[9]
            def nuclei_expansion = it[10]

            return [patient_id, dapi, segmentation_mask, type, membrane_diameter, membrane_compactness, nuclei_expansion]
    }

    nuclei_segmentation_quality_control_input =  pipex_nuclei_segmentation.out.map { it ->
            def patient_id = it[0]
            def dapi = it[1]
            def cell_data = it[2]
            def quality_control = it[3]
            def segmentation_binary_mask  = it[4]
            def segmentation_data  = it[5]
            def segmentation_mask  = it[6]
            def segmentation_mask_show = it[7]
            def type = 'nuclei'
            def membrane_diameter = it[8]
            def membrane_compactness = it[9]
            def nuclei_expansion = it[10]

            return [patient_id, dapi, segmentation_mask, type, membrane_diameter, membrane_compactness, nuclei_expansion]
    } 


    membrane_segmentation_quality_control(membrane_segmentation_quality_control_input)
    nuclei_segmentation_quality_control(nuclei_segmentation_quality_control_input)
}
