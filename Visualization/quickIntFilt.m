intensityFilteredSpotData = goodSpots;
for a = 1:length(intensityFilteredSpotData)
    spotData = intensityFilteredSpotData(a);
    if spotData.steplevels(1) - spotData.steplevels(end) < 1000
        intensityFilteredSpotData(a).nSteps = 'Rejected';
        continue
    end
    nSteps = spotData.nSteps;
    b = 1;
    while b <= nSteps
        stepSize = spotData.steplevels(b) - spotData.steplevels(b+1);
        if stepSize < 1030
            % We are going to eliminate a step.  
            % This if stmt makes sure that if two small steps are right next to each other, the smaller one gets eliminated
            if b < nSteps
               nextStepSize = spotData.steplevels(b+1) - spotData.steplevels(b+2);
               if nextStepSize < stepSize && nextStepSize + stepSize >= 1000
                   b = b+1;
                   continue
               end
            end
            
            %Now eliminate the step
            if b == 1
                prevchangepoint = 1;
            else
                prevchangepoint = spotData.changepoints(b-1,1);
            end
            if b == nSteps
                nextchangepoint = length(spotData.intensityTrace);
            else
                nextchangepoint = spotData.changepoints(b+1,1);
            end
            spotData.steplevels(b) = mean(spotData.intensityTrace(prevchangepoint:nextchangepoint));
            spotData.steplevels(b+1) = [];
            spotData.nSteps = spotData.nSteps - 1;
            nSteps = nSteps -1;
        else
            b = b+1;
        end
    end
    intensityFilteredSpotData(a) = spotData;
end
index = arrayfun(@(x) isnumeric(x.nSteps),  intensityFilteredSpotData);
intensityFilteredSpotData = intensityFilteredSpotData(index);
intensityFilteredHist = {intensityFilteredSpotData(:).nSteps};
intensityFilteredHist = histc(cell2mat(intensityFilteredHist),1:10);
bar(intensityFilteredHist);
