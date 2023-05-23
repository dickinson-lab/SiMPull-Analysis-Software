function detectMoleculesForDensity(varargin)
%  This is a modified version of the Probablisitic Segementation section of the
%  detectCoAppearance_extendedPS script. This function is meant to be run
%  on samples that have '_greedyCoApp.mat' files and no '_greedyPlus.mat' files.

%  This function calls spotcount_ps for average images for the prey and 
%  bait channels as well as the difference images for the prey channel. 
%  The number of appearing and present molecules in each window are recorded. 
%  These data are later used to calculate density of molecules so that unreliably 
%  dense or sparse windows of acqusition can be excluded from later analysis 
%  because they interfere with accurate co-appearance dection.
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

% Save parameters for future use
params.LeftChannel = LeftChannel;
params.RightChannel = RightChannel;
params.BaitPos = BaitPos;

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
    preyPos = 'Right';
elseif strcmp(BaitPos, 'Right')
    xmin = xmax/2 + 1;
    preyPos = 'Left';
end
% Save image size
params.imageY_X = [ymax, xmax/2];

% Calculate windowed average and difference images
baitAvg = windowMean(stackObj,window,BaitPos);

% Calculate windowed prey channel images for later visualization
preyAvg = windowMean(stackObj,window,preyPos); 
preyDiff = diff(preyAvg,1,3);

% Determine preyChannel 
if strcmp(BaitPos, 'Left')
    preyChannel = RightChannel;
else
    preyChannel = LeftChannel;
end

lastFoundPreySpots = {};
[~,~,ndiffs] = size(preyDiff);
for b = 1:ndiffs
    %% Probabilistic Segmentation
    waitbar((b-1)/ndiffs,wb);
    % Run PS for both the difference and average images
    psAvgResults = spotcount_ps(baitChannel, baitAvg(:,:,b), params, struct('dataFolder',expDir,'avgWindow',window), 1);
    psPreyDiffResults = spotcount_ps(preyChannel, preyDiff(:,:,b), params, struct('dataFolder',expDir,'avgWindow',window), 1);
    psPreyAvgResults = spotcount_ps(preyChannel, preyAvg(:,:,b), params, struct('dataFolder',expDir,'avgWindow',window), 1);
    % To avoid double counting, the spots per window of the difference images are calculated later but the entry for this window is created now to avoid errors    dynData.([preyChannel 'DiffCount'])(b) = 0;
    dynData.([preyChannel 'DiffCount'])(b) = 0;
    % The baitDiff approach will tend to find the same object in two consecutive windows. So now we need 
    % to go through the list of found spots and keep only those that weren't found previously. 
    if b==1 %...unless this is the first time through the loop
        [dynData.([preyChannel 'DiffSpotData'])] = psPreyDiffResults.([preyChannel 'SpotData']);
        [dynData.([preyChannel 'DiffSpotData']).appearedInWindow] = deal(b);%Save info about when these spots appeared
        %Put PS data in a temporary structure foundSpots (by default, lastFoundSpots in first loop iteration)
        [lastFoundPreySpots] = {psPreyDiffResults.([preyChannel 'SpotData']).spotLocation}';
        
        % For the first time through the loop, all of the spots will be newly appearing molecules; all will be counted toward the spot count in the first window of difference images
        dynData.([preyChannel 'DiffCount'])(b) = psPreyDiffResults.([preyChannel 'SpotCount']);
    else
        [foundPreySpots] = {psPreyDiffResults.([preyChannel 'SpotData']).spotLocation}';
        for c = 1:psPreyDiffResults.([preyChannel 'SpotCount'])
            query = cell2mat(foundPreySpots(c));
            if ~isempty(lastFoundPreySpots) && ~isempty(lastFoundPreySpots{1}) % This If statement protects against errors when no spots were found in the previous frame.
                Preymatch = find(cellfun(@(x) sum(abs(x-query))<3, lastFoundPreySpots)); %Peaks <3 pixels from a previously-found peak are ignored
            else
                Preymatch = [];
            end
            if isempty(Preymatch) %If we didn't find a match, that means it's a new spot. Add it to the main data structure
                psPreyDiffResults.([preyChannel 'SpotData'])(c).appearedInWindow = b; %Save info about when this spot appeared
                dynData.([preyChannel 'DiffSpotData'])(end+1) = psPreyDiffResults.([preyChannel 'SpotData'])(c);
                %Each time a new spot in the difference image is added to SpotData, count and save to prey spots for that window
                dynData.([preyChannel 'DiffCount'])(b) = dynData.([preyChannel 'DiffCount'])(b) + 1;
            end
        end
        lastFoundPreySpots = foundPreySpots;
    end  
    
    % Save the number of bait and prey spots in this window of the average image
    dynData.([baitChannel 'AvgCount'])(b) = psAvgResults.([baitChannel 'SpotCount']);
    dynData.([preyChannel 'AvgCount'])(b) = psPreyAvgResults.([preyChannel 'SpotCount']);
end
clear baitAvg preyAvg preyDiff
% Count the total number of prey spots across difference images
[dynData.([preyChannel 'SpotCount']),~] = size(dynData.([preyChannel 'DiffSpotData'])); 

%% Save data
save([expDir filesep imgName '_forDensity.mat'], 'dynData','params');
close(wb)