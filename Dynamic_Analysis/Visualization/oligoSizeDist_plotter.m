% Plots the distribution of observed bait oligomer sizes, sorted by co-appearing
% and non-coappearing spots. 

warning('off') % Suppress unnecessary warnings while plotting

% Ask user for data files
matFiles = uipickfiles('Prompt','Select data files to analyze','Type',{'*.mat'});

% Extract size and co-appearance information from data
dataTables = tabulateCoAppearance(matFiles, true);
nEmbryos = length(matFiles);

%% Calculate frequency of sizes
preyChannelNames = fieldnames(dataTables.filteredCounted);
for b = 1:length(preyChannelNames)
    %Add up observations
    preyChannel = preyChannelNames{b};
    [~,~,maxSize] = size(dataTables.filteredCounted.(preyChannel));
    totalObs = cell(1,maxSize);
    colocObs = cell(1,maxSize);
    totalBaits = zeros(nEmbryos,1);
    for a = 1:maxSize
        totalObs{a} = sum(dataTables.filteredCounted.(preyChannel)(:,:,a),2);
        totalBaits = totalBaits + totalObs{a};
        colocObs{a} = sum(dataTables.filteredCoApp.(preyChannel)(:,:,a),2);
    end
    nonColocObs = cellfun(@minus,totalObs,colocObs,'UniformOutput',false);
    
    %Calculate averages per embryo
    meanTotalObs = cellfun(@mean, totalObs);
    ciTotalObs = cell2mat( cellfun(@(x) bootci(10000,@mean,x), totalObs, 'UniformOutput', false) ); %bootci calculates a bootstrap 95% confidence interval
    ciTotalObs(ciTotalObs == 0) = 1e-10; %Replace zeros with 1e-10 so that they don't cause issues on log plots
    ciTotalObs(:, meanTotalObs == 0) = NaN; %Eliminate error bars from points with no data
    
    meanColocObs = cellfun(@mean, colocObs);
    ciColocObs = cell2mat( cellfun(@(x) bootci(10000,@mean,x), colocObs, 'UniformOutput', false) ); 
    ciColocObs(ciColocObs == 0) = 1e-10;
    ciColocObs(:, meanColocObs == 0) = NaN;
    
    meanNonColocObs = cellfun(@mean, nonColocObs);
    ciNonColocObs = cell2mat( cellfun(@(x) bootci(10000,@mean,x), nonColocObs, 'UniformOutput', false) ); 
    ciNonColocObs(ciNonColocObs == 0) = 1e-10;
    ciNonColocObs(:, meanNonColocObs == 0) = NaN;

    %Calculate averages normalized on a per-bait basis
    totalObsNormalized = cellfun(@(x) x./totalBaits, totalObs, 'UniformOutput', false);
    meanTotalObsNormalized = cellfun(@mean, totalObsNormalized);
    ciTotalObsNormalized = cell2mat( cellfun(@(x) bootci(10000,@mean,x), totalObsNormalized, 'UniformOutput', false) ); 
    ciTotalObsNormalized(ciTotalObsNormalized == 0) = 1e-10;
    ciTotalObsNormalized(:, meanTotalObs == 0) = NaN; %Eliminate error bars from points with no data

    colocObsNormalized = cellfun(@(x) x./totalBaits, colocObs, 'UniformOutput', false);
    meanColocObsNormalized = cellfun(@mean, colocObsNormalized);
    ciColocObsNormalized = cell2mat( cellfun(@(x) bootci(10000,@mean,x), colocObsNormalized, 'UniformOutput', false) ); 
    ciColocObsNormalized(ciColocObsNormalized == 0) = 1e-10;
    ciColocObsNormalized(:, meanColocObs == 0) = NaN;
    
    nonColocObsNormalized = cellfun(@(x) x./totalBaits, nonColocObs, 'UniformOutput', false);
    meanNonColocObsNormalized = cellfun(@mean, nonColocObsNormalized);
    ciNonColocObsNormalized = cell2mat( cellfun(@(x) bootci(10000,@mean,x), nonColocObsNormalized, 'UniformOutput', false) ); 
    ciNonColocObsNormalized(ciNonColocObsNormalized == 0) = 1e-10;
    ciNonColocObsNormalized(:, meanNonColocObs == 0) = NaN;

    %% Plot
    fig = figure;
    fig.UserData = struct('DatasetsPlotted',matFiles);
    ax = axes;
    set(ax,'YScale','log');
    hold on
    qw = {};
    %Plot total data
    noData = find(~meanTotalObs);
    breaks = [0, noData, maxSize+1]; %This is a bit funky but results in each "segment" between zeros being plotted on its own in the loop below
    for c = 1:(length(breaks) - 1)
        l = breaks(c)+1;
        r = breaks(c+1)-1;
        x2 = [l:r, fliplr(l:r)];
        fill(ax,x2,[ciTotalObs(1,l:r), fliplr(ciTotalObs(2,l:r)) ],[0.5 0.5 0.5],'EdgeColor','none','FaceAlpha',0.3);
    end
    x = 1:maxSize;
    plot(ax,x,ciTotalObs(1,:),'k');
    plot(ax,x,ciTotalObs(2,:),'k');
    qw{1} = plot(ax,x,meanTotalObs,'o-k','LineWidth',2,'MarkerSize',8);
    enoughData = cellfun(@sum,totalObs) >= 10;
    qw{2} = plot(ax,x(enoughData),meanTotalObs(enoughData),'ok','LineWidth',2,'MarkerSize',8,'MarkerFaceColor','k'); %Draw these points again to highlight points supported by >10 observations
    set(ax,'FontSize',14,'Box','on','LineWidth',2);
    ylabel(ax,'Mean Observations per Embryo');
    xlabel(ax,'Oligomer Size');
    %Custom legend
        [hleg,hl] = legendflex([qw{:}],{'All spots', '>10 observations'});
        xl = get(hl(3),'XData');
        yl = get(hl(3),'YData');
        patch([xl fliplr(xl)], [yl+5 yl-5],[0.5 0.5 0.5],'EdgeColor','none','FaceAlpha',0.3,'Parent',hleg);

    fig2 = figure;
    fig2.UserData = struct('DatasetsPlotted',matFiles);
    ax = axes;
    set(ax,'YScale','log');
    hold on
    %Plot colocalized data
    noData = find(~meanColocObs);
    breaks = [0, noData, maxSize+1]; %This is a bit funky but results in each "segment" between zeros being plotted on its own in the loop below
    for c = 1:(length(breaks) - 1)
        l = breaks(c)+1;
        r = breaks(c+1)-1;
        x2 = [l:r, fliplr(l:r)];
        fill(ax,x2,[ciColocObs(1,l:r), fliplr(ciColocObs(2,l:r)) ],[0 1 0],'EdgeColor','none','FaceAlpha',0.3);
    end
    plot(ax,1:maxSize,ciColocObs(1,:),'Color',[0 0.5 0])
    plot(ax,1:maxSize,ciColocObs(2,:),'Color',[0 0.5 0])
    qw{1} = plot(ax,1:maxSize,meanColocObs,'o-','Color',[0 0.5 0],'LineWidth',2,'MarkerSize',8);
    enoughData = cellfun(@sum,colocObs) >= 10;
    qw{2} = plot(ax,x(enoughData),meanColocObs(enoughData),'o','Color',[0 0.5 0],'LineWidth',2,'MarkerSize',8,'MarkerFaceColor',[0 0.5 0]); %Draw these points again to highlight points supported by >10 observations
    %Plot non-colocalized data
    noData = find(~meanNonColocObs);
    breaks = [0, noData, maxSize+1]; %This is a bit funky but results in each "segment" between zeros being plotted on its own in the loop below
    for c = 1:(length(breaks) - 1)
        l = breaks(c)+1;
        r = breaks(c+1)-1;
        x2 = [l:r, fliplr(l:r)];
        fill(ax,x2,[ciNonColocObs(1,l:r), fliplr(ciNonColocObs(2,l:r)) ],[0.2 0 1],'EdgeColor','none','FaceAlpha',0.3);
    end
    plot(ax,1:maxSize,ciNonColocObs(1,:),'Color',[0.2 0 1])
    plot(ax,1:maxSize,ciNonColocObs(2,:),'Color',[0.2 0 1])
    qw{3} = plot(ax,1:maxSize,meanNonColocObs,'o-','Color',[0.2 0 1],'LineWidth',2,'MarkerSize',8);
    enoughData = cellfun(@sum,nonColocObs) >= 10;
    qw{4} = plot(ax,x(enoughData),meanNonColocObs(enoughData),'o','Color',[0.2 0 1],'LineWidth',2,'MarkerSize',8,'MarkerFaceColor',[0.2 0 1]); %Draw these points again to highlight points supported by >10 observations
    set(ax,'FontSize',14,'Box','on','LineWidth',2);
    ylabel(ax,'Mean Observations per Embryo');
    xlabel(ax,'Oligomer Size');
    %Custom legend
        [hleg,hl] = legendflex([qw{:}],{'All spots', '>10 observations', 'All spots', '>10 observations'});
        xl = get(hl(5),'XData');
        yl = get(hl(5),'YData');
        patch([xl fliplr(xl)], [yl+5 yl-5],[0 0.5 0],'EdgeColor','none','FaceAlpha',0.3,'Parent',hleg);
        xl = get(hl(9),'XData');
        yl = get(hl(9),'YData');
        patch([xl fliplr(xl)], [yl+5 yl-5],[0.2 0 1],'EdgeColor','none','FaceAlpha',0.3,'Parent',hleg);
    
end

