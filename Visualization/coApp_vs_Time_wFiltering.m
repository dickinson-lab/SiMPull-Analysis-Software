% Plots percent co-appearance as a function of time since lysis

baitChannel = 'Green'; preyChannel = 'FarRed'; trendWindow = 50; % These channel settings were a constant for the dataset this script was originally used on. In the future this part of the script should be channged to pull information from the params variable.

% These variables are used to distinguish markers on the plot according to experimental condition.
controlExps = {'Exp8_','Exp9_','Exp10_','Exp11_','Exp20_'}; %50 mW 638 nm laser
lowLaserExps = {'Exp17_'};                                  %5 mW 638 nm laser

% User selects the files desired in dataset
files = uipickfiles('Prompt','Select directories containing .mat files of dynamic data from automated analysis','Type',{'Directory'});

% Generate a struct 'colors' containing a spectrum of unique colors to distinguish each sample in the dataset
colors = jet(length(files));

% Manual entry of seconds elapsed since lysis entered in precisely the order in which files were selected earlier (ascending numerical order)
% Uncommented based on which dataset is being analyzed
% offSet = zeros(length(files),1); % Ignore offsets
offSet = [40,9,5,5,10,10,10,11,11,100,25,16,17,10,120,10,26,27,25,30]; % mNG::Halo
% offSet = [11,12,6,7,6,8,5,5,8,150,21,14,11,16,70,37,13,20,13,15,24,11,10,10,10,12,7,26,18,18,25,20,10,13]; % aPKC/PAR-6

% Manualy set based on desired filters
blinkerFilter = false;
lowDensityFilter = false;
highDensityFilter = false;
lateAppearanceFilter = true;

% Sanity check
wb = waitbar(0,['Makin a plot']);

% Initiate figures
coApp_vs_TimePlot = figure('Name','Control (mNG::Halo)','NumberTitle','off'); title('Co-Appearance Over Time'); xlabel('Seconds After Lysis'); ylabel('Percent Co-Appearance');
coApp_vs_TimePlotTrends = figure('Name','Control (mNG::Halo)','NumberTitle','off'); title('Co-Appearance Over Time'); xlabel('Seconds After Lysis'); ylabel('Percent Co-Appearance');

% Create empty vectors to store data across samples
totalxAxis = []; 
totalpctCoApp = [];

for f=1:length(files)
    slash = strfind(files{f},filesep);
    expDir = files{f};
    fileName = files{f}(slash(end)+1:end);
    waitbar((f-1)/length(files),wb);
    
    if exist([expDir filesep fileName '_greedyPlus_reReg.mat'])
        load([expDir filesep fileName '_greedyPlus_reReg.mat'])
    elseif exist([expDir filesep fileName '_greedyPlus.mat'])
        load([expDir filesep fileName '_greedyPlus.mat'])
    elseif exist([expDir filesep fileName '_greedyCoApp_reReg.mat'])
        load([expDir filesep fileName '_greedyCoApp_reReg.mat']);
        density = load([expDir filesep fileName '_forDensity.mat']);
    else
        load([expDir filesep fileName '_greedyCoApp.mat']);
        density = load([expDir filesep fileName '_forDensity.mat']);
    end 
    
    % Determine image area for density calculations
    img4size = Tiff([files{f} filesep fileName '_baitAvg.tif'],'r');
    imgData = read(img4size);
    [imgLength, width] = size(imgData);
    imgArea = imgLength * width * params.pixelSize^2;
    
    % Calculate % co-appearance and density for bait and prey molecules appearing and present in each time window for current sample    
    colocData = {dynData.([baitChannel 'SpotData']).(['appears_w_' preyChannel])};
    nspots = length(colocData);
    lastWindow = max(cell2mat({dynData.([baitChannel 'SpotData']).appearedInWindow}));
    
    % Remove blinking and late-appearing molecules based on user selection above
    if blinkerFilter == true
        blinker = cellfun(@(x) isnumeric(x) && length(x)==1 && ~isnan(x) && x<2500, {dynData.([baitChannel 'SpotData']).nFramesSinceLastApp});
    end
    if lateAppearanceFilter
        late = false(1,nspots);
        for b = 1:nspots
            late(b) = isnumeric(dynData.([baitChannel 'SpotData'])(b).appearTime) && dynData.([baitChannel 'SpotData'])(b).appearTime > 50 * (dynData.([baitChannel 'SpotData'])(b).appearedInWindow + 1);
        end
    end
    for a = 1:lastWindow
        index = cell2mat({dynData.([baitChannel 'SpotData']).appearedInWindow}) == a;
        if blinkerFilter == true
           index = index & ~blinker;
        end
        if lateAppearanceFilter
            index = index & ~late;
        end
        baitsCounted(a) = sum(~cellfun(@(x) isempty(x)||isnan(x), colocData(index)));
        coAppearing(a) = sum(cellfun(@(x) ~isempty(x) && x==true, colocData(index)));
        dBDensity(a) = (sum(index))/imgArea;
    end
    pctCoApp = 100 * (coAppearing ./ baitsCounted);
    if exist('density')
        aBDensity = density.dynData.([baitChannel 'AvgCount']) ./ imgArea;
        aPDensity = density.dynData.([preyChannel 'AvgCount']) ./ imgArea;
    else
        aBDensity = dynData.([baitChannel 'AvgCount']) ./ imgArea;
        aPDensity = dynData.([preyChannel 'AvgCount']) ./ imgArea;
    end
    
    % Stupid thing I have to do because I made a mistake in the processing step for some samples
    if aBDensity(1) == 0
        aBDensity(1) = NaN;
    end
    if aPDensity(1) == 0
        aPDensity(1) = NaN;
    end

    % Calculate mean trend for sample
    baitTrend = movsum(baitsCounted,trendWindow,'omitnan');
    preyTrend = movsum(coAppearing,trendWindow,'omitnan');
    coAppTrend = 100 * (preyTrend ./ baitTrend);
    
    % Filter out the appropriate windows if filtering by density
    if lowDensityFilter == true
        for a = 1:lastWindow
            if dBDensity(a) < 5e-9
                pctCoApp(a) = NaN;
                coAppTrend(a) = NaN;
            end
        end
    end
    if highDensityFilter == true
       for a = 1:lastWindow
           if aBDensity(a) > 8e-7 || aPDensity(a) > 8e-7
               pctCoApp(a) = NaN;
               coAppTrend(a) = NaN;
           end
       end
    end
    
    % Set x axis for this sample by offseting the first point by how many seconds aquisition started after lysis
    x = 2.5*[1:lastWindow];
    x = bsxfun(@plus, x, offSet(f));
    
    % Set plot markers according to experiment
    if contains(fileName, controlExps)
        marker = 'o';
        lineMarker = '-';
    elseif contains(fileName, lowLaserExps)
        marker = 's';
        lineMarker = '--';
    end
    
    % Plot sample
    figure(coApp_vs_TimePlot); hold on; plot(x,pctCoApp,marker,'MarkerSize',2.5,'Color',colors(f,:),'DisplayName',fileName); hold off  % Plots all data point
    figure(coApp_vs_TimePlotTrends); hold on; plot(x,coAppTrend,lineMarker,'LineWidth',1,'Color',colors(f,:),'DisplayName',fileName);hold off  % Plots sample means

    %Add information about this sample to the structs containing cumulative information across samples in the dataset
    totalxAxis = [totalxAxis x];
    totalpctCoApp = [totalpctCoApp pctCoApp];
    
    clear density dBDensity aBDensity aPDensity baitsCounted coAppearing pctCoApp coAppTrend
end

% Sort x-axis values from low to high and align it with the co-appearance percentage at each time point to find the median trend line
[xAxisSorted,sortOrder]=sort(totalxAxis);
pctCoAppSorted = totalpctCoApp(sortOrder);

for a=1:ceil(max(xAxisSorted)/trendWindow)
    low = (a-1)*trendWindow;
    high = a*trendWindow;
    sortIndex = (low<xAxisSorted) & (xAxisSorted<high) & pctCoAppSorted ~= 0 & ~isnan(pctCoAppSorted);
    pctCoAppMedian(a) = median(pctCoAppSorted(sortIndex));
end
x = 0:trendWindow:max(totalxAxis);
figure(coApp_vs_TimePlot); hold on;
plot(x,pctCoAppMedian,'-','Color', 'k','LineWidth',2);

savefig(coApp_vs_TimePlot,'Z:\Sarikaya_Sena\Exp26\coApp_vs_Time_blinkerFilter.fig')
savefig(coApp_vs_TimePlotTrends,'Z:\Sarikaya_Sena\Exp26\coApp_vs_Time_blinkerFilter_trends.fig')

close(wb)

