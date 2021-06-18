function dynData = getLongerIntensityTraces(varargin)

%  This program re-processes dynamic SiMPull data to extract longer
%  fluorescence intensity traces.  This is sometimes needed for dwell time
%  distribution analysis. 
%
%  Arguments: If called with no arguments, this function queries the user to get the location of the file 
%  to be re-processed and the new desired trace length. This information can also be provided
%  with the function call (to allow batch processing) by calling 
%  detectCoAppearance_greedy_reprocess(fileName,expDir,traceLength)
%
%  This latter usage is not meant to be called directly by the user;
%  instead run the batch_coApp_reprocess.m wrapper script. 

%% Set up
if nargin == 0 
    % Get data file from user
    [fileName, expDir] = uigetfile('*.mat','Choose .mat file to re-process',pwd);
    load([expDir filesep fileName]);
    
    % Ask for desired new trace length
    answer = inputdlg('Enter desired fluorescence intensity trace length','Trace Length',1,{'1000'});
    traceLength = str2double(answer);
    
elseif nargin == 3
    fileName = varargin{1};
    expDir = varargin{2};
    traceLength = varargin{3};
    load([expDir filesep fileName]);
else
    error('Incorrect number of input arguments given. Call detectCoAppearance(imgFilesCellArray, DialogBoxAnswers, regData) to provide parameters, or call with no arguments to raise dialog boxes.');
end

baitChannel = params.BaitChannel;
preyChannel = params.PreyChannel;

%% Load images
wb = waitbar(0,'Loading Images...','Name',strrep(['Analyzing Experiment ' expDir],'_','\_'));
warning('off'); %Prevent unnecessary warnings from libtiff
d = uipickfiles_subs.filtered_dir([expDir filesep '*.ome.tif'],'',false,@(x,c)uipickfiles_subs.file_sort(x,[1 0 0],c)); % See comments in uipickfiles_subs for syntax here
imgFile = arrayfun(@(x) [x.folder filesep x.name], d, 'UniformOutput', false);
if length(imgFile) > 1 %if the diretory contains multiple files
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

%% Extract intensity traces 
% Bait channel
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

ndiffs = dynData.([baitChannel 'SpotData'])(end).appearedInWindow;
window = dynData.avgWindow;
for b = 1:ndiffs
    waitbar(b/ndiffs,wb,'Extracting traces for the bait channel...')
    % Load the appropriate portion of the image into memory - this makes trace extraction much faster.
    if b==1
        % The first time through the loop, we just want the first n frames
        subStack = stackObj(:,xmin:xmax,1:traceLength);
    else
        % On subsequent iterations, shift the portion of the image in memory by 1 window
        startTime = (b-1) * window + (traceLength - window + 1);
        endTime = min((b-1) * window + traceLength, tmax);
        subStack = cat(3, subStack(:,:,window+1:end), stackObj(:,xmin:xmax,startTime:endTime));
    end
    
    % Get intensity traces
    index = b==cell2mat({dynData.([baitChannel 'SpotData']).appearedInWindow});
    dynData = extractIntensityTraces(baitChannel, subStack, params, dynData, index);
end

% Prey channel
% Figure out x indices - opposite logic to the code above to get the opposite half
[ymax, xmax, tmax] = size(stackObj);
if strcmp(params.BaitPos, 'Right')
    xmin = 1;
    xmax = xmax/2;
elseif strcmp(params.BaitPos, 'Left')
    xmin = xmax/2 + 1;
end
for e = 1:ndiffs
    waitbar(e/ndiffs,wb,'Extracting traces for the prey channel...')
    % Load the appropriate portion of the image into memory
    if e==1
        % The first time through the loop, we just want the first 500 frames
        subStack = stackObj(:,xmin:xmax,1:traceLength);
    else
        % On subsequent iterations, shift the portion of the image in memory by 1 window
        startTime = (e-1) * window + (traceLength - window + 1);
        endTime = min((e-1) * window + traceLength, tmax);
        subStack = cat(3, subStack(:,:,window+1:end), stackObj(:,xmin:xmax,startTime:endTime));
    end
    
    % Get intensity traces
    index = e==cell2mat({dynData.([preyChannel 'SpotData']).appearedInWindow});
    dynData = extractIntensityTraces(preyChannel, subStack, params, dynData, index);
end

% Detect changepoints
nspots = dynData.([baitChannel 'SpotCount']);
for c = 1:nspots
    waitbar(c/nspots,wb,'Finding changepoints...')
    % Bait channel
    baitTraj = dynData.([baitChannel 'SpotData'])(c).intensityTrace;
    [results, ~] = find_changepoints_c(baitTraj,2);
    dynData.([baitChannel 'SpotData'])(c).changepoints = results.changepoints;
    dynData.([baitChannel 'SpotData'])(c).steplevels = results.steplevels;
    dynData.([baitChannel 'SpotData'])(c).stepstdev = results.stepstdev;
    
    % Prey channel
    preyTraj = dynData.([preyChannel 'SpotData'])(c).intensityTrace;
    [results, ~] = find_changepoints_c(preyTraj,2);
    dynData.([preyChannel 'SpotData'])(c).changepoints = results.changepoints;
    dynData.([preyChannel 'SpotData'])(c).steplevels = results.steplevels;
    dynData.([preyChannel 'SpotData'])(c).stepstdev = results.stepstdev;
end


%% Save data
expName = fileName(1 : strfind(fileName,'.mat')-1);
save([expDir filesep expName '_longerTraces.mat'], 'dynData','params');
close(wb)