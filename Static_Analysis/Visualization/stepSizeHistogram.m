%Extracts the initial intensities of spots in a SiMPull experiment and
%displays this information as a histogram.

%clear all;

%Get the data from the spot counter
[matFile matPath] = uigetfile('*.mat','Choose a .mat file with data from the spot counter');
load([matPath filesep matFile]);

%Choose which spots to include in the plot
prompt = {'Choose which traces to analyze\nMinimum Number of Steps:','Maximum Number of Steps:'};
dlg_title = 'Choose traces';
num_lines = 1;
def = {'1','10'};
answer2 = inputdlg(prompt,dlg_title,num_lines,def);

%answer2 = inputdlg('Analyze data for spots with >= this many photobleaching steps:','',1,{'1'});
minSteps = str2double(answer2{1});
maxSteps = str2double(answer2{2});
for a = 1:nChannels
    channel = channels{a};
    if ~isfield(statsByColor, [channel 'StepHist'])
        continue
    end
    foundData = 1;
    
    stepSizes = getStepSizes(gridData, channel, minSteps, maxSteps);
    
    histogram(stepSizes);

end

if ~foundData
    msgbox('This program requires photobleaching step data.  Please run the step counter first');
    return
end
