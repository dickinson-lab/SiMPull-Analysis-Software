% Given an image stack (from SiMPull data) and coordinates of found spots,
% extracts the intensity of each spot as a function of time and performs
% local background subtraction.

% In addition to the required inputs which are self-explanatory, the
% function can also take a logical index as the last argument, which will 
% be used to choose only a subset of spots for trace extraction. 

function [dataStruct] = extractIntensityTraces(channel, rawImage, params, dataStruct, varargin)
    %Get a box containing each spot and measure the intensity.
    %Subtract local background by measuring a larger box (Ted's method).
    
    %Get number of spots
    nPeaks = length(dataStruct.([channel 'SpotData']));
    
    %Check for logical index input
    if nargin == 4
        index = true(1,nPeaks);
    elseif nargin == 5 && islogical(varargin{1})
        index = varargin{1};
    else
        error('Incorrect number or type of input arguments given');
    end
    
    %Determine the Wavelength
    if (strcmp(channel, 'Blue'))
        lambda = 480;
    elseif (strcmp(channel, 'Green'))
        lambda = 525;
    elseif (strcmp(channel, 'Red'))
        lambda = 600;
    elseif (strcmp(channel, 'FarRed'))
        lambda = 655;
    else
        error('Unexpected channel information given');
    end
    
    %Based on the wavelength and the pixel size, calculate the size of box to use
    PSFrad = lambda / (2*1.49); %Assumes we're using a 1.49 NA TIRF objective
    smBoxRad = ceil(PSFrad/params.pixelSize); %This will result in a 5x5 box for large-pixel cameras (EMCCD, Prime95B) and a 7x7 box for small-pixel cameras (sCMOS)
    smBoxArea = (2*smBoxRad + 1)^2; 
    lgBoxRad = smBoxRad + 2;
    lgBoxArea = (2*lgBoxRad + 1)^2;
    areaDiff =  lgBoxArea - smBoxArea; 
    
    [~,~,tmax] = size(rawImage);
    
    %Calculate the background and perform the subtraction
    for e = 1:nPeaks
        % Skip this spot if instructed by calling function
        if ~index(e)
            continue
        end
        
        % Check if we already have an intensity trace for this spot; if so, we don't need to calculate it again. 
        if isfield(dataStruct.([channel 'SpotData']), 'intensityTrace') && ~isempty(dataStruct.([channel 'SpotData'])(e).intensityTrace) && length(dataStruct.([channel 'SpotData'])(e).intensityTrace) >= tmax 
            continue
        end
        % Otherwise, go ahead
        xcoord = dataStruct.([channel 'SpotData'])(e).spotLocation(1);
        ycoord = dataStruct.([channel 'SpotData'])(e).spotLocation(2);   
        spotMat = rawImage(ycoord-smBoxRad:ycoord+smBoxRad,xcoord-smBoxRad:xcoord+smBoxRad,:);
        traceSmall = squeeze(sum(sum(spotMat,1),2));
        BGMat = rawImage(ycoord-lgBoxRad:ycoord+lgBoxRad,xcoord-lgBoxRad:xcoord+lgBoxRad,:);
        traceLarge = squeeze(sum(sum(BGMat,1),2));
        traceAvgBG = (traceLarge - traceSmall)/areaDiff;
        traceSmallMBG = traceSmall-traceAvgBG*smBoxArea;
        dataStruct.([channel 'SpotData'])(e).intensityTrace = transpose(traceSmallMBG);
    end
end

