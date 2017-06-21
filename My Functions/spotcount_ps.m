% Detects spots in a single, 1-channel image. 

% Background subtraction and spot detection are done using a probabilistic 
% segmentation algorithm coded by Jacques Boisvert, Jonas Dorn and Paul
% Maddox.

% Intensity traces are calculated from the unfiltered time series by summing
% pixel intensities in a 5x5 spot centered on each peak pixel and subtracting 
% local background. 

function outStruct = spotcount_ps(channel,rawImage,params,outStruct)                   
    [ymax, xmax, tmax] = size(rawImage);

    %Make average image 
    timeAvg = double(zeros(ymax,xmax));
    count = 0;
    for b=params.firstTime:params.lastTime
        timeAvg = timeAvg + rawImage(:,:,b);
        count = count+1;
    end
    timeAvg = timeAvg/count;

    %Save average image for later reference
    avgImage = uint16(timeAvg);
    imwrite(avgImage,[outStruct.tiffDir filesep params.imageName '_' channel 'avg.tif'],'tiff');
    
    % Spot detection with probabilistic segmentation
    [coordinates,~,~] = psDetectSpots(avgImage,[25 25],params.psfSize,'fpExp',params.fpExp,'poissonNoise',params.poissonNoise);
    if isempty(coordinates)  %Protects against crashing when no spots are found
        peakLocations = [];
    else
        peakLocations = coordinates(:,2);
        peakLocations(:,2) = coordinates(:,1);
    end
    
    %Throw out peaks that are too close to the edge
    [nPeaks, ~] = size(peakLocations);
    for c = nPeaks:-1:1
        if (min(peakLocations(c,:))<6 || peakLocations(c,1)>xmax-5 || peakLocations(c,2)>ymax-5)
            peakLocations(c,:) = [];
        end
    end
    [nPeaks, ~] = size(peakLocations);

    %Saves the results
    if nPeaks == 0
        outStruct.([channel 'SpotData']) = struct('spotLocation',[0,0],...
                                                  'intensityTrace',zeros(1,tmax),...
                                                  'isColocalized',false);
    else
        peakCell = mat2cell(peakLocations,ones(nPeaks,1));
        outStruct.([channel 'SpotData']) = struct('spotLocation',peakCell);
    end
    outStruct.([channel 'SpotCount']) = nPeaks;
    
    %Get a 5x5 box containing each spot and measure the intensity.
    %Subtract local background by measuring a 9x9 box (Ted's method).
    if nPeaks > 0 
        for e = 1:nPeaks
            xcoord = peakLocations(e,1);
            ycoord = peakLocations(e,2);   
            spotMat = rawImage(ycoord-2:ycoord+2,xcoord-2:xcoord+2,:);
            trace5x5 = squeeze(sum(sum(spotMat,1),2));
            BGMat = rawImage(ycoord-4:ycoord+4,xcoord-4:xcoord+4,:);
            trace9x9 = squeeze(sum(sum(BGMat,1),2));
            traceAvgBG = (trace9x9 - trace5x5)/(81-25);
            trace5x5MBG = trace5x5-traceAvgBG*25;
            outStruct.([channel 'SpotData'])(e).intensityTrace = transpose(trace5x5MBG);
        end
    end
    return;