%Compares the signal to noise ratio between two or more different
%SiMPull experiments

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

load([matPath{1} filesep matFile{1}]);

%%%% Options Dialog Box using inputsdlg
Title = 'Choose which data to plot';
Options.Resize = 'on';
Options.Interpreter = 'tex';
Options.CancelButton = 'on';
Options.ApplyButton = 'off';
Options.ButtonNames = {'Continue','Cancel'}; 
Prompt = {};
Formats = {};
DefAns = struct([]);

Prompt(1,:) = {'Minimum photobleaching steps:','minSteps',[]};
Formats(1,1).type = 'edit';
Formats(1,1).format = 'integer';
Formats(1,1).limits = [1 inf];
Formats(1,1).size = [40 25];
Formats(1,1).unitsloc = 'bottomleft';
Formats(1,1).enable = 'on';
DefAns(1).minSteps = 1;

Prompt(2,:) = {'Maximum photobleaching steps:','maxSteps',[]};
Formats(2,1).type = 'edit';
Formats(2,1).format = 'integer';
Formats(2,1).limits = [1 inf];
Formats(2,1).size = [40 25];
Formats(2,1).unitsloc = 'bottomleft';
Formats(2,1).enable = 'on';
DefAns.maxSteps = 10;

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
    figHandles.(channel) = figure('Name',[channel ' Signal:Noise'],'NextPlot','add');
    
    if ~isfield(statsByColor, [channel 'StepHist'])
        continue
    end
    foundData = 1;

    allStepSNR = transpose(getStepSNR(gridData, channel, minSteps, maxSteps));
    
    for a = 2:number
        load([matPath{a} filesep matFile{a}]);
        if ~isfield(statsByColor, [channel 'StepHist'])
            continue
        end
        foundData = 1;

        stepSNR = transpose(getStepSNR(gridData, channel, minSteps, maxSteps));
        if length(allStepSNR) > length(stepSNR)
            stepSNR( length(stepSNR)+1 : length(allStepSNR) ) = NaN;
        elseif length(stepSNR) > length(allStepSNR)
            allStepSNR( length(allStepSNR)+1 : length(stepSNR), :) = NaN;
        end
        allStepSNR = horzcat(allStepSNR, stepSNR);
    end
    
    distributionPlot(allStepSNR, 'showMM',6, 'xyOri','flipped', 'xNames',matFile, 'histOpt',1.1);
    
end

if ~foundData
    warndlg('This program requires photobleaching step data.  Please run the step counter first.');
end