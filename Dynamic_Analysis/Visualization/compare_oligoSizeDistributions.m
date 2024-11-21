% Compares the oligomer size distributions for two sc-SiMPull datasets.
% Data can be passed in as a pair of cell arrays containing data from
% tabulateCoAppearance.m.  Alternatively, the user will be prompted to
% select data as .mat files, and the function will plot total, coappearing
% and non-coappearing distributions.  

% Fold difference between datasets is calculated and plotted by finding the 
% difference between log-transformed datasets, and confidence intervals are 
% determined using bootstrapping. 

% Arguments (all optional): 
% data1, data2: Pre-calculated curves from tabulateCoAppearance, provided as cell arrays
%               (see tabulateCoAppearance.m for details about format)
% color1, color2: User-specified colors for each curve, in any color format recognized by MATLAB
% name1, name2: Names for each dataset

% Example: compare_oligoSizeDistributions('data1', totalObs_WT, 'data2', totalObs_Mutant, 'color1', [0 0 0], 'color2', 'r');

function compare_oligoSizeDistributions(varargin)

% Get & validate user input
p = inputParser;
addParameter(p, 'data1', {}, @iscell);
addParameter(p, 'data2', {}, @iscell);
addParameter(p, 'color1', 'k');
addParameter(p, 'color2', 'r');
addParameter(p, 'name1', 'Dataset 1');
addParameter(p, 'name2', 'Dataset 2');
parse(p,varargin{:});
data1 = p.Results.data1;
data2 = p.Results.data2;
color1 = p.Results.color1;
color2 = p.Results.color2;
name1 = p.Results.name1;
name2 = p.Results.name2;
try validatecolor(color1); catch color1 = 'k'; end
try validatecolor(color2); catch color2 = 'r'; end

% Get and plot data if it wasn't provided by the user
if (isempty(data1) || isempty(data2))
    % Ask user for data files
    matFiles1 = uipickfiles('Prompt','Select data files or folders in Dataset 1','Type',{'*.mat'});
    matFiles2 = uipickfiles('Prompt','Select data files or folders in Dataset 2','Type',{'*.mat'});
    matFiles = [matFiles1, matFiles2];
    
    % Extract size and co-appearance information 
    dataTables_data1 = tabulateCoAppearance(matFiles1, true);
    dataTables_data2 = tabulateCoAppearance(matFiles2, true);
    preyChannelNames = fieldnames(dataTables_data1.filteredCounted);
    for b = 1:length(preyChannelNames)
        %Add up observations from dataset 1
        preyChannel = preyChannelNames{b};
        nEmbryos = length(matFiles1);
        [~,~,maxSize] = size(dataTables_data1.filteredCounted.(preyChannel));
        totalObs_data1 = cell(1,maxSize);
        colocObs_data1 = cell(1,maxSize);
        totalBaits_data1 = zeros(nEmbryos,1);
        for a = 1:maxSize
            totalObs_data1{a} = sum(dataTables_data1.filteredCounted.(preyChannel)(:,:,a),2);
            totalBaits_data1 = totalBaits_data1 + totalObs_data1{a};
            colocObs_data1{a} = sum(dataTables_data1.filteredCoApp.(preyChannel)(:,:,a),2);
        end
        nonColocObs_data1 = cellfun(@minus,totalObs_data1,colocObs_data1,'UniformOutput',false);

        %Add up observations from dataset 2
        preyChannel = preyChannelNames{b};
        nEmbryos = length(matFiles2);
        [~,~,maxSize] = size(dataTables_data2.filteredCounted.(preyChannel));
        totalObs_data2 = cell(1,maxSize);
        colocObs_data2 = cell(1,maxSize);
        totalBaits_data2 = zeros(nEmbryos,1);
        for a = 1:maxSize
            totalObs_data2{a} = sum(dataTables_data2.filteredCounted.(preyChannel)(:,:,a),2);
            totalBaits_data2 = totalBaits_data2 + totalObs_data2{a};
            colocObs_data2{a} = sum(dataTables_data2.filteredCoApp.(preyChannel)(:,:,a),2);
        end
        nonColocObs_data2 = cellfun(@minus,totalObs_data2,colocObs_data2,'UniformOutput',false);

        %Plot 
        makePlots(totalObs_data1, totalObs_data2, 'All spots');
        makePlots(colocObs_data1, colocObs_data2, 'Coappearing spots');
        makePlots(nonColocObs_data1, nonColocObs_data2, 'Non-Coappearing spots');
    end

% Otherwise, plot the data that was passed to the function
else
    matFiles = [];
    makePlots(data1, data2, '');
end

%% Nested function to calculate & plot effect sizes
function makePlots(data1, data2, plotTitle)
    %% Plot mean & 95% confidence interval
    % Calculate means & CIs
        
    meanData1 = cellfun(@mean, data1);
    ciData1 = cell2mat( cellfun(@(x) bootci(10000,@mean,x), data1, 'UniformOutput', false) ); %bootci calculates a bootstrap 95% confidence interval

    meanData2 = cellfun(@mean, data2);
    ciData2 = cell2mat( cellfun(@(x) bootci(10000,@mean,x), data2, 'UniformOutput', false) ); %bootci calculates a bootstrap 95% confidence interval

    %Plot
    fig1 = figure;
    fig1.UserData = struct('DatasetsPlotted',matFiles);
    ax = axes;
    set(ax,'YScale','log');
    title(ax,plotTitle,'FontSize',14);
    hold on
    %Plot data1 
    maxSize = length(data1);
    enoughData = ciData1(1,:)>0;
    x1 = find(enoughData);
    noData = find(~enoughData);
    breaks = [0, noData, max(x1)+1]; %This is a bit funky but results in each "segment" between zeros being plotted on its own in the loop below
    for c = 1:(length(breaks) - 1)
        l = breaks(c)+1;
        r = breaks(c+1)-1;
        if l==r
            % No easy way to draw a single error bar that matches the style, so do it manually
            patch([l-0.1,l+0.1,l+0.1,l-0.1],[ciData1(1,l), ciData1(1,l),ciColocObs(2,l),ciData1(2,l)], color1,'FaceAlpha',0.3,'EdgeColor','none');
            line([l-0.1,l+0.1], [ciData1(1,l), ciData1(1,l)],'Color',color1);
            line([l-0.1,l+0.1], [ciData1(2,l), ciData1(2,l)],'Color',color1);
        else
            x2 = [l:r, fliplr(l:r)];
            fill(ax,x2,[ciData1(1,l:r), fliplr(ciData1(2,l:r)) ],color1,'EdgeColor','none','FaceAlpha',0.3);
            plot(ax,l:r,ciData1(1,l:r),'Color',color1);
            plot(ax,l:r,ciData1(2,l:r),'Color',color1);
        end
    end
    plot(ax,1:maxSize,meanData1,'o-','Color',color1,'LineWidth',2,'MarkerSize',8);
    plot(ax,x1,meanData1(x1),'o','Color',color1,'LineWidth',2,'MarkerSize',8,'MarkerFaceColor',color1); %Draw these points again to highlight points supported by >10 observations
    %Plot data2
    maxSize = length(data2);
    enoughData = ciData2(1,:)>0;
    x1 = find(enoughData);
    noData = find(~enoughData);
    breaks = [0, noData, max(x1)+1]; %This is a bit funky but results in each "segment" between zeros being plotted on its own in the loop below
    for c = 1:(length(breaks) - 1)
        l = breaks(c)+1;
        r = breaks(c+1)-1;
        if l==r
            % No easy way to draw a single error bar that matches the style, so do it manually
            patch([l-0.1,l+0.1,l+0.1,l-0.1],[ciData2(1,l), ciData2(1,l),ciData2(2,l),ciData2(2,l)], color2,'FaceAlpha',0.3,'EdgeColor','none');
            line([l-0.1,l+0.1], [ciData2(1,l), ciData2(1,l)],'Color',color2);
            line([l-0.1,l+0.1], [ciData2(2,l), ciData2(2,l)],'Color',color2);
        else
            x2 = [l:r, fliplr(l:r)];
            fill(ax,x2,[ciData2(1,l:r), fliplr(ciData2(2,l:r)) ],color2,'EdgeColor','none','FaceAlpha',0.3);
            plot(ax,l:r,ciData2(1,l:r),'Color',color2);
            plot(ax,l:r,ciData2(2,l:r),'Color',color2);
        end
    end
    plot(ax,x1,ciData2(1,x1),'Color',color2)
    plot(ax,x1,ciData2(2,x1),'Color',color2)
    plot(ax,1:maxSize,meanData2,'o-','Color',color2,'LineWidth',2,'MarkerSize',8);
    plot(ax,x1,meanData2(x1),'o','Color',color2,'LineWidth',2,'MarkerSize',8,'MarkerFaceColor',color2); %Draw these points again to highlight points supported by >10 observations
    set(ax,'FontSize',14,'Box','on','LineWidth',2);
    ylabel(ax,'Mean Observations per Embryo');
    xlabel(ax,'Oligomer Size');
    %Custom legend
        qw = {};
        qw{1} = plot(ax,nan,nan,'o-','Color',color1,'LineWidth',2,'MarkerSize',8,'MarkerFaceColor',color1);
        qw{2} = plot(ax,nan,nan,'o-','Color',color2,'LineWidth',2,'MarkerSize',8,'MarkerFaceColor',color2);
        [hleg,hl] = legendflex([qw{:}],{name1, name2});
        xl = get(hl(3),'XData');
        yl = get(hl(3),'YData');
        patch([xl fliplr(xl)], [yl+5 yl-5],color1,'EdgeColor','none','FaceAlpha',0.3,'Parent',hleg);
        xl = get(hl(5),'XData');
        yl = get(hl(5),'YData');
        patch([xl fliplr(xl)], [yl+5 yl-5],color2,'EdgeColor','none','FaceAlpha',0.3,'Parent',hleg);

    %% Calculate mean differences and confidence intervals, and plot
    % Calculate
    dataSize = min(length(data1),length(data2));
    meanDiff = nan(1,dataSize);
    ciDiff = nan(2,dataSize);
    for a = 1:dataSize
        meanDiff(a) = meanFC(data2{a}, data1{a});
        % These three lines are borrowed from meanEffectSize.m
        % bootci only can work on data of the same size, so instead, we stack
        % the x and y together, and give bootstrap a vector of indices to
        % sample from. The function passed to bootbca will translate from the
        % sampled indices to the corresponding values of x and y
        idx = 1:(numel(data2{a})+numel(data1{a}));
        bootfun = @(idx) unpairedSamplesBootstrapFcn(idx, data2{a}, data1{a}, @meanFC);
        ciDiff(:,a) = bootbca(idx, 10000, bootfun, 0.05);
    end

    % Plot
    fig2 = figure;
    fig2.UserData = struct('DatasetsPlotted',matFiles);
    ax = axes;
    set(ax,'YScale','log');
    title(ax,plotTitle,'FontSize',14);
    hold on
    %Plot total data
    enoughData = isfinite(ciDiff(1,:)) & ciDiff(1,:)>0 & isfinite(ciDiff(2,:) & ciDiff(2,:)>0);
    x1 = find(enoughData);
    noData = find(~enoughData);
    breaks = [0, noData, max(x1)+1]; %This is a bit funky but results in each "segment" between zeros being plotted on its own in the loop below
    for c = 1:(length(breaks) - 1)
        l = breaks(c)+1;
        r = breaks(c+1)-1;
        if l==r
            % No easy way to draw a single error bar that matches the style, so do it manually
            patch([l-0.1,l+0.1,l+0.1,l-0.1],[ciDiff(1,l), ciDiff(1,l),ciDiff(2,l),ciDiff(2,l)], color2,'FaceAlpha',0.3,'EdgeColor','none');
            line([l-0.1,l+0.1], [ciDiff(1,l), ciDiff(1,l)],'Color',color2);
            line([l-0.1,l+0.1], [ciDiff(2,l), ciDiff(2,l)],'Color',color2);
        else
            x2 = [l:r, fliplr(l:r)];
            fill(ax,x2,[ciDiff(1,l:r), fliplr(ciDiff(2,l:r)) ],color2,'EdgeColor','none','FaceAlpha',0.3);
            plot(ax,l:r,ciDiff(1,l:r),color2);
            plot(ax,l:r,ciDiff(2,l:r),color2);
        end
    end
    plot(ax,1:dataSize,meanDiff,'o-','Color',color2,'LineWidth',2,'MarkerSize',8);
    plot(ax,x1,meanDiff(x1),'o','Color',color2,'LineWidth',2,'MarkerSize',8,'MarkerFaceColor',color2); %Draw these points again to highlight points supported by >10 observations
    plot(ax,1:dataSize,ones(1,dataSize),'--k','LineWidth',1);
    set(ax,'FontSize',14,'Box','on','LineWidth',2);
    ylabel(ax,'Fold Difference in Means');
    xlabel(ax,'Oligomer Size');
    %Custom legend
        qw = {};
        qw{1} = plot(ax,nan,nan,'o-','Color',color2,'LineWidth',2,'MarkerSize',8,'MarkerFaceColor',color2);
        [hleg,hl] = legendflex([qw{:}],{[name2 ' / ' name1]});
        xl = get(hl(2),'XData');
        yl = get(hl(2),'YData');
        patch([xl fliplr(xl)], [yl+5 yl-5],color2,'EdgeColor','none','FaceAlpha',0.3,'Parent',hleg);
    
end

%% Custom function to calculate fold change of means
function result = meanFC(input1,input2) %bootCI can only handle a single input, so the two datasets to be compared need to be combined into a cell array with two entries
    avg1 = mean(input1);
    avg2 = mean(input2);
    result = avg1/avg2;
end

%% These two functions are borrowed from meanEffectSize.m and allow bootbca to be performed on two datasets of different sizes
function effect = unpairedSamplesBootstrapFcn(indices, x, y, effectFcn)
    % This function is used with bootci for computing confidence intervals when
    % the x and y samples are unequal in size
    xIdx = (indices <= numel(x));
    yIdx = ~xIdx;
    currX = x(indices(xIdx));
    currY = y(indices(yIdx) - numel(x));
    if isempty(currX) || isempty(currY)
        % Sample generated samples that have no data from X or Y
        % We can't reason about what the effect should be, so return NaN
        effect = NaN;
    else
        effect = effectFcn(currX, currY);
    end
end
    
function [ci,bstat] = bootbca(dataInds, nboot, bootfun, alpha)%, bootstrpOptions)
    % corrected and accelerated percentile bootstrap CI
    effect = bootfun(dataInds);
    bstat = bootstrp(nboot, bootfun, dataInds);%, 'Options', bootstrpOptions);
    % Remove any NaN values, which indicate a sample where all x or all y were
    % missing
    bstat(isnan(bstat)) = [];
    
    % same as bootcper, this is the bias correction
    z0 = norminv(mean(bstat < effect,1) + mean(bstat == effect,1)/2);
    
    % apply jackknife
    jstat = jackknife(bootfun, dataInds);%, 'Options', bootstrpOptions);
    % Remove NaN for the same reason as above
    jstat(isnan(jstat)) = [];
    N = size(jstat,1);
    weights = repmat(1/N,N,1);
    
    % acceleration finding
    mjstat = sum(jstat.*weights,1); % mean along 1st dim.
    score = mjstat - jstat; % score function at stat; ignore (N-1) factor because it cancels out in the skew
    iszer = all(score==0,1);
    skew = sum((score.^3).*weights,1) ./ ...
        (sum((score.^2).*weights,1).^1.5) /sqrt(N); % skewness of the score function
    skew(iszer) = 0;
    acc = skew/6;  % acceleration
    
    % transform back with bias corrected and acceleration
    z_alpha1 = norminv(alpha/2);
    z_alpha2 = -z_alpha1;
    pct1 = 100*normcdf(z0 +(z0+z_alpha1)./(1-acc.*(z0+z_alpha1)));
    pct1(z0==Inf) = 100;
    pct1(z0==-Inf) = 0;
    pct2 = 100*normcdf(z0 +(z0+z_alpha2)./(1-acc.*(z0+z_alpha2)));
    pct2(z0==Inf) = 100;
    pct2(z0==-Inf) = 0;
    
    % inverse of ECDF
    m = numel(effect);
    lower = zeros(1,m);
    upper = zeros(1,m);
    for i=1:m
        lower(i) = prctile(bstat(:,i),pct2(i),1);
        upper(i) = prctile(bstat(:,i),pct1(i),1);
    end
    ci = sort([lower;upper],1);
end
end

