#!/usr/bin/env python
# Compute affine transformation matrix

import logging
import argparse
import os
import numpy as np
from utils.io import load_h5, save_h5, load_pickle
from utils.cropping import reconstruct_image
from utils.read_metadata import get_image_file_shape
from utils import logging_config

# Set up logging configuration
logging_config.setup_logging()
logger = logging.getLogger(__name__)

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
    args = parser.parse_args()
    return args


def main():
    handler = logging.FileHandler('/hpcnfs/scratch/DIMA/chiodin/repositories/attend_image_analysis/LOG.log')
    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    handler.setFormatter(formatter)
    logger.addHandler(handler)

    args = _parse_args()
    original_shape = get_image_file_shape(args.moving, format='.h5')
    crops_files = args.crops
    reconstructed_image = np.zeros(original_shape, dtype='float32')
    for crop_file in crops_files:
        crop = load_pickle(crop_file)
        logger.info(f"Loaded crop: {crop_file}")

        x, y = map(int, os.path.basename(crop_file).split("_")[1:3])
        position = (x, y)
        reconstructed_image = reconstruct_image(reconstructed_image, crop, position, original_shape, args.overlap_size)

    moving_channels = os.path.basename(args.moving)\
        .split('.')[0] \
        .split('_')[2:4][::-1] # Select first two channels (omit DAPI)
    
    fixed_channels = os.path.basename(args.fixed) \
        .split('.')[0] \
        .split('_')[1:4][::-1] # Select all channels
    
    for idx, ch in enumerate(moving_channels):
        save_h5(
            np.expand_dims(reconstructed_image[:,:,idx], axis=0).astype(np.float32), 
            f"registered_{args.patient_id}_{ch}.h5"
        )
    
    for idx, ch in enumerate(fixed_channels):
        image = load_h5(args.fixed, channels_to_load=idx).astype(np.float32)
        image = np.expand_dims(image, axis=0)
        save_h5(
            image, 
            f"registered_{args.patient_id}_{ch}.h5"
        )
    



if __name__ == "__main__":
    main()
