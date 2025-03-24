# Z-Ant module by module overview

## Table of Contents

1. [Core](#core).
    - [Quantization](#quantization).
    - [Tensors and TensorMath](#tensor-and-tensormath).
2. [ONXX](#onxx).
3. [Data Handler and Trainer](#data-handler-and-trainer).
    - [Data Handler](#data-handler).
    - [Trainer](#trainer).
4. [CodeGen and Static Library](#codegen-and-static-library).

# Core

Core comprises all the essential components of Z-Ant, it handles all linear algebra related operations and abstractions, it is comprised of two modules: [Quantization](#quantization) and [Tensor](#tensor-and-tensormath).

## Quantization

As of now, quantization is not implemented in master.

## Tensor and TensorMath. 

- [In depth function documentation](tensor.md).

Tensors are what makes us able to compute, develop and train AI models in Z-Ant, most of our work under the hood will have to do with modifying, applying, creating and slicing tensors.

### What is a tensor?
A tensor is a generalized multidimensional matrix, stored in memory as a contiguous array of data.\
Our usecase dictates that we use four-dimentional ones, where each dimension has a specific purpose:

1. __Batch__: makes us able to represent multiple members of a dataset in the same tensor, useful in image training.
2. __Channels__: represents multiple components all part of one singular set member. (i.e. RGB channels in an image).
3. __Rows__: self-explanatory.
4. __Columns__: self-explanatory.

### TensorMath
Of course tensors would be useless if there wasn't any way to do operations with/on them, so Z-Ant provides multiple sets of operations in two different formats: __Lean__ and __Standard__:

__Lean__ is our simplified lightweight math library, it requires the user to initialize their own output tensor and __lacks checks that could prevent branches__.

__Standard__ is the main library to be used, it initializes outputs by itself, it does all necessary checks for a proper and stable result, any standard function _calls lean under the hood_ after doing all necessary checks, so the core of the module is the lean operations.

> As of now TensorMath needs a refactoring, please use standard until further changes in this documentation.

# ONXX

- [In depth function documentation](onxx.md).

In depth documentation on ONNX and its internals [here](../src/onnx/ONNX_IR.md).

# Data handler and trainer

- [In depth function documentation](data_handler.md).

## Data Handler

Z-Ant provides multiple ways to gather and load training data, and provides an iterator to move and batch through the data, as of now these data types are supported:

- __CSV files__
- __MNIST Datasets.__

as Z-Ant develops more formats will be supported.

## Trainer

As of now ```trainer.zig``` contains all the training procedures currently supported by Z-Ant.

The two procedures currently implemented are:

- Tensor directed general training, through the ```trainTensor()``` function.
- Traning through data loaded from a file, well accustomed and optimized for MNIST datasets, through the ```TrainDataLoader()``` function.

Both take in the respective Loader/Tensor, and train it in accordance to the training data provided.

# Codegen and static library

- [In depth function documentation](codegen.md).

Will be written at a later date when Codegen is mature enough to be documented.





