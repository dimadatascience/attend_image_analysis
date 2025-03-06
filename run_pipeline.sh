nextflow run /path/to/main.nf \
        -profile singularity \
        --with-tower \
        --executor 'local' \
        --input /path/to/sample_sheet.csv \
        --outdir /path/to/outdir \
        --log_file /path/to/log.log \
        -resume
