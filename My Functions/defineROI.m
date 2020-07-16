%
% Eliminates a portion of an  image from a SiMPull dataset and 
% re-calculates summary tables. Used for getting rid of known artifacts 
% (e.g. edge of microfluidic channel)
%
% At first glance a lot of inputs seem to be required, but this is because
% all of the analysis data is passed via the calling function to avoid
% (slow) loading from disk.
%
% This function is not meant to be called directly.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [gridData, statsByColor, summary] = defineROI(gridData, channels, nChannels, nPositions, params, statsByColor, matPath, matFile, selection, ROI, keepROI) 
    % selection = number of image to be modified
    % keepROI   = logical 1 if ROI contains the good region of the image
    %           = logical 0 if ROI contains an artifact to be excluded    
                                                                                    
    %Update gridData with a record of what regions have been defined
    %and/or excluded
    if ~keepROI
       %Check if an ROI has already been excluded for this image
       alreadyExists = any(cellfun(@(x) isequal(x, 'None'), gridData(selection).excludedRegions));
       %If this is the first excluded ROI, replace 'None' with the ROI
       if alreadyExists    
          gridData(selection).excludedRegions{1} = ROI;
       %Otherwise, append the newly excluded ROI to the existing list 
       else
          gridData(selection).excludedRegions{end+1} = ROI;
       end
    else 
       %Check if an ROI has already been defined for this image, etc.
       alreadyExists = any(cellfun(@(x) isequal(x, 'All'), gridData(selection).regionsOfInterest));
       if alreadyExists
          gridData(selection).regionsOfInterest{1} = ROI;
       else
          gridData(selection).regionsOfInterest{end+1} = ROI;
       end
    end
    
    % Remove non-selected spots from image and re-calculate summary stats
    for c = 1:nChannels
        % Spot count data
        color1 = channels{c};
        index = true(size(gridData(selection).([color1 'SpotData'])));
        for d = 1:length(index)
            %Get spot location
            spotLoc = gridData(selection).([color1 'SpotData'])(d).spotLocation;
            %If necessary, transform to account for registration
            if isfield(statsByColor,[color1 'RegistrationData']) && strcmp(statsByColor.([color1 'DVposition']),'Right')
                spotLoc = transformPointsForward( statsByColor.([color1 'RegistrationData']).Transformation, spotLoc);
            end
            index(d) = ( ROI(1) < spotLoc(1) && spotLoc(1) < ROI(1)+ROI(3) && ROI(2) < spotLoc(2) && spotLoc(2) < ROI(2)+ROI(4) );
        end
        if ~keepROI
            index = ~index;
        end
        gridData(selection).([color1 'SpotData']) = gridData(selection).([color1 'SpotData'])(index);
        gridData(selection).([color1 'SpotCount']) = length(gridData(selection).([color1 'SpotData']));
        statsByColor.(['total' color1 'Spots']) = sum(cell2mat({gridData.([color1 'SpotCount'])}));
        statsByColor.(['avg' color1 'Spots']) = statsByColor.(['total' color1 'Spots']) / nPositions;
        
        % Colocalized spot data
        for b = 1:length(channels)
            color2 = channels{b};
            if isfield(gridData, [color1 color2 'ColocSpotData']) && isnumeric(gridData(selection).([color1 color2 'ColocSpots']))
                index = true(size(gridData(selection).([color1 color2 'ColocSpotData'])));
                for e = 1:length(index)
                    spotLoc = [];
                    if isfield(statsByColor, [color1 'RegistrationData']) %If color1 has been shifted due to registration, use color2 locations to filter spots
                        spotLoc = gridData(selection).([color1 color2 'ColocSpotData'])(e).([color2 'SpotLocation']);
                    else %otherwise, just use color1 locations
                        spotLoc = gridData(selection).([color1 color2 'ColocSpotData'])(e).([color1 'SpotLocation']);
                    end
                    index(e) = ( ROI(1) < spotLoc(1) && spotLoc(1) < ROI(1)+ROI(3) && ROI(2) < spotLoc(2) && spotLoc(2) < ROI(2)+ROI(4) );
                end
                if ~keepROI
                    index = ~index;
                end
                gridData(selection).([color1 color2 'ColocSpotData']) = gridData(selection).([color1 color2 'ColocSpotData'])(index);
                gridData(selection).([color1 color2 'ColocSpots']) = length(gridData(selection).([color1 color2 'ColocSpotData']));
                
                countedIndex = cellfun(@isnumeric, {gridData.([color1 color2 'ColocSpots'])});
                statsByColor.(['pct' color1 'Coloc_w_' color2]) = 100 * sum(cell2mat({gridData(countedIndex).([color1 color2 'ColocSpots'])})) / sum(cell2mat({gridData(countedIndex).([color1 'SpotCount'])}));
            end
        end
        
        %Photobleaching data
        if isfield(statsByColor, [color1 'TracesAnalyzed']) && isnumeric(gridData(selection).([color1 'GoodSpotCount']))
            counts = {gridData(selection).([color1 'SpotData']).nSteps};
            nosteps = cellfun(@(x) any(x(:)==0),counts);
            rejected = strcmp(counts,'Rejected');
            badspots = sum(rejected) + sum(nosteps);
            gridData(selection).([color1 'GoodSpotCount']) = gridData(selection).([color1 'SpotCount']) - badspots;
            
            for f = 1:20
                fsteps = cellfun(@(x) any(x(:)==f),counts);
                gridData(selection).([color1 'StepDist'])(f) = sum(fsteps);
            end
            
            countedIndex = cellfun(@isnumeric, {gridData.([color1 'GoodSpotCount'])});
            statsByColor.([color1 'TracesAnalyzed']) = sum(cell2mat({gridData(countedIndex).([color1 'SpotCount'])}));
            statsByColor.([color1 'BadSpots']) = sum(cell2mat({gridData(countedIndex).([color1 'SpotCount'])})) - sum(cell2mat({gridData(countedIndex).([color1 'GoodSpotCount'])}));
            statsByColor.([color1 'StepHist']) = sum(cell2mat({gridData.([color1 'StepDist'])})');
        end
            
    end

    % Save data
    varToSave = {'nPositions', 'nChannels', 'gridData', 'channels', 'statsByColor', 'params'};
    save([matPath filesep matFile], varToSave{:});
    summary = updateSummaryTable(matFile, matPath, statsByColor);