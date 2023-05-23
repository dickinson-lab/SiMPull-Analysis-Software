function [stepSizes, aborted] = getStepSizes(gridData,channel,minSteps,maxSteps)
    % Extracts a histogram of intensity step sizes from a data set.
    index2 = zeros(length(gridData),1);
    for b = 1:length(gridData)
        index2(b) = isfield(gridData(b).([channel 'SpotData']),'nSteps');
    end
    index2 = logical(index2);
    if ~any(index2)
        warndlg(['Photobleaching data do not appear to exist for the ' channel ' channel in this dataset']);
        stepSizes = [];
        aborted = true;
        return
    end
    spotData = {gridData(index2).([channel 'SpotData'])};
    spotData = vertcat(spotData{ cellfun(@length, spotData) > 1 }); % The argument inside {} tosses images with no spots
    index = arrayfun(@(x) isnumeric(x.nSteps) && x.nSteps>=minSteps && x.nSteps<=maxSteps,  spotData);
    goodSpots = spotData(index);

    totalSteps = sum(cell2mat({goodSpots(:).nSteps}));
    stepSizes = zeros(totalSteps,1);
    counter = 1;
    for a=1:length(goodSpots)
        nSteps = goodSpots(a).nSteps;
        for b=1:nSteps
            stepSizes(counter) = goodSpots(a).steplevels(b) - goodSpots(a).steplevels(b+1);
            counter = counter + 1;
        end
    end
    aborted = false;