% Plots the distribution of observed bait oligomer sizes, sorted by co-appearing
% and non-coappearing spots. 

warning('off') % Suppress unnecessary warnings while plotting

% Ask user for data files
matFiles = uipickfiles('Prompt','Select data files or folders to analyze','Type',{'*.mat'});

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
        
    meanColocObs = cellfun(@mean, colocObs);
    ciColocObs = cell2mat( cellfun(@(x) bootci(10000,@mean,x), colocObs, 'UniformOutput', false) ); 
    
    meanNonColocObs = cellfun(@mean, nonColocObs);
    ciNonColocObs = cell2mat( cellfun(@(x) bootci(10000,@mean,x), nonColocObs, 'UniformOutput', false) ); 

    %Calculate averages normalized on a per-bait basis
    totalObsNormalized = cellfun(@(x) x./totalBaits, totalObs, 'UniformOutput', false);
    meanTotalObsNormalized = cellfun(@mean, totalObsNormalized);
    ciTotalObsNormalized = cell2mat( cellfun(@(x) bootci(10000,@mean,x), totalObsNormalized, 'UniformOutput', false) ); 

    colocObsNormalized = cellfun(@(x) x./totalBaits, colocObs, 'UniformOutput', false);
    meanColocObsNormalized = cellfun(@mean, colocObsNormalized);
    ciColocObsNormalized = cell2mat( cellfun(@(x) bootci(10000,@mean,x), colocObsNormalized, 'UniformOutput', false) ); 
    
    nonColocObsNormalized = cellfun(@(x) x./totalBaits, nonColocObs, 'UniformOutput', false);
    meanNonColocObsNormalized = cellfun(@mean, nonColocObsNormalized);
    ciNonColocObsNormalized = cell2mat( cellfun(@(x) bootci(10000,@mean,x), nonColocObsNormalized, 'UniformOutput', false) ); 

    %% Plot
    fig = figure;
    fig.UserData = struct('DatasetsPlotted',matFiles);
    ax = axes;
    set(ax,'YScale','log');
    hold on
    %Plot total data
    enoughData = ciTotalObs(1,:)>0;
    x1 = find(enoughData);
    noData = find(~enoughData);
    breaks = [0, noData, max(x1)+1]; %This is a bit funky but results in each "segment" between zeros being plotted on its own in the loop below
    for c = 1:(length(breaks) - 1)
        l = breaks(c)+1;
        r = breaks(c+1)-1;
        if l==r
            % No easy way to draw a single error bar that matches the style, so do it manually
            patch([l-0.1,l+0.1,l+0.1,l-0.1],[ciTotalObs(1,l), ciTotalObs(1,l),ciTotalObs(2,l),ciTotalObs(2,l)], [0.5 0.5 0.5],'FaceAlpha',0.3,'EdgeColor','none');
            line([l-0.1,l+0.1], [ciTotalObs(1,l), ciTotalObs(1,l)],'Color','k');
            line([l-0.1,l+0.1], [ciTotalObs(2,l), ciTotalObs(2,l)],'Color','k');
        else
            x2 = [l:r, fliplr(l:r)];
            fill(ax,x2,[ciTotalObs(1,l:r), fliplr(ciTotalObs(2,l:r)) ],[0.5 0.5 0.5],'EdgeColor','none','FaceAlpha',0.3);
            plot(ax,l:r,ciTotalObs(1,l:r),'k');
            plot(ax,l:r,ciTotalObs(2,l:r),'k');
        end
    end
    plot(ax,1:maxSize,meanTotalObs,'o-k','LineWidth',2,'MarkerSize',8);
    plot(ax,x1,meanTotalObs(x1),'ok','LineWidth',2,'MarkerSize',8,'MarkerFaceColor','k'); %Draw these points again to highlight points supported by >10 observations
    set(ax,'FontSize',14,'Box','on','LineWidth',2);
    ylabel(ax,'Mean Observations per Embryo');
    xlabel(ax,'Oligomer Size');
    %Custom legend
        qw = {};
        qw{1} = plot(ax,nan,nan,'o-k','LineWidth',2,'MarkerSize',8,'MarkerFaceColor','k');
        [hleg,hl] = legendflex([qw{:}],{'All spots'});
        xl = get(hl(2),'XData');
        yl = get(hl(2),'YData');
        patch([xl fliplr(xl)], [yl+5 yl-5],[0.5 0.5 0.5],'EdgeColor','none','FaceAlpha',0.3,'Parent',hleg);

    fig2 = figure;
    fig2.UserData = struct('DatasetsPlotted',matFiles);
    ax = axes;
    set(ax,'YScale','log');
    hold on
    %Plot colocalized data
    enoughData = ciColocObs(1,:)>0;
    x1 = find(enoughData);
    noData = find(~enoughData);
    breaks = [0, noData, max(x1)+1]; %This is a bit funky but results in each "segment" between zeros being plotted on its own in the loop below
    for c = 1:(length(breaks) - 1)
        l = breaks(c)+1;
        r = breaks(c+1)-1;
        if l==r
            % No easy way to draw a single error bar that matches the style, so do it manually
            patch([l-0.1,l+0.1,l+0.1,l-0.1],[ciColocObs(1,l), ciColocObs(1,l),ciColocObs(2,l),ciColocObs(2,l)], [0 0.5 0],'FaceAlpha',0.3,'EdgeColor','none');
            line([l-0.1,l+0.1], [ciColocObs(1,l), ciColocObs(1,l)],'Color',[0 0.5 0]);
            line([l-0.1,l+0.1], [ciColocObs(2,l), ciColocObs(2,l)],'Color',[0 0.5 0]);
        else
            x2 = [l:r, fliplr(l:r)];
            fill(ax,x2,[ciColocObs(1,l:r), fliplr(ciColocObs(2,l:r)) ],[0 0.5 0],'EdgeColor','none','FaceAlpha',0.3);
            plot(ax,l:r,ciColocObs(1,l:r),'Color',[0 0.5 0]);
            plot(ax,l:r,ciColocObs(2,l:r),'Color',[0 0.5 0]);
        end
    end
    plot(ax,1:maxSize,meanColocObs,'o-','Color',[0 0.5 0],'LineWidth',2,'MarkerSize',8);
    plot(ax,x1,meanColocObs(x1),'o','Color',[0 0.5 0],'LineWidth',2,'MarkerSize',8,'MarkerFaceColor',[0 0.5 0]); %Draw these points again to highlight points supported by >10 observations
    %Plot non-colocalized data
    enoughData = ciNonColocObs(1,:)>0;
    x1 = find(enoughData);
    noData = find(~enoughData);
    breaks = [0, noData, max(x1)+1]; %This is a bit funky but results in each "segment" between zeros being plotted on its own in the loop below
    for c = 1:(length(breaks) - 1)
        l = breaks(c)+1;
        r = breaks(c+1)-1;
        if l==r
            % No easy way to draw a single error bar that matches the style, so do it manually
            patch([l-0.1,l+0.1,l+0.1,l-0.1],[ciNonColocObs(1,l), ciNonColocObs(1,l),ciNonColocObs(2,l),ciNonColocObs(2,l)], [0 0.5 0],'FaceAlpha',0.3,'EdgeColor','none');
            line([l-0.1,l+0.1], [ciNonColocObs(1,l), ciNonColocObs(1,l)],'Color',[0.2 0 1]);
            line([l-0.1,l+0.1], [ciNonColocObs(2,l), ciNonColocObs(2,l)],'Color',[0.2 0 1]);
        else
            x2 = [l:r, fliplr(l:r)];
            fill(ax,x2,[ciNonColocObs(1,l:r), fliplr(ciNonColocObs(2,l:r)) ],[0.2 0 1],'EdgeColor','none','FaceAlpha',0.3);
            plot(ax,l:r,ciNonColocObs(1,l:r),'Color',[0.2 0 1]);
            plot(ax,l:r,ciNonColocObs(2,l:r),'Color',[0.2 0 1]);
        end
    end
    plot(ax,x1,ciNonColocObs(1,x1),'Color',[0.2 0 1])
    plot(ax,x1,ciNonColocObs(2,x1),'Color',[0.2 0 1])
    plot(ax,1:maxSize,meanNonColocObs,'o-','Color',[0.2 0 1],'LineWidth',2,'MarkerSize',8);
    plot(ax,x1,meanNonColocObs(x1),'o','Color',[0.2 0 1],'LineWidth',2,'MarkerSize',8,'MarkerFaceColor',[0.2 0 1]); %Draw these points again to highlight points supported by >10 observations
    set(ax,'FontSize',14,'Box','on','LineWidth',2);
    ylabel(ax,'Mean Observations per Embryo');
    xlabel(ax,'Oligomer Size');
    %Custom legend
        qw = {};
        qw{1} = plot(ax,nan,nan,'o-','Color',[0 0.5 0],'LineWidth',2,'MarkerSize',8,'MarkerFaceColor',[0 0.5 0]);
        qw{2} = plot(ax,nan,nan,'o-','Color',[0.2 0 1],'LineWidth',2,'MarkerSize',8,'MarkerFaceColor',[0.2 0 1]);
        [hleg,hl] = legendflex([qw{:}],{'Colocalized spots', 'Non-Coloclized Spots'});
        xl = get(hl(3),'XData');
        yl = get(hl(3),'YData');
        patch([xl fliplr(xl)], [yl+5 yl-5],[0 0.5 0],'EdgeColor','none','FaceAlpha',0.3,'Parent',hleg);
        xl = get(hl(5),'XData');
        yl = get(hl(5),'YData');
        patch([xl fliplr(xl)], [yl+5 yl-5],[0.2 0 1],'EdgeColor','none','FaceAlpha',0.3,'Parent',hleg);
    
end

