%Detects colocalization between red and green TIRF channels by 
%looking for detected spots that overlap.

function [gridData, colocResults] = coloc_spots(gridData, statsByColor, testChannel, maxSpots)

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Adjustable Parameters are here                                 %
                                                                    %
    colocDistance = 4;  %Spots must be less than this many pixels   %
                        %apart to be considered colocalized         %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Check input
    channels = {'Blue' 'Green' 'Red' 'FarRed' 'blue' 'green' 'red' 'farRed'};
    if sum(strcmpi(testChannel, channels)) == 0
        errordlg('Invalid channel selected');
        return
    end
    if ~isfield(gridData, [testChannel 'SpotData'])
        errordlg('Invalid channel selected');
        return
    end
    
    gridSize = size(gridData);
    nElements = gridSize(1)*gridSize(2);
    
    % Figure out what channels we have.  The test channel is ignored.
    channelIdx = false(1, length(channels));
    for c = 1:length(channels)
        if (~strcmpi(testChannel, channels{c}) && isfield(gridData, [channels{c} 'SpotData']))
            channelIdx(c) = 1;
            colocResults.([testChannel channels{c} 'ColocSpots']) = 0;
            colocResults.([testChannel channels{c} 'SpotsTested']) = 0;
        end
    end
    channels = channels(channelIdx);
    if length(channels) == 0  % == 0 because we're ignoring the test channel (i.e., test if there are 0 other channels present)
        warndlg('Input data contain only a single channel. Press ok to exit.');
        return
    end
    
    % For each channel that is present, check for colocalization with the test channel.  
    colocwb = waitbar(0, ['Determining colocalization for the ' testChannel ' channel']);
    for b = 1:nElements
        if gridData(b).([testChannel 'SpotCount']) == 0 %Skip this image if there are no spots
            continue
        end
        for d = 1:length(channels) 
            thisChannel = channels{d};
            if (gridData(b).([testChannel 'SpotCount']) > maxSpots || gridData(b).([thisChannel 'SpotCount']) > maxSpots)
                gridData(b).([testChannel thisChannel 'ColocSpots']) = 'Too Many Spots to Analyze';
                [ gridData(b).([testChannel 'SpotData']).(['coloc' thisChannel]) ] = deal( logical([]) );
                gridData(b).([testChannel thisChannel 'ColocSpotData']) = struct([]);
            else
                gridData(b).([testChannel thisChannel 'ColocSpots']) = 0;
                if gridData(b).([testChannel 'SpotCount']) > 0   
                    [ gridData(b).([testChannel 'SpotData']).(['coloc' thisChannel]) ] = deal(false);
                    if gridData(b).([thisChannel 'SpotCount']) > 0  
                        % For each spot detected in the test channel, see if there is a matching spot in the current channel
                        
                        % Extract spot locations
                        [testSpots] = {gridData(b).([testChannel 'SpotData']).spotLocation}';
                        [theseSpots] = {gridData(b).([thisChannel 'SpotData']).spotLocation}';
                        
                        % If necessary, apply an affine transformation for registration
                        if isfield(statsByColor, [testChannel 'RegistrationData'])
                            testSpots = cellfun(@(x) transformPointsForward( statsByColor.([testChannel 'RegistrationData']).Transformation, x), testSpots, 'UniformOutput', false);
                            theseSpots = cellfun(@(x) transformPointsForward( statsByColor.([thisChannel 'RegistrationData']).Transformation, x), theseSpots, 'UniformOutput', false);
                        end
                        
                        % Look for colocalization
                        for a = 1:gridData(b).([testChannel 'SpotCount'])
                            query = cell2mat(testSpots(a));
                            match = find(cellfun(@(x) sum(abs(x-query))<colocDistance, theseSpots));
                            if ~isempty(match)
                                gridData(b).([testChannel 'SpotData'])(a).(['coloc' thisChannel]) = true;
                                gridData(b).([testChannel thisChannel 'ColocSpots']) = gridData(b).([testChannel thisChannel 'ColocSpots']) + 1;
                                colocResults.([testChannel thisChannel 'ColocSpots']) = colocResults.([testChannel thisChannel 'ColocSpots']) + 1;
                                %These next lines copy the data for colocalized spots into their own struct array
                                gridData(b).([testChannel thisChannel 'ColocSpotData'])(gridData(b).([testChannel thisChannel 'ColocSpots'])).([thisChannel 'SpotLocation']) = gridData(b).([thisChannel 'SpotData'])(match).spotLocation;
                                gridData(b).([testChannel thisChannel 'ColocSpotData'])(gridData(b).([testChannel thisChannel 'ColocSpots'])).([thisChannel 'IntensityTrace']) = gridData(b).([thisChannel 'SpotData'])(match).intensityTrace;
                                try gridData(b).([testChannel thisChannel 'ColocSpotData'])(gridData(b).([testChannel thisChannel 'ColocSpots'])).([thisChannel 'NSteps']) = gridData(b).([thisChannel 'SpotData'])(match).nSteps; end
                                try gridData(b).([testChannel thisChannel 'ColocSpotData'])(gridData(b).([testChannel thisChannel 'ColocSpots'])).([thisChannel 'Changepoints']) = gridData(b).([thisChannel 'SpotData'])(match).changepoints; end
                                try gridData(b).([testChannel thisChannel 'ColocSpotData'])(gridData(b).([testChannel thisChannel 'ColocSpots'])).([thisChannel 'Steplevels']) = gridData(b).([thisChannel 'SpotData'])(match).steplevels; end
                                gridData(b).([testChannel thisChannel 'ColocSpotData'])(gridData(b).([testChannel thisChannel 'ColocSpots'])).([testChannel 'SpotLocation']) = gridData(b).([testChannel 'SpotData'])(a).spotLocation;
                                gridData(b).([testChannel thisChannel 'ColocSpotData'])(gridData(b).([testChannel thisChannel 'ColocSpots'])).([testChannel 'IntensityTrace']) = gridData(b).([testChannel 'SpotData'])(a).intensityTrace;
                                try gridData(b).([testChannel thisChannel 'ColocSpotData'])(gridData(b).([testChannel thisChannel 'ColocSpots'])).([testChannel 'NSteps']) = gridData(b).([testChannel 'SpotData'])(a).nSteps; end
                                try gridData(b).([testChannel thisChannel 'ColocSpotData'])(gridData(b).([testChannel thisChannel 'ColocSpots'])).([testChannel 'Changepoints']) = gridData(b).([testChannel 'SpotData'])(a).changepoints; end
                                try gridData(b).([testChannel thisChannel 'ColocSpotData'])(gridData(b).([testChannel thisChannel 'ColocSpots'])).([testChannel 'Steplevels']) = gridData(b).([testChannel 'SpotData'])(a).steplevels; end
                            else
                                gridData(b).([testChannel 'SpotData'])(a).(['coloc' thisChannel]) = false;
                            end
                            colocResults.([testChannel thisChannel 'SpotsTested']) = colocResults.([testChannel thisChannel 'SpotsTested']) + 1;
                        end
                    end
                end
            end
        end
        waitbar(b/nElements, colocwb);
    end % of for loop b over gridData
    close(colocwb);