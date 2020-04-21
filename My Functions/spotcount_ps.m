% Detects spots in a single, 1-channel image. 

% Background subtraction and spot detection are done using a probabilistic 
% segmentation algorithm coded by Jacques Boisvert, Jonas Dorn and Paul
% Maddox.

function outStruct = spotcount_ps(channel, avgImage, params, outStruct)                   
    [ymax, xmax] = size(avgImage);

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
    if isfield(outStruct, [channel 'SpotData']) && nPeaks > 0
        
        % If our data structure already has some spots, add the new ones to the end of the list
        existingSpots = length(outStruct.([channel 'SpotData']));
        peakCell = mat2cell(peakLocations,ones(nPeaks,1));
        % I couldn't figure out how to do this assignment on one line
        temp = struct('spotLocation',peakCell);
        [ outStruct( existingSpots+1 : existingSpots+nPeaks).spotLocation ] = temp.spotLocation;
        outStruct.([channel 'SpotCount']) = existingSpots + nPeaks;
    
    else
        
        %Otherwise, make new fields to hold the data. 
        if nPeaks == 0
        outStruct.([channel 'SpotData']) = struct('spotLocation',[],...
                                                  'intensityTrace',[]);
        else
            peakCell = mat2cell(peakLocations,ones(nPeaks,1));
            outStruct.([channel 'SpotData']) = struct('spotLocation',peakCell,...
                                                      'intensityTrace',[]);
        end
        outStruct.([channel 'SpotCount']) = nPeaks;
    end