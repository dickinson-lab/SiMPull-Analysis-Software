%Compares the distributions of intensities between two or more different
%SiMPull experiments

% Choose mode
mode = questdlg('What do you want to do?', 'Choose Mode', 'Select multiple datasets from one folder', 'Select datasets individually', 'Select multiple datasets from one folder');

%Get the data from the spot counter
if strcmp(mode, 'Select datasets individually')
    answer = inputdlg('Number of experiments to compare:');
    number = str2num(answer{1});
    matFile = {};
    matPath = {};
    startpath = pwd;
    for a = 1:number
        [file path] = uigetfile('*.mat','Choose a .mat file with data from the spot counter',startpath);
        matFile{a} = file;
        matPath{a} = path;
        startpath = path;
    end
else
    [matFile path] = uigetfile('*.mat','Select .mat files to analyze','Multiselect','on');
    number = length(matFile);
    [matPath{1:number}] = deal(path);
end

load([matPath{1} filesep matFile{1}]);

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

Prompt(1,:) = {'Show data for spots with >= this many photobleaching steps:','cutoff',[]};
Formats(1,1).type = 'edit';
Formats(1,1).format = 'integer';
Formats(1,1).limits = [0 inf];
Formats(1,1).size = [40 25];
Formats(1,1).unitsloc = 'bottomleft';
Formats(1,1).enable = 'on';
DefAns(1).cutoff = 1;

Prompt(2,:) = {'Include rejected spots?','includeRejected',[]};
Formats(2,1).type = 'check';
Formats(2,1).enable = 'on';
DefAns.includeRejected = true;

[Answer,Cancelled] = inputsdlg(Prompt,Title,Formats,DefAns,Options);
%%%% End of dialog box

% Check input
if Cancelled 
    return
else
    v2struct(Answer);
end

foundData = 0;
colors = hsv(12);

for b = 1:nChannels
    load([matPath{1} filesep matFile{1}]);
    
    channel = channels{b};
    figHandles.(channel) = figure('Name',[channel 'Channel Intensities'],'NextPlot','add');
    
    if ~isfield(statsByColor, [channel 'StepHist'])
        continue
    end
    foundData = 1;

    [~, allIntensities] = getIntensities(gridData,channel,'nStepsCutoff',cutoff,'includeRejected',includeRejected);
    
    for a = 2:number
        load([matPath{a} filesep matFile{a}]);
        if ~isfield(statsByColor, [channel 'StepHist'])
            continue
        end
        foundData = 1;

        [~, intensities] = getIntensities(gridData,channel,'nStepsCutoff',cutoff,'includeRejected',includeRejected);
        if length(allIntensities) > length(intensities)
            intensities( length(intensities)+1 : length(allIntensities) ) = NaN;
        elseif length(intensities) > length(allIntensities)
            allIntensities( length(allIntensities)+1 : length(intensities), :) = NaN;
        end
        allIntensities = horzcat(allIntensities, intensities);
    end
    
    distributionPlot(allIntensities, 'showMM',6, 'xyOri','flipped', 'xNames',matFile, 'histOpt',1.1, 'globalNorm',0);
    
end

if ~foundData
    warndlg('This program requires photobleaching step data.  Please run the step counter first.');
end