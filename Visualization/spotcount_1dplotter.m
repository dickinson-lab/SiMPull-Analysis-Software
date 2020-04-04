% Extracts the spot counts from a grid and displays this information as a heatmap.
% Update 10/22/2015 to add support for specifying a background dataset and plotting its mean spotcount as a line.

clearvars -except summary

% Choose mode
mode = questdlg('What do you want to do?', 'Choose Mode', 'Select multiple datasets from one folder', 'Select datasets individually', 'Select multiple datasets from one folder');

%Get the data from the spot counter
if strcmp(mode, 'Select datasets individually')
    answer = inputdlg('Number of experiments to compare:');
    number = str2num(answer{1});
    matFile = {};
    matPath = {};
    startpath = pwd;
    for a = 1:number
        [file path] = uigetfile('*.mat','Choose a .mat file with data from the spot counter',startpath);
        matFile{a} = file;
        matPath{a} = path;
        startpath = path;
    end
else
    [matFile path] = uigetfile('*.mat','Select .mat files to analyze','Multiselect','on');
    number = length(matFile);
    [matPath{1:number}] = deal(path);
end

% Optional: Select background images
background = listdlg('PromptString', 'Optional: Select Background Datasets (Press Cancel to not Specify Background)',...
                          'ListSize', [300 300],...
                          'ListString', matFile);

colors = jet(number);
%colors = {'b','r','g','k','c','m',[0.5 0 0],[0.5 0 1],[0.5 0.5 0.5]};

load([matPath{1} filesep matFile{1}]);
    
for c = 1:nChannels
    color = channels{c};
    figure('Name',[color ' channel']);
    hold on
    bkgMean = [];
    
    for b=1:number
        if b>1 %No need to re-load the first file since we already loaded it above
            load([matPath{b} filesep matFile{b}]);
        end
        fileName = matFile{b};
        
        %Get y values
        spotCount = cell(size(gridData));
        [spotCount{:}] = gridData.([color 'SpotCount']);
        spotCount = transpose(cell2mat(spotCount'));
        if ~isvector(spotCount)
            msgbox('This program only works for 1-dimensional spotcount data.  If you have 2D data, use spotcount_gridplotter.m instead');
            return
        end
        
        %Get x values
        imageNames = cell(size(gridData));
        [imageNames{:}]=gridData.imageName;
        splitNames = cellfun(@(x) strsplit(x,'_'), imageNames, 'UniformOutput', false);
        xvalues = cell2mat( cellfun(@(x) str2num(x{end}), splitNames, 'UniformOutput', false) );
        
        plot(xvalues,spotCount,'Marker','.','MarkerSize',10,'Color',colors(b,:),'DisplayName',strrep(fileName(1:end-4),'_','\_'));
        
        % If this is a background dataset, record the mean
        if ismember(b, background)
            bkgMean(end+1) = mean(spotCount);
        end
        
    end
    
    % Plot the mean and mean*2 for background datasets
    if ~isempty(bkgMean)
        for d=1:length(bkgMean)
            plot(get(gca,'xlim'), [bkgMean(d) bkgMean(d)], 'Color',colors(background(d),:),'LineStyle','--'); 
            plot(get(gca,'xlim'), [2*bkgMean(d) 2*bkgMean(d)], 'Color',colors(background(d),:)); 
        end
    end
    
end

