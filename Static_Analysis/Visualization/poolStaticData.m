% Pools different SiMPull .mat files into a single .mat file.  Useful for analyzing
% all data from a day of experiments together. 

clear all

[matFile, matPath] = uigetfile('*.mat','Choose .mat files to combine',pwd,'MultiSelect','on');
nFiles = length(matFile);

if nFiles < 2
    msgbox('Please select more than one file');
    return
end

%Do the first dataset
load([matPath filesep matFile{1}]);

%Choose which images to use
imageNames = {gridData.imageName};
[selection, ok] = listdlg('PromptString', [{['Select Images to use from dataset ' matFile{1}]} {''}],...
                          'ListSize', [300 300],...
                          'ListString', imageNames);
if ~ok
    return
end
gridData = gridData(selection);
nPositions = length(gridData);

%Actually pool the data
bigGridData = gridData;
bigChannels = channels;
bigNPositions = nPositions;
bigStatsByColor = statsByColor;
for g = 1:length(bigChannels)
    color1 = bigChannels{g};
    for h = 1:length(bigChannels)
        color2 = bigChannels{h};
        if isfield(bigStatsByColor, ['pct' color1 'Coloc_w_' color2]);
            bigStatsByColor.(['num' color1 'Coloc_w_' color2]) = round( ( bigStatsByColor.(['pct' color1 'Coloc_w_' color2]) * bigStatsByColor.(['total' color1 'Spots']) ) / 100 );
        end
    end
end


% Combine data structures
for a = 2:nFiles
    load([matPath filesep matFile{a}]);
    
    %Choose which images to use
    imageNames = {gridData.imageName};
    [selection, ok] = listdlg('PromptString', [{['Select Images to use from dataset ' matFile{a}]} {''}],...
                              'ListSize', [300 300],...
                              'ListString', imageNames);
    if ~ok
        return
    end
    gridData = gridData(selection);
    nPositions = length(gridData);

    %Combine the selected images
    if ~isempty(setdiff(bigChannels, channels)) || ~isempty(setdiff(channels, bigChannels))
        errordlg('The selected datasets do not appear to contain the same channels');
        return
    end
    
    if length(gridData) > length(bigGridData)
        [bigGridData(length(gridData),:).imageName] = deal('');
    elseif length(bigGridData) > length(gridData)
        [gridData(length(bigGridData),:).imageName] = deal('');
    end
    bigGridData = horzcat(bigGridData, gridData);
    
    bigNPositions = bigNPositions + nPositions;
    
    fields = fieldnames(statsByColor);
    for b = 1:length(fields)
        bigStatsByColor.(fields{b}) = bigStatsByColor.(fields{b}) + statsByColor.(fields{b});
    end
    for e = 1:length(bigChannels)
        color1 = bigChannels{e};
        for f = 1:length(bigChannels)
            color2 = bigChannels{f};
            if isfield(bigStatsByColor, ['pct' color1 'Coloc_w_' color2]);
                bigStatsByColor.(['num' color1 'Coloc_w_' color2]) = bigStatsByColor.(['num' color1 'Coloc_w_' color2]) + round( ( statsByColor.(['pct' color1 'Coloc_w_' color2]) * statsByColor.(['total' color1 'Spots']) ) / 100 );
            end
        end
    end
end

% Re-calculate averages and percentages across the whole dataset
for c = 1:length(bigChannels)
    color = bigChannels{c};
    
    % Recalculate averages
    if isfield(bigStatsByColor, ['avg' color 'Spots'])
        bigStatsByColor.(['avg' color 'Spots']) = bigStatsByColor.(['total' color 'Spots']) / bigNPositions;
    end
    
    % Recalculate percentages
    for d = 1:length(bigChannels)
        color2 = bigChannels{d};
        if isfield(bigStatsByColor, ['pct' color 'Coloc_w_' color2])
            bigStatsByColor.(['pct' color 'Coloc_w_' color2]) = ( bigStatsByColor.(['num' color 'Coloc_w_' color2]) / bigStatsByColor.(['total' color 'Spots']) ) * 100;
        end
    end
end

% Save
gridData = bigGridData;
channels = bigChannels;
nChannels = length(channels);
nPositions = bigNPositions;
statsByColor = bigStatsByColor;
[outFile, outPath] = uiputfile('*.mat','Select save location',[matPath filesep 'combined.mat']);
save([outPath filesep outFile], 'gridData', 'channels', 'nChannels', 'nPositions', 'statsByColor');
