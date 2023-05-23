%Extracts the spot counts from a grid and displays this information as a heatmap.

clear all;
close all;

%Get the data from the spot counter
[matFile matPath] = uigetfile('*.mat','Choose a .mat file with data from the spot counter');
load([matPath filesep matFile]);
gridSize = size(gridData);

greenSpotCount = cell(gridSize);
[greenSpotCount{:}] = gridData.greenSpotCount;
greenSpotCount = transpose(cell2mat(greenSpotCount));
figure('Name','Green Spots');
imshow(greenSpotCount,'DisplayRange',[0 max(max(greenSpotCount))],'InitialMagnification',4000);%,'Colormap',colormap(jet));

if isfield(gridData,'redSpotCount')
    redSpotCount = cell(gridSize);
    [redSpotCount{:}] = gridData.redSpotCount;
    redSpotCount = transpose(cell2mat(redSpotCount));
    figure('Name','Red Spots');
    imshow(redSpotCount,'DisplayRange',[0 max(max(redSpotCount))],'InitialMagnification',4000);%,'Colormap',colormap(jet));
end

if isfield(gridData,'colocalizedSpots')
    colocSpots = cell(gridSize);
    [colocSpots{:}] = gridData.colocalizedSpots;
    colocSpots = transpose(cell2mat(colocSpots));
    figure('Name','Colocalized Spots');
    imshow(colocSpots,'DisplayRange',[0 100],'InitialMagnification',4000);%'Colormap',colormap(jet));
    %totalSpots = greenSpotCount + redSpotCount;
    colocPercent = (colocSpots ./ redSpotCount) * 100;
    figure('Name','Percentage of Colocalized Spots');
    imshow(colocPercent,'DisplayRange',[0 50],'InitialMagnification',4000);%,'Colormap',colormap(jet));
end

