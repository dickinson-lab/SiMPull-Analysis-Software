function dataStruct = count_steps_c(dataStruct, channel)
    
    ntraces = dataStruct.([channel 'SpotCount']);
    logodds = 2; %Adjustable parameter
    
    %Count steps
    for a = 1:ntraces
        
        %Detect Changepoints
        traj = dataStruct.([channel 'SpotData'])(a).intensityTrace;
        %[dataStruct.([channel 'SpotData'])(a), error] = find_changepoints_c(traj,logodds);
        [results, error] = find_changepoints_c(traj,logodds);
        nSteps = results.nSteps;
        dataStruct.([channel 'SpotData'])(a).changepoints = results.changepoints;
        dataStruct.([channel 'SpotData'])(a).steplevels = results.steplevels;
        dataStruct.([channel 'SpotData'])(a).stepstdev = results.stepstdev;
        if error
            dataStruct.([channel 'SpotData'])(a).appearTime = 'Analysis Failed';
            continue
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