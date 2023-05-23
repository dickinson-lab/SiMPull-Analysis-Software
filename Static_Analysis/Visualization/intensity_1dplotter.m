%Extracts the intensities of spots in each image and displays this information as a function of position.
%Note, this only works if gridData is 1-dimensional (i.e. images were
%acquired in a stripe)

clear all;
%close all;

%Get the data from the spot counter
startpath = pwd;
[file path] = uigetfile('*.mat','Choose a .mat file with data from the spot counter',startpath);

load([path filesep file]);
gridSize = size(gridData);

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

for c = 1:nChannels
    color = channels{c};
    
    [~, allIntensities] = getIntensities(gridData(1),color,'nStepsCutoff',cutoff,'includeRejected',includeRejected);
    
    for a = 2:length(gridData)
        [~, intensities] = getIntensities(gridData(a),color,'nStepsCutoff',cutoff,'includeRejected',includeRejected);
        if length(allIntensities) > length(intensities)
            intensities( length(intensities)+1 : length(allIntensities), : ) = NaN;
        elseif length(intensities) > length(allIntensities)
            allIntensities( length(allIntensities)+1 : length(intensities), :) = NaN;
        end
        allIntensities = horzcat(allIntensities, intensities);
    end
    
    figHandles.(color) = figure('Name',[color ' Intensities'],'NextPlot','add');
    if isempty(allIntensities)
        continue 
    elseif length(allIntensities) > 100
        distributionPlot(allIntensities, 'showMM',6, 'histOpt',1.1, 'globalNorm',2); %This will sometimes throw an error if any images contain only a few spots.  For now the simplest work-around is to just plot a subset of the stage positions.
    else
        plotSpread(allIntensities);
        axesHandle = get(figHandles.(color), 'Children');
        dataHandles = get(axesHandle, 'Children');
        set(dataHandles, 'MarkerSize', 10);
    end
    
end
