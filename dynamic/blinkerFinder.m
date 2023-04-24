% This script broswes dynData and records the number of frames since the last appearance event that occured at a particular spotLocation
function dynData = blinkerFinder(dynData, baitChannel)
    % Isolate the bait spotLocation information from dynData
    baitSpotLocation = cell2mat({dynData.([baitChannel 'SpotData']).spotLocation}');

    for a = 1:dynData.([baitChannel 'SpotCount'])
        if a == 1               % If this is the first recorded bait appperance, there can't possibly be a previous event to check against
            dynData.([baitChannel 'SpotData'])(a).nFramesSinceLastApp = 'No previous appearance';
            continue
        end
        found = 0;              % Set the flag to indicate whether a spotLocation match has been found to false when starting the current iteration of the for loop
        b = a-1;                % The first bait appearance location to check against will be the location of the appearance event immediately before the current one
        while found == 0
            match = baitSpotLocation(a,1) == baitSpotLocation(b,1) && baitSpotLocation(a,2) == baitSpotLocation(b,2); 
            if match            % If the spotLocation of bait 'a' matches the location of a previous bait appearance 'b', calculate the number of frames between appearance events
                % If appearance time was not found in the analysis of either of the traces, enter NaN for nFramesSinceLastApp between these two bait appearances at this location
                if strcmp(dynData.([baitChannel 'SpotData'])(a).appearTimeFrames,'Not found')||strcmp(dynData.([baitChannel 'SpotData'])(b).appearTimeFrames,'Not found')
                    dynData.([baitChannel 'SpotData'])(a).nFramesSinceLastApp = NaN;
                else
                    dynData.([baitChannel 'SpotData'])(a).nFramesSinceLastApp = dynData.([baitChannel 'SpotData'])(a).appearTimeFrames - dynData.([baitChannel 'SpotData'])(b).appearTimeFrames;
                end
                found = 1;  % After recording nFramesSinceLastApp, break out of the while loop by changing the flag to indicate a spotLocation has been found so that the next iteration of the for loop can begin
            else
                b = b-1;        % If bait appearance 'b' did not appear at the spotLocation of bait appearance 'a', check the location of the bait apperance prior to 'b'
            end
            if b == 0           % If the list of bait appearances up to 'a' have been exhausted and no mataches have been found...
                dynData.([baitChannel 'SpotData'])(a).nFramesSinceLastApp = 'No previous appearance';   % Record that there were no previous bait apperances at this spotLocation
                found = 1;      % Change the flag to break out of the while loop despite not finding a match
            end
        end
    end
end