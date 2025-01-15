/*
    Register images with respect to a predefined fixed image
*/

process affine{
    cpus 2
    maxRetries = 3
    // memory { 70.GB }
    memory { 5.GB }
    conda '/hpcnfs/scratch/DIMA/chiodin/miniconda3'
    input:
        tuple val(patient_id), path(moving), path(fixed), path(channels_to_register)
    output:
        tuple val(patient_id), path(moving), path(fixed), path("*pkl"), path(channels_to_register)
 
    script:
    """
        affine.py \
            --patient_id $patient_id \
            --channels_to_register $channels_to_register \
            --moving_image $moving \
            --fixed_image $fixed \
            --crop_size_affine ${params.crop_size_affine} \
            --overlap_size_affine ${params.overlap_size_affine} \
            --crop_size_diffeo ${params.crop_size_diffeo} \
            --overlap_size_diffeo ${params.overlap_size_diffeo}
    """
}
 

process diffeomorphic{
    cpus 1
    maxRetries = 3
    memory { 2.GB * task.attempt }
    conda '/hpcnfs/scratch/DIMA/chiodin/miniconda3'
    input:
        tuple val(patient_id), path(moving), path(fixed), path(crop), path(channels_to_register)
    output:
        tuple val(patient_id), path(moving), path(fixed), path("qc*"), path("registered*"), path(channels_to_register)
 
    script:
    """
        diffeomorphic.py \
            --channels_to_register $channels_to_register \
            --crop_image $crop \
            --moving_image $moving
    """
}