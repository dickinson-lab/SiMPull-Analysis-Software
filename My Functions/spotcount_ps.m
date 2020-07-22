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
    
    % Check for previously-existing spots
    if isfield(outStruct, [channel 'SpotCount'])
        existingSpots = outStruct.([channel 'SpotCount']);
    else
        %Make fields in gridData to hold the results
        outStruct.([channel 'SpotData']) = struct('spotLocation',[],...
                                                  'intensityTrace',[]);
        outStruct.([channel 'SpotCount']) = 0;
        existingSpots = 0;
    end
    
    if existingSpots > 0 && nPeaks > 0
        
        % If our data structure already has some spots, add the new ones to the end of the list
        peakCell = mat2cell(peakLocations,ones(nPeaks,1));
        % I couldn't figure out how to do this assignment on one line
        temp = struct('spotLocation',peakCell);
        [ outStruct( existingSpots+1 : existingSpots+nPeaks).spotLocation ] = temp.spotLocation;
        outStruct.([channel 'SpotCount']) = existingSpots + nPeaks;
    
    elseif nPeaks > 0
        
        %Otherwise, just put the new data in place 
        peakCell = mat2cell(peakLocations,ones(nPeaks,1));
        outStruct.([channel 'SpotData']) = struct('spotLocation',peakCell,...
                                                  'intensityTrace',[]);
        outStruct.([channel 'SpotCount']) = nPeaks;
    end