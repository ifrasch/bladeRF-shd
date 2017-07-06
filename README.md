# bladeRF-shd
FPGA-based implementation of RF spectrum hole detector (SHD) on bladeRF software-defined radio. Completed for Rochester Institute of Technology (RIT) Computer Engineering MS Thesis.  
Author: Ian Frasch

Directories are organized as follows:

bladeRF - Source code to implement the SHD on bladeRF SDR (VHDL, C). This code combines with original bladeRF source code (https://github.com/Nuand/bladeRF) to create an FPGA image for performing the hole detection and PC software for receiving detector output samples from the bladeRF through USB connection.  
matlab - MATLAB/Octave script for plotting SHD output in real time. The program compiled from bladeRF/c/toplevel/bladeRF-shd.c must be run before running this script.

I will soon add instructions for building the SHD FPGA image, building the PC software, and actually getting the detector running on your bladeRF with the real-time visualization in MATLAB or Octave.
