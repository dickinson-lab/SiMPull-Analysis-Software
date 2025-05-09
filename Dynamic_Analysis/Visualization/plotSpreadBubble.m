function handles = plotSpreadBubble(varargin)
%
% PLOTSPREAD plots distributions of points by spreading them around the y-axis
%
% Support for different size bubbles added 4/2/2020 by Dan Dickinson.
% Default marker was changed to 'o' to accommodate this.
% Pass property "markerSizes" with same format and shape as y data, or pass 
% a scalar to change the sizes of all points. 
%
% To nicely plot SiMPull data, make a variable pctColoc with each column as
% one experimental condition and replicate measurements in rows. Make a second
% variable nBaits with corresponding number of spots tested for colocalization
% in each sample. Then call 
%       >> plotSpreadBubble(pctColoc,'markerSizes',nBaits);
%
% As of 6/7/2023, normalizing marker sizes (to prevent really huge bubbles)
% is optional. Pass property 'normalizeMarkerSizes', false to disable
% (default = true). 
%
% One can also show a weighted mean and 95% confidence interval as follows: 
%       >> plotSpreadBubble(pctColoc, 'markerSizes', nBaits,...
%                           'showWeightedMean', argument);
%
%   where argument can be either a logical true (to show the weighted mean 
%   using default settings), or a color identifier string or colormap array.  
%   Weighted mean and 95% confidence intervals are calculated on the basis
%   of the number of baits given as an argument to 'markerSizes'. If
%   'markerSizes' is not specified, a non-weighted mean with no error bars
%   is shown instead. 
%
% It is also often useful to set the 'xNames' and 'distributionColors' properties
% (see below).
%
%
% Original documentation from Jonas Dorn follows below:
%
% SYNOPSIS: handles = plotSpread(data, propertyName, propertyValue, ...)
%           handles = plotSpread(ah, ...
%           deprecated:
%           handles = plotSpread(data,binWidth,spreadFcn,xNames,showMM,xValues)
%
% INPUT data: cell array of distributions or nDatapoints-by-mDistributions
%           array, or array with data that is indexed by either
%           distributionIdx or categoryIdx, or both.
%       distributionIdx: grouping variable that determines to which
%           distribution a data point belongs. Grouping is
%           resolved by calling grp2idx, and unless xNames have
%           been supplied, group names determine the x-labels.
%           If the grouping variable is numeric, group labels also
%           determine x-values, unless the parameter xValues has
%           been specified.
%       distributionColors : color identifier (string, cell array of
%           strings), or colormap, with a single color, or one color per
%           distribution (or per entry in distributionIdx). Colors the
%           distributions. Default: 'b'
%       distributionMarkers : string, or cell array of strings, with either
%           a single marker or one marker per distribution (or per entry in
%           distributionIdx). See linespec for admissible markers.
%           Default: 'o'
%		categoryIdx: grouping variable that determines group membership for data
%			points across distributions. Grouping is resolved by calling
%           grp2idx.
%       categoryColors : color identifier (cell array of
%           strings), or colormap, with one color per category.
%           Colors the categories, and will override distributionColors.
%           Default is generated using distinguishable_colors by Timothy E.
%           Holy.
%       categoryMarkers : cell array of strings, with one marker per
%           category. See linespec for admissible markers. Will override
%           distributionMarkers. Default: ''
%       categoryLabels : cell array of strings with one label per category
%           (categories sorted in ascending order). Default: unique
%           category indices
%       binWidth : width of bins (along y) that control which data
%           points are considered close enough to be spread. Default: 0.1
%       spreadFcn : cell array of length 2 with {name,param}
%           if name is 'lin', the spread goes linear with the number of
%             points inside the bin, until it reaches the maximum of 0.9 at
%             n==param.
%           if name is 'xp', the spread increases as 1-exp(log(0.9)*x).
%             param is empty
%           Default {'xp',[]}
%       spreadWidth : width, along the x-axis (y-axis if flipped) that can
%           at most be covered by the points. Default:
%           median(diff(sort(xValues))); 1 if no xValues have been supplied
%       showMM : if 1, mean and median are shown as red crosses and
%                green squares, respectively. Default: 0
%                2: only mean
%                3: only median
%                4: mean +/- standard error of the mean (no median)
%                5: mean +/- standard deviation (no median)
%       xNames : cell array of length nDistributions containing x-tick names
%               (instead of the default '1,2,3')
%       xValues : list of x-values at which the data should
%                 be plotted. Default: 1,2,3...
%       xMode  : if 'auto', x-ticks are spaced automatically. If 'manual',
%                there is a tick for each distribution. If xNames is
%                provided as input, xMode is forced to 'manual'. Default:
%                'manual'.
%       xyOri  : orientation of axes. Either 'normal' (=default), or
%                'flipped'. If 'flipped', the x-and y-axes are switched, so
%                that violin plots are horizontal. Consequently,
%                axes-specific properties, such as 'yLabel' are applied to
%                the other axis.
%       yLabel : string with label for y-axis. Default : ''
%       ah  : handles of axes into which to plot
%
% OUTPUT handles: 3-by-1 cell array with handles to distributions,
%          mean/median etc, and the axes, respectively
%
% REMARKS: plotSpread is useful for distributions with a small number of
%          data points. For larger amounts of data, distributionPlot is
%          more suited.
%
% EXAMPLES: data = {randn(25,1),randn(100,1),randn(300,1)};
%           figure,plotSpread(data,[],[],{'25 pts','100 pts','300 pts'})
%
%            data = [randn(50,1);randn(50,1)+3.5]*[1 1];
%            catIdx = [ones(50,1);zeros(50,1);randi([0,1],[100,1])];
%            figure
%            plotSpread(data,'categoryIdx',catIdx,...
%                 'categoryMarkers',{'o','+'},'categoryColors',{'r','b'})
%
% END
%
% created with MATLAB ver.: 7.9.0.3470 (R2009b) on Mac OS X  Version: 10.5.7 Build: 9J61
%
% created by: jonas
% DATE: 11-Jul-2009
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

def.binWidth = 0.1;
def.spreadFcn = {'xp',[]};
def.xNames = [];
def.showMM = false;
def.xValues = [];
def.distributionIdx = [];
def.distributionColors = 'b';
def.distributionMarkers = 'o';
def.xMode = 'manual';
def.xyOri = 'normal';
def.categoryIdx = [];
def.categoryColors = [];
def.categoryMarkers = '';
def.categoryLabels = '';
def.yLabel = '';
def.spreadWidth = [];
def.markerSizes = 6;
def.normalizeMarkerSizes = true;
def.showWeightedMean = false;
def.upper = [];
def.lower = [];

% in development
def.individualLabels = false; % one category label across all distributions
%                               this should be smartly determined rather
%                               than hard-coded

%% CHECK INPUT

% check for axes handle
if ~iscell(varargin{1}) && length(varargin{1}) == 1 && ...
        ishandle(varargin{1}) && strcmp(get(varargin{1},'Type'),'axes')
    ah = varargin{1};
    data = varargin{2};
    varargin(1:2) = [];
    newAx = false;
else
    figure
    ah = gca;
    data = varargin{1};
    varargin(1) = [];
    % if the axes have children, it's not new (important for adjusting
    % limits below)
    newAx = isempty(get(ah,'Children'));
end

% optional arguments
parserObj = inputParser;
parserObj.FunctionName = 'plotSpread';
distributionIdx = [];distributionLabels = '';
if ~isempty(varargin) && ~ischar(varargin{1}) && ~isstruct(varargin{1})
    % old syntax
    parserObj.addOptional('binWidth',def.binWidth);
    parserObj.addOptional('spreadFcn',def.spreadFcn);
    parserObj.addOptional('xNames',def.xNames);
    parserObj.addOptional('showMM',def.showMM);
    parserObj.addOptional('xValues',def.xValues);
    parserObj.addOptional('markerSizes',def.markerSizes);
    parserObj.addOptional('normalizeMarkerSizes',def.normalizeMarkerSizes)
    parserObj.addOptional('showWeightedMean',def.showWeightedMean);
    parserObj.addOptional('upper',def.upper);
    parserObj.addOptional('lower',def.lower);
    
    parserObj.parse(varargin{:});
    opt = parserObj.Results;
    
    opt.distributionIdx = [];
    opt.distributionColors = def.distributionColors;
    opt.distributionMarkers = def.distributionMarkers;
    opt.xMode = def.xMode;
    opt.xyOri = def.xyOri;
    opt.categoryIdx = [];
    opt.categoryColors = def.distributionColors;
    opt.categoryMarkers = def.distributionMarkers;
    opt.yLabel = '';
    opt.spreadWidth = def.spreadWidth;
    opt.individualLabels = false;
    
    for fn = fieldnames(def)'
        if ~isfield(opt,fn{1})
            % Manually adding the new defaults means a lot fewer bugs
            error('please add option %s to old syntax',fn{1});
        end
        if isempty(opt.(fn{1}))
            opt.(fn{1}) = def.(fn{1});
        end
    end
    
else
    % new syntax
    defNames = fieldnames(def);
    for dn = defNames(:)'
        parserObj.addParamValue(dn{1},def.(dn{1}));
    end
    
    
    parserObj.parse(varargin{:});
    opt = parserObj.Results;
end


% If user provided marker sizes or upper and lower error bars, make sure 
% this input is the same size as the data
if ~isscalar(opt.markerSizes)
    if any(size(opt.markerSizes) ~= size(data))
        error('Marker size data must match y axis data.');
    end
end
if ~isempty(opt.upper) 
    if any(size(opt.upper) ~= size(data))
        error('Error bar data must match y axis data.');
    end
end
if ~isempty(opt.lower) 
    if any(size(opt.lower) ~= size(data))
        error('Error bar data must match y axis data.');
    end
end

% We want data to be a vector, so that indexing with both groupIdx and
% distributionIdx becomes straightforward, and so that we can conveniently
% eliminate NaNs that otherwise could mess up grouping.
% Consequently, if data is a cell array, we convert it, and build a
% corresponding distributionIdx (allowing a user-supplied distributionIdx
% to override, though), and then we go and take care of groupIdx. Once all
% three indices have been built, NaN can be removed.

if iscell(data)
    % make sure data is all n-by-1
    data = cellfun(@(x)x(:),data,'UniformOutput',false);
    nData = length(data);
    nn = cellfun(@numel,data);
    % make vector
    data = cat(1,data{:});
    distributionIdx = repeatEntries((1:nData)',nn);
else
    % distributions in columns
    nData = size(data,2);
    distributionIdx = repeatEntries((1:nData)',size(data,1));
    data = data(:);
end


% Now do the same for marker sizes and error bars, but no need to re-generate
% distributionIdx or nData since these must be the same as for the data.

if ~isscalar(opt.markerSizes)
    if iscell(opt.markerSizes)
        % make sure data is all n-by-1
        opt.markerSizes = cellfun(@(x)x(:),opt.markerSizes,'UniformOutput',false);
        % make vector
        opt.markerSizes = cat(1,opt.markerSizes{:});
    else
        % distributions in columns
        opt.markerSizes = opt.markerSizes(:);
    end
end
if ~isscalar(opt.upper)
    if iscell(opt.upper)
        % make sure data is all n-by-1
        opt.upper = cellfun(@(x)x(:),opt.upper,'UniformOutput',false);
        % make vector
        opt.upper = cat(1,opt.upper{:});
    else
        % distributions in columns
        opt.upper = opt.upper(:);
    end
end
if ~isscalar(opt.lower)
    if iscell(opt.lower)
        % make sure data is all n-by-1
        opt.lower = cellfun(@(x)x(:),opt.lower,'UniformOutput',false);
        % make vector
        opt.lower = cat(1,opt.lower{:});
    else
        % distributions in columns
        opt.lower = opt.lower(:);
    end
end

% distribution groups
if ~isempty(opt.distributionIdx)
    [distributionIdx,distributionLabels,vals] = grp2idx(opt.distributionIdx);
    % convert data to cell array
    nData = length(distributionLabels);
    % if not otherwise provided, use group labels for xnames
    if isempty(opt.xNames)
        opt.xNames = distributionLabels;
        if ~iscell(opt.xNames)
            opt.xNames = num2cell(opt.xNames);
        end
    end
    if isnumeric(vals) && isempty(opt.xValues)
        opt.xValues = vals;
    end
end

if ~isempty(opt.xNames)
    opt.xMode = 'manual';
end


% distribution colors
if ischar(opt.distributionColors)
    opt.distributionColors = {opt.distributionColors};
end
if iscell(opt.distributionColors)
    if length(opt.distributionColors) == 1
        % expand
        opt.distributionColors = repmat(opt.distributionColors,nData,1);
    elseif length(opt.distributionColors) ~= nData
        error('please submit one color per distribution (%i dist, %i colors)',nData,length(opt.distributionColors));
    end
    
else
    if size(opt.distributionColors,2) ~= 3
        error('please specify colormap with three columns')
    end
    if size(opt.distributionColors,1) == 1
        opt.distributionColors = repmat(opt.distributionColors,nData,1);
    elseif size(opt.distributionColors,1) ~= nData
        error('please submit one color per distribution (%i dist, %i colors)',nData,size(opt.distributionColors,1));
    end
    
    % create a cell array
    opt.distributionColors = mat2cell(opt.distributionColors,ones(nData,1),3);
end

% distribution markers
if ischar(opt.distributionMarkers)
    opt.distributionMarkers = {opt.distributionMarkers};
end
if length(opt.distributionMarkers) == 1
    % expand
    opt.distributionMarkers = repmat(opt.distributionMarkers,nData,1);
elseif length(opt.distributionMarkers) ~= nData
    error('please submit one marker style per distribution (%i dist, %i colors)',nData,length(opt.distributionMarkers));
end

% marker sizes
allMarkersSameSize = false;
if length(opt.markerSizes) == 1
    % Save information that we have only a single marker size
    allMarkersSameSize = true; 
    % expand
    opt.markerSizes = repmat(opt.markerSizes,length(data),1);
elseif length(opt.markerSizes) ~= length(data)
    error('please submit one marker size per data point (%i data points, %i sizes)',length(data),length(opt.markerSizes));
end
% Normalize size
if (opt.normalizeMarkerSizes) && max(opt.markerSizes) > 500
    scalefactor = 500 / max(opt.markerSizes);
    opt.markerSizes = scalefactor .* opt.markerSizes;
end

% Weighted mean
if opt.showWeightedMean
    % Set color to default if a logical value was given
    if islogical(opt.showWeightedMean)
        opt.showWeightedMean = 'k';
    end
    % Validate color if specified
    if isnumeric(opt.showWeightedMean)
        if size(opt.showWeightedMean,2) ~= 3 || size(opt.distributionColors,1) ~= 1
            error('please specify colormap with one row and three columns')
        end
    elseif ~ischar(opt.showWeightedMean)
        error('Argument to showWeightedMean must be a logical true, a colorspec string or a 3-number colormap.')
    end
end

stdWidth = 1;
if isempty(opt.xValues)
    opt.xValues = 1:nData;
end


if isempty(opt.spreadWidth) 
    % scale width
    tmp = median(diff(sort(opt.xValues)));
    if ~isnan(tmp)
        stdWidth = tmp;
    end
else
    stdWidth = opt.spreadWidth;
end

if ~ischar(opt.xyOri) || ~any(ismember(opt.xyOri,{'normal','flipped'}))
    error('option xyOri must be either ''normal'' or ''flipped'' (is ''%s'')',opt.xyOri);
end


% check for categoryIdx/colors/markers
% If there are categories, check colors/markers individually first,
% then check whether any of them at all have been supplied, and
% if not, override distributionColors with default categoryColors

if isempty(opt.categoryIdx)
    categoryIdx = ones(size(distributionIdx));
    nCategories = 1;
    categoryLabels = '';
else
    [categoryIdx,categoryLabels] = grp2idx(opt.categoryIdx(:));
    nCategories = max(categoryIdx);
end
if ~isempty(opt.categoryLabels)
    categoryLabels = opt.categoryLabels;
elseif ~iscell(categoryLabels)
    categoryLabels = num2cell(categoryLabels);
end

% plotColors, plotMarkers, plotLabels: nDist-by-nCat arrays
plotColors = repmat(opt.distributionColors(:),1,nCategories);
plotMarkers= repmat(opt.distributionMarkers(:),1,nCategories);

if isempty(distributionLabels)
    distributionLabels = opt.xNames;
    if isempty(distributionLabels)
        distributionLabels = cellstr(num2str(opt.xValues(:)));
    end
end

if nCategories == 1
    plotLabels = distributionLabels(:);
else
    plotLabels = cell(nData,nCategories);
    for iData = 1:nData
        for iCategory = 1:nCategories
            if opt.individualLabels
            plotLabels{iData,iCategory} = ...
                sprintf('%s-%s',num2str(distributionLabels{iData}),...
                num2str(categoryLabels{iCategory}));
            else
                plotLabels{iData,iCategory} = ...
                sprintf('%s',...
                num2str(categoryLabels{iCategory}));
            end
        end
    end
    
end




categoryIsLabeled = false;
if nCategories > 1
    % if not using defaults for categoryColors: apply them
    if ~any(strcmp('categoryColors',parserObj.UsingDefaults))
        if iscell(opt.categoryColors)
            if length(opt.categoryColors) ~= nCategories
                error('please supply one category color per category')
            end
            plotColors = repmat(opt.categoryColors(:)',nData,1);
            categoryIsLabeled = true;
        else
            if all(size(opt.categoryColors) ~= [nCategories,3])
                error('please supply a #-of-categories-by-3 color array')
            end
            plotColors = repmat( mat2cell(opt.categoryColors,ones(nCategories,1),3)', nData,1);
            categoryIsLabeled = true;
        end
    end
    
    if ~any(strcmp('categoryMarkers',parserObj.UsingDefaults))
        if length(opt.categoryMarkers) ~= nCategories
            error('please supply one category marker per category')
        end
        if ~iscell(opt.categoryMarkers)
            error('please supply a list of markers as cell array')
        end
        plotMarkers = repmat(opt.categoryMarkers(:)',nData,1);
        categoryIsLabeled = true;
    end
    
    if ~categoryIsLabeled
        % use distinguishable_colors to mark categories
        
        plotColors = repmat( mat2cell(...
            distinguishable_colors(nCategories),...
            ones(nCategories,1),3)', nData,1);
        
    end
    
end


% remove NaNs from data
badData = ~isfinite(data) | ~isfinite(distributionIdx) | ~isfinite(categoryIdx);
data(badData) = [];
distributionIdx(badData) = [];
categoryIdx(badData) = [];
opt.markerSizes(badData) = [];
if ~isempty(opt.lower)
    opt.lower(badData) = [];
end
if ~isempty(opt.upper)
    opt.upper(badData) = [];
end

%% TRANSFORM DATA
% Here, I try to estimate what the aspect ratio of the data is going to be
fh = figure('Visible','off');
if ~isempty(data)
    minMax = [min(data);max(data)];
else
    minMax = [0 1];
end
switch opt.xyOri
    case 'normal'
        plot([0.5;nData+0.5],minMax,'o');
    case 'flipped'
        plot(minMax,[0.5;nData+0.5],'o');
        
end
aspectRatio = get(gca,'DataAspectRatio');
close(fh);

tFact = aspectRatio(2)/aspectRatio(1);
if strcmp(opt.xyOri,'flipped')
    tFact = 1/tFact;
end

%% SPREAD POINTS
% assign either nData, or xValues number of values, in case we're working
% with group-indices
[wm,m,md,sem,sd,ci] = deal(nan(max(nData,length(opt.xValues)),1));
% make sure xValues are not something weird
opt.xValues = double(opt.xValues);

    
% augment data to make n-by-2
data(:,2) = 0;
for iData = 1:nData
    currentDataIdx = distributionIdx==iData;
    currentData = data(currentDataIdx,1);
    
    if ~isempty(currentData)
        
        % transform and sort
        currentData = currentData / tFact;
        %currentData = sort(currentData);
        
        % add x
        currentData = [ones(size(currentData))*opt.xValues(iData),currentData]; %#ok<AGROW>
        
        % step through the data in 0.1 increments. If there are multiple
        % entries, spread along x
        for y = min(currentData(:,2)):opt.binWidth:max(currentData(:,2))
            % find values
            valIdx = find(currentData(:,2) >= y & currentData(:,2) < y+opt.binWidth);
            nVal = length(valIdx);
            if nVal > 1
                % spread
                switch opt.spreadFcn{1}
                    case 'xp'
                        spreadWidth = stdWidth*0.9*(1-exp(log(0.9)*(nVal-1)));
                    case 'lin'
                        spreadWidth = stdWidth*0.9*min(nVal-1,opt.spreadFcn{2})/opt.spreadFcn{2};
                end
                spreadDist = spreadWidth / (nVal - 1);
                if isEven(nVal)
                    offset = spreadDist / 2;
                else
                    offset = eps;
                end
                for v = 1:nVal
                    currentData(valIdx(v),1) = opt.xValues(iData) + offset;
                    % update offset
                    offset = offset - sign(offset) * spreadDist * v;
                end
            end
        end
        
        % update data
        currentData(:,2) = data(currentDataIdx,1);
        data(currentDataIdx,:) = currentData;
        
        % Calculate mean and confidence intervals
        if opt.showWeightedMean
            m(iData) = mean(currentData(:,2),'omitnan');
            if ~allMarkersSameSize
                currNBaits = opt.markerSizes(currentDataIdx,1);
                weights = currNBaits ./ sum(currNBaits);
                wm(iData) = sum(weights.*currentData(:,2));
                weightedDiffSq = weights .* ( (currentData(:,2)-wm(iData)).^2 );
                sumSqWeights = sum( weights .^ 2 );
                ci(iData) = 1.96 * sqrt( sum(weightedDiffSq) / (length(currNBaits) * (1 - sumSqWeights))); 
            end
        end
        if opt.showMM > 0
            m(iData) = nanmean(currentData(:,2));
            md(iData) = nanmedian(currentData(:,2));
            sd(iData) = nanstd(currentData(:,2));
            sem(iData) = sd(iData)/sqrt(sum(isfinite(currentData(:,2))));
        end
    end % test isempty
end


%% plot
set(ah,'NextPlot','add')

% Draw weighted means and error bars
if opt.showWeightedMean
    if allMarkersSameSize
        errorbar(ah,opt.xValues,m,zeros(1,nData),'.','Color',opt.showWeightedMean,'LineWidth',2,'CapSize',15)
    else
        errorbar(ah,opt.xValues,wm,zeros(1,nData),'.','Color',opt.showWeightedMean,'LineWidth',2,'CapSize',15)
        errorbar(ah,opt.xValues,wm,ci,'.','Color',opt.showWeightedMean,'LineWidth',2)
    end
end

ph = NaN(nData,nCategories);
eh = NaN(nData,nCategories);
for iData = 1:nData
    for iCategory = 1:nCategories
        currentIdx = distributionIdx == iData & categoryIdx == iCategory;
        if any(currentIdx)
            switch opt.xyOri
                case 'normal'
                    ph(iData,iCategory) = scatter(ah,data(currentIdx,1),...
                        data(currentIdx,2),...
                        opt.markerSizes(currentIdx),...                        
                        plotColors{iData,iCategory},...
                        plotMarkers{iData,iCategory},...
                        'LineWidth',1,...
                        'DisplayName',plotLabels{iData,iCategory});
                case 'flipped'
                    ph(iData,iCategory) = plot(ah,data(currentIdx,2),...
                        data(currentIdx,1),...
                        opt.markerSizes(currentIdx),...                        
                        plotColors{iData,iCategory},...
                        plotMarkers{iData,iCategory},...
                        'LineWidth',1,...
                        'DisplayName',plotLabels{iData,iCategory});
            end
            %Add error bars on each point
            if ~isempty(opt.upper) || ~isempty(opt.lower)
                 switch opt.xyOri
                    case 'normal'
                        eh(iData,iCategory) = errorbar(ah,data(currentIdx,1),...
                            data(currentIdx,2),...
                            opt.lower(currentIdx),...                        
                            opt.upper(currentIdx),...
                            '.','Color',plotColors{iData,iCategory},...
                            'CapSize',0,...
                            'LineWidth',0.5);
                    case 'flipped'
                        eh(iData,iCategory) = plot(ah,data(currentIdx,2),...
                            data(currentIdx,1),...
                            opt.lower(currentIdx),...                        
                            opt.upper(currentIdx),...
                            'horizontal',...
                            '.','Color', plotColors{iData,iCategory},...
                            CapSize',0,...
                            'LineWidth',0.5); 
                 end
            end
        end
    end
end



% if ~empty, use xNames
switch opt.xyOri
    case 'normal'
        switch opt.xMode
            case 'manual'
                set(ah,'XTick',opt.xValues);
                if ~isempty(opt.xNames)
                    set(ah,'XTickLabel',opt.xNames)
                end
            case 'auto'
                % no need to do anything
        end
        
        % have plot start/end properly
        minX = min(opt.xValues)-stdWidth;
        maxX = max(opt.xValues)+stdWidth;
        if ~newAx
            oldLim = xlim;
            minX = min(minX,oldLim(1));
            maxX = max(maxX,oldLim(2));
        end
        xlim([minX,maxX])
        
        ylabel(ah,opt.yLabel)
        
    case 'flipped'
        switch opt.xMode
            case 'manual'
                set(ah,'YTick',opt.xValues);
                if ~isempty(opt.xNames)
                    set(ah,'YTickLabel',opt.xNames)
                end
            case 'auto'
                % no need to do anything
        end
        
        % have plot start/end properly (for ease of copying, only switch
        % xlim to ylim
        minX = min(opt.xValues)-stdWidth;
        maxX = max(opt.xValues)+stdWidth;
        if ~newAx
            oldLim = ylim;
            minX = min(minX,oldLim(1));
            maxX = max(maxX,oldLim(2));
        end
        ylim([minX,maxX])
        
        xlabel(ah,opt.yLabel);
        
end

% ## in development
if ~opt.individualLabels
       % hack: add legend entry only once per category
       goodH = ishandle(ph);
       for iCategory = 1:nCategories
           for iData = find(goodH(:,iCategory),1,'first')+1:nData
       if goodH(iData,iCategory)
           set(get(get(ph(iData,iCategory),'Annotation'),'LegendInformation'),...
        'IconDisplayStyle','off');
       end
           end
       end
       
end


% add mean/median (Original code from Jonas - see above for weighted means)
mh = [];mdh=[];
if opt.showMM
    % plot mean, median. Mean is filled red circle, median is green square
    % I don't know of a very clever way to flip xy and keep everything
    % readable, thus it'll be copy-paste
    switch opt.xyOri
        case 'normal'
            if any(opt.showMM==[1,2])
                mh = plot(ah,opt.xValues,m,'+r','Color','r','MarkerSize',12);
            end
            if any(opt.showMM==[1,3])
                mdh = plot(ah,opt.xValues,md,'sg','MarkerSize',12);
            end
            if opt.showMM == 4
                mh = plot(ah,opt.xValues,m,'+r','Color','r','MarkerSize',12);
                mdh = myErrorbar(ah,opt.xValues,m,sem);
            end
            if opt.showMM == 5
                mh = plot(ah,opt.xValues,m,'+r','Color','r','MarkerSize',12);
                mdh = myErrorbar(ah,opt.xValues,m,sd);
            end
        case 'flipped'
            if any(opt.showMM==[1,2])
                mh = plot(ah,m,opt.xValues,'+r','Color','r','MarkerSize',12);
            end
            if any(opt.showMM==[1,3])
                mdh = plot(ah,md,opt.xValues,'sg','MarkerSize',12);
            end
            if opt.showMM == 4
                mh = plot(ah,m,opt.xValues,'+r','Color','r','MarkerSize',12);
                mdh = myErrorbar(ah,m,opt.xValues,[sem,NaN(size(sem))]);
            end
            if opt.showMM == 5
                mh = plot(ah,m,opt.xValues,'+r','Color','r','MarkerSize',12);
                mdh = myErrorbar(ah,m,opt.xValues,[sd,NaN(size(sd))]);
            end
    end
end

%==========================
%% CLEANUP & ASSIGN OUTPUT
%==========================

if nargout > 0
    handles{1} = ph;
    handles{2} = eh;
    handles{3} = [mh;mdh];
    handles{4} = ah;
end

