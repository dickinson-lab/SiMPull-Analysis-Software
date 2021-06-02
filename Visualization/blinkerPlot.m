% This script plots bait molecules that are potentially exhibiting fluorphore blinking behavior. 
% This information is displayed as percent co-appearance as a function of the number of frames since last appearance. Thus, the sampled molecules are all ones that have had a previous appearance event at the same location.
% 
% This script also creates a summary file of the sample by sample data used in the plot and the percent co-appearance for spots that had no previous appearance in that sample.

% Ask user for data files
matFiles = uipickfiles('Prompt','Select data files to analyze','Type',{'*.mat'});
statusbar = waitbar(0);

% Indicate bait and prey channels -- notice, these parameters should not be constants if this script is used in the future
baitChannel = 'Green'; preyChannel = 'FarRed';

% Create indicators to be used later when plotting to distinguish experimental conditions of interest
controlLaserExps = {'Exp8_','Exp9_','Exp10_','Exp11_','Exp20_'};
lowLaserExps = {'Exp17_'};

% Create structures to hold sample data across the dataset
totalx = [];
totalpctCoApp = [];
summary = struct();

% Choose an artibtrary bin to average baits per Xframes since last appearance
nFramesBin = 100;

% Initialize the plot 
thePlot = figure('Name','Control (mNG::Halo)','NumberTitle','off'); title('Potential Blinkers'); xlabel('nFramesSinceLastApp'); ylabel('Percent Co-Appearance');

for a = 1:length(matFiles)
    % Get image name and root directory
    slash = strfind(matFiles{a},filesep);
    fileName = matFiles{a}(slash(end)+1:end); 
    expDir = matFiles{a}(1:slash(end));
    colors = jet(length(matFiles));
    waitbar((a-1)/length(matFiles),statusbar,strrep(['Working on ' fileName],'_','\_'));
    
    % Load data
    load([expDir filesep fileName]);
    
    excess = '_greedy';
    snipsnop = regexp(fileName,excess,'split');
    genfileName = snipsnop{1};

    % Isolate bait appearances with earlier bait appearances at the same spotLocation
    earlierAppearanceIndex = ~strcmp({dynData.([baitChannel 'SpotData']).nFramesSinceLastApp}, 'No previous appearance') & cellfun(@(x) ~isempty(x) && ~isnan(x), {dynData.([baitChannel 'SpotData']).(['appears_w_' preyChannel])});
    earlierAppearanceSpots = cell2mat({dynData.([baitChannel 'SpotData'])(earlierAppearanceIndex).nFramesSinceLastApp});
    traces = find(earlierAppearanceIndex);
    
    % Of the isolated bait appearances with earlier appearances at the same spotLocation, pull out the ones that co-appear for the second appearance
    coAppIndex = earlierAppearanceIndex & cellfun(@(x) ~isempty(x) && ~isnan(x) && x==true, {dynData.([baitChannel 'SpotData']).(['appears_w_' preyChannel])});
    coAppSpots = cell2mat({dynData.([baitChannel 'SpotData'])(coAppIndex).nFramesSinceLastApp});
    
    % Calculate and plot percent co-appearance of repeat bait appearances vs nFramesSinceLastApp for this sample
    nFramesMax = max(earlierAppearanceSpots);
    for b=1:ceil(nFramesMax/nFramesBin)
        low = (b-1)*nFramesBin;
        high = b*nFramesBin;
        totalBin = (low<=earlierAppearanceSpots & earlierAppearanceSpots<high);
        coAppBin = (low<=coAppSpots & coAppSpots<high);
        pctCoApp(b) = 100* (sum(coAppBin)/sum(totalBin));
    end
    x = 0:nFramesBin:nFramesMax;
    if contains(fileName, controlLaserExps)
            marker = 'o';
    elseif contains(fileName, lowLaserExps)
           marker = 's';
    end
    figure(thePlot); hold on; plot(x,pctCoApp,marker,'MarkerSize',2.5,'Color',colors(a,:),'DisplayName',genfileName); hold off
    
    % Compile sample data for median calculation later
    totalx = [totalx x];
    totalpctCoApp = [totalpctCoApp pctCoApp];
    
    % Save the pctCoApp with it's corresponding nFramesSinceLastAppearance bin for this sample in a summary file across the data set
    summary(a).fileName = genfileName;
    summary(a).binned_nFramesSinceLastAppearance = x;
    summary(a).pctCoApp = pctCoApp;
    
    clear x pctCoApp
    
    %% Calculate percent co-appearance for non-blinkers
    
    % Isolate bait appearances with no earlier bait appearances at the same spotLocation
    noEarlierAppearanceIndex = strcmp({dynData.([baitChannel 'SpotData']).nFramesSinceLastApp}, 'No previous appearance') & cellfun(@(x) ~isempty(x) && ~isnan(x), {dynData.([baitChannel 'SpotData']).(['appears_w_' preyChannel])});
    % Pull out the co-appearance status of these isolated bait appearances
    coAppStatus = cell2mat({dynData.([baitChannel 'SpotData'])(noEarlierAppearanceIndex).(['appears_w_' preyChannel])});
    
    % Calculate and save percent co-appearance for this sample
    summary(a).nonBlinkerPctCoApp = 100*(sum(coAppStatus)/length(coAppStatus));
    save('Z:\Sarikaya_Sena\Exp26\summary.mat','summary');
end
% Calculate median across dataset
nFramesMax = max(totalx);
[xSorted,sortOrder]=sort(totalx);           % The xSorted vector is what is reported on the nFramesSinceLastAppearance column on the Exp26 tab on Laser Lysis Google Sheet
pctCoAppSorted = totalpctCoApp(sortOrder);  % The pctCoAppSorted vector is what is reported on the pctCoApp column on the Exp26 tab on the Laser Lysis Google Sheet
for b=1:ceil(nFramesMax/nFramesBin)
    low = (b-1)*nFramesBin;
    high = b*nFramesBin;
    index = (low<=xSorted) & (xSorted<high);
    medianPctCoApp(b) = median(pctCoAppSorted(index),'omitnan');
end
close(statusbar)

% Plot the mean pctCoApp across data set median trendline
x = 0:nFramesBin:nFramesMax;x(1) = [];
hold on; plot(x,medianPctCoApp,'-','LineWidth',2,'Color','k')

% Save plot
savefig('Z:\Sarikaya_Sena\Exp26\blinkerPlot_w_Median.fig')


