function dynData = detectCoAppearance(varargin)

%  This program is for analyzing SiMPull data in which the binidng of bait
%  proteins to the coverslip is monitored in real time following cell
%  lysis. 
%
%  The program first uses diff followed by probabilistic segmentation to
%  identify spots that appear in the bait channel during an acquisiton.  
%  Then, those spots are analyzed to determine their time of appearance 
%  and whether spots in a prey channel co-appear. 
%
%  Any up-step in prey intensity coincinding with bait appearance is 
%  counted as a co-appearance event, regardless of whether it's the 
%  first up-step in the prey channel.
%
%  This function can be run in two modes.  If called with no arguments, the
%  user is asked to select files to analyze and set options; this works well 
%  for processing a single dataset.  Alternatively, a cell array containing
%  the paths to the images to be analyzed can be passed in along with
%  channel and registration information, by calling 
%  >> detectCoAppearance(imgFilesCellArray, DialogBoxAnswers, regData)
%
%  This latter usage is not meant to be called directly by the user;
%  instead run the batchDetectCoAppearance.m wrapper script. 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Adjustable parameters for spot detection are here                                                 %
params.psfSize = 1;                                                                                 %
params.fpExp = 1e-5; %Expectation value for false positive objects in probabilistic segmentation    %
params.poissonNoise = 0; %Set this option to 1 if photon shot noise dominates detector noise        %
params.window = 50; %Temporal averaging window for spot detection                                   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Set up
warning('off'); %Prevent unnecessary warnings from libtiff
if nargin == 0 
    % Ask user for images. Multiselect is used here because sometimes Micro-Manager splits long time series into pieces. 
    imgFile = uipickfiles('Prompt','Select image files to analyze and arrange them in order','Type',{'*.tif','TIF-file'});

    % Get image name and root directory
    slash = strfind(imgFile{1},filesep);
    expDir = imgFile{1}(1:slash(end));

    % Options dialog box
    [Answer,Cancelled] = dynamicChannelInfoDlg(expDir);
    if Cancelled 
        return
    else
        v2struct(Answer);
        DataType = 'Composite Data';  %% Data types are deprecated, set here to preserve backward compatibility
        params.isNDTiff = exist('tiffType','var') && regexp(tiffType,'NDTiff');
    end
    
    % Image registration
    if strcmp(DataType,'Composite Data')
        % Register composite images
        regImg = TIFFStack(regFile,[],nChannels);
        subImg = regImg(:,:,:,RegWindow1:RegWindow2);
        avgImg = mean(subImg, 4);
        for g = 1:nChannels 
            if g == baitChNum 
                continue 
            else
                regData(g) = registerImages( avgImg(:,:,g), avgImg(:,:,baitChNum) );
            end
        end
    else
        % Register side-by-side dual-view images
        regImg = TIFFStack(regFile);
        subImg = regImg(:,:,RegWindow1:RegWindow2);
        avgImg = mean(subImg, 3);
        [~, xmax] = size(avgImg);
        leftImg = avgImg(:,1:(xmax/2));
        rightImg = avgImg(:,(xmax/2)+1:xmax);
        regData = registerImages(rightImg, leftImg);
    end
    % We don't save the registration info here because it's saved as part of each individual file below.  
    % Instead we just hang on to the regData variable for later use.
elseif nargin == 3
    imgFile = varargin{1};
    slash = strfind(imgFile{1},filesep);
    expDir = imgFile{1}(1:slash(end));  
    
    Answer = varargin{2};
    v2struct(Answer);
    regData = varargin{3};
    DataType = 'Composite Data';  %% Data types are deprecated, set here to preserve backward compatibility
    params.isNDTiff = exist('tiffType','var') && startsWith(tiffType,'NDTiff');
else
    error('Incorrect number of input arguments given. Call detectCoAppearance(imgFilesCellArray, DialogBoxAnswers, regData) to provide parameters, or call with no arguments to raise dialog boxes.');
end

%% Detect Co-appearance: Save parameters for future use and branch based on image type
params.DataType = DataType;
params.pixelSize = pixelSize;
params.RegistrationData = regData; 
params.RegFile = regFile;
if strcmp(DataType,'Composite Data')
    % if nChannels == 1 
    %     error('Composite data should have more than one channel');
    % end
    params.nChannels = nChannels;
    params.baitChNum = baitChNum;
    params.BaitChannel = 'Bait';
    %% Load images
    wb = waitbar(0,'Loading Images...','Name',strrep(['Analyzing Experiment ' expDir],'_','\_'));       
    tempDir = [userpath filesep 'temp'];
    % Find out if file is local or on a network drive
    remote = isNetworkDrive(imgFile{1});
    if length(imgFile) > 1 %if the user selected multiple files
        slash = strfind(expDir,filesep);
        imgName = expDir(slash(end-1)+1 : end-1);
        nFiles = length(imgFile);
        stackOfStacks = cell(nFiles,1);
        if remote
            % Download files from pod - this is faster than opening over the network
            copyfile(expDir,[tempDir filesep imgName]);
            % Each file will be loaded as a TIFFStack object, then concatenated together.
            % We use TIFFStack even for NDTiff files, as it's faster than the native NDTiff opener.
            % Order is determined by the user via uipickfiles, or guessed at automatically in batch mode
            for a = 1:nFiles
                localFile{a} = [tempDir filesep imgName filesep imgFile{a}(slash(end):end)];        
                stackOfStacks{a} = TIFFStack(localFile{a},[],params.nChannels);
            end
        else
            for a = 1:nFiles     
                stackOfStacks{a} = TIFFStack(imgFile{a},[],params.nChannels);
            end
        end
        stackObj = TensorStack(4, stackOfStacks{:});
    else
        % If there's just a single TIFF file, it's simpler
        slash = strfind(expDir,filesep);
        imgName = expDir(slash(end-1)+1 : end-1);
        if remote
            copyfile(expDir,[tempDir filesep imgName]);
            localFile = [tempDir filesep imgName filesep imgFile{1}(slash(end):end)];
            stackObj = TIFFStack(localFile,[],params.nChannels);
        else
            stackObj = TIFFStack(imgFile{1},[],params.nChannels);
        end
    end
    [dynData, params] = detCoApp_comp(expDir,stackObj,params,wb);
else
    params.LeftChannel = LeftChannel;
    params.RightChannel = RightChannel;
    params.BaitPos = BaitPos;
    params.BaitChannel = Answer.([BaitPos 'Channel']); 
    [imgName, dynData, params] = detCoApp_dv(expDir,imgFile,params);
end

%% Run blinkerFinder.m
dynData = blinkerFinder(dynData,params.BaitChannel);

%% Plot coAppearance over time
% Calculated time elapsed between embryo lysis and data acquisition and save in params
elapsedTime = getElapsedTime(expDir, imgName, params.isNDTiff);
params.elapsedTime = elapsedTime;
% Create and save plot
params = coApp_vs_time(dynData,params,expDir);

%% Optionally count photobleaching steps
if countBleaching
    dynData = countDynamicBleaching(dynData,params,stackObj);
end

%% Save data
save([expDir(1:end-1) '.mat'], 'dynData','params',"-v7.3");

% Delete Temp Files
if strcmp(DataType,'Composite Data') && remote
    clear stackObj
    delete([tempDir filesep imgName]);
end
end


%% Functions for Individual Data Types

%% Composite data (Images are ImageJ hyperstacks with multiple channels) 
function [dynData, params] = detCoApp_comp(expDir,stackObj,params,wb)
    %% Find difference peaks
    waitbar(0,wb,'Finding bait protein appearances...');
    % Figure out what portion of the image we're going to work with and set x indices accordingly
    [ymax, xmax, ~, tmax] = size(stackObj);

    % Save image size
    params.imageY_X = [ymax, xmax];

    % Calculate windowed average and difference images
    avgImg = windowMean(stackObj,params.window);
    diffImg = diff(avgImg,1,4); % "1" for first derivative, "4" for fourth (time) dimension
    % Note that since the first diff we take is between the first and second windows, spots appearing 
    % during the first few frames (early in the first window) might be missed. This is ok for now.

    %% Save average and difference images
    % Check if data have already been processed. If so, check if the value of 'window' has changed.
    newAvg = false;
    if exist([expDir(1:end-1) '.mat'], 'file')
        existingData = load([expDir(1:end-1) '.mat'], 'dynData');
        % If a different number of windows were used previously, make newAvg flag true for next step
        if existingData.dynData.avgWindow ~= params.window
            newAvg = true;
        end
        clear existingData
    end

    [~,~,~,ndiffs] = size(diffImg); 
    % Check if any windowed average and difference images exist before saving
    if exist([expDir(1:end-1) '_avgImg.tif'], 'file')||exist([expDir(1:end-1) '_diffImg.tif'], 'file')
        if newAvg % If averaging window has been changed, delete all existing files
           warning('off','all');
           delete ([expDir(1:end-1) '_avgImg.tif']);
           delete ([expDir(1:end-1) '_diffImg.tif']);
           % Save difference images with new averaging window
           for w=1:ndiffs
               for v=1:params.nChannels
                    imwrite(uint16(diffImg(:,:,v,w)),[expDir(1:end-1) '_diffImg.tif'],'tif','WriteMode','append','Compression','none');
               end
           end
           % Save average images
           for w=1:ndiffs+1
               for v=1:params.nChannels
                   imwrite(uint16(avgImg(:,:,v,w)),[expDir(1:end-1) '_avgImg.tif'],'tif','WriteMode','append','Compression','none');
               end
           end
        end
    else % Save if no images yet exist
        for w=1:ndiffs
            for v=1:params.nChannels
                imwrite(uint16(diffImg(:,:,v,w)),[expDir(1:end-1) '_diffImg.tif'],'tif','WriteMode','append','Compression','none');
           end
        end
        for w=1:ndiffs+1
            for v=1:params.nChannels
                imwrite(uint16(avgImg(:,:,v,w)),[expDir(1:end-1) '_avgImg.tif'],'tif','WriteMode','append','Compression','none');
            end
        end
    end

    %% Run PS on the bait channel
    lastFoundSpots = {};
    for b = 1:ndiffs
        %% Probabilistic Segmentation
        waitbar((b-1)/ndiffs,wb);
        % Run PS for the difference images
        psDiffResults = spotcount_ps('Bait', diffImg(:,:,params.baitChNum,b), params, struct('dataFolder',expDir,'avgWindow',params.window), 1);
        
        if b==1 %...unless this is the first time through the loop
            dynData = psDiffResults;
            [dynData.BaitSpotData.appearedInWindow] = deal(b); %Save info about when these spots appeared
            %Put PS data in a temporary structure foundSpots (by default, lastFoundSpots in first loop iteration)
            [lastFoundSpots] = {psDiffResults.BaitSpotData.spotLocation}'; %Save foundSpots for the next iteration of the loop
        else
            [dynData,lastFoundSpots] = filterLastFoundSpots(psDiffResults,dynData,lastFoundSpots,'Bait',b);
        end
        
    %% Extract intensity traces and find the actual time of spot appearance
        % Intensity extraction
        % Doing this in the same loop  as PS allows pulling only the part of the trace we actually care about - 
        % where the spot appeared.

        % Load the appropriate portion of the image into memory - this makes trace extraction much faster.
        if b==1
            % The first time through the loop, we just want the first 500 frames
            subStack = squeeze(stackObj(:,:,params.baitChNum,1:500));
        else
            % On subsequent iterations, shift the portion of the image in memory by 1 window
            startTime = (b-1) * params.window + 451;
            endTime = min(b * params.window + 450, tmax);
            subStack = cat(3, subStack(:,:,params.window+1:end), squeeze(stackObj(:,:,params.baitChNum,startTime:endTime)));
        end

        % Get intensity traces
        dynData = extractIntensityTraces('Bait', subStack, params, dynData);
    end
    
    % Make sure the BaitSpotData structure is organized as a column vector
    if isrow(dynData.BaitSpotData)
        dynData.BaitSpotData = dynData.BaitSpotData';
    end

    % Count the total number of bait spots across difference images
    [dynData.BaitSpotCount,~] = size(dynData.BaitSpotData);

    % Detect up-steps in intensity
    dynData = findAppearanceTimes(dynData, 'Bait');
    
    %% Find co-appearing spots in each prey channel
    % We don't do spot detection for the prey channel; 
    % instead, just copy the positions of spots found in the bait channel and apply a registration correction.
    % At the same time, identify and ignore bait spots that are so close to the edge that they aren't visible in the prey channel
    waitbar(0,wb,'Getting prey intensity traces...');
    params.preyChNums = [];
    for j = 1:params.nChannels
        if j == params.baitChNum
            continue %Skip the bait channel
        end
        params.preyChNums(end+1) = j; %Save information about which channel numbers are prey
        preyChannel = ['PreyCh' num2str(j)];
        dynData.([preyChannel 'SpotData']) = struct('spotLocation',[]);
        index = true(dynData.BaitSpotCount,1);
        for d = 1:dynData.BaitSpotCount
            % Inverse affine transformation to calculate the bait spot location within the prey image
            preySpotLocation = round(transformPointsInverse(params.RegistrationData(j).Transformation, dynData.BaitSpotData(d).spotLocation) );
            if preySpotLocation(1) < 6 || preySpotLocation(1) > xmax-5 || preySpotLocation(2) < 6 || preySpotLocation(2) > ymax-5
                index(d) = false; %Ignore this spot if it doesn't map within the prey image or is too close to the edge
            else
                dynData.([preyChannel 'SpotData'])(d,1).spotLocation = preySpotLocation; %Add this location to the places to check for prey
            end
        end
        % Ignore spots that are too close to the edge
        dynData.BaitSpotData = dynData.BaitSpotData(index);
        for g = params.preyChNums
            dynData.(['PreyCh' num2str(g) 'SpotData']) = dynData.(['PreyCh' num2str(g) 'SpotData'])(index);
        end
        [dynData.BaitSpotCount,~] = size(dynData.BaitSpotData); %Count how many bait spots are left
    
        % Pull intensity traces for the prey
        if dynData.BaitSpotCount > 0 %This if statement prevents crashing if no spots were found
            nWindows = dynData.BaitSpotData(end).appearedInWindow;
            for e = 1:nWindows
                waitbar((e-1)/nWindows,wb);
                % Load the appropriate portion of the image into memory
                if e==1
                    % The first time through the loop, we just want the first 500 frames
                    subStack = squeeze(stackObj(:,:,j,1:500));
                else
                    % On subsequent iterations, shift the portion of the image in memory by 1 window
                    startTime = (e-1) * params.window + 451;
                    endTime = min(e * params.window + 450, tmax);
                    subStack = cat(3, subStack(:,:,params.window+1:end), squeeze(stackObj(:,:,j,startTime:endTime)) );
                end
                index = e==cell2mat({dynData.BaitSpotData.appearedInWindow});
                [dynData.([preyChannel 'SpotData'])(index).appearedInWindow] = deal(e);
                dynData = extractIntensityTraces(preyChannel, subStack, params, dynData, index);
            end
            
            %% Find co-appearing spots
            dynData = findCoApp(dynData, 'Bait', preyChannel, wb);
        end
    end
    close(wb)
end

function [dynData,lastFoundSpots] = filterLastFoundSpots(psDiffResults,dynData,lastFoundSpots,baitChName,currentFrame)
    % The baitDiff approach will tend to find the same object in two consecutive windows. So now we need 
    % to go through the list of found spots and keep only those that weren't found previously. 
    [foundSpots] = {psDiffResults.([baitChName 'SpotData']).spotLocation}';
    for c = 1:psDiffResults.([baitChName 'SpotCount'])
        query = cell2mat(foundSpots(c));
        if ~isempty(lastFoundSpots) && ~isempty(lastFoundSpots{1}) % This If statement protects against errors when no spots were found in the previous frame.
            match = find(cellfun(@(x) sum(abs(x-query))<3, lastFoundSpots)); %Peaks <3 pixels from a previously-found peak are ignored
        else
            match = [];
        end
        if isempty(match) %If we didn't find a match, that means it's a new spot. Add it to the main data structure
            psDiffResults.([baitChName 'SpotData'])(c).appearedInWindow = currentFrame; %Save info about when this spot appeared
            dynData.([baitChName 'SpotData'])(end+1) = psDiffResults.([baitChName 'SpotData'])(c);
        end
    end
    lastFoundSpots = foundSpots; %Save the list of spots found this time to compare to the next time through the loop
end


function dynData = findCoApp(dynData, baitChannel, preyChannel, wb)
    % Find spots that appear at the same time. Here a "greedy" algorithm is
    % used that counts any up-step in prey intensity coincinding with bait appearance as a co-appearance
    % event, regardless of whether it's the first up-step in the prey channel
    waitbar(0,wb,'Finding prey co-appearance events...');
    for c = 1:dynData.([baitChannel 'SpotCount'])
        waitbar((c-1)/dynData.([baitChannel 'SpotCount']),wb);
        %Detect Changepoints
        traj = dynData.([preyChannel 'SpotData'])(c).intensityTrace;
        [results, error] = find_changepoints_c(traj,2);
        dynData.([preyChannel 'SpotData'])(c).changepoints = results.changepoints;
        dynData.([preyChannel 'SpotData'])(c).steplevels = results.steplevels;
        dynData.([preyChannel 'SpotData'])(c).stepstdev = results.stepstdev;
        if error
            dynData.([preyChannel 'SpotData'])(c).appearTimeFrames = 'Analysis Failed';
            dynData.([baitChannel 'SpotData'])(c).(['appears_w_' preyChannel]) = NaN;
            continue
        end

        %Look for an upstep at the appearance time
        if isnumeric(dynData.([baitChannel 'SpotData'])(c).appearTimeFrames)
            baitAppearTime = dynData.([baitChannel 'SpotData'])(c).appearTimeFrames;

            % Make sure there is a step to be tested 
            if ~isempty(dynData.([preyChannel 'SpotData'])(c).changepoints)
                preyStepTimes = dynData.([preyChannel 'SpotData'])(c).changepoints(:,1) + dynData.avgWindow * (dynData.([preyChannel 'SpotData'])(c).appearedInWindow - 1);
            else
                % If there are no steps in the prey channel, we're done - it can't co-appear
                dynData.([baitChannel 'SpotData'])(c).(['appears_w_' preyChannel]) = false;
                continue 
            end
            matchingStep = find( abs(baitAppearTime - preyStepTimes) <= 4 );  %Spots appearing within 4 frames of each other are considered simultaneous

            if ~isempty(matchingStep) && dynData.([preyChannel 'SpotData'])(c).steplevels(max(matchingStep)+1) > dynData.([preyChannel 'SpotData'])(c).steplevels(min(matchingStep)) % && the intensity has to increase (otherwise it's not an appearance event)
                                                                                                                                                                                     % The "min" and "max" avoid crashing when more than one step matches.
                dynData.([baitChannel 'SpotData'])(c).(['appears_w_' preyChannel]) = true;
            else
                dynData.([baitChannel 'SpotData'])(c).(['appears_w_' preyChannel]) = false;
            end

        else
            dynData.([baitChannel 'SpotData'])(c).(['appears_w_' preyChannel]) = NaN;
        end
    end

    % Tally results
    dynData.([baitChannel 'AppearanceFound']) = sum( isnumeric([ dynData.([baitChannel 'SpotData']).appearTimeFrames ]) ) ;
    dynData.([baitChannel preyChannel 'CoAppearing']) = sum([ dynData.([baitChannel 'SpotData']).(['appears_w_' preyChannel]) ], 'omitnan');
end

%% Dual-view data (side-by-side images)
% Deprecated; preserved for backwards-compatibility only
function [imgName, dynData, params] = detCoApp_dv(expDir,imgFile,params)
    %% Load images
    wb = waitbar(0,'Loading Images...','Name',strrep(['Analyzing Experiment ' expDir],'_','\_'));
    if length(imgFile) > 1 %if the user selected multiple files
        nFiles = length(imgFile);
        stackOfStacks = cell(nFiles,1);
        % Each file will be loaded as a TIFFStack object, then concatenated together.
        % Order is determined by the user via uipickfiles
        for a = 1:nFiles
            stackOfStacks{a} = TIFFStack(imgFile{a});
        end
        stackObj = TensorStack(3, stackOfStacks{:});
    else
        % If there's just a single TIFF file, it's simpler
        stackObj = TIFFStack(imgFile{1});
    end

    %% Find difference peaks
    waitbar(0,wb,'Finding bait protein appearances...');
    % Figure out what portion of the image we're going to work with and set x indices accordingly
    [ymax, xmax, tmax] = size(stackObj);
    if strcmp(params.BaitPos, 'Left')
        xmin = 1;
        xmax = xmax/2;
        preyPos = 'Right';
    elseif strcmp(params.BaitPos, 'Right')
        xmin = xmax/2 + 1;
        preyPos = 'Left';
    end
    % Save image size
    params.imageY_X = [ymax, xmax/2];

    % Calculate windowed average and difference images
    baitAvg = windowMean(stackObj,params.window,params.BaitPos);
    baitDiff = diff(baitAvg,1,3); % "1" for first derivative, "3" for third dimension
    % Note that since the first diff we take is between the first and second windows, spots appearing 
    % during the first few frames (early in the first window) might be missed. This is ok for now.

    % Calculate windowed prey channel images for later visualization
    preyAvg = windowMean(stackObj,params.window,preyPos); 
    preyDiff = diff(preyAvg,1,3);

    %% Save average and difference images for the bait and prey channels 
    % Check if data have already been processed. If so, check if the value of 'window' has changed.
    newAvg = false;
    slash = strfind(imgFile{1},filesep);
    imgName = imgFile{1}(slash(end)+1:strfind(imgFile{1},'_MMStack')-1); 
    if exist([expDir filesep imgName '.mat'], 'file')
        existingData = load([expDir filesep imgName '.mat'], 'dynData');
        % If a different number of windows were used previously, make newAvg flag true for next step
        if existingData.dynData.avgWindow ~= params.window
            newAvg = true;
        end
        clear existingData
    end

    [~,~,ndiffs] = size(baitDiff); 
    % Check if any windowed average and difference images exist before saving
    if exist([expDir filesep imgName '_baitAvg.tif'], 'file')||exist([expDir filesep imgName '_baitDiff.tif'], 'file')||exist([expDir filesep imgName '_preyAvg.tif'], 'file')||exist([expDir filesep imgName '_preyDiff.tif'], 'file')
        if newAvg % If averaging window has been changed, delete all existing files
           warning('off','all');
           delete ([expDir filesep imgName '_baitAvg.tif']);
           delete ([expDir filesep imgName '_baitDiff.tif']);
           delete ([expDir filesep imgName '_preyAvg.tif']);
           delete ([expDir filesep imgName '_preyDiff.tif']); 
           % Save bait and prey channel difference images with new averaging window
           for w=1:ndiffs
               imwrite(uint16(baitDiff(:,:,w)),[expDir filesep imgName '_baitDiff.tif'],'tif','WriteMode','append','Compression','none');
               imwrite(uint16(preyDiff(:,:,w)),[expDir filesep imgName '_preyDiff.tif'],'tif','WriteMode','append','Compression','none');
           end
           % Save bait and prey channel average images
           for w=1:ndiffs+1
               imwrite(uint16(baitAvg(:,:,w)),[expDir filesep imgName '_baitAvg.tif'],'tif','WriteMode','append','Compression','none');
               imwrite(uint16(preyAvg(:,:,w)),[expDir filesep imgName '_preyAvg.tif'],'tif','WriteMode','append','Compression','none');
           end
        end
    else % Save if no images yet exist
        for w=1:ndiffs
            imwrite(uint16(baitDiff(:,:,w)),[expDir filesep imgName '_baitDiff.tif'],'tif','WriteMode','append','Compression','none');
            imwrite(uint16(preyDiff(:,:,w)),[expDir filesep imgName '_preyDiff.tif'],'tif','WriteMode','append','Compression','none');
        end
        for w=1:ndiffs+1
            imwrite(uint16(baitAvg(:,:,w)),[expDir filesep imgName '_baitAvg.tif'],'tif','WriteMode','append','Compression','none');
            imwrite(uint16(preyAvg(:,:,w)),[expDir filesep imgName '_preyAvg.tif'],'tif','WriteMode','append','Compression','none');
        end
    end
    clear preyAvg preyDiff

    %% Run PS on the bait channel
    baitChannel = params.BaitChannel;
    [~,~,ndiffs] = size(baitDiff);
    lastFoundSpots = {};
    for b = 1:ndiffs
        %% Probabilistic Segmentation
        waitbar((b-1)/ndiffs,wb);
        % Run PS for the difference images
        psDiffResults = spotcount_ps(baitChannel, baitDiff(:,:,b), params, struct('dataFolder',expDir,'avgWindow',params.window), 1);
        % The baitDiff approach will tend to find the same object in two consecutive windows. So now we need 
        % to go through the list of found spots and keep only those that weren't found previously. 
        if b==1 %...unless this is the first time through the loop
            dynData = psDiffResults;
            [dynData.([baitChannel 'SpotData']).appearedInWindow] = deal(b); %Save info about when these spots appeared
            %Put PS data in a temporary structure foundSpots (by default, lastFoundSpots in first loop iteration)
            [lastFoundSpots] = {psDiffResults.([baitChannel 'SpotData']).spotLocation}'; %Save foundSpots for the next iteration of the loop
        else
            [dynData,lastFoundSpots] = filterLastFoundSpots(psDiffResults,dynData,lastFoundSpots,baitChannel,b);
        end   
    %% Extract intensity traces and find the actual time of spot appearance
        % Intensity extraction
        % Doing this in the same loop  as PS allows pulling only the part of the trace we actually care about - 
        % where the spot appeared.

        % Load the appropriate portion of the image into memory - this makes trace extraction much faster.
        if b==1
            % The first time through the loop, we just want the first 500 frames
            subStack = stackObj(:,xmin:xmax,1:500);
        else
            % On subsequent iterations, shift the portion of the image in memory by 1 window
            startTime = (b-1) * params.window + 451;
            endTime = min(b * params.window + 450, tmax);
            subStack = cat(3, subStack(:,:,params.window+1:end), stackObj(:,xmin:xmax,startTime:endTime));
        end

        % Get intensity traces
        dynData = extractIntensityTraces(baitChannel, subStack, params, dynData);   
    end
    clear baitAvg baitDiff 
    % Count the total number of bait spots across difference images
    [dynData.([baitChannel 'SpotCount']),~] = size(dynData.([baitChannel 'SpotData']));

    % Detect up-steps in intensity
    dynData = findAppearanceTimes(dynData, baitChannel);
    
    %% Find co-appearing spots in the prey channel
    % We don't do spot detection for the prey channel; 
    % instead, just copy the positions of spots found in the bait channel and apply a registration correction.
    % At the same time, identify and ignore bait spots that are so close to the edge that they aren't visible in the prey channel
    waitbar(0,wb,'Getting prey intensity traces...');
    if strcmp(params.BaitPos, 'Left')
        preyChannel = params.RightChannel;
    else
        preyChannel = params.LeftChannel;
    end
    
    dynData.([preyChannel 'SpotData']) = struct('spotLocation',[]);
    index = true(dynData.([baitChannel 'SpotCount']),1);
    for d = 1:dynData.([baitChannel 'SpotCount'])
        if strcmp(params.BaitPos, 'Left')
            % Inverse affine transformation if bait channel is on the left
            preySpotLocation = round( transformPointsInverse(params.RegistrationData.Transformation, dynData.([baitChannel 'SpotData'])(d).spotLocation) );
        else
            % Forward affine transformation if bait channel is on the right
            preySpotLocation = round( transformPointsForward(params.RegistrationData.Transformation, dynData.([baitChannel 'SpotData'])(d).spotLocation) );
        end
        if preySpotLocation(1) < 6 || preySpotLocation(1) > (xmax - xmin + 1)-5 || preySpotLocation(2) < 6 || preySpotLocation(2) > ymax-5
            index(d) = false; %Ignore this spot if it doesn't map within the prey image or is too close to the edge
        else
            dynData.([preyChannel 'SpotData'])(d,1).spotLocation = preySpotLocation; %Add this location to the places to check for prey
        end
    end
    % Ignore spots that are too close to the edge
    dynData.([baitChannel 'SpotData']) = dynData.([baitChannel 'SpotData'])(index);
    dynData.([preyChannel 'SpotData']) = dynData.([preyChannel 'SpotData'])(index);
    [dynData.([baitChannel 'SpotCount']),~] = size(dynData.([baitChannel 'SpotData'])); %Count how many bait spots are left

    % Pull intensity traces for the prey
    % Figure out x indices - opposite logic to the code above to get the opposite half
    if dynData.([baitChannel 'SpotCount']) > 0 %This if statement prevents crashing if no spots were found
        [~, xmax, tmax] = size(stackObj);
        if strcmp(params.BaitPos, 'Right')
            xmin = 1;
            xmax = xmax/2;
        elseif strcmp(params.BaitPos, 'Left')
            xmin = xmax/2 + 1;
        end
        nWindows = dynData.([baitChannel 'SpotData'])(end).appearedInWindow;
        for e = 1:nWindows
            waitbar((e-1)/nWindows,wb);
            % Load the appropriate portion of the image into memory
            if e==1
                % The first time through the loop, we just want the first 500 frames
                subStack = stackObj(:,xmin:xmax,1:500);
            else
                % On subsequent iterations, shift the portion of the image in memory by 1 window
                startTime = (e-1) * params.window + 451;
                endTime = min(e * params.window + 450, tmax);
                subStack = cat(3, subStack(:,:,params.window+1:end), stackObj(:,xmin:xmax,startTime:endTime));
            end
            index = e==cell2mat({dynData.([baitChannel 'SpotData']).appearedInWindow});
            [dynData.([preyChannel 'SpotData'])(index).appearedInWindow] = deal(e);
            dynData = extractIntensityTraces(preyChannel, subStack, params, dynData, index);
        end
        
        %% Find co-appearing spots
        dynData = findCoApp(dynData, baitChannel, preyChannel, wb);
    end
close(wb)
end