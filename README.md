# api-matlab

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
