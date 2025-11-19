% Compares the number of fluorophores counted in bait vs prey channels for
% co-appearing spots

% Ask user for data files
matFiles = uipickfiles('Prompt','Select data files to analyze','Type',{'*.mat'});

stepCountData = {};
fileBar = waitbar(0);
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

    % Load data structure
    load([expDir filesep fileName],'dynData','params');

    %Extract channel info - this is just for code readability
    BaitChannel = params.BaitChannel;

    % Check if we have photobleaching data
    maxSteps = 1;
    if isfield(dynData.BaitSpotData,'nFluors')
        if maxSteps < max([dynData.BaitSpotData.nFluors])
            maxSteps = max([dynData.BaitSpotData.nFluors]);
        end
    else
        warning(['Dataset ' fileName ' is missing photobleaching step data.' newline 'Please run countDynamicBleaching first.']);
        continue
    end  
    
    % Get the fluor counts for coappearing spots
    for b = params.preyChNums
        coAppIdx = cellfun(@(x) islogical(x) && x==true, {dynData.BaitSpotData.(['appears_w_PreyCh' num2str(b)])} );
        nBaitFluors = cell2mat({dynData.BaitSpotData(coAppIdx).nFluors});
        nPreyFluors = cell2mat({dynData.(['PreyCh' num2str(b) 'SpotData'])(coAppIdx).nFluors});
        
        % Eliminate any wacko bait spots w/ <1 step
        filterIdx = nBaitFluors > 0;
        nBaitFluors = nBaitFluors(filterIdx);
        nPreyFluors = nPreyFluors(filterIdx);

        tempData = [nBaitFluors;nPreyFluors];
        if a==1
            stepCountData{b} = tempData;
        else
            stepCountData{b} = horzcat(stepCountData{b},tempData);
        end
    end
end
close(fileBar)

% Plot results
for c = params.preyChNums
    figure('Name','Prey Channel 2 Histogram')
    h = histogram2(stepCountData{c}(1,:), stepCountData{c}(2,:), 'BinMethod', 'integers');
    xlabel('Bait Molecules Counted')
    ylabel('Prey Molecules Counted')
    figure('Name','Prey Channel 2 Bubble Plot')
    x = h.XBinEdges +0.5;
    x = x(1:end-1);
    y = h.YBinEdges + 0.5;
    y = y(1:end-1);
    sizes = h.Values * 5; % Multiply by 5 to make sure the smallest values are still big enough to see
    hold on
    for d = x
        idx = sizes(d,:)>0;
        scatter(repmat(d,1,sum(idx)),y(idx),sizes(d,idx),'o')
    end
    xlabel('Bait Molecles Counted')
    ylabel('Prey Molecules Counted')
end