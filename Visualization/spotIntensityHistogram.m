%Extracts the initial intensities of spots in a SiMPull experiment and
%displays this information as a histogram.

clear all;
%close all;

%Get the data from the spot counter
[matFile matPath] = uigetfile('*.mat','Choose a .mat file with data from the spot counter');
load([matPath filesep matFile]);

foundData = 0;
for b = 1:nChannels
    channel = channels{b};
    figHandles.(channel) = figure('Name',[channel ' Channel Intensities'],'NextPlot','add');
    
    if ~isfield(statsByColor, [channel 'StepHist'])
        continue
    end
    
    foundData = 1;
    [~,intensities] = getIntensities(gridData,channel);
    
    histogram(intensities);
end

if ~foundData
    msgbox('This program requires photobleaching step data.  Please run the step counter first');
end