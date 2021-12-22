% This script plots bait molecules that are potentially exhibiting fluorphore blinking behavior. 
% This information is displayed as percent co-appearance as a function of the number of frames since last appearance. Thus, the sampled molecules are all ones that have had a previous appearance event at the same location.
% 
% This script also creates a summary file of the data used in the plot and the percent co-appearance for spots that had no previous appearance in that sample.

% Ask user for data files
matFiles = uipickfiles('Prompt','Select mat files to compile for blinkerPlot','Type',{'*.mat'});
statusbar = waitbar(0);

% Generate a struct 'colors' containing a spectrum of unique colors to distinguish each sample in the dataset
 colors = jet(length(matFiles));

% Create structures to hold information across the dataset
totalx = [];
totalpctCoApp = [];
summary = struct();

% Size adjustable bin to average baits per Xframes since last appearance
nFramesBin = 100;

% Initialize the plot 
thePlot = figure('NumberTitle','off','visible','off'); title('Potential Blinkers'); xlabel('nFramesSinceLastApp'); ylabel('Percent Co-Appearance');

for a = 1:length(matFiles)
    % Get image name and root directory
    slash = strfind(matFiles{a},filesep);
    fileName = matFiles{a}(slash(end)+1:end); 
    expDir = matFiles{a}(1:slash(end));
    waitbar((a-1)/length(matFiles),statusbar,strrep(['Working on ' fileName],'_','\_'));
    
    % Load data
    load([expDir filesep fileName]);
    
    % Obtain bait and prey channel info from params variable
    baitChannel = params.BaitChannel;
    if strcmp(params.BaitPos, 'Left')
        preyChannel = params.RightChannel;
    else
        preyChannel = params.LeftChannel;
    end

    % Isolate bait appearances with earlier bait appearances at the same spotLocation
    earlierAppearanceIndex = ~strcmp({dynData.([baitChannel 'SpotData']).nFramesSinceLastApp}, 'No previous appearance') & cellfun(@(x) ~isempty(x) && ~isnan(x), {dynData.([baitChannel 'SpotData']).(['appears_w_' preyChannel])});
    earlierAppearanceSpots = cell2mat({dynData.([baitChannel 'SpotData'])(earlierAppearanceIndex).nFramesSinceLastApp});
    traces = find(earlierAppearanceIndex);
    
    % Of the isolated bait appearances with earlier appearances at the same spotLocation, pull out the ones that co-appear for the second appearance
    coAppIndex = earlierAppearanceIndex & cellfun(@(x) ~isempty(x) && ~isnan(x) && x==true, {dynData.([baitChannel 'SpotData']).(['appears_w_' preyChannel])});
    coAppSpots = cell2mat({dynData.([baitChannel 'SpotData'])(coAppIndex).nFramesSinceLastApp});
    
    %% Calculate and plot percent co-appearance of repeat bait appearances vs nFramesSinceLastApp for this sample
    nFramesMax = max(earlierAppearanceSpots);
    for b=1:ceil(nFramesMax/nFramesBin)
        low = (b-1)*nFramesBin;
        high = b*nFramesBin;
        totalBin = (low<=earlierAppearanceSpots & earlierAppearanceSpots<high);
        coAppBin = (low<=coAppSpots & coAppSpots<high);
        pctCoApp(b) = 100* (sum(coAppBin)/sum(totalBin));
    end
    x = 0:nFramesBin:nFramesMax;

    figure(thePlot); hold on; plot(x,pctCoApp,'Color',colors(a,:),'DisplayName',fileName); hold off
    
    % Compile sample data for median calculation later
    totalx = [totalx x];
    totalpctCoApp = [totalpctCoApp pctCoApp];
    
    %% Add the pctCoApp with it's corresponding nFramesSinceLastAppearance bin for this sample in a summary file across the data set
    summary(a).fileName = fileName;
    summary(a).binned_nFramesSinceLastAppearance = x;
    summary(a).pctCoApp = pctCoApp;
    
    clear x pctCoApp
    
    %% Calculate percent co-appearance for non-blinkers
    
    % Isolate bait appearances with no earlier bait appearances at the same spotLocation
    noEarlierAppearanceIndex = strcmp({dynData.([baitChannel 'SpotData']).nFramesSinceLastApp}, 'No previous appearance') & cellfun(@(x) ~isempty(x) && ~isnan(x), {dynData.([baitChannel 'SpotData']).(['appears_w_' preyChannel])});
    % Pull out the co-appearance status of these isolated bait appearances
    coAppStatus = cell2mat({dynData.([baitChannel 'SpotData'])(noEarlierAppearanceIndex).(['appears_w_' preyChannel])});
    
    % Calculate the percent co-appearance for non-blinkers for this sample and add to summary file
    summary(a).nonBlinkerPctCoApp = 100*(sum(coAppStatus)/length(coAppStatus));
end

% Calculate median across dataset
nFramesMax = max(totalx);
[xSorted,sortOrder]=sort(totalx);
pctCoAppSorted = totalpctCoApp(sortOrder);
for b=1:ceil(nFramesMax/nFramesBin)
    low = (b-1)*nFramesBin;
    high = b*nFramesBin;
    index = (low<=xSorted) & (xSorted<high);
    medianPctCoApp(b) = median(pctCoAppSorted(index),'omitnan');
end

%% Plot the mean pctCoApp across data set median trendline
x = 0:nFramesBin:nFramesMax;x(1) = [];
hold on; plot(x,medianPctCoApp,'-','LineWidth',2,'Color','k')
set(thePlot, 'visible','on'); % Present the plot to the user

close(statusbar)


