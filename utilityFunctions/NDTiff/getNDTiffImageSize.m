% Determines the size of the image contained in an NDTiff dataset
function [x,y, c, z, t, p] = getNDTiffImageSize(input)

    %Check input
    if ~isa(input,'char') || ~isfolder(input)
        error('Wrong input type - provide the image directory as a string');
    end
    %Get pointer to dataset
    dataset = javaObject('org.micromanager.ndtiffstorage.NDTiffStorage', input);
    %Get axes information
    axesSet = dataset.getAxesSet();
    %Convert to a MATLAB-readable format and extract the info we want. 
    axesStruct = concurrentHashMapToStruct(axesSet);
    singleImgSize = dataset.getImageBounds;
    x = singleImgSize(3);
    y = singleImgSize(4);
    z = max(cell2mat({axesStruct.z})) + 1; %+1 because java coords are 0-based
    c = max(cell2mat({axesStruct.channel})) + 1;
    t = max(cell2mat({axesStruct.time})) + 1;
    p = max(cell2mat({axesStruct.position})) + 1;
    
    %Clean up MATLAB's mess on Mac - without this, each dataset can only be
    %opened once. 
    if exist([input filesep '._NDTiff.index'], 'file')==2
        delete([input filesep '._NDTiff.index']);
    end
end
