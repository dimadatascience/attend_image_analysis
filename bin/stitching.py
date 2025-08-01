#!/usr/bin/env python
# Compute affine transformation matrix

import logging
import argparse
import os
import numpy as np
import re
import tifffile as tiff
from utils.io import load_h5, save_h5
from utils.cropping import image_reconstruction_loop
from utils.metadata_tools import get_image_file_shape
from utils import logging_config

# Set up logging configuration
logging_config.setup_logging()
logger = logging.getLogger(__name__)

def are_all_alphabetic_lowercase(string):
    # Filter alphabetic characters and check if all are lowercase
    return all(char.islower() for char in string if char.isalpha())

def remove_lowercase_channels(channels):
    filtered_channels = []
    for ch in channels:
        if not are_all_alphabetic_lowercase(ch):
            filtered_channels.append(ch)
    return filtered_channels


def _parse_args():
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-p",
        "--patient_id",
        type=str,
        default=None,
        required=True,
        help="A string containing the current patient id.",
    )
    parser.add_argument(
        "-d",
        "--dapi_crops",
        type=str,
        default=None,
        required=True,
        nargs='+',
        help="A list of crops (DAPI channel)",
    )
    parser.add_argument(
        "-c",
        "--crops",
        type=str,
        default=None,
        required=True,
        nargs='+',
        help="A list of crops",
    )
    parser.add_argument(
        "-cs",
        "--crop_size",
        type=int,
        default=2000,
        required=False,
        help="Size of the crop",
    )
    parser.add_argument(
        "-o",
        "--overlap_size",
        type=int,
        default=200,
        required=False,
        help="Size of the overlap",
    )
    parser.add_argument(
        "-f",
        "--fixed",
        type=str,
        default=None,
        required=True,
        help="Padded full fixed file.",
    )
    parser.add_argument(
        "-m",
        "--moving",
        type=str,
        default=None,
        required=True,
        help="Padded full moving file.",
    )
    parser.add_argument(
        "-l",
        "--log_file",
        type=str,
        required=False,
        help="Path to log file.",
    )
    args = parser.parse_args()
    return args

def save_tiff(image, output_path, resolution=None, bigtiff=True, ome=True, metadata=None):
    tiff.imwrite(
        output_path, 
        image, 
        resolution=resolution,
        bigtiff=bigtiff, 
        ome=ome,
        metadata=metadata
    )

def main():
    args = _parse_args()

    handler = logging.FileHandler(args.log_file)
    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    handler.setFormatter(formatter)
    logger.addHandler(handler)

    original_shape = get_image_file_shape(args.moving, format='.h5')

    matches = []
    for crop_name in args.crops:
        matches.append(len(crop_name.split('.')[0].split('_')[-1]) == 64) # Check if filename ends in a 64 characters hash 

    if not all(matches):
        crops_files = args.crops
        cr = load_h5(crops_files[0])

        if not isinstance(cr, int):
            shape = (original_shape[0], original_shape[1], cr.shape[2])
            reconstructed_image = image_reconstruction_loop(crops_files, shape, args.overlap_size)

            moving_channels = os.path.basename(args.moving).replace('padded_', '') \
                .split('.')[0] \
                .split('_')[3:] \
                [::-1] # Select first two channels (omit DAPI) and reverse list
            
            fixed_channels = os.path.basename(args.fixed).replace('padded_', '') \
                .split('.')[0] \
                .split('_')[2:] \
                [::-1] # Select all channels and reverse list
            
            moving_channels_to_export = remove_lowercase_channels(moving_channels)
            moving_channels_to_export_no_dapi = [ch for ch in moving_channels_to_export if ch != 'DAPI']
            fixed_channels_to_export = remove_lowercase_channels(fixed_channels)

            # Save moving channels
            for idx, ch in enumerate(moving_channels_to_export_no_dapi):
                # save_h5(
                #     np.expand_dims(reconstructed_image[:,:,idx], axis=0).astype(np.float32), 
                #     f"registered_{args.patient_id}_{ch}.h5"
                # )
                save_tiff(reconstructed_image[:,:,idx], 
                    f"registered_{args.patient_id}_{ch}.tiff")
            
            # Save fixed channels
            for idx, ch in enumerate(fixed_channels_to_export):
                image = load_h5(args.fixed, channels_to_load=idx)
                image = image.astype(np.float32)
                save_tiff(image, f"registered_{args.patient_id}_{ch}.tiff")
                image = np.expand_dims(image, axis=0)
                # save_h5(
                #     image, 
                #     f"registered_{args.patient_id}_{ch}.h5"
                # )
                
    else:
        tiff.imwrite(
            f"registered_{args.patient_id}.tiff",
            0
        )

        # save_h5(
        #         0, 
        #         f"registered_{args.patient_id}.h5"
        # )



if __name__ == "__main__":
    main()
