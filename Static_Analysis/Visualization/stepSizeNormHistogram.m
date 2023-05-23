%Extracts the initial intensities of spots in a SiMPull experiment and
%displays this information as a histogram.

%clear all;

%Get the data from the spot counter
[matFile matPath] = uigetfile('*.mat','Choose a .mat file with data from the spot counter');
load([matPath filesep matFile]);
if ~exist('greenStepHist')
    msgbox('This program requires photobleaching step data.  Please run the step counter first');
    return
end

if exist('redStepHist')
    button = questdlg('Multi-Channel Data Found. Select Channel to Display',...
                       'Select Channel',...
                       'Green','Red','Green');
    if strcmp(button,'Green')
        channel = 'green';
        stepHist = greenStepHist;
    else
        channel = 'red';
        stepHist = redStepHist;
    end
else
    button = 'Green';
    channel = 'green';
    stepHist = greenStepHist;
end

prompt = {'Choose which traces to analyze\nMinimum Number of Steps:','Maximum Number of Steps:'};
dlg_title = 'Choose traces';
num_lines = 1;
def = {'1','10'};
answer2 = inputdlg(prompt,dlg_title,num_lines,def);
%answer2 = inputdlg('Analyze data for spots with >= this many photobleaching steps:','',1,{'1'});
minSteps = str2double(answer2{1});
maxSteps = str2double(answer2{2});

%Now the actual caculation
%Get the data
index2 = zeros(length(gridData),1);
for b = 1:length(gridData)
    index2(b) = isfield(gridData(b).([channel 'SpotData']),'nSteps');
end
nImages = sum(index2);
index2 = logical(index2);
spotData = {gridData(index2).([channel 'SpotData'])};
spotData = vertcat(spotData{:});
index = arrayfun(@(x) isnumeric(x.nSteps) && x.nSteps>=minSteps && x.nSteps<=maxSteps,  spotData);
goodSpots = spotData(index);

%Caculate normalized step sizes
normStepSizes = [];
for a=1:length(goodSpots)
    nSteps = goodSpots(a).nSteps;
    stepSizes = zeros(nSteps,1);
    for b=1:nSteps
        stepSizes(b) = goodSpots(a).steplevels(b) - goodSpots(a).steplevels(b+1);
    end
    normSteps = stepSizes ./ median(stepSizes);
    normStepSizes = vertcat(normStepSizes,normSteps);
end
   
logNormStepSizes = log2(normStepSizes);
binwidth = max(logNormStepSizes)/50;
bins = [min(logNormStepSizes):binwidth:max(logNormStepSizes)];
figure;
bar(bins,histc(logNormStepSizes,bins));