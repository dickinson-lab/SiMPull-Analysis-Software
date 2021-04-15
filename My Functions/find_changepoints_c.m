function [resultStruct,error] = find_changepoints_c(traj,logodds)
    resultStruct = struct('changepoints',[],...
                          'steplevels',[],...
                          'stepstdev',[]);

    tmax = length(traj);
    try
        [nSteps, changepoint_pos, bayes_factors] = cpdetect_c('Gaussian', single(traj), logodds);
    catch Err
        warning([Err.message ' for trace ' num2str(a)]);
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

        %Throw out steps that are (erroneously) detected when intensity is close to 0
        if (level-stdev) < 0
            if b == 1 
                % If the first segment has intensity < stDev, it might just mean we have a step up; go to the next iteration
                % of the loop to check the second segment.
                b = 2; 
                lastchangepoint = changepoint+1; %"+1" just keeps the segments from overlapping
                continue
            elseif b == 2 && resultStruct.steplevels(1) < resultStruct.stepstdev(1) 
                % Steps at beginning of trajectory - this code only runs if the first two segments of the trajectory have intensity < stDev
                nSteps = nSteps-1;
                resultStruct.changepoints(1,:) = [];
                b = 1; % After eliminating the first step, we need to go back to the beginning and check the new (longer) first segment
                continue
            else
                % Steps at end of trajectory
                nSteps = b-1;
                subtraj = traj(lastchangepoint:end);
                level = mean(subtraj);
                resultStruct.steplevels(b) = level;
                resultStruct.changepoints(b:end,:) = [];
                break
            end
        end

        lastchangepoint = changepoint+1; %"+1" just keeps the segments from overlapping
        b = b+1;
    end
    
    error = false;
end

