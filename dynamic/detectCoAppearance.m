function detectCoAppearance(varargin)
%  This program is for analyzing SiMPull data in which the binidng of bait
%  proteins to the coverslip is monitored in real time following cell
%  lysis. 
%
%  The program first uses diff followed by probabilistic segmentation to
%  identify spots that appear in the bait channel during an acquisiton.  
%  Then, those spots are analyzed to determine their time of appearance 
%  and whether spots in a prey channel co-appear. 
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
window = 50; %Temporal averaging window for spot detection                                          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Set up
if nargin == 0 
    % Ask user for images. Multiselect is used here because sometimes Micro-Manager splits long time series into pieces. 
    imgFile = uipickfiles('Prompt','Select image files to analyze and arrange them in order','Type',{'*.tif','TIF-file'});

    % Get image name and root directory
    slash = strfind(imgFile{1},filesep);
    imgName = imgFile{1}(slash(end)+1:strfind(imgFile{1},'_MMStack')-1); 
    expDir = imgFile{1}(1:slash(end));

    % Options dialog box
    [Answer,Cancelled] = dynamicChannelInfoDlg(expDir);
    if Cancelled 
        return
    else
        v2struct(Answer);
    end

    % Image registration
    regImg = TIFFStack(regFile);
    subImg = regImg(:,:,RegWindow1:RegWindow2);
    avgImg = mean(subImg, 3);
    [~, xmax] = size(avgImg);
    leftImg = avgImg(:,1:(xmax/2));
    rightImg = avgImg(:,(xmax/2)+1:xmax);
    regData = registerImages(rightImg, leftImg);
    % We don't save the registration info here because it's saved as part of each individual file below.  
    % Instead we just hang on to the regData variable for later use.
elseif nargin == 3
    imgFile = varargin{1};
    slash = strfind(imgFile{1},filesep);
    imgName = imgFile{1}(slash(end)+1:strfind(imgFile{1},'_MMStack')-1); 
    expDir = imgFile{1}(1:slash(end));  
    
    Answer = varargin{2};
    v2struct(Answer);
    regData = varargin{3};
else
    error('Incorrect number of input arguments given. Call detectCoAppearance(imgFilesCellArray, DialogBoxAnswers, regData) to provide parameters, or call with no arguments to raise dialog boxes.');
end

%% Load images
wb = waitbar(0,'Loading Images...','Name',strrep(['Analyzing Experiment ' expDir],'_','\_'));
warning('off'); %Prevent unnecessary warnings from libtiff
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
baitChannel = Answer.([BaitPos 'Channel']); 
params.pixelSize = pixelSize;
% Figure out what portion of the image we're going to work with and set x indices accordingly
[ymax, xmax, tmax] = size(stackObj);
if strcmp(BaitPos, 'Left')
    xmin = 1;
    xmax = xmax/2;
elseif strcmp(BaitPos, 'Right')
    xmin = xmax/2 + 1;
end

windowedStack = windowMean(stackObj,window,BaitPos); 
diffMap = diff(windowedStack,1,3); % "1" for first derivative, "3" for third dimension
% Note that since the first diff we take is between the first and second windows, spots appearing 
% during the first few frames (early in the first window) might be missed. This is ok for now. 

lastFoundSpots = {};
[~,~,ndiffs] = size(diffMap);
for b = 1:ndiffs
    %% Probabilistic Segmentation
    waitbar((b-1)/ndiffs,wb);
    % Run PS and put data in a temporary structure (foundSpots)
    psResults = spotcount_ps(baitChannel, diffMap(:,:,b), params, struct('dataFolder',path,'avgWindow',window));
    
    % The diffMap approach will tend to find the same object in two consecutive windows. So now we need 
    % to go through the list of found spots and keep only those that weren't found previously. 
    if b==1 %...unless this is the first time through the loop
        dynData = psResults;
        [dynData.([baitChannel 'SpotData']).appearedInWindow] = deal(b); %Save info about when these spots appeared
        [lastFoundSpots] = {psResults.([baitChannel 'SpotData']).spotLocation}'; %Save foundSpots for the next iteration of the loop
    else
        [foundSpots] = {psResults.([baitChannel 'SpotData']).spotLocation}';
        for c = 1:psResults.([baitChannel 'SpotCount'])
            query = cell2mat(foundSpots(c));
            if ~isempty(lastFoundSpots{1}) % This If statement protects against errors when no spots were found in the previous frame.
                match = find(cellfun(@(x) sum(abs(x-query))<3, lastFoundSpots)); %Peaks <3 pixels from a previously-found peak are ignored
            else
                match = [];
            end
            if isempty(match) %If we didn't find a match, that means it's a new spot. Add it to the main data structure
                psResults.([baitChannel 'SpotData'])(c).appearedInWindow = b; %Save info about when this spot appeared
                dynData.([baitChannel 'SpotData'])(end+1) = psResults.([baitChannel 'SpotData'])(c);         
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
        startTime = (b-1) * window + 451;
        endTime = min(b * window + 450, tmax);
        subStack = cat(3, subStack(:,:,window+1:end), stackObj(:,xmin:xmax,startTime:endTime));
    end
    
    % Get intensity traces
    dynData = extractIntensityTraces(baitChannel, subStack, params, dynData);   
end
[dynData.([baitChannel 'SpotCount']),~] = size(dynData.([baitChannel 'SpotData']));

% Detect up-steps in intensity
dynData = findAppearanceTimes(dynData, baitChannel);

%% Find co-appearing spots in the prey channel
% We don't do spot detection for the prey channel; 
% instead, just copy the positions of spots found in the bait channel and apply a registration correction.
% At the same time, identify and ignore bait spots that are so close to the edge that they aren't visible in the prey channel
waitbar(0,wb,'Finding co-appearing prey spots...');
if strcmp(BaitPos, 'Left')
    preyChannel = RightChannel;
else
    preyChannel = LeftChannel;
end
dynData.([preyChannel 'SpotData']) = struct('spotLocation',[]);
index = true(dynData.([baitChannel 'SpotCount']),1);
for d = 1:dynData.([baitChannel 'SpotCount'])
    if strcmp(Answer.BaitPos, 'Left')
        % Forward affine transformation if bait channel is on the right
        preySpotLocation = round( transformPointsInverse(regData.Transformation, dynData.([baitChannel 'SpotData'])(d).spotLocation) );
    else
        % Inverse affine transformation if bait channel is on the left
        preySpotLocation = round( transformPointsForward(regData.Transformation, dynData.([baitChannel 'SpotData'])(d).spotLocation) );
    end
    if preySpotLocation(1) < 0 || preySpotLocation(1) > xmax || preySpotLocation(2) < 0 || preySpotLocation(2) > ymax
        index(d) = false; %Ignore this spot if it doesn't map within the prey image
    else
        dynData.([preyChannel 'SpotData'])(d,1).spotLocation = preySpotLocation; %Add this location to the places to check for prey
    end
end
% Ignore spots that are too close to the edge
dynData.([baitChannel 'SpotData']) = dynData.([baitChannel 'SpotData'])(index);
dynData.([preyChannel 'SpotData']) = dynData.([preyChannel 'SpotData'])(index);
[dynData.([baitChannel 'SpotCount']),~] = size(dynData.([baitChannel 'SpotData'])); %Count how many bait spots are left

params.RegistrationData = regData; %Save Registration info


% Pull intensity traces for the prey
% Figure out x indices - opposite logic to the code above to get the opposite half
[ymax, xmax, tmax] = size(stackObj);
if strcmp(BaitPos, 'Right')
    xmin = 1;
    xmax = xmax/2;
elseif strcmp(BaitPos, 'Left')
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
        startTime = (e-1) * window + 451;
        endTime = min(e * window + 450, tmax);
        subStack = cat(3, subStack(:,:,window+1:end), stackObj(:,xmin:xmax,startTime:endTime));
    end
    index = e==cell2mat({dynData.([baitChannel 'SpotData']).appearedInWindow});
    [dynData.([preyChannel 'SpotData'])(index).appearedInWindow] = deal(e);
    dynData = extractIntensityTraces(preyChannel, subStack, params, dynData, index);
end
% Look for spot appearances in the prey channel
dynData = findAppearanceTimes(dynData, preyChannel);

% Find spots that appear at the same time
for c = 1:dynData.([baitChannel 'SpotCount'])
    if isnumeric(dynData.([baitChannel 'SpotData'])(c).appearTime)
        
        if isnumeric(dynData.([preyChannel 'SpotData'])(c).appearTime) &&... 
           abs( dynData.([baitChannel 'SpotData'])(c).appearTime - dynData.([preyChannel 'SpotData'])(c).appearTime ) <= 4 
            
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

%% Save data
save([expDir filesep imgName '.mat'], 'dynData','params');
close(wb)