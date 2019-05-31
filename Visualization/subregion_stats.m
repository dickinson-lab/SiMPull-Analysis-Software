%Calculates summary statistics for a region of a dataset

[matFile matPath] = uigetfile('*.mat','Choose a .mat file with data from the spot counter');

load([matPath filesep matFile]);
if exist('gridData', 'var') ~= 1
    msgbox('This script requires SiMPull data from the spot counter.');
    return
end

imageNames = {gridData.imageName};

[selection, ok] = listdlg('PromptString', 'Select Images to Summarize',...
                          'ListSize', [300 300],...
                          'ListString', imageNames);
if ~ok
    return
end

subGridData = gridData(selection);

nPositions = length(subGridData);

for a = 1:length(channels)
    color1 = channels{a};

    %Spot count data
    regionStats.(['total' color1 'Spots']) = sum(cell2mat({subGridData.([color1 'SpotCount'])}));
    regionStats.(['avg' color1 'Spots']) = regionStats.(['total' color1 'Spots']) / nPositions;

    %Colocalization data
    for b = 1:length(channels)
        color2 = channels{b};
        if isfield(statsByColor, ['pct' color1 'Coloc_w_' color2]);
            colocIndex = cellfun(@isnumeric, {subGridData.([color1 color2 'ColocSpots'])});
            regionStats.([color1 '_vs_' color2 '_SpotsTested']) = sum(cell2mat({subGridData(colocIndex).([color1 'SpotCount'])}));
            regionStats.(['num' color1 'Coloc_w_' color2]) = sum(cell2mat({subGridData(colocIndex).([color1 color2 'ColocSpots'])}));
            regionStats.(['pct' color1 'Coloc_w_' color2]) = 100 * regionStats.(['num' color1 'Coloc_w_' color2]) / regionStats.([color1 '_vs_' color2 '_SpotsTested']);
        end
    end

    %Photobleaching data
    if isfield(statsByColor, [color1 'TracesAnalyzed']);
        countedIndex = cellfun(@isnumeric, {subGridData.([color1 'GoodSpotCount'])});
        regionStats.([color1 'TracesAnalyzed']) = sum(cell2mat({subGridData(countedIndex).([color1 'SpotCount'])}));
        regionStats.([color1 'BadSpots']) = regionStats.(['total' color1 'Spots']) - sum(cell2mat({subGridData(countedIndex).([color1 'GoodSpotCount'])}));
        regionStats.([color1 'StepHist']) = sum(cell2mat({subGridData(countedIndex).([color1 'StepDist'])}),2);
    end
end

