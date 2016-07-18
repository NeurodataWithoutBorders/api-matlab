# api-matlab

**Note: Usage of this software is NOT recommended**

**Reason:** This is a pure Matlab implementation of the alpha version of the NWB format.  It has
not been updated to incorporate changes made in later versions of the NWB format.  Instead of this
software, it is recommended to use an alternative Matlab API (called the "matlab_bridge" API)
that is included with the NWB Python API.  The matlab_bridge API works by calling the Python API
from MatLab so it is always up-to-date with the most recent NWB version.  See file "0_README.txt"
in the "matlab_bridge" directory of the api-python repository for more information about this recommended
alternative Matlab API.


--------------------------------------------------------------------------------------------------------

QUICKSTART INSTRUCTIONS AND REMARKS

Requirements: Matlab2014b or newer

To get started:

- install jsonlab 
  (http://www.mathworks.com/matlabcentral/fileexchange/33381-jsonlab--a-toolbox-to-encode-decode-json-files-in-matlab-octave)
- put the Matlab API folder in the desired location
- add the nwb path by typing
  addpath(genpath(‘/YourPath/Matlab API/nwb’))
  to the command line and replace your path with the location of the API on your computer
- write and run your scripts

If you experience a Matlab crash:
- try typing
  feature('accel','off’)
  to the command line
