# NDTiff reader for MATLAB
Allows loading of image data in [NDTiff format](https://github.com/micro-manager/NDStorage) into MATLAB. 
The NDTiff file format is utilized by [Micro-Manager](https://micro-manager.org/Micro-Manager_File_Formats) and [Pycro-Manager](https://pycro-manager.readthedocs.io/en/latest/index.html) and is a more efficient alterantive to the conventional TIFF and OME-TIFF formats. 

## Installation
- Clone this repository or download the .m files and place them in your MATLAB working directory (or add them to your MATLAB path).
- Download and install a recent [Micro-Manager Nightly Build](https://micro-manager.org/Micro-Manager_Nightly_Builds).
- In the Micro-Manager installation directory, locate these two files: `../plugins/Micro-Manager/MMCoreJ.jar` and `../plugins/Micro-Manager/NDTiffStorage-#.#.#.jar` (replace #.#.# with the actual version number included in your nightly build).
- In your MATLAB installation directory, find the Java Classpath file, which is located at `$MATLAB\toolbox\local\classpath.txt`. Open it. Add two lines to the end of this text file, one containing the complete path to each of the .jar files above. For example, on my machine, these two lines are:  
  `/Applications/Micro-Manager-2.0.3-20250818/plugins/Micro-Manager/MMCoreJ.jar` and  
  `/Applications/Micro-Manager-2.0.3-20250818/plugins/Micro-Manager/NDTiffStorage-2.18.4.jar`.  
  Save and close the classpath file. Launch (or re-launch) MATLAB and you are ready to go.  

## Usage
To load an entire NDTiff dataset into memory, use the command  
`[image, smd] = loadNDTiffDataset(<path/to/dataset>);`  
where the path should point to the directory containing your NDTiff file(s) and the `NDTiff.index` file. Provide the path to the directory, not the .tif file.  
`image` will be a multi-dimensional array containing the image data, in the dimension order x, y, c, z, t, pos. Any singleton dimensions are skipped.  
`smd` will be a MATLAB structure containing the summary metadata.  

You can also load a subset of the data by specifying the optional `subregion`, `channels`, `frames`, `slices` and `positions` arguments.  
For example, to load only channel 2 of a 3-color dataset, use the command  
`[image, smd] = loadNDTiffDataset(<path/to/dataset>, 'channels', 2);`  
To load only z planes 2-4 of a dataset containing more z planes, use  
`[image, smd] = loadNDTiffDataset(<path/to/dataset>, 'slices', 2:4);`  

To determine the size of a dataset (how many channels, slices, frames etc. it contains), use  
`[x, y, c, z, t, p] = getNDTiffImageSize(<path/to/dataset>);`

## Known limitations
Currently this package only supports reading NDTiff files. Any modified data will need to be saved in conventional TIFF or another format, for example using MATLAb's built-in `imwrite` function. Support for writing NDTiff files may be added in a future version. 
