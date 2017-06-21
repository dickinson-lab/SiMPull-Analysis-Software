function dataStruct = count_steps_c(dataStruct, channel)
    
    ntraces = dataStruct.([channel 'SpotCount']);
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
        dataStruct.([channel 'SpotData'])(a).allchangepoints = changepoints;
        
        %Extract the signal levels at each step
        dataStruct.([channel 'SpotData'])(a).steplevels = [];
        dataStruct.([channel 'SpotData'])(a).stepstdev = [];
        lastchangepoint = 1;
        for b = 1:nSteps+1
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
            
            %Throw out steps that are (erroneously) detected after the spot has bleached to 0
            if (level-stdev) < 0
                nSteps = b-1; 
                subtraj = traj(lastchangepoint:end);
                level = mean(subtraj);
                dataStruct.([channel 'SpotData'])(a).steplevels(b) = level;
                dataStruct.([channel 'SpotData'])(a).changepoints(b:end,:) = [];
                break
            end
            
            lastchangepoint = changepoint+1; %"+1" just keeps the segments from overlapping
        end
        
        %Reject trajectories that don't show stepwise photobleaching
        goodtraj = true;
        for c = 1:(length(dataStruct.([channel 'SpotData'])(a).steplevels) - 1)
            if dataStruct.([channel 'SpotData'])(a).steplevels(c) < dataStruct.([channel 'SpotData'])(a).steplevels(c+1)
                dataStruct.([channel 'SpotData'])(a).nSteps = 'Rejected';
                goodtraj = false;
                break
            end
        end
        
        %Warn if trajectory has too many steps
        if nSteps>20
            warning(['Warning: Found a trajectory with ' num2str(nSteps) ' steps in image ' dataStruct.imageName ' (' channel ' channel).']);
        end
        
        %If trajectory wasn't rejected, store information about number of steps
        if goodtraj && nSteps>0 && nSteps<=20
            dataStruct.([channel 'SpotData'])(a).nSteps = nSteps;
            dataStruct.([channel 'StepDist'])(nSteps) = dataStruct.([channel 'StepDist'])(nSteps)+1;
        end
    end