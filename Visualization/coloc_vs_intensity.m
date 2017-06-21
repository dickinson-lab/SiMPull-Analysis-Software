% Plots the intensities of colocalized vs. non-colocalized spots

%Get the data from the spot counter
[matFile matPath] = uigetfile('*.mat','Choose a .mat file with data from the spot counter');
load([matPath filesep matFile]);

if nChannels < 2
    msgbox('This program is intended for analyzing multicolor data.');
    return
end

% Get Intensity Data
% Right now this assumes 2-channel data - make it a loop later for more
% than 2 channels
[~, ch1ColocInt] = getIntensities(gridData, channels{1}, 'nStepsCutoff',1,'intMode', 'coloc', 'colocChannel', channels{2});
[~, ch1NotColocInt] = getIntensities(gridData, channels{1}, 'nStepsCutoff',1, 'intMode', 'notColoc', 'colocChannel', channels{2});
[~, ch2ColocInt] = getIntensities(gridData, channels{2}, 'nStepsCutoff',1, 'intMode','coloc', 'colocChannel',channels{1});
[~, ch2NotColocInt] = getIntensities(gridData, channels{2}, 'nStepsCutoff',1, 'intMode','notColoc', 'colocChannel',channels{1});
    

% Set up figure window
screenSize = get(0,'ScreenSize');
figSize = min([800 screenSize(3:4)]);
figXpos = (screenSize(3) - figSize)/2;
figYpos = (screenSize(4) - figSize)/2;
figure('Position',[figXpos figYpos figSize figSize]);

% Set up axes
colocPlot = axes('Units','Normalized', 'Position',[0.3 0.3 0.65 0.65]);
xPlot = axes('Units','Normalized', 'Position',[0.3 0.05 0.65 0.2], 'XAxisLocation','top');
yPlot = axes('Units','Normalized', 'Position',[0.05 0.3 0.2 0.65], 'YAxisLocation','right');

% Plot the data
scatter(colocPlot, ch1ColocInt, ch2ColocInt, 'k', 'MarkerFaceColor', 'k');
set(colocPlot, 'XLimMode','Auto', 'YLimMode','Auto');
distributionPlot(xPlot, ch1NotColocInt, 'showMM',0, 'histOri','left', 'xyOri','flipped', 'color',[0 0.7 0]);
set(xPlot, 'XLimMode','Auto');
distributionPlot(yPlot, ch2NotColocInt, 'showMM',0, 'histOri','left', 'color',[0.8 0 0]);
set(yPlot, 'YLimMode','Auto');

% Normalize axis scaling and fix labeling
colocXLim = get(colocPlot,'XLim');
ch1XLim = get(xPlot,'XLim');
Xmax = max([colocXLim(2) ch1XLim(2)]);
set(colocPlot, 'XLim',[0 Xmax]);
set(xPlot, 'XTickLabel','', 'YTickLabel','', 'YTick',[], 'XLim',[0 Xmax]);

colocYLim = get(colocPlot,'YLim');
ch2YLim = get(yPlot,'YLim');
Ymax = max([colocYLim(2) ch2YLim(2)]);
set(colocPlot, 'YLim',[0 Ymax]);
set(yPlot, 'XTickLabel','', 'YTickLabel','', 'YTick',[], 'YLim',[0 Ymax]);
