% Counts photobleaching steps in dynamic SiMPull data. All channels are
% analyzed (but note that in not all cases will the results for all
% channels be informative). 

function countDynamicBleaching(varargin)
warning('off'); %Prevent unnecessary warnings from libtiff

if nargin==1
    matFiles = varargin{1};
else
    % Ask user for data files
    matFiles = uipickfiles('Prompt','Select data files to analyze','Type',{'*.mat'});
end

fileBar = waitbar(0);
for a = 1:length(matFiles)  
    % Get file name
    slash = strfind(matFiles{a},filesep);
    fileName = matFiles{a}(slash(end)+1:end); 

    % Get Directory
    if isfolder(matFiles{a})
        fileName = [fileName '.mat'];
        expDir = matFiles{a};
        if ~isfile([expDir filesep fileName])
            warndlg(['No .mat file found for selected folder ' expDir]);
            continue
        end
    else
        expDir = matFiles{a}(1:slash(end));
    end
    
    % Load data structure
    load([expDir filesep fileName],'dynData','params');
    %Extract channel info - this is just for code readability
    BaitChannel = params.BaitChannel;
    if ~strcmp(params.DataType, 'Composite Data')
        PreyChannel = params.PreyChannel;
    end
         
    %% Loop over spots, count spots for each
    waitbar((a-1)/length(matFiles),fileBar,strrep(['Counting Photobleaching Steps for ' fileName],'_','\_'));
    nSpots = length(dynData.([BaitChannel 'SpotData']));
    needsLongerTrace = false(params.nChannels,nSpots); %This variable will be set to true each time a spot doesn't bleach completely.
    for c = 1:nSpots
        %Bait Channel 
        countStepsDynamic(c, BaitChannel, params.baitChNum);
        %Prey Channel(s)
        if strcmp(params.DataType,'Composite Data')
            for g = params.preyChNums
                % We only care about preys that co-appear
                if dynData.([BaitChannel 'SpotData'])(c).(['appears_w_PreyCh' num2str(g)]) == true
                    countStepsDynamic(c, ['PreyCh' num2str(g)], g);
                end
            end
        else
            % We only care about preys that co-appear
            if dynData.([BaitChannel 'SpotData'])(c).(['appears_w_' PreyChannel]) == true
                countStepsDynamic(c, PreyChannel, params.preyChNums);
            end
        end
    end 

    %% Pull out longer intensity traces and re-count where needed
    if any(any(needsLongerTrace))
        waitbar((a-1)/length(matFiles),fileBar,strrep(['Loading Images for ' fileName],'_','\_'));
        % Locate image files
        d = uipickfiles_subs.filtered_dir([expDir filesep '*.tif'],'',false,@(x,c)uipickfiles_subs.file_sort(x,[1 0 0],c)); % See comments in uipickfiles_subs for syntax here
        imgFile = arrayfun(@(x) [x.folder filesep x.name], d, 'UniformOutput', false);
        % Since data have been previously processed, the data files will include average and difference images generated by detectCoAppearance.m 
        % These images end with 'Img.tif' and will be excluded in the imgFile list.
        index = arrayfun(@(x) ~endsWith([x.name],'Img.tif'), d);
        imgFile = imgFile(index);
        if length(imgFile) > 1 %if there are multiple files
            nFiles = length(imgFile);
            stackOfStacks = cell(nFiles,1);
            % Each file will be loaded as a TIFFStack object, then concatenated together.
            % Order is determined by the user via uipickfiles
            for e = 1:nFiles
                stackOfStacks{e} = TIFFStack(imgFile{e},[],params.nChannels);
            end
            stackObj = TensorStack(4, stackOfStacks{:});
        else
            % If there's just a single TIFF file, it's simpler
            stackObj = TIFFStack(imgFile{1},[],params.nChannels);
        end
        dataSize = size(stackObj);
        tmax = dataSize(end);
        traceLength = length(dynData.([BaitChannel 'SpotData'])(1).intensityTrace);
        
        % Load image data piecewise into memory, get longer traces and re-count
        appearedInWindow = [dynData.([BaitChannel 'SpotData']).appearedInWindow];
        traceFirstFrame = (appearedInWindow - 1) .* params.window + 1;
        statusBar = waitbar(0);
        for d = traceLength:traceLength:tmax-1
            waitbar(d/(tmax-1),statusBar,'Extracting longer intensity traces');
            traceWindowStart = d+1;
            traceWindowEnd = min(d+traceLength, tmax);
            firstFrameIdx = traceFirstFrame < traceWindowStart;
           
            % Bait Channel
            pullThisTrace = firstFrameIdx & needsLongerTrace(params.baitChNum,:);
            if any(pullThisTrace) 
                getLongerTraces(pullThisTrace, BaitChannel, params.baitChNum, traceWindowStart, traceWindowEnd);
            end

            %Prey Channel(s)
            if strcmp(params.DataType,'Composite Data')
                for h = params.preyChNums
                    pullThisTrace = firstFrameIdx & needsLongerTrace(h,:);
                    if any(pullThisTrace) 
                        getLongerTraces(pullThisTrace, ['PreyCh' num2str(h)], h, traceWindowStart, traceWindowEnd);
                    end
                end
            else
                pullThisTrace = firstFrameIdx & needsLongerTrace(params.preyChNums,:);
                if any(pullThisTrace) 
                    getLongerTraces(pullThisTrace, PreyChannel, params.preyChNums, traceWindowStart, traceWindowEnd);
                end
            end         
        end

    end
       
    %% Save 
    waitbar((a-1)/length(matFiles),fileBar,strrep(['Saving ' fileName],'_','\_'));
    save([expDir filesep fileName], 'dynData','params', "-v7.3");
end

close(fileBar)

    %% Helper function to count bleaching events for a single trace
    % Since this is a nested function, it can access variables from the parent
    function countStepsDynamic(spotNum, channel, chNum)
        if isempty(dynData.([channel 'SpotData'])(spotNum).changepoints) % No dwell time info available if there are no steps
            dynData.([channel 'SpotData'])(spotNum).nFluors = NaN;
            return
        end
        
        spotData = dynData.([channel 'SpotData'])(spotNum); % Copy data for just this spot - for code readability purposes
        % Find the appearance, count intervening steps and check for disappearance
        appearanceStep = 0;
        disappearanceStep = 0;
        
        [nSteps, ~] = size(spotData.changepoints);
        nFluors = 0;
    
        for b = 1:nSteps
            if ~appearanceStep
                if spotData.steplevels(b) < spotData.steplevels(b+1)
                    appearanceStep = b;
                end
            elseif ~disappearanceStep
                % Here we find the disappearance time by looking for the intensity to return to its initial value.  
                if ( ( spotData.steplevels(b+1) - spotData.steplevels(appearanceStep) ) < spotData.stepstdev(b+1) ) || ( spotData.steplevels(b+1) - spotData.steplevels(1) ) < spotData.stepstdev(b+1)
                    disappearanceStep = b;
                    nFluors = nFluors + 1; %Increment the number of detected fluorescent molecules
                elseif ( spotData.steplevels(b+1) < spotData.steplevels(b) ) % Decrease in intensity
                    nFluors = nFluors + 1; %Increment the number of detected fluorescent molecules
                elseif ( ( spotData.steplevels(b+1) - spotData.steplevels(b-1) ) < spotData.stepstdev(b+1) ) || ( ( spotData.steplevels(b+1) - spotData.steplevels(b-1) ) < spotData.stepstdev(b-1) ) %Next level equals previous level - suggests blinking
                    nFluors = nFluors - 1; %Decrement the number of detected molecules, to correct for blinking - this isn't perfect, but good enough for a first pass
                end
            end
        end
        
        % Check results
        % If there's no appearance, we can't do anything - let's get out of here
        if ~appearanceStep
            dynData.([channel 'SpotData'])(spotNum).nFluors = NaN;
            return
        end
        
        if disappearanceStep
            needsLongerTrace(chNum,spotNum) = false;
        else
            % If there's no disappearance, we need to go back and extract a longer trace 
            needsLongerTrace(chNum,spotNum) = true;
        end
        % If we've made it to this point, we can safely return a number of estimated molecules 
        dynData.([channel 'SpotData'])(spotNum).nFluors = nFluors;
    end

    %% Helper function to extract longer intensity traces for spots that didn't fully photobleach
    function getLongerTraces(traceIdx, channel, chNum, firstFrame, lastFrame)
        tempData.SpotData = struct('spotLocation', {dynData.([channel 'SpotData']).spotLocation}); %Temporary structure to hold the new traces
        subStack = stackObj(:,:,chNum,firstFrame:lastFrame);
        tempData = extractIntensityTraces('',subStack,params,tempData,traceIdx);
        % Concatenate to existing data and re-count
        for f = find(traceIdx)
            dynData.([channel 'SpotData'])(f).intensityTrace = horzcat(dynData.([channel 'SpotData'])(f).intensityTrace(1:firstFrame-traceFirstFrame(f)), tempData.SpotData(f).intensityTrace);
            [results, error] = find_changepoints_c(dynData.([channel 'SpotData'])(f).intensityTrace, 2);
            dynData.([channel 'SpotData'])(f).changepoints = results.changepoints;
            dynData.([channel 'SpotData'])(f).steplevels = results.steplevels;
            dynData.([channel 'SpotData'])(f).stepstdev = results.stepstdev;
            countStepsDynamic(f, channel, chNum);
        end
    end
end
