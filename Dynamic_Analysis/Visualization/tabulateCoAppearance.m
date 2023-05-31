% Utility function for tabulating co-appearance vs. size vs. time for a list of datasets. 

% Takes a file list as input, or can be run with no arguments and will then
% prompt the user to select files. 
% The second argument, if true, enables warnings for missing photobleaching
% step counting. Default: false

% Returns a structure with two metrics for total spots ("totalCounted" and "totalCoApp")
% and two for their filtered counterparts "filteredCounted" and "filteredCoApp"
% Data Organization: 
    % Each metric is saved in a structure with a field for each prey channel.
    % Each field holds a cell array with one element for each particle size being analyzed (loop b).
    % In each of these arrays, the horizontal dimension represents time (in windows), and the vertical dimension is for datasets (loop a).
    % We also sum all of the baitsCounted for purposes of calculating density

% In addition, the function returns logical indices called "lowDensity" and
% "highDensity" that can be used for filtering purposes.

function output = tabulateCoAppearance(varargin)
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

    %% Calculate co-appearance vs. size vs. time

    % Convert appearance times from frames to seconds and shift based on the gap between lysis and acquisition
    if ~isnumeric(params.elapsedTime)
        params.elapsedTime = 0;
    end
    if ~isfield(dynData.BaitSpotData,'appearTimeSecs') %If this field has already been created, we can skip calculating times again
        if isfield(dynData.BaitSpotData,'appearTimeFrames') % Updated naming convention
            for c = 1:length(dynData.BaitSpotData)
                if isnumeric(dynData.BaitSpotData(c).appearTimeFrames)
                    dynData.BaitSpotData(c).appearTimeSecs = dynData.BaitSpotData(c).appearTimeFrames * 0.05 + params.elapsedTime; %Hard-coded 50 ms exposure time - could be a paramter later if needed 
                else
                    dynData.BaitSpotData(c).appearTimeSecs = NaN;
                end
            end    
        else % Legacy naming convention
            for c = 1:length(dynData.BaitSpotData)
                if isnumeric(dynData.BaitSpotData(c).appearTime)
                    dynData.BaitSpotData(c).appearTimeSecs = dynData.BaitSpotData(c).appearTime * 0.05 + params.elapsedTime; %Hard-coded 50 ms exposure time - could be a paramter later if needed 
                else
                    dynData.BaitSpotData(c).appearTimeSecs = NaN;
                end
            end
        end
    end

    lastWindow = max(cell2mat({dynData.([BaitChannel 'SpotData']).appearedInWindow}));
    baitsForDensity = [];
    for b = 1:maxSteps
        % spotChoiceIdx selects spots with a given number of photobleaching steps
        if isfield(dynData.BaitSpotData,'nFluors')
            spotChoiceIdx = [dynData.BaitSpotData.nFluors] == b;
        else
            spotChoiceIdx = true (1, length(dynData.BaitSpotData));
        end
        spotChoiceIdx = spotChoiceIdx & ~cellfun(@isnan, {dynData.BaitSpotData.appearTimeSecs}); 
        
        % filterIdx eliminates blinking, late-appearing and short-dwell spots, 
        % In a future version, these three filters could be applied separately. 
        filterIdx = spotChoiceIdx & ~cellfun(@(x) isnumeric(x) && length(x)==1 && ~isnan(x) && x<2500, {dynData.BaitSpotData.nFramesSinceLastApp}); % Blinker filter
        filterIdx = filterIdx & ~cellfun(@(x,y) x > 50*(y+1), {dynData.BaitSpotData.appearTimeSecs}, {dynData.BaitSpotData.appearedInWindow}); % Late appearance filter
        if ~isfield(dynData.BaitSpotData,'dwellTime')
            [dynData, ~] = dwellTime_koff(0,{[expDir filesep fileName]},false, dynData, params);
        end
        filterIdx = filterIdx & ~cellfun(@(x) x<10, {dynData.BaitSpotData.dwellTime}); % Short Dwell Time Filter

        % Create structs for each prey's % co-appearance with bait
        for s = 1:params.nChannels
            if s == params.baitChNum
                continue %Skip the bait channel
            end
            preyChannel = ['PreyCh' num2str(s)];
            colocData = {dynData.([BaitChannel 'SpotData'])(spotChoiceIdx).(['appears_w_' preyChannel])};
            filteredColocData = {dynData.BaitSpotData(filterIdx).(['appears_w_' preyChannel])};
            % Calculate a filtering index to ignore co-appearing spots 
            % with equal dwell times (which likely result fluorescence bleed-through). 
            dwellDiff = cell2mat({dynData.BaitSpotData.dwellTime}) - cell2mat({dynData.PreyCh2SpotData.dwellTime});
            equalDwellIdx = abs(dwellDiff) <= 5; % The threshold of 5 matches what is used in dwellTime_koff.m. This value could be adjusted for more or less stringent filtering.
            baitsCounted = zeros(1,lastWindow);
            coAppearing = zeros(1,lastWindow);
            filtCounted = zeros(1,lastWindow);
            filtCoAppearing = zeros(1,lastWindow);
            for d = 1:lastWindow
                lowerBound = (d-1) * params.window * 0.05;
                upperBound = d * params.window * 0.05; %Hard-coded 50 ms exposure time - could be a paramter later if needed 
                % Unfiltered data
                index = cell2mat({dynData.([BaitChannel 'SpotData'])(spotChoiceIdx).appearTimeSecs}) > lowerBound & cell2mat({dynData.([BaitChannel 'SpotData'])(spotChoiceIdx).appearTimeSecs}) <= upperBound;
                baitsCounted(d) = sum(~cellfun(@(x) isempty(x) || isnan(x), colocData(index)));
                coAppearing(d) = sum(cellfun(@(x) ~isempty(x) && x==true, colocData(index)));
                % Filtered data
                index = cell2mat({dynData.([BaitChannel 'SpotData'])(filterIdx).appearTimeSecs}) > lowerBound & cell2mat({dynData.([BaitChannel 'SpotData'])(filterIdx).appearTimeSecs}) <= upperBound;
                filtCounted(d) = sum(~cellfun(@(x) isempty(x) || isnan(x), filteredColocData(index)));
                index = cell2mat({dynData.([BaitChannel 'SpotData'])(filterIdx & ~equalDwellIdx).appearTimeSecs}) > lowerBound & cell2mat({dynData.([BaitChannel 'SpotData'])(filterIdx & ~equalDwellIdx).appearTimeSecs}) <= upperBound; %Second index calculation here because the equal dwell filter applies only to coappearance, not to bait spot count.
                filtCoAppearing(d) = sum(cellfun(@(x) ~isempty(x) && x==true, filteredColocData(index)));
            end  

            % Put all the data together. Organization: 
                % Each metric is saved in a structure with a field for each prey channel.
                % Each field holds a cell array with one element for each particle size being analyzed (loop b).
                % In each of these arrays, the horizontal dimension represents time (in windows), and the vertical dimension is for datasets (loop a).
                % We also sum all of the baitsCounted for purposes of calculating density
            if a == 1
                output.totalCounted.(preyChannel){b} = baitsCounted;
                output.totalCoApp.(preyChannel){b} = coAppearing;
                output.filteredCounted.(preyChannel){b} = filtCounted;
                output.filteredCoApp.(preyChannel){b} = filtCoAppearing;
            else
                output.totalCounted.(preyChannel){b}(a,1:length(baitsCounted)) = baitsCounted;
                output.totalCoApp.(preyChannel){b}(a,1:length(coAppearing)) = coAppearing;
                output.filteredCounted.(preyChannel){b}(a,1:length(baitsCounted)) = filtCounted;
                output.filteredCoApp.(preyChannel){b}(a,1:length(coAppearing)) = filtCoAppearing;
            end
            if b == 1
                baitsForDensity = baitsCounted;
            else
                baitsForDensity = baitsForDensity + baitsCounted;
            end
            clear coAppearing baitsCounted
        end
    end
    % Add information for filtering low- and high-density data
    lowThreshold = (params.imgArea / 1e6) * 0.005; %0.005 molecules / um^2 is the lowest level where measurements are reliable. 
    output.lowDensity(a,1:length(baitsForDensity)) = baitsForDensity < lowThreshold;
    highThreshold = (params.imgArea / 1e6) * 0.8; %0.8 molecules / um^2 is the highest level where measurements are reliable. 
    output.highDensity(a,1:length(baitsForDensity)) = baitsForDensity > highThreshold;
end
close(fileBar)