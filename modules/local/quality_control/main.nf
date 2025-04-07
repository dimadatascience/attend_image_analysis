process quality_control{
    cpus 1
    maxRetries = 3
    memory { task.memory + 10 * task.attempt}
    publishDir "${params.outdir}/${patient_id}/registration/quality_control", mode: 'copy', pattern: "QC_*"
    tag "quality_control"
    
    input:
        tuple val(patient_id), path(moving), path(fixed), path(dapi_crops), path(crops)
    output:
        tuple val(patient_id), path("QC*")
 
    script:
    """
    echo "\$(date) Memory allocated to process "quality_control": ${task.memory}" >> ${params.log_file}

        quality_control.py \
            --patient_id $patient_id \
            --dapi_crops $dapi_crops \
            --crops $crops \
            --crop_size ${params.crop_size_diffeo} \
            --overlap_size ${params.overlap_size_diffeo} \
            --fixed $fixed \
            --moving $moving \
            --downscale_factor ${params.downscale_factor} \
            --log_file "${params.log_file}"
    """
}

process segmentation_quality_control{
    cpus 1
    maxRetries = 3
    // memory { 70.GB }
    publishDir "${params.outdir}/${patient_id}/${patient_id}_ne${nuclei_expansion}_md${membrane_diameter}_mc${membrane_compactness}/segmentation/quality_control/${type}", mode: 'copy', pattern: "QC_*"
    tag "segmentation_quality_control"
    
    input:
        tuple val(patient_id), 
            path(dapi_image),
            path(segmentation_mask),
            val(type),
            val(membrane_diameter), 
            val(membrane_compactness),
            val(nuclei_expansion)

    output:
        tuple val(patient_id), path("QC*")
 
    script:
    """
    echo "\$(date) Memory allocated to process "segmentation_quality_control": ${task.memory}" >> ${params.log_file}
    if [ "${type}" == "membrane" ]; then
        echo "\$(date) Segmentation type: membrane" >> ${params.log_file}
        quality_control_segmentation.py \
            --patient_id $patient_id \
            --dapi_image $dapi_image \
            --segmentation_mask $segmentation_mask \
            --membrane_diameter $membrane_diameter \
            --membrane_compactness $membrane_compactness \
            --nuclei_expansion $nuclei_expansion \
            --log_file "${params.log_file}"
    elif [ "${type}" == "nuclei" ]; then
        echo "\$(date) Segmentation type: nuclei" >> ${params.log_file}
        quality_control_segmentation.py \
            --patient_id $patient_id \
            --dapi_image $dapi_image \
            --segmentation_mask $segmentation_mask \
            --log_file "${params.log_file}"
    else
        echo "\$(date) Segmentation type: unknown" >> ${params.log_file}
    fi
        
    """
}