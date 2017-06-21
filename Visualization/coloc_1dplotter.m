%Extracts the spot counts from a grid and displays this information as a heatmap.

clear all;
%close all;

%Get the data from the spot counter
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

colors = hsv(12);
%colors = {'b','r','g','k','c','m',[0.5 0 0],[0.5 0 1],[0.5 0.5 0.5]};

load([matPath{1} filesep matFile{1}]);
    
for c = 1:nChannels
    color1 = channels{c};
    
    for d = 1:nChannels
        color2 = channels{d};
        if strcmp(color1, color2)
            continue
        end
        
        figure('Name',[color1 ' vs ' color2 ' colocalization']);
        hold on

        for b=1:number
            load([matPath{b} filesep matFile{b}]);
            fileName = matFile{b};
            
            colocSpots = cell(size(gridData));
            [colocSpots{:}] = gridData.([color1 color2 'ColocSpots']);
            
            %Guard against images with too many spots
            index = ~cellfun(@isnumeric, colocSpots);
            if any(index)
                [colocSpots{index}] = deal(NaN);
            end
            
            colocSpots = transpose(cell2mat(colocSpots'));
            if ~isvector(colocSpots)
                msgbox('This program only works for 1-dimensional spotcount data.  If you have 2D data, use spotcount_gridplotter.m instead');
                return
            end
            
            spotCounts = cell(size(gridData));
            [spotCounts{:}] = gridData.([color1 'SpotCount']);
            spotCounts = transpose(cell2mat(spotCounts'));
            
            pctColoc = ( colocSpots ./ spotCounts ) * 100;
            
            xvalues = (1:length(colocSpots))';
            plot(xvalues,pctColoc,'Marker','.','MarkerSize',10,'Color',colors(b,:),'DisplayName',strrep(fileName(1:end-4),'_','\_'));
        end
    end
end

