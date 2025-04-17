process create_membrane_channel {
    //cpus 2
    memory { 70.GB }
    tag "create_membrane_channel"
    
    input:
    tuple val(patient_id), path(tiff)

    output:
    tuple val(patient_id), path(tiff), path("*MEMBRANE.tiff")

    script:
    """
    create_membrane_channel.py \
        --patient_id $patient_id \
        --channels $tiff \
        --log_file ${params.log_file} 
    """
}
