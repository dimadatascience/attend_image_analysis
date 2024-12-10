process stitching{
    cpus 1
    maxRetries = 3
    memory { 20.GB }
    conda '/hpcnfs/scratch/DIMA/chiodin/miniconda3'
    
    input:
        tuple val(patient_id), path(moving), path(fixed), path(crops)
    output:
        tuple val(patient_id), path(fixed), path("registered_${moving}")
 
    script:
    """
        stitching.py \
            --crops $crops \
            --crop_size ${params.crop_size_diffeo} \
            --overlap_size ${params.overlap_size_diffeo} \
            --original_file $moving 
    """
}
