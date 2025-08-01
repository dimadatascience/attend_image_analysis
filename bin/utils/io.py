#!/usr/bin/env python

import h5py
import pickle
import nd2


## H5
def load_h5(path, loading_region=None, channels_to_load=None, shape="YXC"):
    with h5py.File(path, "r") as hdf5_file:
        dataset = hdf5_file["dataset"]

        # Handle empty datasets
        if dataset.shape == ():
            return dataset[()]

        # Define default slicing
        slices = [slice(None)] * len(shape)

        if loading_region:
            start_row, end_row, start_col, end_col = loading_region
            if shape == "YXC" or shape == "YX":
                slices[0] = slice(start_row, end_row)
                slices[1] = slice(start_col, end_col)
            elif shape == "CYX":
                slices[1] = slice(start_row, end_row)
                slices[2] = slice(start_col, end_col)

        if channels_to_load is not None:
            if shape == "YXC":
                slices[2] = channels_to_load
            elif shape == "CYX":
                slices[0] = channels_to_load

        # Extract data using slices
        data = dataset[tuple(slices)]

    return data


def save_h5(data, path, dtype=None):
    if isinstance(data, int):
        chunks = None
        maxshape = None
        dtype = "int"
    else:
        ndim = data.ndim
        chunks = True
        maxshape = tuple([None] * ndim)
        if dtype is None:
            dtype = data.dtype

    with h5py.File(path, "w") as hdf5_file:
        hdf5_file.create_dataset(
            "dataset", data=data, chunks=chunks, maxshape=maxshape, dtype=dtype
        )
        hdf5_file.flush()


## PICKLE
def load_pickle(path):
    # Open the file in binary read mode
    with open(path, "rb") as file:
        # Deserialize the object from the file
        loaded_data = pickle.load(file)

    return loaded_data


def save_pickle(object, path):
    # Open a file in binary write mode
    with open(path, "wb") as file:
        # Serialize the object and write it to the file
        pickle.dump(object, file)


## ND2
def load_nd2(file_path):
    """
    Read an ND2 file and return the image array.

    Parameters:
    file_path (str): Path to the ND2 file

    Returns:
    numpy.ndarray: Image data
    """
    with nd2.ND2File(file_path) as nd2_file:
        data = nd2_file.asarray()

    return data
