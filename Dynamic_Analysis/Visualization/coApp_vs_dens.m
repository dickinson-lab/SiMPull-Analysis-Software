% Plots percent co-appearance as a function of spot density for dynamic SiMPull data.

% dB = bait spot data using difference images 
% dP = prey spot data using difference images 
% aB = bait spot data using average images 
% aP = prey spot data using average images 

% Ask user for data files
matFiles = uipickfiles('Prompt','Select _forDensity.mat files.','Type',{'*_forDensity.mat'});
statusbar = waitbar(0);

% Generate a struct 'colors' containing a spectrum of unique colors to distinguish each sample in the dataset
colors = jet(length(matFiles));

% User decides meanInterval 
opts.Interpreter = 'tex';
answer = inputdlg('\fontsize{10}How many intervals would you like to divide the max density per sample for percent co-appearance vs density trend line?',...
    'trendWindow',[1 60],{'21'},opts);
meanInterval = str2double(answer);

% User indicates if a low density filter will be applied
opts.Interpreter = 'tex';
answer = inputdlg('\fontsize{10}Exclude images with less than 5e-9 spots/nm^2 (i.e. apply a low density filter)? Type Y for "yes" or N for "no."',...
    'lowDensityFilter',[1 60],{'Y'},opts);
lowDensityFilter = contains(answer,'Y');

% Initiate figures
dBplot = figure('Name','Appearing Bait','NumberTitle','off','visible','off'); title('Appearing Bait'); xlabel('Appearing Bait Density (spots/nm^2)'); ylabel('Percent Co-Appearance');
dPplot = figure('Name','Appearing Prey','NumberTitle','off','visible','off'); title('Appearing Prey'); xlabel('Appearing Prey Density (spots/nm^2)'); ylabel('Percent Co-Appearance');
aBplot = figure('Name','Present Bait','NumberTitle','off','visible','off'); title('Present Bait'); xlabel('Present Bait Density (spots/nm^2)'); ylabel('Percent Co-Appearance');
aPplot = figure('Name','Present Prey','NumberTitle','off','visible','off'); title('Present Prey'); xlabel('Present Prey Density (spots/nm^2)'); ylabel('Percent Co-Appearance');

% Create empty vectors to store data across samples
pctCoAppCumulative = [];
dBcumulativeDensity = [];
dPcumulativeDensity = [];
aBcumulativeDensity = [];
aPcumulativeDensity = [];

for f = 1:length(matFiles)
    % Get image name and root directory
    slash = strfind(matFiles{f},filesep);
    fileName = matFiles{f}(slash(end)+1:end); 
    expDir = matFiles{f}(1:slash(end));
   
    % Load density data
    density = load([expDir filesep fileName]);
    
    % Load appearing bait data 
     remove = "_forDensity";
     snipsnop = regexp(fileName,remove,'split');
     fileName = snipsnop{1};
     load([expDir filesep fileName '.mat']);
     waitbar((f-1)/length(matFiles),statusbar,strrep(['Working on ' fileName],'_','\_'));
    
    % Obtain bait and prey channel info from params variable
    baitChannel = params.BaitChannel;
    if strcmp(params.BaitPos, 'Left')
        preyChannel = params.RightChannel;
    else
        preyChannel = params.LeftChannel;
    end

    % Pull image area from params variable
    imgArea = params.imgArea;
    
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
    dPDensity = density.dynData.([preyChannel 'DiffCount']) ./ imgArea;
    aBDensity = density.dynData.([baitChannel 'AvgCount']) ./ imgArea;
    aPDensity = density.dynData.([preyChannel 'AvgCount']) ./ imgArea;
        
    % Filter out the appropriate windows if excluding low densities
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
end    
close(statusbar)
% Sort density from low to high and align it with the co-appearance percentage at each density for averaging 
message = msgbox('Calculating trendline...');

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

% Plot dB data
x = 0:dBdensityWindow:max(dBcumulativeDensity); x(1) = [];
figure(dBplot,'visible','on'); hold on;
plot(x,dBpctCoAppMean,'-','Color','k','LineWidth',1.5)

% Plot dP data
x = 0:dPdensityWindow:max(dPcumulativeDensity); x(1) = [];
figure(dPplot,'visible','on'); hold on;
plot(x,dPpctCoAppMean,'-','Color','k','LineWidth',1.5)
 
% Plot aB data
x = 0:aBdensityWindow:max(aBcumulativeDensity); x(1) = [];
figure(aBplot,'visible','on'); hold on;
plot(x,aBpctCoAppMean,'-','Color','k','LineWidth',1.5)

% Plot aP data
x = 0:aPdensityWindow:max(aPcumulativeDensity); x(1) = [];
figure(aPplot,'visible','on'); hold on;
plot(x,aPpctCoAppMean,'-','Color','k','LineWidth',1.5)

close (message);
