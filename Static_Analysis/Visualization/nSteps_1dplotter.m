%Extracts the number of photobleaching steps and displays this information as a function of position.
%Note, this only works if gridData is 1-dimensional (i.e. images were
%acquired in a stripe)

clear all;
%close all;

%Get the data from the spot counter
startpath = pwd;
[file path] = uigetfile('*.mat','Choose a .mat file with data from the spot counter',startpath);

load([path filesep file]);
gridSize = size(gridData);

for c = 1:nChannels
    color = channels{c};
    stepDist = cell(gridSize);
    [stepDist{:}] = gridData.([color 'StepDist']);
    stepDist = transpose(cell2mat(stepDist'));
    stepDistNorm = zeros(size(stepDist));
    for a = 1:gridSize(1)
        stepDistNorm(a,:) = 100*stepDist(a,:)./sum(stepDist(a,:));
        d23(a) = 150/(1.5 + stepDist(a,2)/stepDist(a,3));
        d34(a) = 400/(4 + stepDist(a,3)/stepDist(a,4));
    end

    thisfig = figure('Name', [color ' Step Counts'],'NextPlot','add');
    
    %Get x values
    imageNames = cell(size(gridData));
    [imageNames{:}]=gridData.imageName;
    splitNames = cellfun(@(x) strsplit(x,'_'), imageNames, 'UniformOutput', false);
    if contains(imageNames,'composite')
        xvalues = cell2mat(cellfun(@(x) str2num(x{end-1}), splitNames, 'UniformOutput', false) );
    else
        xvalues = cell2mat( cellfun(@(x) str2num(x{end}), splitNames, 'UniformOutput', false) );
    end
    
    figcolors = hsv(length(statsByColor.([color 'StepHist'])));
    hold on
    for b = 1:length(statsByColor.([color 'StepHist']))
        plot(xvalues,stepDistNorm(:,b),'Marker','.','MarkerSize',10,'Color',figcolors(b,:));
    end

    dfig = figure('Name',[color ' Calculated % Detection']);
    hold on
    plot(xvalues,d23,'b','Marker','.','MarkerSize',10);
    plot(xvalues,d34,'r','Marker','.','MarkerSize',10);
end
