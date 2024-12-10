#!/usr/bin/env python

import os
import numpy as np
import tifffile as tiff
import argparse
import logging
from utils.read_metadata import get_metadata_nd2
from utils.io import save_pickle
from utils import logging_config

# Set up logging configuration
logging_config.setup_logging()
logger = logging.getLogger(__name__)


def create_tiff_metadata(src_path, channel_names):
    metadata = get_metadata_nd2(src_path)
    pixel_microns = metadata['pixel_microns']
    resolution = (1/pixel_microns, 1/pixel_microns)
    metadata = {
        'axes': 'CYX', 
        'PhysicalSizeX': pixel_microns, 
        'PhysicalSizeY': pixel_microns, 
        'PhysicalSizeXUnit': 'µm',                             
        'PhysicalSizeYUnit': 'µm', 
        'Channel': {'Name': channel_names}
    }

    return resolution, metadata

def save_tiff(image, save_path, resolution, metadata):
    tiff.imwrite(
        save_path, 
        image, 
        resolution=resolution,
        bigtiff=True, 
        ome=True,
        metadata=metadata
    )

def _parse_args():
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-i",
        "--nd2_files",
        type=str,
        default=None,
        required=True,
        help="A string of nd2 files.",
    )
    parser.add_argument(
        "-f",
        "--fixed",
        type=str,
        default=None,
        required=True,
        help="String of paths to h5 files (fixed image).",
    )
    parser.add_argument(
        "-r",
        "--registered",
        type=str,
        default=None,
        required=True,
        help="String of paths to h5 files (registered images).",
    )
    parser.add_argument(
        "-p",
        "--patient_id",
        type=str,
        default=None,
        required=True,
        help="A string containing the current patient id.",
    )

    args = parser.parse_args()
    return args

def main():
    handler = logging.FileHandler('/hpcnfs/scratch/DIMA/chiodin/repositories/attend_image_analysis/LOG.log')
    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    handler.setFormatter(formatter)
    logger.addHandler(handler)

    args = _parse_args()

    nd2_files = args.nd2_files.split() 
    fixed = args.fixed
    registered = args.registered.split()

    registered.append(fixed)

    h5_files = registered   

    channels = []
    for file in h5_files:
        filename = os.path.basename(file).split('.')[0]
        channel_names = [filename.split('_')[1], filename.split('_')[2], filename.split('_')[3]]

        for name in channel_names:
            channels.append(name)
            
    # Only keep DAPI channel from fixed image
    channels.reverse()  
    first_occurrence = True
    result = []
    for item in channels:
        if item == 'DAPI':
            if first_occurrence:
                result.append(item)
                first_occurrence = False
        else:
            result.append(item)

    resolution, metadata = create_tiff_metadata(nd2_files[0], result)

    meta = (resolution, metadata)
    save_path = f"metadata_{args.patient_id}.pkl"
    save_pickle(meta, save_path)

if __name__ == "__main__":
    main()