% Filters SiMPull data based on a minimum number of photobleaching steps 

clear pooledData; %This prevnts carrying over data from a previous run of this script

% Select files to filter
[fileList, expDir] = uigetfile('*.mat','Choose .mat files to filter',pwd,'MultiSelect','on');

%%%% Options Dialog Box using inputsdlg
Title = 'Program Options';
Options.Resize = 'on';
Options.Interpreter = 'tex';
Options.CancelButton = 'on';
Options.ApplyButton = 'off';
Options.ButtonNames = {'Continue','Cancel'}; 
Prompt = {};
Formats = {};
DefAns = struct([]);

Prompt(1,:) = {'Choose which channels to filter',[],[]};
Formats(1,1).type = 'text';
Formats(1,1).span = [1 4];  

Prompt(2,:) = {'Blue','filterBlue',[]};
Formats(2,1).type = 'check';
DefAns(1).filterBlue = false;

Prompt(3,:) = {'Green','filterGreen',[]};
Formats(2,2).type = 'check';
DefAns.filterGreen = true;

Prompt(4,:) = {'Red','filterRed',[]};
Formats(2,3).type = 'check';
DefAns.filterRed = false;

Prompt(5,:) = {'Far Red','filterFarRed',[]};
Formats(2,4).type = 'check';
DefAns.filterFarRed = false;

Prompt(6,:) = {' ',[],[]};
Formats(3,1).type = 'text';
Formats(3,1).span = [1 4];

Prompt(7,:) = {'Filter based on photobleaching step size to reject dim noise?','applyIntFilt',[]};
Formats(4,1).type = 'check';
Formats(4,1).span = [1 4];
DefAns.applyIntFilt = true;

Prompt(8,:) = {'Choose how to apply step size filter',[],[]};
Formats(5,1).type = 'text';
Formats(5,1).span = [1 4];

Prompt(9,:) = {'','intFiltMode',[]};
Formats(6,1).type = 'list';
Formats(6,1).format = 'text';
Formats(6,1).style = 'radiobutton';
Formats(6,1).items = {'Calculate threshold separately for each experiment' 'Use threshold from a reference sample for all data' 'Calculate a global threshold by pooling all data'};
Formats(6,1).size = [0 25];
Formats(6,1).span = [1 4];  
DefAns.intFiltMode = 'Calculate a global threshold by pooling all data';

Prompt(10,:) = {'Step size filter strength:',[],[]};
Formats(7,1).type = 'text';
Formats(7,1).span = [1 4];

Prompt(11,:) = {'','intFiltStrength',[]};
Formats(8,1).type = 'list';
Formats(8,1).format = 'text';
Formats(8,1).style = 'radiobutton';
Formats(8,1).items = {'Aggressive' 'Moderate' 'Conservative'};
Formats(8,1).size = [0 25];
Formats(8,1).span = [1 4];  
DefAns.intFiltStrength = 'Moderate';

Prompt(12,:) = {' ',[],[]};
Formats(9,1).type = 'text';
Formats(9,1).span = [1 4];

Prompt(13,:) = {'Filter based on number of photobleaching steps per spot?','applyStepFilt',[]};
Formats(10,1).type = 'check';
Formats(10,1).span = [1 4];
DefAns.applyStepFilt = true;

Prompt(14,:) = {'Keep data with >= this many photobleaching steps:','stepCutoff',[]};
Formats(11,1).type = 'edit';
Formats(11,1).format = 'integer';
Formats(11,1).limits = [0 inf];
Formats(11,1).size = [40 25];
Formats(11,1).span = [1 4];  
Formats(11,1).unitsloc = 'bottomleft';
Formats(11,1).enable = 'on';
DefAns.stepCutoff = 1;

Prompt(15,:) = {'Retain spots that show a step up in intensity?','includeRejected',[]};
Formats(12,1).type = 'check';
Formats(12,1).enable = 'on';
Formats(12,1).span = [1 4];  
DefAns.includeRejected = true;

[FilterParams,Cancelled] = inputsdlg(Prompt,Title,Formats,DefAns,Options);
%%%% End of dialog box

% Check input
if Cancelled 
    return
else
    v2struct(FilterParams);
    filter.Blue = filterBlue; clear filterBlue;
    filter.Green = filterGreen; clear filterGreen;
    filter.Red = filterRed; clear filterRed;
    filter.FarRed = filterFarRed; clear filterFarRed;
    if strcmp(intFiltMode, 'Calculate threshold separately for each experiment')
        intFiltMode = 'Individual';
    elseif strcmp(intFiltMode, 'Use threshold from a reference sample for all data')
        intFiltMode = 'Reference';
    elseif strcmp(intFiltMode, 'Calculate a global threshold by pooling all data')
        intFiltMode = 'Global';
    else
        error('Invalid filtering mode selected');
    end
end

%fileList = dir([expDir filesep '*.mat']);

% Ask what to do if filtered data already exist
if any(cell2mat(strfind(fileList, 'filtered')))
    button = questdlg('Filtered data already exist for this experiment. How do you want to proceed?',...
        'Found Existing Data',...
        'Stop','Overwrite','Overwrite');
    if strcmp(button, 'Stop')
        return
    end
end

% If we're filtering based on a reference step size threshold, get the reference dataset and calculate the threshold
if applyIntFilt && strcmp(intFiltMode, 'Reference');
    [refname,pathname] = uigetfile(pwd,'Select a .mat file with data from the reference sample',expDir);
    reffile = [pathname filesep refname];
    load(reffile);
    for h = 1:nChannels
        color = channels{h};
        if filter.(color)
            [globalThreshold.(color), aborted] = calculateIntensityThreshold(gridData,color,intFiltStrength);
            if aborted
                errordlg(['Calculation of global threshold for ' color ' channel failed']);
                return
            end
        end
    end
    FilterParams.refSample = refname;
    FilterParams.globalThreshold = globalThreshold;
end

% If we're filtering based on a global threshold, load and pool all of the data and calculate the threshold
if applyIntFilt && strcmp(intFiltMode, 'Global');
    % Gather the data
    for j = 1:length(fileList)
        % Don't try to analyze the summary table
        if strfind(fileList{j}, 'summary')
            continue
        end

        % Don't include data that have been filtered previously
        if strfind(fileList{j}, 'filtered')
            continue 
        end

        % Load data and add to a big structure that has all of the data
        load([expDir filesep fileList{j}]);
        if ~exist('pooledData', 'var')
            pooledData = gridData;
        else
            pooledData = vertcat(pooledData, gridData);
        end        
    end
    
    % Calculate the thresholds
    for k = 1:nChannels
        color = channels{k};
        if filter.(color)
            [globalThreshold.(color), aborted] = calculateIntensityThreshold(pooledData,color,intFiltStrength);
            if aborted
                errordlg(['Calculation of global threshold for ' color ' channel failed']);
                return
            end
        end
    end
    FilterParams.globalThreshold = globalThreshold;
end


% Set up summary table
summary = cell(2, 28);
summary(1,:) = {'Experiment','Spots per Image','% Coloc w/ Blue', '% Coloc w/ Green','% Coloc w/ Red','% Coloc w/ FarRed','Traces Analyzed','% 1 step','% 2 step','% 3 step','% 4 step','% 5 step','% 6 step','% 7 step','% 8 step','% 9 step','% 10 step','% 11 step ','% 12 step','% 13 step','% 14 step','% 15 step','% 16 step','% 17 step','% 18 step','% 19 step','% 20 step','% Rejected'};
rowcounter = 2;

for a = 1:length(fileList)
    aborted = false;
    
    % Don't try to analyze the summary table
    if strfind(fileList{a}, 'summary')
        continue
    end
    
    % Don't re-filter data that has been filtered previously
    if strfind(fileList{a}, 'filtered')
        continue 
    end
    
    load([expDir filesep fileList{a}]);
    
    % Filtering by step size (intensity)
    if applyIntFilt
        for k = 1:nChannels
            color = channels{k};
 
            % Skip channels that aren't selected
            if ~filter.(color)
                continue
            end           
            
            % Apply step size filter                
            if strcmp(intFiltMode, 'Individual')
                [gridData, statsByColor, threshold, aborted] = stepSizeFilter(gridData, color, statsByColor, intFiltStrength);
                FilterParams.threshold = threshold;
            else
                [gridData, statsByColor, threshold, aborted] = stepSizeFilter(gridData, color, statsByColor, globalThreshold.(color));
            end
            if aborted
                errordlg(['Step size filter failed! Experiment ' fileList{a} ' was not filtered']);
                continue
            end
        end
    end 
    
    if aborted
        continue
    end
    
    % Filtering by number of steps
    for b = 1:length(gridData)
        for c = 1:nChannels
            color = channels{c};
            
            % Skip channels that aren't selected
            if ~filter.(color)
                continue
            end
            
            % Skip this image if there are too many spots
            if strcmp( gridData(b).([color 'GoodSpotCount']), 'Too Many Spots to Analyze' )
                continue
            end
            
            % Eliminate spots that don't have the minimum number of steps
            if stepCutoff > 0
                nStepsIdx = arrayfun(@(x) isnumeric(x.nSteps) && x.nSteps>=stepCutoff,  gridData(b).([color 'SpotData']));
            else
                nStepsIdx = true(length(gridData(b).([color 'SpotData'])), 1);
            end

            if includeRejected
                rejectedIdx = arrayfun(@(x) strcmp(x.nSteps,'Rejected'), gridData(b).([color 'SpotData']));
            else
                rejectedIdx = false(length(gridData(b).([color 'SpotData'])), 1);
            end

            includeIdx = nStepsIdx | rejectedIdx;
            gridData(b).([color 'SpotData']) = gridData(b).([color 'SpotData'])(includeIdx);
            
            % Re-count total spots
            gridData(b).([color 'SpotCount']) = length(gridData(b).([color 'SpotData']));
           
        end
    end
    
    % Re-count colocalized spots
    if nChannels >1
        for h = 1:nChannels
            color = channels{h};
            [gridData, results] = coloc_spots(gridData, statsByColor, color, params.maxSpots);
            for m = 1:nChannels
                color2 = channels{m};
                if strcmp(color, color2)
                    continue
                end
                statsByColor.([color color2 'SpotsTested']) = results.([color color2 'SpotsTested']);
                statsByColor.(['pct' color 'Coloc_w_' color2]) = 100*results.([color color2 'ColocSpots']) / results.([color color2 'SpotsTested']);
            end
        end
    end

    
    % Re-calculate summary statistics
    for f = 1:nChannels
        color = channels{f};
        
        statsByColor.(['total' color 'Spots']) = sum( cell2mat( {gridData.([color 'SpotCount'])} ) );
        statsByColor.(['avg' color 'Spots']) = statsByColor.(['total' color 'Spots']) / numel(gridData);
        
        if isfield(statsByColor, [color 'TracesAnalyzed']) %Checks whether step counting was done for this channel
            statsByColor.([color 'StepHist']) = sum( cell2mat({gridData.([color 'StepDist'])})' );

            index = cellfun(@(x) isnumeric(x), {gridData.([color 'GoodSpotCount'])});
            statsByColor.([color 'BadSpots']) = sum(cell2mat( {gridData(index).([color 'SpotCount'])} )) - sum(cell2mat( {gridData(index).([color 'GoodSpotCount'])} ));

            statsByColor.([color 'TracesAnalyzed']) = statsByColor.([color 'BadSpots']) + sum(statsByColor.([color 'StepHist']));
        end
    end
    
    extIdx = strfind(fileList{a}, '.mat');
    dataName = fileList{a}(1 : extIdx-1);
    outFileName = [dataName '_filtered.mat'];
    save([expDir filesep outFileName], 'gridData', 'channels', 'nChannels', 'nPositions', 'statsByColor', 'FilterParams');
    
    %%% Add Data to the Summary Table %%%
    for q = 1:nChannels 
        color = channels{q};
        summary{rowcounter, 1} = [dataName ' ' color];
        summary{rowcounter, 2} = statsByColor.(['avg' color 'Spots']);
        if isfield(statsByColor, ['pct' color 'Coloc_w_Blue'])
            summary{rowcounter, 3} = statsByColor.(['pct' color 'Coloc_w_Blue']);
        else
            summary{rowcounter, 3} = '-';
        end
        if isfield(statsByColor, ['pct' color 'Coloc_w_Green'])
            summary{rowcounter, 4} = statsByColor.(['pct' color 'Coloc_w_Green']);
        else
            summary{rowcounter, 4} = '-';
        end
        if isfield(statsByColor, ['pct' color 'Coloc_w_Red'])
            summary{rowcounter, 5} = statsByColor.(['pct' color 'Coloc_w_Red']);
        else
            summary{rowcounter, 5} = '-';
        end
        if isfield(statsByColor, ['pct' color 'Coloc_w_FarRed'])
            summary{rowcounter, 6} = statsByColor.(['pct' color 'Coloc_w_FarRed']);
        else
            summary{rowcounter, 6} = '-';
        end
        if isfield(statsByColor, [color 'TracesAnalyzed'])
            summary{rowcounter, 7} = statsByColor.([color 'TracesAnalyzed']);
            summary(rowcounter, 8:27) = num2cell( 100 * statsByColor.([color 'StepHist']) / statsByColor.([color 'TracesAnalyzed']) );
            summary{rowcounter, 28} = 100 * statsByColor.([color 'BadSpots']) / statsByColor.([color 'TracesAnalyzed']);
        else
            [summary{rowcounter, 7:28}] = deal('-');
        end
        rowcounter = rowcounter + 1;
    end
    
    rowcounter = rowcounter + 1; %Leaves a blank row between samples for easier readability
    clear statsByColor gridData

end

% Condense summary table by removing empty columns
emptyColumns = [];
cellfind = @(string)(@(cell_contents)(strcmp(string,cell_contents)));
for f = 3:6
    slashCells = cellfun(cellfind('-'),summary(2:end,f));
    blankCells = cellfun(@(x) isempty(x), summary(2:end,f));
    emptyCells = slashCells | blankCells;
    if min(emptyCells) == 1 
        emptyColumns(end+1) = f;
    end
end
for g = 8:27
    emptyCells = logical(cellfun(cellfind('-'),summary(2:end,g)));
    column = summary(2:end,g);
    column = cell2mat(column(~emptyCells));
    if max(column) == 0
        emptyColumns(end+1) = g;
    end
end
summary(:,emptyColumns) = [];

% Save summary table
slash = strfind(expDir,filesep);
expName = expDir(slash(end)+1:end);
save([expDir filesep expName '_summary_filtered.mat'],'summary');

% Clear variables, keeping only summary table
clearvars -except summary pooledData

