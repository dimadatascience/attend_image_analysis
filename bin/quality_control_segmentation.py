#!/usr/bin/env python

import numpy as np
import os

os.environ["NUMBA_CACHE_DIR"] = "/tmp/numba_cache"

import argparse
import tifffile as tiff
import logging
from cellpose.utils import masks_to_outlines
from skimage.transform import rescale
from utils import logging_config

# Set up logging configuration
logging_config.setup_logging()
logger = logging.getLogger(__name__)


def normalize_image(image):
    """Normalize each channel of the image independently to [0, 255] uint8."""
    min_val = image.min(axis=(1, 2), keepdims=True)
    max_val = image.max(axis=(1, 2), keepdims=True)
    scaled_image = (image - min_val) / (max_val - min_val) * 255
    return scaled_image.astype(np.uint8)


def rescale_to_uint8(image):
    # Rescale downsampled image to uint8
    min_val = image.min(axis=(1, 2), keepdims=True)
    max_val = image.max(axis=(1, 2), keepdims=True)
    image = (image - min_val) / (max_val - min_val) * 255
    image = image.astype(np.uint8)

    return image


def _parse_args():
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--patient_id",
        type=str,
        default=None,
        required=True,
        help="A string containing the current patient id.",
    )
    parser.add_argument(
        "--dapi_image",
        type=str,
        default=None,
        required=True,
        help="List of tiff single channel images.",
    )
    parser.add_argument(
        "--membrane_image",
        type=str,
        default=None,
        required=False,
        help="List of tiff single channel images.",
    )
    parser.add_argument(
        "--nuclei_expansion",
        type=int,
        default=None,
        required=False,
        help="Integer value for nuclei expansion.",
    )
    parser.add_argument(
        "--membrane_diameter",
        type=int,
        default=None,
        required=False,
        help="Integer value for membrane diameter.",
    )
    parser.add_argument(
        "--membrane_compactness",
        type=float,
        default=None,
        required=False,
        help="Float value for membrane compactness.",
    )
    parser.add_argument(
        "--segmentation_mask",
        type=str,
        default=None,
        required=True,
        help="Tif file containing segmentation mask",
    )
    parser.add_argument(
        "--log_file",
        type=str,
        required=False,
        help="Path to log file.",
    )

    args = parser.parse_args()
    return args


if __name__ == "__main__":
    args = _parse_args()

    handler = logging.FileHandler(args.log_file)
    formatter = logging.Formatter(
        "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    )
    handler.setFormatter(formatter)
    logger.addHandler(handler)

    dapi_image = args.dapi_image
    membrane_image = args.membrane_image
    segmentation_mask = args.segmentation_mask
    nuclei_expansion = args.nuclei_expansion
    membrane_diameter = args.membrane_diameter
    membrane_compactness = args.membrane_compactness


    dapi = tiff.imread(dapi_image).astype("float32")
    mask = tiff.imread(segmentation_mask).astype("float32")
    outlines = masks_to_outlines(mask)
    outlines = np.array(outlines, dtype="float32")
    

    if membrane_image is not None:
        membrane = tiff.imread(membrane_image).astype("float32")
        output_array = np.stack((dapi, membrane, mask, outlines), axis=0).astype("float32")
        output_array = normalize_image(output_array)
        output_array = np.array([
            rescale(output_array[0], scale=0.5, anti_aliasing=True),  
            rescale(output_array[1], scale=0.5, anti_aliasing=True),
            rescale(output_array[2], scale=0.5, anti_aliasing=False),  
            rescale(output_array[3], scale=0.5, anti_aliasing=False)  
        ])
        
    else:
        output_array = np.stack((dapi, mask, outlines), axis=0).astype("float32")
        output_array = normalize_image(output_array)
        output_array = np.array([
            rescale(output_array[0], scale=0.5, anti_aliasing=True), 
            rescale(output_array[1], scale=0.5, anti_aliasing=False),
            rescale(output_array[2], scale=0.5, anti_aliasing=False)
        ])

    output_array = rescale_to_uint8(output_array)
    output_path = f"QC_segmentation_ne{nuclei_expansion}_md{membrane_diameter}_mc{membrane_compactness}_{dapi_image}"
    pixel_microns = 0.34533768547788
    tiff.imwrite(
        output_path, 
        output_array, 
        imagej=True, 
        resolution=(1/pixel_microns, 1/pixel_microns), 
        metadata={'unit': 'um', 'axes': 'CYX', 'mode': 'composite'}
    )


    