function [nFluors_all, coApp_all] = catSingleBleachObs(varargin)
% Parse input
if nargin == 0
    matFiles = uipickfiles('Prompt','Select data files or folders to analyze','Type',{'*.mat'});
    warnFlag = false;
elseif nargin == 1
    matFiles = varargin{1};
    warnFlag = false;
elseif nargin == 2
    matFiles = varargin{1};
    warnFlag = varargin{2};
else
    error('Wrong number of input arguments');
end

fileBar = waitbar(0);
nFluors_all = [];
coApp_all = [];
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

    waitbar((a-1)/length(matFiles),fileBar,strrep(['Loading ' fileName],'_','\_'));

    % Load data structure
    load([expDir filesep fileName],'dynData','params');

    %Extract channel info - this is just for code readability
    BaitChannel = params.BaitChannel;

    % Check if we have photobleaching data
    maxSteps = 1;
    if isfield(dynData.BaitSpotData,'nFluors')
        if maxSteps < max([dynData.BaitSpotData.nFluors])
            maxSteps = max([dynData.BaitSpotData.nFluors]);
        end
    elseif warnFlag
        warning(['Dataset ' fileName ' is missing photobleaching step data.' newline 'Please run countDynamicBleaching first.']);
    end               

    %% Add up events
    % Filter artifacts: 
    % filterIdx eliminates blinking, late-appearing and short-dwell spots.  
    % In a future version, these three filters could be applied separately. 
    filterIdx = ~cellfun(@(x) isnumeric(x) && length(x)==1 && ~isnan(x) && x<2500, {dynData.BaitSpotData.nFramesSinceLastApp}); % Blinker filter
    filterIdx = filterIdx & ~cellfun(@(x,y) isnumeric(x) && x > 50*(y+1), {dynData.BaitSpotData.appearTimeFrames}, {dynData.BaitSpotData.appearedInWindow}); % Late appearance filter
    if ~isfield(dynData.BaitSpotData,'dwellTime')
        [dynData, ~] = dwellTime_koff(0,{[expDir filesep fileName]},false, dynData, params);
    end
    filterIdx = filterIdx & ~cellfun(@(x) x<10, {dynData.BaitSpotData.dwellTime}); % Short Dwell Time Filter

    nFluors = cell2mat({dynData.BaitSpotData(filterIdx).nFluors})';
    nFluors_all = vertcat(nFluors_all,nFluors);

    coApp = {dynData.BaitSpotData(filterIdx).appears_w_PreyCh2}';
    coApp_all = vertcat(coApp_all,coApp);
end
% Clean up zeros, negatives and nans
coApp_all(isnan(nFluors_all)) = [];
nFluors_all(isnan(nFluors_all)) = [];
coApp_all(nFluors_all<=0) = [];
nFluors_all(nFluors_all<=0) = [];
coApp_all = cell2mat(coApp_all);

close(fileBar)