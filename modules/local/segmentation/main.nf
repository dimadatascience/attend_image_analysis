process preprocess_dapi {
    // cpus 5
    //memory { task.memory + 10 * task.attempt}
    
    input:
    tuple val(patient_id), path(tiff)

    output:
    tuple val(patient_id), path("*tiff")

    script:
    """
    dapi_preprocessing.py \
        --patient_id $patient_id \
        --images $tiff \
        --log_file ${params.log_file} 
    """
}


process pipex_membrane_segmentation {
    // cpus 5
    memory { 70.GB }
    publishDir "${params.outdir}/${patient_id}/${patient_id}_ne${nuclei_expansion}_md${membrane_diameter}_mc${membrane_compactness}/segmentation/membrane/", mode: 'copy'
    tag "pipex_segmentation"
    container "docker://yinxiu/pipex:latest"
    // container "/hpcnfs/scratch/DIMA/chiodin/tests/segmentation_tests/yinxiu-pipex-latest.img"
    
    input:
    tuple val(patient_id), path(tiff), val(membrane_diameter), val(membrane_compactness), val(nuclei_expansion)
    output:
    tuple val(patient_id), 
        path("membrane_segmentation_${patient_id}_ne${nuclei_expansion}_md${membrane_diameter}_mc${membrane_compactness}/*DAPI.tiff"),
        path("membrane_segmentation_${patient_id}_ne${nuclei_expansion}_md${membrane_diameter}_mc${membrane_compactness}/*MEMBRANE.tiff"),
        path("membrane_segmentation_${patient_id}_ne${nuclei_expansion}_md${membrane_diameter}_mc${membrane_compactness}/analysis/cell_data.csv"), 
        path("membrane_segmentation_${patient_id}_ne${nuclei_expansion}_md${membrane_diameter}_mc${membrane_compactness}/analysis/quality_control"),
        path("membrane_segmentation_${patient_id}_ne${nuclei_expansion}_md${membrane_diameter}_mc${membrane_compactness}/analysis/segmentation_binary_mask.tif"), 
        path("membrane_segmentation_${patient_id}_ne${nuclei_expansion}_md${membrane_diameter}_mc${membrane_compactness}/analysis/segmentation_data.npy"), 
        path("membrane_segmentation_${patient_id}_ne${nuclei_expansion}_md${membrane_diameter}_mc${membrane_compactness}/analysis/segmentation_mask.tif"), 
        path("membrane_segmentation_${patient_id}_ne${nuclei_expansion}_md${membrane_diameter}_mc${membrane_compactness}/analysis/segmentation_mask_show.jpg"),
        val(membrane_diameter),
        val(membrane_compactness), 
        val(nuclei_expansion)

    script:
    """
    export PIPEX_MAX_RESOLUTION=90000

    echo "\$(date) Segmentation input files:" >> ${params.log_file}

    mkdir -p ./membrane_segmentation_${patient_id}_ne${nuclei_expansion}_md${membrane_diameter}_mc${membrane_compactness}

    channels=""
    for file in $tiff; do
        chname=`basename \$file | sed 's/.tiff//g' | sed 's/prep_registered_//g' | cut -d'_' -f2-`
        channels+=" \$chname"

        cp \$file ./membrane_segmentation_${patient_id}_ne${nuclei_expansion}_md${membrane_diameter}_mc${membrane_compactness}
    done
    
    channels=`echo \$channels | sed 's/ /,/g'`
    echo "\$(date): pipex_segmentation: Channels to be quantified: \$channels" >> ${params.log_file}

    echo "\$(date) Performing image segmentation..." >> ${params.log_file}
    

    ##############################################
    ##############################################
    ##############################################
    # Segmentation step

    python -u -W ignore /pipex/segmentation.py \
        -data=./membrane_segmentation_${patient_id}_ne${nuclei_expansion}_md${membrane_diameter}_mc${membrane_compactness} \
        -measure_markers=\$channels \
        -nuclei_marker=DAPI \
        -nuclei_definition=0.5 \
        -nuclei_closeness=0.5 \
        -nuclei_diameter=5 \
        -nuclei_expansion=${nuclei_expansion} \
        -membrane_marker=MEMBRANE \
        -membrane_diameter=${membrane_diameter} \
        -membrane_compactness=${membrane_compactness}

    echo "\$(date) Image segmentation done." >> ${params.log_file}
    """
}


process pipex_nuclei_segmentation {
    //cpus 2
    //memory { task.memory + 10 * task.attempt}
    memory { 70.GB }
    publishDir "${params.outdir}/${patient_id}/segmentation/nuclei/", mode: 'copy'
    tag "pipex_segmentation"
    container "docker://yinxiu/pipex:latest"
    // container "/hpcnfs/scratch/DIMA/chiodin/tests/segmentation_tests/yinxiu-pipex-latest.img"
    
    input:
    tuple val(patient_id), path(tiff)

    output:
    tuple val(patient_id), 
        path("nuclei_segmentation/*DAPI.tiff"),
        path("nuclei_segmentation/analysis/cell_data.csv"), 
        path("nuclei_segmentation/analysis/quality_control"),
        path("nuclei_segmentation/analysis/segmentation_binary_mask.tif"), 
        path("nuclei_segmentation/analysis/segmentation_data.npy"), 
        path("nuclei_segmentation/analysis/segmentation_mask.tif"), 
        path("nuclei_segmentation/analysis/segmentation_mask_show.jpg"),
        val(""), 
        val(""),
        val("")

    script:
    """
    export PIPEX_MAX_RESOLUTION=90000

    echo "\$(date) Segmentation input files:" >> ${params.log_file}

    mkdir -p ./nuclei_segmentation

    channels=""
    for file in $tiff; do
        chname=`basename \$file | sed 's/.tiff//g' | sed 's/prep_registered_//g' | cut -d'_' -f2-`
        channels+=" \$chname"

        cp \$file ./nuclei_segmentation
    done
    
    channels=`echo \$channels | sed 's/ /,/g'`
    echo "\$(date): pipex_segmentation: Channels to be quantified: \$channels" >> ${params.log_file}

    echo "\$(date) Performing image segmentation..." >> ${params.log_file}
    

    ##############################################
    ##############################################
    ##############################################
    # Segmentation step

    python -u -W ignore /pipex/segmentation.py \
        -data=./nuclei_segmentation \
        -nuclei_marker=DAPI \
        -nuclei_definition=0.5 \
        -nuclei_closeness=0.5 \
        -nuclei_diameter=5 \
        -measure_markers=\$channels

    echo "\$(date) Image segmentation done." >> ${params.log_file}
    """
}

// {params.nuclei_definition}
// {params.nuclei_closeness}
// {params.nuclei_diameter}
// {params.nuclei_expansion} 5 - 40  nuclei_expansion (5 - 15 - 30 - 40) 
// {params.membrane_diameter} 5 - 40  membrane_diameter (5 - 10 - 20 - 40)
// {params.membrane_compactness}