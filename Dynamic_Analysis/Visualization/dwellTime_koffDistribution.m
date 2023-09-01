% Takes a list of data files for which dwell time data are available (or
% can be calculated). Then, corrects each measurement for k_bleach and, in
% a statistically robust way, calculates the mean and 95% credible interval
% for k_off for each experimental condition. 

% Before running this script, you need a list of experiments to analyze and 
% a matched photobleaching control for each dataset - this is typically 
% mNG::Halo data captured the same day (or at least the same week) as your 
% experiment.

%% User dialog to capture information about datasets

if exist('infoTable','var') == 1
    % Populate dialog with existing information, if available
    app = koffPlotterDlg(infoTable,controlNames);
else
    % Otherwise, start from scratch
    app = koffPlotterDlg({},{});
end
uiwait(app.SampleInformationUIFigure);
clear app

categories = infoTable(:,2);
bleachControls = infoTable(:,3);

%% Set up structures to hold the results
names = unique(categories,'stable');
names = names(~cellfun(@isempty, names));
for c = 1:length(names)
    sample_names.(names{c}) = {};
    k_off_combined.(names{c}) = [];
    n_combined.(names{c}) = []; 
    n_off_combined.(names{c}) = [];
    n_bound_combined.(names{c}) = [];
end
remember = false;
% Calculate k_off for each dataset
for b = 1:length(fileNames)
    % Check input
    if isempty(categories{b}) && ~isempty(categories) 
        warning(['Warning: No category was specified for dataset ' fileNames{b} '. This dataset will not be included in the analysis']);
        continue
    end
    if strcmp(bleachControls{b},'Choose')
        warning(['Warning: No k_bleach was specified for dataset ' fileNames{b} '. This dataset will not be included in the analysis']);
        continue
    end
    
    % Load data
    vars = who('-file', [expDir{b} filesep fileNames{b}]);
    if ismember('koff_results',vars)
        load([expDir{b} filesep fileNames{b}],'params','koff_results')
    else
        [~, ~, koff_results] = dwellTime_koff(0, {[expDir{b} filesep fileNames{b}]}, false);
        load([expDir{b} filesep fileNames{b}],'params')
    end
    
    % Determine prey channel
    if ~isscalar(params.preyChNums) 
        if ~remember
            [selectedPreyCh, remember] = choosePreyChDlg(params.preyChNums);
        end
        PreyCh = selectedPreyCh;
    else
        PreyCh = ['PreyCh' num2str(params.preyChNums)];
    end
    
    n = koff_results.([PreyCh '_n']);
    n_off = koff_results.([PreyCh '_n_off']);
    n_bound = koff_results.([PreyCh '_n_bound']);
    
    % Load bleach control data
    controlIdx = find(strcmp(controlNames,bleachControls{b}));
    if length(controlIdx) ~= 1
        errorDlg('It appears you have multiple control datasets with the same filenames. For this analysis to work, each control filename needs to be unique. Please rename your files accordingly.')
    end
    vars = who('-file', [controlDir{controlIdx} filesep controlNames{controlIdx}]);
    if ismember('koff_results',vars)
        load([controlDir{controlIdx} filesep controlNames{controlIdx}],'params','koff_results')
    else
        [~, ~, koff_results] = dwellTime_koff(0, {[controlDir{controlIdx} filesep controlNames{controlIdx}]}, false);
        load([controlDir{controlIdx} filesep controlNames{controlIdx}],'params')
    end
    % Determine prey channel
    if ~isscalar(params.preyChNums) 
        if ~remember
            [selectedPreyCh, remember] = choosePreyChDlg(params.preyChNums);
        end
        PreyCh = selectedPreyCh;
    else
        PreyCh = ['PreyCh' num2str(params.preyChNums)];
    end
    k_bleach = [koff_results.([PreyCh '_k_obs_lower']) koff_results.([PreyCh '_k_obs']) koff_results.([PreyCh '_k_obs_upper'])];

    % Do the math to correct for k_bleach
    Pbleach = 1-exp(-k_bleach);
    n_bleach = round(Pbleach * (n_off + n_bound));  
    if any(n_off <= n_bleach) 
        warning(['Dataset ' fileNames{b} ' shows no evidence of prey protein unbinding'])
        null = n_off <= n_bleach;
        n_bound(null) = n_off + n_bound;
        n_off(null) = 0;
    else 
        n_off = n_off - n_bleach;
        n_bound = n_bound + n_bleach;
    end
    P_corr = betaincinv(0.5,1+n_off,1+n_bound);
    k_corr = -log(1-P_corr) / 0.05; % Here a 50 ms exposure time is assumed
    
    % Store results
    sample_names.(categories{b}){end+1} = fileNames{b}(1:end-4);
    k_off_combined.(categories{b})(end+1) = k_corr(2);
    n_combined.(categories{b})(end+1) = n;
    n_off_combined.(categories{b})(end+1,:) = n_off;
    n_bound_combined.(categories{b})(end+1,:) = n_bound;
end

%% Calculate Mean & Credible Interval, and Plot
k_off_cell = cell(length(names),1);
n_cell = cell(length(names),1);
fh = figure;
ah = axes;
hold on
resultSummary = cell(length(names),1);
for d = 1:length(names)
    k_off_cell(d) = {k_off_combined.(names{d})};
    n_cell(d) = {n_combined.(names{d})};
    n_off = sum(n_off_combined.(names{d}));
    n_bound = sum(n_bound_combined.(names{d}));
    P(1,1) = betaincinv(0.025, 1+n_off(1), 1+n_bound(1), 'upper'); %Upper bound of confidence interval
    P(2,1) = (1 + n_off(2)) / (2 + n_off(2) + n_bound(2)); %Maximum likelihood estimate of k_off
    P(3,1) = betaincinv(0.025, 1+n_off(3), 1+n_bound(3), 'lower'); %Lower bound of confidence interval
    k_off = -log(1-P) / 0.05; % Here a 50 ms exposure time is assumed
    resultSummary{d} = ['Condition ' names{d} ': k_off = ' num2str(k_off(3,1)) ' < ' num2str(k_off(2,1)) ' < ' num2str(k_off(1,1)) ];
    disp(resultSummary{d});
    errorbar(ah, d, k_off(2), k_off(2)-k_off(3), k_off(1)-k_off(2), '_k', 'MarkerSize', 12,'LineWidth',1.5);
end
if length(k_off_cell) == 1
    k_off_mat = k_off_cell{1}';
    n_mat = n_cell{1}';
else
    k_off_mat = padcat(k_off_cell{:})';
    n_mat = padcat(n_cell{:})';
end
% Remove zeros, which cause errors
zeroIdx = n_mat == 0;
k_off_mat(zeroIdx) = NaN;
n_mat(zeroIdx) = NaN;

bubbleHandles = plotSpreadBubble(ah,k_off_mat,'markerSizes',n_mat,'xNames',names,'normalizeMarkerSizes',false);
ylabel('k_o_f_f (s^-^1)');
for e = 1:length(names)
    labelHandle = get(bubbleHandles{1}(e),'DataTipTemplate');
    labelHandle.DataTipRows(1) = dataTipTextRow('Sample:',strrep(sample_names.(names{e}),'_','\_') );
    labelHandle.DataTipRows(2).Label = 'k_o_f_f';
    labelHandle.DataTipRows(3).Label = 'n coappearing';
end
userData.Results = resultSummary;
userData.DataAnalyzed = infoTable;
set(fh,'UserData',userData);