function [gridData, statsByColor, threshold, aborted] = stepSizeFilter(varargin) 
% To run as a function, call stepSizeFilter(gridData, channel, statsByColor, threshold); 
% threshold parameter may be either a number (the threshold), or one of'Aggressive', 'Moderate' or 'Conservative' filtering modes.
% Aggressive filter tosses 99% of noise peak; conservative filter keeps 99% of signal peak; 
% moderate filter (default) draws threshold at the local minimum between signal and noise peaks.

% NOTE: This function is intended to deal with only a single channel and
% does not update colocalization data.  To do so, call coloc_spots separately.

    %Filters photobleaching step data by removing small steps based on a
    %calculated threshold.
    
    if nargin < 1
        [filename,pathname] = uigetfile(pwd,'Select a .mat file with data from the spot counter');
        infile = [pathname filesep filename];
        load(infile);
        if nChannels > 1
            channel = questdlg('Multi-Channel Data Found. Select Channel to Filter',...
                       'Select Channel',...
                       channels{:},channels{1});
        else
            channel = channels{1};
        end
        saveOutput = true;
    else
        saveOutput = false;
        gridData = varargin{1};
        channel = varargin{2};
        statsByColor = varargin{3};
        %Calculate the intensity threshold or get it from the arguments
        if isnumeric(varargin{4})
            threshold = varargin{4};
        else
            if any(strcmp(varargin{4},{'Aggressive' 'Conservative' 'Moderate'}))
                filterStrength = varargin{4};
            else
                warning('Invalid threshold provided; using the default instead');
                filterStrength = 'Moderate';
            end
            [threshold, aborted] = calculateIntensityThreshold(gridData, channel, filterStrength);
            if aborted
                warndlg('Could not calculate intensity threshold');
                return
            end
        end
        
    end
    
    gridSize = size(gridData);
    nPositions = gridSize(1)*gridSize(2);

    newStepHist = zeros(20,1);        
    
    %Apply intensity filter
    for a = 1:nPositions        
        
        %Skip this position if step counting wasn't done (due to too many steps) 
        if ~isnumeric(gridData(a).([channel 'GoodSpotCount']))
            continue
        end
        
        gridData(a).([channel 'StepDist']) = zeros(20,1); %Erase the step histogram - we'll regenerate it as we go
        
        %Get data
        posSpotData = gridData(a).([channel 'SpotData']);
        index = true(length(posSpotData),1); %Used later for eliminating spots
        for c = 1:length(posSpotData)
            spotData = posSpotData(c);
           
            %If the trace was previously rejected, we'll un-reject it and see if it can be salvaged 
            if strcmp(spotData.nSteps, 'Rejected')
                spotData.nSteps = length(spotData.steplevels) - 1;
                statsByColor.([channel 'BadSpots']) = statsByColor.([channel 'BadSpots']) -1;
            end
            
            % Eliminate this spot and move on if total intensity is below the threshold. 
            % This will also eliminate dim spots that don't bleach
            if spotData.steplevels(1) < threshold
                index(c) = 0;
                continue
            end
            
            %Continue with filtering individual steps
            nSteps = spotData.nSteps;
            b = 1;
            while b <= nSteps
                stepSize = abs(spotData.steplevels(b) - spotData.steplevels(b+1));
                if stepSize < threshold
                    % We are going to eliminate a step.  
                    % This if stmt makes sure that if two small steps are right next to each other, the smaller one gets eliminated
                    if b < nSteps
                       nextStepSize = spotData.steplevels(b+1) - spotData.steplevels(b+2);
                       if nextStepSize < stepSize && nextStepSize + stepSize >= threshold
                           b = b+1;
                           continue
                       end
                    end

                    %Now eliminate the step
                    if b == 1
                        prevchangepoint = 1;
                    else
                        prevchangepoint = spotData.changepoints(b-1,1);
                    end
                    if b == nSteps
                        nextchangepoint = length(spotData.intensityTrace);
                    else
                        nextchangepoint = spotData.changepoints(b+1,1);
                    end
                    spotData.steplevels(b) = mean(spotData.intensityTrace(prevchangepoint:nextchangepoint));
                    spotData.steplevels(b+1) = [];
                    spotData.stepstdev(b) = std(spotData.intensityTrace(prevchangepoint:nextchangepoint));
                    spotData.stepstdev(b+1) = [];                    
                    spotData.nSteps = spotData.nSteps - 1;
                    nSteps = spotData.nSteps;
                    spotData.changepoints(b,:) = [];
                    b = 1; % After eliminating a step, go back and start over to make sure we get rid of all of the small ones
                else
                    b = b+1;
                end
            end
            
            %Reject trace if it shows a step up in intensity
            for d = 1:(length(spotData.steplevels) - 1)
                if spotData.steplevels(d) < spotData.steplevels(d+1)
                    spotData.nSteps = 'Rejected';
                    nSteps = 'Rejected';
                    statsByColor.([channel 'BadSpots']) = statsByColor.([channel 'BadSpots']) + 1;
                    break
                end
            end
            
            %Save resuls for this spot
            posSpotData(c) = spotData;
            if isnumeric(nSteps) && nSteps>0
                gridData(a).([channel 'StepDist'])(nSteps) = gridData(a).([channel 'StepDist'])(nSteps) + 1;
            end
        end
        
        %Save results for the whole image
        posSpotData = posSpotData(index); %This elminates spots that were found to be too dim 
        gridData(a).([channel 'SpotData']) = posSpotData;
        
        %Tabulate the spot counts 
        newStepHist = newStepHist + gridData(a).([channel 'StepDist']);
        gridData(a).([channel 'SpotCount']) = length(posSpotData);
        gridData(a).([channel 'GoodSpotCount']) = sum(gridData(a).([channel 'StepDist']));
        
    end
    %Update statsByColor
    statsByColor.(['total' channel 'Spots']) = sum(cell2mat({ gridData.([channel 'SpotCount']) }) );
    statsByColor.(['avg' channel 'Spots']) = statsByColor.(['total' channel 'Spots']) / nPositions;
    statsByColor.([channel 'StepHist']) = newStepHist;
    
    index2 = cellfun(@(x) isnumeric(x), {gridData.([channel 'GoodSpotCount'])});
    statsByColor.([channel 'BadSpots']) = sum(cell2mat( {gridData(index2).([channel 'SpotCount'])} )) - sum(cell2mat( {gridData(index2).([channel 'GoodSpotCount'])} ));

    statsByColor.([channel 'TracesAnalyzed']) = statsByColor.([channel 'BadSpots']) + sum(statsByColor.([channel 'StepHist']));
    
    aborted = false;
    
    if saveOutput 
        dataName = filename(1 : extIdx-1);
        outFileName = [dataName '_filtered.mat'];
        save([pathname filesep outFileName],'gridData', 'channels', 'nChannels', 'nPositions', 'statsByColor', 'threshold','-append');
    end