% Extracts the total spotcount and the number of spots with a specified
% number of photobleaching steps for each image in a dataset. 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Adjustable parameters are here %
minSteps = 1;  %Counts spots with >= this many photobleaching steps
maxSteps = 10; %Counts spots with <= this many photobleaching steps (must be <= 10 or the program will crash)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[matFile, matPath] = uigetfile('*.mat','Choose a .mat file with data from the spot counter');
load([matPath filesep matFile]);
gridSize = size(gridData);
nElements = gridSize(1)*gridSize(2);

result = cell(nElements+1,3);
result(1,:) = {'Spot Count',['Spots with between ' num2str(minSteps) ' and ' num2str(maxSteps) ' steps'],'Percentage'};
for a=1:nElements
    result{a+1,1} = gridData(a).greenSpotCount;
    result{a+1,2} = sum(gridData(a).greenStepDist(minSteps:maxSteps));
    result{a+1,3} = (result{a+1,2}/gridData(a).greenGoodSpotCount)*100;
end
