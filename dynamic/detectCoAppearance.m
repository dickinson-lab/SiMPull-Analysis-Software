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
else
    error('Incorrect number of input arguments given. Call detectCoAppearance(imgFilesCellArray, DialogBoxAnswers, regData) to provide parameters, or call with no arguments to raise dialog boxes.');
end

% Save parameters for future use and branch based on image type
params.DataType = DataType;
params.pixelSize = pixelSize;
params.RegistrationData = regData; 
if strcmp(DataType,'Composite Data')
    params.nChannels = nChannels;
    params.baitChNum = baitChNum;
    [imgName, dynData] = detCoApp_comp(expDir,imgFile,params);
else
    params.LeftChannel = LeftChannel;
    params.RightChannel = RightChannel;
    params.BaitPos = BaitPos;
    params.baitChannel = Answer.([BaitPos 'Channel']); 
    [imgName, dynData] = detCoApp_dv(expDir,imgFile,params);
end

%% Run blinkerFinder.m
dynData = blinkerFinder(dynData);

%% Plot and save coAppearance over time
% Calculated time elapsed between embryo lysis and data acquisition and save in params
elapsedTime = getElapsedTime(expDir, imgName);
params.elapsedTime = elapsedTime;
% Create and save plot
coApp_vs_time = coApp_vs_time(dynData, params);
save([expDir filesep imgName '_coApp_vs_time.mat'], 'coApp_vs_time');

%% Save data
save([expDir filesep imgName '.mat'], 'dynData','params');
close(wb)
end


%% Functions for Individual Data Types

%% Composite data (Images are ImageJ hyperstacks with multiple channels) 
function dynData = detCoApp_comp(expDir,imgFile,params)
    
end

%% Dual-view data (side-by-side images)
function [imgName, dynData] = detCoApp_dv(expDir,imgFile,params)
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
    dynData = PS_dynamicBait(expDir, stackObj, xmin, xmax, tmax, params.baitChannel, baitDiff, params, wb);
    
    %% Find co-appearing spots in the prey channel
    % We don't do spot detection for the prey channel; 
    % instead, just copy the positions of spots found in the bait channel and apply a registration correction.
    % At the same time, identify and ignore bait spots that are so close to the edge that they aren't visible in the prey channel
    waitbar(0,wb,'Getting prey intensity traces...');
    baitChannel = params.baitChannel;
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
end


%% Functions for processing data - these can be reused as they are independent of data format
function dynData = PS_dynamicBait(expDir, stackObj, xmin, xmax, tmax, baitChannel, baitDiff, params, wb)
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
            [foundSpots] = {psDiffResults.([baitChannel 'SpotData']).spotLocation}';
            for c = 1:psDiffResults.([baitChannel 'SpotCount'])
                query = cell2mat(foundSpots(c));
                if ~isempty(lastFoundSpots) && ~isempty(lastFoundSpots{1}) % This If statement protects against errors when no spots were found in the previous frame.
                    match = find(cellfun(@(x) sum(abs(x-query))<3, lastFoundSpots)); %Peaks <3 pixels from a previously-found peak are ignored
                else
                    match = [];
                end
                if isempty(match) %If we didn't find a match, that means it's a new spot. Add it to the main data structure
                    psDiffResults.([baitChannel 'SpotData'])(c).appearedInWindow = b; %Save info about when this spot appeared
                    dynData.([baitChannel 'SpotData'])(end+1) = psDiffResults.([baitChannel 'SpotData'])(c);
                end
            end
            lastFoundSpots = foundSpots; %Save the list of spots found this time to compare to the next time through the loop
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
end

function dynData = findCoApp(dynData, baitChannel, preyChannel, wb)
    % Find spots that appear at the same time. Here a "greedy" algorithm is
    % used that counts any up-step in prey intensity coincinding with bait appearance as a co-appearance
    % event, regardless of whether it's the first up-step in the prey channel
    waitbar(0,wb,'Finding prey co-appearance events...');
    for c = 1:dynData.([baitChannel 'SpotCount'])
        %Detect Changepoints
        traj = dynData.([preyChannel 'SpotData'])(c).intensityTrace;
        [results, error] = find_changepoints_c(traj,2);
        dynData.([preyChannel 'SpotData'])(c).changepoints = results.changepoints;
        dynData.([preyChannel 'SpotData'])(c).steplevels = results.steplevels;
        dynData.([preyChannel 'SpotData'])(c).stepstdev = results.stepstdev;
        if error
            dynData.([preyChannel 'SpotData'])(c).appearTime = 'Analysis Failed';
            continue
        end

        %Look for an upstep at the appearance time
        if isnumeric(dynData.([baitChannel 'SpotData'])(c).appearTime)
            baitAppearTime = dynData.([baitChannel 'SpotData'])(c).appearTime;

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
    dynData.([baitChannel 'AppearanceFound']) = sum( ~isnan([ dynData.([baitChannel 'SpotData']).(['appears_w_' preyChannel]) ]) ) ;
    dynData.([baitChannel preyChannel 'CoAppearing']) = sum([ dynData.([baitChannel 'SpotData']).(['appears_w_' preyChannel]) ], 'omitnan');
end