% Plots co-appearance vs. time for complexes of different stoichiometry.
% Samples are pooled to avoid low-number artifacts.

% For the time being, this only works for composite data.

% Adjustable parameter for how many 50 frame windows will be averaged for the trendline
trendWindow = 50;

% Ask user for data files
matFiles = uipickfiles('Prompt','Select data files to analyze','Type',{'*.mat'});

fileBar = waitbar(0);
totalCounted = struct();
totalCoApp = struct();
for a = 1:length(matFiles)  
    % Get image name and root directory
    slash = strfind(matFiles{a},filesep);
    fileName = matFiles{a}(slash(end)+1:end); 
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
    
    % Load data structure
    load([expDir filesep fileName],'dynData','params');
    %Extract channel info - this is just for code readability
    BaitChannel = params.BaitChannel;
    if ~strcmp(params.DataType, 'Composite Data')
        PreyChannel = params.PreyChannel;
    end
         
    %% Calculate co-appearance vs. time
    waitbar((a-1)/length(matFiles),fileBar,strrep(['Analyzing ' fileName],'_','\_'));
    lastWindow = max(cell2mat({dynData.([BaitChannel 'SpotData']).appearedInWindow}));
    baitsCounted = zeros(1, lastWindow);
    % Create structs for each prey's % co-appearance with bait
    for b = 1:5
        if b == 5
            spotChoiceIdx = [dynData.BaitSpotData.nFluors] >= 5;
        else
            spotChoiceIdx = [dynData.BaitSpotData.nFluors] == b;
        end
        for s = 1:params.nChannels
            if s == params.baitChNum
                continue %Skip the bait channel
            end
            preyChannel = ['PreyCh' num2str(s)];
            colocData = {dynData.([BaitChannel 'SpotData'])(spotChoiceIdx).(['appears_w_' preyChannel])};
            baitsCounted = zeros(1,lastWindow);
            coAppearing = zeros(1,lastWindow);
            for c = 1:lastWindow
                index = cell2mat({dynData.([BaitChannel 'SpotData'])(spotChoiceIdx).appearedInWindow}) == c;
                baitsCounted(c) = sum(~cellfun(@(x) isempty(x) || isnan(x), colocData(index)));
                coAppearing(c) = sum(cellfun(@(x) ~isempty(x) && x==true, colocData(index)));
            end  
            % Shift the x-axis by the time elapsed between lysis and acquisition
            if ~strcmp(params.elapsedTime, 'No Shot Times Recorded')
                gap = round(params.elapsedTime / (params.window * 0.05)); %Hard-coded 50 ms exposure time - could be a paramter later if needed 
                baitsCounted = [zeros(1,gap-1) baitsCounted];
                coAppearing = [zeros(1,gap-1) coAppearing];
            end
            
            % Put all the data together. Organization: 
                % Each metric is saved in a structure with a field for each prey channel.
                % Each field holds a cell array with one element for each particle size being analyzed (loop b).
                % In each of these arrays, the horizontal dimension represents time (in windows), and the vertical dimension is for datasets (loop a).
            if a == 1
                totalCounted.(preyChannel){b} = baitsCounted;
                totalCoApp.(preyChannel){b} = coAppearing;
            else
                totalCounted.(preyChannel){b}(a,1:length(baitsCounted)) = baitsCounted;
                totalCoApp.(preyChannel){b}(a,1:length(coAppearing)) = coAppearing;
            end
            clear coAppearing baitsCounted
        end
    end
end
close(fileBar)

% Condense data and Plot
totalPctCoApp = zeros(a,5);
colors = jet(params.nChannels);
for s = 1:params.nChannels
    if s == params.baitChNum
        continue %Skip the bait channel
    end
    preyChannel = ['PreyCh' num2str(s)];
    for d = 1:5
        % Condense data so that summary statistics can be counted
        coAppearing = sum(totalCoApp.(preyChannel){d},1,'omitnan');
        baitsCounted = sum(totalCounted.(preyChannel){d},1,'omitnan');
        % Calculate % co-appearance for each prey channel & cluster size with the bait
        pctCoApp = 100 * (coAppearing ./ baitsCounted);
        % Calculate moving (weighted) mean
        baitTrend = movsum(baitsCounted,trendWindow,'omitnan');
        preyTrend = movsum(coAppearing,trendWindow,'omitnan');
        colocTrend = 100 * (preyTrend ./ baitTrend);
        % Calculate total (time-independent) co-appearance
        totalPctCoApp(:,d) = 100 * (sum(totalCoApp.(preyChannel){d},2,'omitnan') ./ sum(totalCounted.(preyChannel){d},2,'omitnan') );
        disp(['N(' num2str(d) ')=' num2str(sum(baitsCounted))]);

        %Plot
        f = figure('Name',['Traces with ' num2str(d) ' steps']);
        xlabel('Time elapsed since lysis (sec)')
        [~,lastWindow] = size(coAppearing);
        x = (2.5*[1:lastWindow]);
        ylabel('Percent Co-Appearance')
        set(gca,'ycolor','k')
        plot(x,pctCoApp,'o','MarkerSize',2.5,'Color',colors(s,:),'DisplayName',preyChannel)
        hold on
        plot(x,colocTrend,'-','LineWidth',1,'Color',colors(s,:),'DisplayName',preyChannel)
    end
    figure('Name','Total pct. co-appearance');
    plotSpreadBubble(totalPctCoApp,'showWeightedMean',true);
end

