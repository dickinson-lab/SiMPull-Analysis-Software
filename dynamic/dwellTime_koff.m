% Finds and saves dwell times for dynamic SiMPull data. Both channels are
% analyzed. Then, the prey channel information if used to calculate and
% save a k_off.

% k_off is estimated following the Bayesian method of Kinz-Thompson & Gonzalez. 
% Note that what is actually reported is k_obs, which is a sum of koff and 
% the photobleaching rate constant k_ph. k_ph must be measured independently, 
% for example by applying this analysis to covalent mNG::Halo dimers. 

% Return values of P and k_obs are 3-element vectors that express the 95%
% credible interval of the estimation; for example, P = [P_upper, P_mean, P_lower]
% Where upper and lower refer to the bounds of the credible interval. 

% k_obs is returned in time units of per (imaging) frame, which must be
% converted to units of per second by the user.

% Note that this code, as written, assumes that the complexes being
% analyzed are 1:1 heterodimers.  It is not designed to deal with oligomers
% and will give strange results if data from an oligomeric complex is analyzed.

% Ask user for data files
matFiles = uipickfiles('Prompt','Select data files to analyze','Type',{'*.mat'});

statusbar = waitbar(0);
for a = 1:length(matFiles)
    % Get image name and root directory
    slash = strfind(matFiles{a},filesep);
    fileName = matFiles{a}(slash(end)+1:end); 
    expDir = matFiles{a}(1:slash(end));
    
    waitbar((a-1)/length(matFiles),statusbar,strrep(['Loading ' fileName],'_','\_'));
    
    % Load data
    load([expDir filesep fileName]);
    BaitChannel = params.BaitChannel; %Extract channel info - this is just for code readability
    PreyChannel = params.PreyChannel;
    
    % Count non-disappearing spots - if this is a large number, we might need to re-process data to pull longer intensity traces
    baitNoDisappearance = 0;
    preyNoDisappearance = 0;
    
    waitbar((a-1)/length(matFiles),statusbar,strrep(['Finding Dwell Times for ' fileName],'_','\_'));
    %% Loop over spots, find dwell times for each
    for c = 1:length(dynData.([BaitChannel 'SpotData']))     
        % Bait channel
        [dynData.([BaitChannel 'SpotData'])(c).dwellTime, dynData.([BaitChannel 'SpotData'])(c).noDisappearance] = calculateDwellTime(dynData.([BaitChannel 'SpotData'])(c));
        baitNoDisappearance = baitNoDisappearance + dynData.([BaitChannel 'SpotData'])(c).noDisappearance;
        
        % Prey channel
        [dynData.([PreyChannel 'SpotData'])(c).dwellTime, dynData.([PreyChannel 'SpotData'])(c).noDisappearance] = calculateDwellTime(dynData.([PreyChannel 'SpotData'])(c));
        preyNoDisappearance = preyNoDisappearance + dynData.([PreyChannel 'SpotData'])(c).noDisappearance;
    end
    
    %% Use the dwell time information to calculate k_off
    waitbar((a-1)/length(matFiles),statusbar,strrep(['Calculating k_off for ' fileName],'_','\_'));
    
    % Pull out co-appearing spots - that's all we're interested in for this calculation
    index = cellfun(@(x) ~isempty(x) && ~isnan(x) && x==true, {dynData.([BaitChannel 'SpotData']).(['appears_w_' PreyChannel])});
    baitStruct = dynData.([BaitChannel 'SpotData'])(index); 
    preyStruct = dynData.([PreyChannel 'SpotData'])(index); 
    
    % Count up the number of spots observed and the number of observations of the complex remaining intact 
    n = dynData.([BaitChannel PreyChannel 'CoAppearing']); % n is the number of complexes observed
    n_bound = sum(cell2mat({preyStruct.dwellTime})); % n_bound is the number of times we observed the prey protein staying bound (not disappearing). 
    
    % Count the number of prey protein disappearances.  We only count cases where 
    % 1) The prey protein is observed to disappear, and 
    % 2) The bait and prey do not disappear together, since co-disappearing traces are likely to just be instances of the whole complex dissociating.
    index1 = ~cell2mat({preyStruct.noDisappearance});
    index2 = abs( cell2mat({preyStruct.dwellTime}) - cell2mat({baitStruct.dwellTime}) ) > 4; % Similar to the criterion for co-appearance, spots are considered to disappear at the same time if they disappear within 4 frames of each other.
    n_off = sum(index1&index2);
    
    % Calculate P and its confidence intervals
    P(1,1) = betaincinv(0.025, 1+n_off, 1+n_bound, 'upper'); %Upper bound of confidence interval
    P(2,1) = (1 + n_off) / (2 + n_off + n_bound);
    P(3,1) = betaincinv(0.025, 1+n_off, 1+n_bound, 'lower'); %Lower bound of confidence interval

    % Calculate koff
    k_obs = -log(1-P);
    
    %% Display the results
    disp(['Results for ' fileName ':']);
    disp(['Analyzed data for ' num2str(n) ' co-appearing spots']);
    disp(['Prey channel k_obs = ' num2str(k_obs(2,1))]);
    disp([ num2str(baitNoDisappearance) ' bait molecules that remained bound throughout their intensity traces' ]);
    disp([ num2str(preyNoDisappearance) ' prey molecules that remained bound throughout their intensity traces' ]);
    disp([ num2str(sum(~index2)) ' bait and prey molecules disappeared simultaneously']);
    disp('');
    
    %Save 
    waitbar((a-1)/length(matFiles),statusbar,strrep(['Saving ' fileName],'_','\_'));
    dynData.([PreyChannel '_P_off']) = P;
    dynData.([PreyChannel '_k_obs']) = k_obs;
    save([expDir filesep fileName], 'dynData','params');
end

close(statusbar)

%% Helper function to find dwell time for a single spot
function [dwellTime, noDisappearance] = calculateDwellTime(spotData)
    if isempty(spotData.changepoints) % No dwell time info available if there are no steps
        dwellTime = NaN;
        noDisappearance = false;
        return
    end

    % Find the appearance and disappearance times 
    appearanceStep = 0;
    disappearanceStep = 0;
    [nSteps, ~] = size(spotData.changepoints);
    
    for b = 1:nSteps
        if ~appearanceStep
            if spotData.steplevels(b) < spotData.steplevels(b+1)
                appearanceStep = b;
            end
        elseif ~disappearanceStep
            % Here we find the disappearance time by looking for the intensity to return to its initial value.  
            % This has both the advantage and the imitation that it ignores any complicated photobleaching or 
            % photophysical behavior. 
            if ( spotData.steplevels(b+1) - spotData.steplevels(appearanceStep) ) < spotData.stepstdev(b+1)
                disappearanceStep = b;
            end
        end
    end
    
    % Check results
    % If there's no appearance, there can't be a dwell time
    if ~appearanceStep
        dwellTime = NaN;
        noDisappearance = false;
        return
    end
    % If there's no disappearance, we can conclude that the molecule stayed bound throughout the
    % intensity trace we extracted. We still warn about this because if it happens frequently, 
    % it may necessitate re-processing the data to extract longer intensity traces. 
    if ~disappearanceStep
        %warning(['Molecule remained bound throughout the intesity trace. If this occurs frequently, you may need to adjust your data processing settings.']);
        dwellTime = length(spotData.intensityTrace) - spotData.changepoints(appearanceStep,1);
        noDisappearance = true;
        return
    end
    
    % If we've made it to this point, we can calculate a dwell time for this spot
    dwellTime = spotData.changepoints(disappearanceStep,1) - spotData.changepoints(appearanceStep,1);
    noDisappearance = false;
end
