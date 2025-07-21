# Starter transformation

[This code sample](...) demonstrates how to generate a wheel out of a simulink model and then run it from quix consuming and producing input and output data to kafka topics.

## How to build the wheel

### 01 - Modify Your Simulink Model
- Create one **Inport** block per input signal. The port numbers define the input order.
- Add **Outport** blocks for the signals you want to output.
- Configure **Data Import/Export** settings:
  - **Load from workspace**: all options **unchecked**
  - **Save to workspace or file**:
    - ✅ Output → saved as `yout`
    - ✅ Data stores → saved as `dsmout`
    - ✅ Single simulation output → saved as `out`
- Save the model after applying these settings.

### 02 - Copy Auxiliary Files
- Copy all files from the `aux-files` folder into the same directory as your Simulink model.
- Open MATLAB from that folder.

### 03 - Wrap the Simulink Model
- Open `simulink_wrapper.m` and set the `mdl` variable (first line) to your Simulink model's name.
- Create an `inputMatrix`, e.g. `[0, x1, x2, ..., xn]`, where `x1` is the value for Inport 1, and so on.  
  Example: `inputMatrix = [0, 1, 1, pi/2]`
- Run `simulink_wrapper(inputMatrix)` to compile and test the model. Make sure the output order is as expected.

### 04 - Compile for Quix
Now that the Simulink model is wrapped inside a MATLAB function, you can compile it using the Quix compiler.
Run the following command from MATLAB, replacing the arguments if needed:
quix_compiler('simulink_wrapper', 'py')
This will generate a folder (py) containing the Python-compatible code.
Once the compilation is complete, you can close MATLAB.

### 05 - Build the wheel
If you used MATLAB Online, download and unzip the compiled folder (py) to your local machine.
Then, from your terminal, navigate to the folder and run:
./build_wheel.sh
This script will create a .whl file. This file is the package you’ll deploy to Quix.

### 06 - Update the .whl in the quix app
Replace the existing .whl file in your Quix app with the new one you just built.
⚠️ If the new filename differs from the previous one, make sure to update the requirements.txt file accordingly.


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