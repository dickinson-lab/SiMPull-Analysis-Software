%Extracts the initial intensities of spots in a SiMPull experiment and
%displays this information as a histogram.

clear all;
%close all;

%Get the data from the spot counter
[matFile matPath] = uigetfile('*.mat','Choose a .mat file with data from the spot counter');
load([matPath filesep matFile]);
if ~exist('greenStepHist')
    msgbox('This program requires photobleaching step data.  Please run the step counter first');
end

greenIntensities = getIntensities(gridData,'green',1);
colocGreenIntensities = getColocIntensities(gridData,'green',1);
figure('Name','Green Channel Intensities');
binwidth = round(max(greenIntensities)/100);
bins = [binwidth:binwidth:max(greenIntensities)];
h1 = axes();
h2 = axes();
area(h1,bins,histc(greenIntensities,bins),'FaceColor','g');
set(h1,'Box','off','YColor',[0 0.5 0],'xlim',[0 max(bins)]);
area(h2,bins,histc(colocGreenIntensities,bins),'FaceColor','b')
set(h2,'Color','none','YAxisLocation','right','Box','off','YColor',[0 0.5 0],'xlim',[0 max(bins)]);
alpha(0.5);

%save([matPath filesep matFile],'greenIntensities','-append')
if isfield(gridData,'redSpotCount')
    redIntensities = getIntensities(gridData,'red',1);
    colocRedIntensities = getColocIntensities(gridData,'red',1);
    figure('Name','Red Channel Intensities');
    binwidth = round(max(redIntensities)/100);
    bins = [binwidth:binwidth:max(redIntensities)];
    h3 = axes();
    h4 = axes();
    area(h3,bins,histc(redIntensities,bins),'FaceColor','r');
    set(h3,'Box','off','YColor',[0 0.5 0],'xlim',[0 max(bins)]);
    area(h4,bins,histc(colocRedIntensities,bins),'FaceColor','b')
    set(h4,'Color','none','YAxisLocation','right','Box','off','YColor',[0 0.5 0],'xlim',[0 max(bins)]);
    alpha(0.5);

    %save([matPath filesep matFile],'redIntensities','-append')
end