function [resultStruct,error] = find_changepoints_c(traj,logodds)
    resultStruct = struct('nSteps',[],...
                          'changepoints',[],...
                          'steplevels',[],...
                          'stepstdev',[]);

    tmax = length(traj); 
    try
        [nSteps, changepoint_pos, bayes_factors] = cpdetect_c('Gaussian', single(traj), logodds);
    catch Err
        warning(Err.message);
        error = true;
        return
    end
    changepoint_pos = changepoint_pos(1:nSteps);
    bayes_factors = bayes_factors(1:nSteps);
    changepoints = horzcat(changepoint_pos, bayes_factors);
    if ~isempty(changepoints) 
        changepoints = sortrows(changepoints, 1);
    end

    resultStruct.changepoints = changepoints;

    %Extract the signal levels at each step
    lastchangepoint = 1;
    b = 1;
    while b <= nSteps+1
        if b>nSteps
            changepoint = tmax;
        else 
            changepoint = resultStruct.changepoints(b,1);
        end
        if changepoint == 0
            continue
        end
        subtraj = traj(lastchangepoint:changepoint);
        level = mean(subtraj);
        stdev = std(subtraj);
        resultStruct.steplevels(b) = level;
        resultStruct.stepstdev(b) = stdev;

        lastchangepoint = changepoint+1; %"+1" just keeps the segments from overlapping
        b = b+1;
    end
    
    %Throw out steps that are (erroneously) detected when intensity is close to 0
    c=1;
    while c <= nSteps
        if abs(resultStruct.steplevels(c)) < resultStruct.stepstdev(c) && abs(resultStruct.steplevels(c+1)) < resultStruct.stepstdev(c+1) %If both this segment and the one following have near-zero intensity, we ignore this step
            %Erase the step
            nSteps = nSteps-1;
            resultStruct.changepoints(c,:) = [];
            resultStruct.steplevels(c) = [];
            resultStruct.stepstdev(c) = [];
            %Recalculate level & stdev for the new merged segment
            if c == 1 %if we've eliminated the first step
                segmentStart = 1;
            else
                segmentStart = resultStruct.changepoints(c-1,1) + 1; % The previous changepoint; "+1" just keeps the segments from overlapping
            end
            if c > nSteps %if we've eliminated the last step
                segmentEnd = tmax;
            else
                segmentEnd = resultStruct.changepoints(c,1); % The next changepoint - it's "c" not "c+1" because we already eliminated the current changepoint
            end
            subtraj = traj(segmentStart:segmentEnd);
            resultStruct.steplevels(c) = mean(subtraj);
            resultStruct.stepstdev(c) = std(subtraj);
        end    
        c = c+1;
    end
    
    resultStruct.nSteps = nSteps;
    error = false;
end

