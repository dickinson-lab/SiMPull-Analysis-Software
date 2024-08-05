% Plots the distribution of observed bait oligomer sizes, sorted by co-appearing
% and non-coappearing spots. 

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
    stdTotalObs = cellfun(@std, totalObs);
    meanColocObs = cellfun(@mean, colocObs);
    stdColocObs = cellfun(@std, colocObs);
    meanNonColocObs = cellfun(@mean, nonColocObs);
    stdNonColocObs = cellfun(@std, nonColocObs);

    %Calculate averages normalized on a per-bait basis
    totalObsNormalized = cellfun(@(x) x./totalBaits, totalObs, 'UniformOutput', false);
    meanTotalObsNormalized = cellfun(@mean, totalObsNormalized);
    stdTotalObsNormalized = cellfun(@std, totalObsNormalized);
    colocObsNormalized = cellfun(@(x) x./totalBaits, colocObs, 'UniformOutput', false);
    meanColocObsNormalized = cellfun(@mean, colocObsNormalized);
    stdColocObsNormalized = cellfun(@std, colocObsNormalized);
    nonColocObsNormalized = cellfun(@(x) x./totalBaits, nonColocObs, 'UniformOutput', false);
    meanNonColocObsNormalized = cellfun(@mean, nonColocObsNormalized);
    stdNonColocObsNormalized = cellfun(@std, nonColocObsNormalized);


    %% Plot
    fig = figure;
    fig.UserData = struct('DatasetsPlotted',matFiles);
    ax = axes;
    hold on
    errorbar(ax,1:maxSize,meanTotalObs,stdTotalObs,'o-k','LineWidth',2,'MarkerSize',8);
    errorbar(ax,1:maxSize,meanColocObs,stdColocObs,'o','Color',[0 0.5 0],'LineWidth',2,'MarkerSize',8);
    errorbar(ax,1:maxSize,meanNonColocObs,stdNonColocObs,'o','Color',[0.2 0 1],'LineWidth',2,'MarkerSize',8);
    set(ax,'YScale','log');
    set(ax,'FontSize',14,'Box','on','LineWidth',2);
    ylabel(ax,'Mean Observations per Embryo');
    xlabel(ax,'Oligomer Size');
    legend(ax,'All spots','CoAppearing Spots','Non-CoAppearing Spots');

    fig2 = figure;
    fig2.UserData = struct('DatasetsPlotted',matFiles);
    ax = axes;
    hold on
    errorbar(ax,1:maxSize,meanTotalObsNormalized,stdTotalObsNormalized,'o-k','LineWidth',2,'MarkerSize',8);
    errorbar(ax,1:maxSize,meanColocObsNormalized,stdColocObsNormalized,'o','Color',[0 0.5 0],'LineWidth',2,'MarkerSize',8);
    errorbar(ax,1:maxSize,meanNonColocObsNormalized,stdNonColocObsNormalized,'o','Color',[0.2 0 1],'LineWidth',2,'MarkerSize',8);
    set(ax,'YScale','log');
    set(ax,'FontSize',14,'Box','on','LineWidth',2);
    ylabel(ax,'Mean Fraction of Total Baits');
    xlabel(ax,'Oligomer Size');
    legend(ax,'All spots','CoAppearing Spots','Non-CoAppearing Spots');
end

