% Uses changepoint detection software to find the first up-step in an
% intensity trace, corresponding to molecule appearance.

function dataStruct = findAppearanceTimes(dataStruct, channel)
    ntraces = length(dataStruct.([channel 'SpotData']));
    logodds = 2; %Adjustable parameter
    
    %Count steps
    for a = 1:ntraces
        %Detect Changepoints
        traj = dataStruct.([channel 'SpotData'])(a).intensityTrace;
        [dataStruct.([channel 'SpotData'])(a), error] = find_changepoints_c(traj,logodds);
        if error
            dataStruct([channel 'SpotData'])(a).appearTime = 'Analysis Failed';
            continue
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

