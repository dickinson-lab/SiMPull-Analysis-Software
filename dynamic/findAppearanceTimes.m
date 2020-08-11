% Uses changepoint detection software to find the first up-step in an
% intensity trace, corresponding to molecule appearance.

function dataStruct = findAppearanceTimes(dataStruct, channel)
    ntraces = length(dataStruct.([channel 'SpotData']));
    logodds = 2; %Adjustable parameter
    
    %Count steps
    for a = 1:ntraces
        %Detect Changepoints
        traj = dataStruct.([channel 'SpotData'])(a).intensityTrace;
        tmax = length(traj);

        [nSteps, changepoint_pos, bayes_factors] = cpdetect_c('Gaussian', single(traj), logodds);
        changepoint_pos = changepoint_pos(1:nSteps);
        bayes_factors = bayes_factors(1:nSteps);
        changepoints = horzcat(changepoint_pos, bayes_factors);
        if ~isempty(changepoints) 
            changepoints = sortrows(changepoints, 1);
        end
        
        dataStruct.([channel 'SpotData'])(a).changepoints = changepoints;

        %Extract the signal levels at each step
        dataStruct.([channel 'SpotData'])(a).steplevels = [];
        dataStruct.([channel 'SpotData'])(a).stepstdev = [];
        lastchangepoint = 1;
        b = 1;
        while b <= nSteps+1
            if b>nSteps
                changepoint = tmax;
            else 
                changepoint = changepoints(b,1);
            end
            if changepoint == 0
                continue
            end
            subtraj = traj(lastchangepoint:changepoint);
            level = mean(subtraj);
            stdev = std(subtraj);
            dataStruct.([channel 'SpotData'])(a).steplevels(b) = level;
            dataStruct.([channel 'SpotData'])(a).stepstdev(b) = stdev;
            
            %Throw out steps that are (erroneously) detected when intensity is close to 0
            if (level-stdev) < 0
                if b == 1 
                    % If the first segment has intensity < stDev, it might just mean we have a step up; go to the next iteration
                    % of the loop to check the second segment.
                    b = 2; 
                    lastchangepoint = changepoint+1; %"+1" just keeps the segments from overlapping
                    continue
                elseif b == 2 && dataStruct.([channel 'SpotData'])(a).steplevels(1) < dataStruct.([channel 'SpotData'])(a).stepstdev(1) 
                    % Steps at beginning of trajectory - this code only runs if the first two segments of the trajectory have intensity < stDev
                    nSteps = nSteps-1;
                    dataStruct.([channel 'SpotData'])(a).changepoints(1,:) = [];
                    b = 1; % After eliminating the first step, we need to go back to the beginning and check the new (longer) first segment
                    continue
                else
                    % Steps at end of trajectory
                    nSteps = b-1;
                    subtraj = traj(lastchangepoint:end);
                    level = mean(subtraj);
                    dataStruct.([channel 'SpotData'])(a).steplevels(b) = level;
                    dataStruct.([channel 'SpotData'])(a).changepoints(b:end,:) = [];
                    break
                end
            end
            
            lastchangepoint = changepoint+1; %"+1" just keeps the segments from overlapping
            b = b+1;
        end

        % Figure out where the first up-step occurs
        foundAppearance = 0;
        c = 1;
        while c <= nSteps %Using a while statement means this code won't run if there are no steps
            if dataStruct.([channel 'SpotData'])(a).steplevels(c+1) > dataStruct.([channel 'SpotData'])(a).steplevels(c)
                %If step is positive in magnitude, we're good - save info and move on
                if isfield(dataStruct.([channel 'SpotData']),'appearedInWindow')
                    dataStruct.([channel 'SpotData'])(a).appearTime = dataStruct.avgWindow * (dataStruct.([channel 'SpotData'])(a).appearedInWindow - 1) + dataStruct.([channel 'SpotData'])(a).changepoints(c,1);
                else
                    dataStruct.([channel 'SpotData'])(a).appearTime = dataStruct.([channel 'SpotData'])(a).changepoints(c,1);
                end
                foundAppearance = 1;
                break
            end
            c = c+1;
        end
        % Make sure we found it, note if not.
        if ~foundAppearance
            dataStruct.([channel 'SpotData'])(a).appearTime = 'Not found';
        end

    end % of loop over all spots / traces

end

