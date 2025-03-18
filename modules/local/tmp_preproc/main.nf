process pipex_preprocessing {
    //cpus 2
    //memory { task.memory + 10 * task.attempt}
    publishDir "${params.outdir}/preprocessing"
    tag "pipex_preprocessing"
    container "docker://yinxiu/pipex:latest"
    
    input:
    path(images)

    output:
    tuple path("preprocessing_input/preprocessed/*tif")

    script:
    """
    echo "\$(date): Starting pipex_preprocessing process..." >> ${params.log_file}

    mkdir -p ./preprocessing_input

    export PIPEX_MAX_RESOLUTION=90000

    channels=""
    for file in $images; do
        chname=`basename \$file | sed 's/.tiff//g' | sed 's/registered_//g' | cut -d'_' -f2-`
        channels+=" \$chname"
        cp \$file ./preprocessing_input
    done
    channels=`echo \$channels | sed 's/ /,/g'`

    ls ./preprocessing_input  >> ${params.log_file}


    ##############################################
    ##############################################
    ##############################################
    # Preprocessing step

    python -u -W ignore /pipex/preprocessing.py \
        -data=./preprocessing_input \
        -preprocess_markers=\$channels \
        -otsu_threshold_levels=0
    """
}