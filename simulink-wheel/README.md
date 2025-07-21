# Starter transformation

[This code sample](...) demonstrates how to generate a wheel out of a simulink model and then run it from quix consuming and producing input and output data to kafka topics.

## How to build the wheel

### 01 - Modify your simulink model
Ensure any you create one inport block per input you are going to pass.
Port number is important, order will be followed.
Create outport blocks for the data you want to output.
Ensure model setup for Data Import/Export is:
- Load from workspace (all unticked)
- Save to workspace or file:
  - Output (ticked), save as yout
  - Data stores (ticked) save as dsmout
  - Single simulation output save as out
Ensure you save changes.

### 02 - Copy Matlab aux files
Copy the matlab files in this template at the folder matlab-aux-files into your simulink model's location.

### 03 - Simulink wrapper 
- From Matlab, open the simulink_wrapper.m and, on the first line of the function, change the hardcoded mdl variable to the name of your simulink model.
- Create an inputMatrix to test the function, such as [0, x1, x2, ..., xn] where x1 is the input data value for the inport block 1, etc. For example inputMatrix = [0, 1, 1, pi/2].
- Test the wrapper as simulink_wrapper(inputMatrix). The first time is run the model should get compiled. You can test other input values and ensure the model is functioning as expected. Observe output order too

### 04 - Matlab 



## How to run

Create a [Quix](https://portal.platform.quix.io/signup?xlink=github) account or log-in and visit the Samples to use this project.

Clicking `Edit code` on the Sample, forks the project to your own Git repo so you can customize it before deploying.

`important`: Update the license server on line 13 of the docker file to reflect your Matlab license server.

`ENV MLM_LICENSE_FILE=27000@your-license-server`


## Environment variables

The code sample uses the following environment variables:

- **input**: Name of the input topic to listen to.
- **output**: Name of the output topic to write to.

## Contribute

Submit forked projects to the Quix [GitHub](https://github.com/quixio/quix-samples) repo. Any new project that we accept will be attributed to you and you'll receive $200 in Quix credit.

## Open source

This project is open source under the Apache 2.0 license and available in our [GitHub](https://github.com/quixio/quix-samples) repo.

Please star us and mention us on social to show your appreciation.

## How to run

Create a [Quix](https://portal.platform.quix.io/signup?xlink=github) account or log-in and visit the Samples to use this project.

Clicking `Edit code` on the Sample, forks the project to your own Git repo so you can customize it before deploying.

## Environment variables

The code sample uses the following environment variables:

- **input**: Name of the input topic to listen to.
- **output**: Name of the output topic to write to.

## Possible `StreamingDataFrame` Operations

Many different operations and transformations are available, so 
be sure to [explore what's possible](https://quix.io/docs/quix-streams/processing.html)!


## Contribute

Submit forked projects to the Quix [GitHub](https://github.com/quixio/quix-samples) repo. Any new project that we accept will be attributed to you and you'll receive $200 in Quix credit.

## Open source

This project is open source under the Apache 2.0 license and available in our [GitHub](https://github.com/quixio/quix-samples) repo.

Please star us and mention us on social to show your appreciation.

# MATLAB

Use this template to deploy transformations that use MATLAB and Simulink. 

## Requirements

To create Python packages from MATLAB functions you need the following MathWorks products
 - MATLAB
 - MATLAB Compiler
 - MATLAB Compiler SDK 

To create Python packages from Simulink products, in addition to the above list, you also need
 - Simulink
 - Simulink Compiler

## Environment variables
 - `input`: Kafka topic to receive input data from.
 - `output`: Kafka topic to write the results of the transformation.

## Preparing Python packages from MATLAB and Simulink

`MATLAB` directory in the project has pre-compiled packages from MATLAB and Simulink assets. So, you can simply deploy and run this project. However, if you'd like to create the Python package from the source files, you can find them in the `assets` directory of this project. You can compile them using the following command:

```
mcc -W python:quixmatlab engine.m rot.m -d ../MATLAB
```

You only need the package directory that contains the `__init__.py` and a `*.ctf` file, `pyproject.toml` and `setup.py` in the `MATLAB` directory in this template.

## Resources for MATLAB Compiler SDK and MATLAB Runtime APIs

 - [Call MATLAB functions from Python](https://www.mathworks.com/help/matlab/matlab-engine-for-python.html?s_tid=CRUX_lftnav)
 - [MATLAB Arrays in Python](https://www.mathworks.com/help/matlab/matlab_external/matlab-arrays-as-python-variables.html)
 - [Pass data to MATLAB](https://www.mathworks.com/help/matlab/matlab_external/pass-data-to-matlab-from-python.html)
 - [MATLAB Compiler SDK reference](https://www.mathworks.com/help/compiler/mcc.html#d124e20858)
 - [Calling Simulink from Python](https://github.com/mathworks/Call-Simulink-from-Python)