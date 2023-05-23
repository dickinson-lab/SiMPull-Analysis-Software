%Exptracts and displays the time to bleach (i.e., the length of time a
%fluor is active before bleaching). The data are plotted as a histogram of
%bleaching times, which allows the user to see the mode of the bleaching
%time. 

clear all;
%close all;

%Get the data from the spot counter
[matFile matPath] = uigetfile('*.mat','Choose a .mat file with data from the spot counter');
load([matPath filesep matFile]);

foundData = 0;
for b = 1:nChannels
    channel = channels{b};
    figHandles.(channel) = figure('Name',[channel ' Channel Bleaching Times'],'NextPlot','add');
    
    % Get the data
    if ~isfield(statsByColor, [channel 'StepHist'])
        continue
    end
    foundData = 1;
    
    bleachTimes = getBleachTimes(gridData, channel);
    
    %Plot 
    xaxis = 1:length(gridData(1).([channel 'SpotData'])(1).intensityTrace); %This assumes all trajectories have the same length - not bulletproof but good enough for my purposes.
    
    axes1 = axes('Box','off','YTick',[]);
    histogram(bleachTimes);
    [ysmooth, xsmooth] = ksdensity(bleachTimes, 'support', 'positive');
    ysmooth = ysmooth * length(bleachTimes);
    hold on
    plot(axes1,xsmooth,ysmooth,'r','LineWidth',2);
    set(axes1,'Box','off');
    set(axes1,'XLim',[0 length(xaxis)]);
    ylabel(axes1,'Number of steps');  

    axesPosition = get(gca,'Position');          %# Get the current axes position
    axes2 = axes('Position',axesPosition);  %# Place a new axes on top...
    ecdf(axes2, bleachTimes);
    line2 = findobj(gca,'Type','line');
    set(line2,'Color','g','LineWidth',2);
    set(axes2,'YAxisLocation','right','Color','none','Box','off');
    ylabel(axes2,'Percent Bleached');  
    
    set(axes2,'XLim',[0 length(xaxis)]);
end

if ~foundData
    msgbox('This program requires photobleaching step data.  Please run the step counter first');
end