% Plots percent coAppearance as a function of (windowed) appearance time for dynamic SiMPull data. 
% This function is not meant to be called by the user but rather by either detectCoAppearance.m or by batchCoApp_vs_time.m. 

function params = coApp_vs_time(dynData,params,expDir,imgName)
% Adjustable parameter for how many 50 frame windows will be averaged for the trendline
trendWindow = 50;

% If data source is composite images...
if strcmp(params.DataType, 'Composite Data')
    baitChannel = params.baitChannel;
    % Calculate % colocalization for molecules appearing in each time window
    lastWindow = max(cell2mat({dynData.([baitChannel 'SpotData']).appearedInWindow}));
    baitsCounted = zeros(1, lastWindow);
    % Create structs for each prey's % co-appearance with bait
    for s = 1:params.nChannels
        if s == params.baitChNum
            continue %Skip the bait channel
        end
        preyChannel = ['preyCh' num2str(s)];
        colocData = {dynData.([baitChannel 'SpotData']).(['appears_w_' preyChannel])};
        coAppearing = zeros(1,lastWindow);
        for a = 1:lastWindow
            index = cell2mat({dynData.([baitChannel 'SpotData']).appearedInWindow}) == a;
            baitsCounted(a) = sum(~cellfun(@(x) isempty(x) || isnan(x), colocData(index)));
            coAppearing(a) = sum(cellfun(@(x) ~isempty(x) && x==true, colocData(index)));
        end  
        
        % Calculate % co-appearance for each prey channel with the bait
        pctColoc.([preyChannel]) = 100 * (coAppearing ./ baitsCounted);
        % Calculate moving (weighted) mean
        baitTrend = movsum(baitsCounted,trendWindow,'omitnan');
        preyTrend = movsum(coAppearing,trendWindow,'omitnan');
        colocTrend.([preyChannel]) = 100 * (preyTrend ./ baitTrend);
        
        clear colocData coAppearing preyTrend baitTrend
    end

else % If data source is dual-view images...
    % Obtain bait and prey channel info from params variable
    baitChannel = params.baitChannel;
    if strcmp(params.BaitPos, 'Left')
        preyChannel = params.RightChannel;
    else
        preyChannel = params.LeftChannel;
    end

    % Calculate % colocalization for molecules appearing in each time window
    colocData = {dynData.([baitChannel 'SpotData']).(['appears_w_' preyChannel])};
    lastWindow = max(cell2mat({dynData.([baitChannel 'SpotData']).appearedInWindow}));
    baitsCounted = zeros(1, lastWindow);
    coAppearing = zeros(1,lastWindow);
    for a = 1:lastWindow
        index = cell2mat({dynData.([baitChannel 'SpotData']).appearedInWindow}) == a;
        baitsCounted(a) = sum(~cellfun(@(x) isempty(x) || isnan(x), colocData(index)));
        coAppearing(a) = sum(cellfun(@(x) ~isempty(x) && x==true, colocData(index)));
    end

    pctColoc = 100 * (coAppearing ./ baitsCounted);

    % Calculate moving (weighted) mean
    baitTrend = movsum(baitsCounted,trendWindow,'omitnan');
    preyTrend = movsum(coAppearing,trendWindow,'omitnan');
    colocTrend = 100 * (preyTrend ./ baitTrend);
end

    % Determine image area for density calculations
    warning('off'); % Prevent unecessary Tiff library warnings from populating Command Window
    img4size = Tiff(params.regFile,'r');
    imgData = read(img4size);
    [imgLength, width] = size(imgData);
    imgArea = imgLength * width * params.pixelSize^2;


    % Save image area in params for future use (ex. in coApp_vs_dens.m or coApp_vs_Time_Filtered)
    params.imgArea = imgArea;

    % Plot
    f = figure('visible', 'off'); % Prevent figure from populating while analysis is ongoing
    xlabel('Time elapsed since lysis (sec)')
    x = (2.5*[1:lastWindow]);
    if ~strcmp(params.elapsedTime, 'No Shot Times Recorded')
        x = bsxfun(@plus, x, params.elapsedTime); % Shift the x-axis by the time elapsed between lysis and acquisition
    end
    yyaxis right
    ylabel('Density of Bait Spots')
    set(gca,'ycolor','0.65,0.65,0.65')
    hold on
    plot(x,(baitsCounted/imgArea),'-','LineWidth',0.5,'Color','0.90,0.90,0.905')
    yyaxis left
    ylabel('Percent Co-Appearance')
    set(gca,'ycolor','k')
    hold on
    if strcmp(params.DataType, 'Composite Data')
        colors = jet(params.nChannels);
        for s = 1:params.nChannels
            if s == params.baitChNum
                continue %Skip the bait channel
            end
            preyChannel = ['preyCh' num2str(s)];
            plot(x,pctColoc.([preyChannel]),'o','MarkerSize',2.5,'Color',colors(s,:))
            hold on
            plot(x,colocTrend.([preyChannel]),'-','LineWidth',1,'Color',colors(s,:))
        end
    else
        plot(x,pctColoc,'o','MarkerSize',2.5,'Color','k')
        hold on
        plot(x,colocTrend,'-','LineWidth',1,'Color','k')
    end

% Save plot
set(f, 'visible','on'); % Ensure that figure will be visible by default before saving
savefig([expDir filesep imgName '_coApp_vs_time.fig']);
close(f)
end

