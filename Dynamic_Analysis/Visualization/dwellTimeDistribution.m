% Plots the distribution of dwell times for a set of experiments

% Ask user for data files
matFiles = uipickfiles('Prompt','Select data files to analyze','Type',{'*.mat'});

% Set up
allDwellTimes = cell(length(matFiles),1);
noDissociation = cell(length(matFiles),1);
remember = false;
fileBar = waitbar(0);
figure
cd = axes('NextPlot','add');
for a = 1:length(matFiles)  
    % Get file name
    slash = strfind(matFiles{a},filesep);
    fileName = matFiles{a}(slash(end)+1:end); 

    % Get Directory
    if isfolder(matFiles{a})
        fileName = [fileName '.mat'];
        expDir = matFiles{a};
        if ~isfile([expDir filesep fileName])
            warndlg(['No .mat file found for selected folder ' expDir]);
            continue
        end
    else
        expDir = matFiles{a}(1:slash(end));
    end

    waitbar((a-1)/length(matFiles),fileBar,strrep(['Loading ' fileName],'_','\_'));
    
    % Load Data and calculate dwell times if necesary
    vars = who('-file', [expDir filesep fileName]);
    if ismember('koff_results',vars)
        load([expDir filesep fileName])
    else
        [dynData, ~, koff_results] = dwellTime_koff(0, {[expDir filesep fileName]}, false);
        load([expDir filesep fileName],'params')
    end

    BaitChannel = params.BaitChannel; %Extract channel info - this is just for code readability

    % Determine prey channel
    if ~isscalar(params.preyChNums) 
        if ~remember
            [selectedPreyCh, remember] = choosePreyChDlg(params.preyChNums);
        end
        PreyCh = selectedPreyCh;
    else
        PreyCh = ['PreyCh' num2str(params.preyChNums)];
    end

    % Pull out co-appearing spots - that's all we're interested in here
    nonSkippedIndex = ~cellfun(@isnan, {dynData.([BaitChannel 'SpotData']).dwellTime});
    coAppIndex = cellfun(@(x) ~isempty(x) && ~isnan(x) && x==true, {dynData.([BaitChannel 'SpotData']).(['appears_w_' PreyCh])});
    hasStepIndex = ~cellfun(@isnan, {dynData.([PreyCh 'SpotData']).dwellTime});
    index = nonSkippedIndex & coAppIndex & hasStepIndex;
    
    % Compile Dwell Times
    allDwellTimes{a} = cell2mat({dynData.([PreyCh 'SpotData'])(index).dwellTime}) * 0.05; %Assuming a 50 ms exposure time
    noDissociation{a} = cell2mat({dynData.([PreyCh 'SpotData'])(index).noDisappearance});

    % Plot this replicate
    if ~isempty(allDwellTimes{a})
        ecdf(cd,allDwellTimes{a},'Function','survivor','Censoring',double(noDissociation{a}));
        set(cd.Children(1),'Color','b');
    end
end
close(fileBar);

% Plot combined data
dwellTimeVector = horzcat(allDwellTimes{:});
noDissociationVector = horzcat(noDissociation{:});
ecdf(cd,dwellTimeVector,'Function','survivor','Censoring',double(noDissociationVector)); 
set(cd.Children(1),'Color','b','LineWidth',2);
figure
histogram(dwellTimeVector,'DisplayStyle','stairs','BinMethod','fd','Normalization','probability');
