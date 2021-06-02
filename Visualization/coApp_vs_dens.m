% Plots percent co-appearance as a function of spot density for dynamic SiMPull data.

% dB = bait spot data using difference images 
% dP = prey spot data using difference images 
% aB = bait spot data using average images 
% aP = prey spot data using average images 

baitChannel = 'Green'; preyChannel = 'FarRed'; % These channel settings were a constant for the dataset this script was originally used on. In the future this part of the script should be channged to pull information from the params variable.

% These variables are used to distinguish markers on the plot according to experimental condition.
controlExps = {'Exp8_','Exp9_','Exp10_','Exp11_','Exp20_'}; %50 mW 638 nm laser
lowLaserExps = {'Exp17_'};                                  %5 mW 638 nm laser

% User selects the files desired in dataset
files = uipickfiles('Prompt','Select directories containing .mat files with density information','Type',{'Directory'});

% Generate a struct 'colors' containing a spectrum of unique colors to distinguish each sample in the dataset
colors = jet(length(files));

% User decides meanInterval 
opts.Interpreter = 'tex';
answer = inputdlg('\fontsize{10}How many intervals would you like to divide the max density per sample for percent co-appearance vs density trend line?',...
    'trendWindow',[1 35],{'21'},opts);
meanInterval = str2double(answer);

% Manually set based on desired filtering
lowDensityFilter = true;

% Initiate figures
dBplot = figure('Name','Control Appearing Bait (mNG::Halo)','NumberTitle','off'); title('Control Appearing Bait (mNG::Halo)'); xlabel('Appearing Bait Density (spots/nm^2)'); ylabel('Percent Co-Appearance');
dPplot = figure('Name','Control Appearing Prey (mNG::Halo)','NumberTitle','off'); title('Control Appearing Prey (mNG::Halo)'); xlabel('Appearing Prey Density (spots/nm^2)'); ylabel('Percent Co-Appearance');
aBplot = figure('Name','Control Present Bait (mNG::Halo)','NumberTitle','off'); title('Control Present Bait (mNG::Halo)'); xlabel('Present Bait Density (spots/nm^2)'); ylabel('Percent Co-Appearance');
aPplot = figure('Name','Control Present Prey (mNG::Halo)','NumberTitle','off'); title('Control Present Prey (mNG::Halo)'); xlabel('Present Prey Density (spots/nm^2)'); ylabel('Percent Co-Appearance');

% Create empty vectors to store data across samples
pctCoAppCumulative = [];
dBcumulativeDensity = [];
dPcumulativeDensity = [];
aBcumulativeDensity = [];
aPcumulativeDensity = [];

for f=1:length(files)
    slash = strfind(files{f},filesep);
    expDir = files{f};
    fileName = files{f}(slash(end)+1:end);
    
%     % Uncommented for plots displaying data only from 5 mW 638 nm laser power experiments
%     if contains(fileName, controlExps)
%         continue
%     end
    
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
    message = msgbox(['Working on ' fileName]);

    % Determine image area for density calculations
    img4size = Tiff([files{f} filesep fileName '_baitAvg.tif'],'r');
    imgData = read(img4size);
    [imgLength, width] = size(imgData);
    imgArea = imgLength * width * params.pixelSize^2;
    
    % Calculate % co-appearance and density for bait and prey molecules appearing and present in each time window for current sample    
    lastWindow = max(cell2mat({dynData.([baitChannel 'SpotData']).appearedInWindow}));
    colocData = {dynData.([baitChannel 'SpotData']).(['appears_w_' preyChannel])};
    for a = 1:lastWindow
        index = cell2mat({dynData.([baitChannel 'SpotData']).appearedInWindow}) == a;
        baitsCounted(a) = sum(~cellfun(@(x) isempty(x)||isnan(x), colocData(index)));
        coAppearing(a) = sum(cellfun(@(x) ~isempty(x) && x==true, colocData(index)));
        dBDensity(a) = (sum(index))/imgArea;
    end
    pctCoApp = 100 * (coAppearing ./ baitsCounted);
    if exist('density')
        dPDensity = density.dynData.([preyChannel 'DiffCount']) ./ imgArea;
        aBDensity = density.dynData.([baitChannel 'AvgCount']) ./ imgArea;
        aPDensity = density.dynData.([preyChannel 'AvgCount']) ./ imgArea;
    else
        dPDensity = dynData.([preyChannel 'DiffCount']) ./imgArea;
        aBDensity = dynData.([baitChannel 'AvgCount']) ./ imgArea;
        aPDensity = dynData.([preyChannel 'AvgCount']) ./ imgArea;
    end
        
    % Stupid thing I have to do because I made a mistake in the processing step for some samples
    if dPDensity(1) == 0
        dPDensity(1) = NaN;
    end
    if aBDensity(1) == 0
        aBDensity(1) = NaN;
    end
    if aPDensity(1) == 0
        aPDensity(1) = NaN;
    end
    
    % Set plot marker according to experiment
    if contains(fileName, controlExps)
        marker = 'o';
    elseif contains(fileName, lowLaserExps)
        marker = 's';
    end
    
    % Filter out the appropriate windows if filtering by density
    if lowDensityFilter == true
        for a = 1:lastWindow
            if dBDensity(a) < 5e-9
                pctCoApp(a) = NaN;
            end
        end
    end
           
    % Plot density vs pcCoApp for this sample
    figure(dBplot); hold on; plot(dBDensity,pctCoApp,marker,'MarkerSize',2.5,'Color',colors(f,:),'DisplayName',fileName); hold off
    figure(dPplot); hold on; plot(dPDensity,pctCoApp,marker,'MarkerSize',2.5,'Color',colors(f,:),'DisplayName',fileName); hold off
    figure(aBplot); hold on; plot(aBDensity,pctCoApp,marker,'MarkerSize',2.5,'Color',colors(f,:),'DisplayName',fileName); hold off
    figure(aPplot); hold on; plot(aPDensity,pctCoApp,marker,'MarkerSize',2.5,'Color',colors(f,:),'DisplayName',fileName); hold off
    
    %Add information about this sample to the structs containing cumulative information across samples in the dataset
    pctCoAppCumulative = [pctCoAppCumulative pctCoApp];
    dBcumulativeDensity = [dBcumulativeDensity dBDensity];
    dPcumulativeDensity = [dPcumulativeDensity dPDensity];
    aBcumulativeDensity = [aBcumulativeDensity aBDensity];
    aPcumulativeDensity = [aPcumulativeDensity aPDensity];
    
    clear density dBDensity dPDensity aBDensity aPDensity baitsCounted coAppearing pctCoApp
    close (message);
end    

% Sort density from low to high and align it with the co-appearance percentage at each density for averaging 
message = msgbox('Trying to find a trend...');

[dBcumulativeDensitySorted,dB]=sort(dBcumulativeDensity);
[dPcumulativeDensitySorted,dP]=sort(dPcumulativeDensity);
[aBcumulativeDensitySorted,aB]=sort(aBcumulativeDensity);
[aPcumulativeDensitySorted,aP]=sort(aPcumulativeDensity);
dBpctCoAppSorted = pctCoAppCumulative(dB);
dPpctCoAppSorted = pctCoAppCumulative(dP);
aBpctCoAppSorted = pctCoAppCumulative(aB);
aPpctCoAppSorted = pctCoAppCumulative(aP);
    
% Calculate moving (weighted) mean
dBdensityWindow = max(dBcumulativeDensity)/meanInterval;
dPdensityWindow = max(dPcumulativeDensity)/meanInterval;
aBdensityWindow = max(aBcumulativeDensity)/meanInterval;
aPdensityWindow = max(aPcumulativeDensity)/meanInterval;
for a=1:meanInterval
    low = (a-1)*dBdensityWindow;
    high = a*dBdensityWindow;
    dBindex = (low<dBcumulativeDensitySorted) & (dBcumulativeDensitySorted<high);
    dBpctCoAppMean(a) = mean(dBpctCoAppSorted(dBindex),'omitnan');
end 

for a=1:meanInterval
    low = (a-1)*dPdensityWindow;
    high = a*dPdensityWindow;
    dPindex = (low<dPcumulativeDensitySorted) & (dPcumulativeDensitySorted<high);
    dPpctCoAppMean(a) = mean(dPpctCoAppSorted(dPindex),'omitnan');
end

for a=1:meanInterval
    low = (a-1)*aBdensityWindow;
    high = a*aBdensityWindow;
    aBindex = (low<aBcumulativeDensitySorted) & (aBcumulativeDensitySorted<high);
    aBpctCoAppMean(a) = mean(aBpctCoAppSorted(aBindex),'omitnan');
end

for a=1:meanInterval
    low = (a-1)*aPdensityWindow;
    high = a*aPdensityWindow;
    aPindex = (low<aPcumulativeDensitySorted) & (aPcumulativeDensitySorted<high);
    aPpctCoAppMean(a) = mean(aPpctCoAppSorted(aPindex),'omitnan');
end
close (message);

% Plot dB data
x = 0:dBdensityWindow:max(dBcumulativeDensity); x(1) = [];
figure(dBplot); hold on;
plot(x,dBpctCoAppMean,'-','Color','k','LineWidth',1.5)

% Plot dP data
x = 0:dPdensityWindow:max(dPcumulativeDensity); x(1) = [];
figure(dPplot); hold on;
plot(x,dPpctCoAppMean,'-','Color','k','LineWidth',1.5)
 
% Plot aB data
x = 0:aBdensityWindow:max(aBcumulativeDensity); x(1) = [];
figure(aBplot); hold on;
plot(x,aBpctCoAppMean,'-','Color','k','LineWidth',1.5)

% Plot aP data
x = 0:aPdensityWindow:max(aPcumulativeDensity); x(1) = [];
figure(aPplot); hold on;
plot(x,aPpctCoAppMean,'-','Color','k','LineWidth',1.5)

savefig(dBplot,'Z:\Sarikaya_Sena\Exp28\coApp_vs_dens\LowFilter\AppearingBait.fig');
savefig(dPplot,'Z:\Sarikaya_Sena\Exp28\coApp_vs_dens\LowFilter\AppearingPrey.fig');
savefig(aBplot,'Z:\Sarikaya_Sena\Exp28\coApp_vs_dens\LowFilter\PresentBait.fig');
savefig(aPplot,'Z:\Sarikaya_Sena\Exp28\coApp_vs_dens\LowFilter\PresentPrey.fig');
