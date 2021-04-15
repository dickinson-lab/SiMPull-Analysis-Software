% Estimates a koff from dwell time analysis of dynamic data, following the
% Bayesian method of Kinz-Thompson & Gonzalez. Note that what is actually
% reported is k_obs, which is a sum of koff and the photobleaching rate
% constant k_ph. k_ph must be measured independently, for example by
% applying this analysis to covalent mNG::Halo dimers. 

% Return values of P and k_obs are 3-element vectors that express the 95%
% credible interval of the estimation; for example, P = [P_upper, P_mean, P_lower]
% Where upper and lower refer to the bounds of the credible interval. 

% k_obs is returned in time units of per (imaging) frame, which must be
% converted to units of per second by the user.

% Note that this code, as written, assumes that the complexes being
% analyzed are 1:1 heterodimers.  It is not designed to deal with oligomers
% and will give strange results if data from an oligomeric complex is analyzed.

function [P, k_obs, n, preyStruct] = dwellTime_koff(dynData, baitChannel, preyChannel)

% Pull out co-appearing spots - that's all we're interested in here
index = [dynData.([baitChannel 'SpotData']).(['appears_w_' preyChannel])];
index(isnan(index)) = 0; % Replace NaN's with zeros
index = logical(index); % Convert to logical
preyStruct = dynData.([preyChannel 'SpotData'])(index); % We only need the data from the prey channel for what follows

% Count up observations of prey disappearance
% n is the number of complexes observed
% n_off and n_bound are what we measure from the data. 
% n_off is the number of times we observed the prey protein disappearing.
% n_bound is the number of times we observed the prey protein staying bound (not disappearing). 
n = 0;
n_off = 0;
n_bound = 0;
noDisappearanceStep = 0;
for a = 1:length(preyStruct)
    % Find the appearance and disappearance times for this prey
    appearanceStep = 0;
    disappearanceStep = 0;
    [nSteps, ~] = size(preyStruct(a).changepoints);
    for b = 1:nSteps
        if ~appearanceStep
            if preyStruct(a).steplevels(b) < preyStruct(a).steplevels(b+1)
                appearanceStep = b;
            end
        elseif ~disappearanceStep
            % Here we find the disappearance time by looking for the intensity to return to its initial value.  
            % This has both the advantage and the imitation that it ignores any complicated photobleaching or 
            % photophysical behavior. 
            if ( preyStruct(a).steplevels(b+1) - preyStruct(a).steplevels(1) ) < preyStruct(a).stepstdev(b+1)
                disappearanceStep = b;
            end
        end
    end
    % Check results
    % If there's no appearance, something is wrong
    if ~appearanceStep
        warning('Unable to find appearance time for a spot that was previously identified as co-appearing. Check your data!!');
        continue
    end
    
    % Add these observations to our running tallies of n, n_off and n_bound
    % If there's no disappearance, we can conclude that the molecule stayed bound throughout the
    % intensity trace we extracted. We still warn about this because if it happens frequently, 
    % it may necessitate re-processing the data to extract longer intensity traces. 
    if ~disappearanceStep
        warning(['Prey molecule ' num2str(a) ' remained bound throughout the intesity trace. If this occurs frequently, you may need to adjust your data processing settings.']);
        noDisappearanceStep = noDisappearanceStep + 1;
        n_bound = n_bound + (length(preyStruct(a).intensityTrace) - preyStruct(a).changepoints(appearanceStep,1));
    else        
        n_off = n_off + 1; 
        n_bound = n_bound + (preyStruct(a).changepoints(disappearanceStep,1) - preyStruct(a).changepoints(appearanceStep,1)); 
    end
    n = n+1;
end

% Calculate P and its confidence intervals
P(1,1) = betaincinv(0.025, 1+n_off, 1+n_bound, 'upper'); %Upper bound of confidence interval
P(2,1) = (1 + n_off) / (2 + n_off + n_bound);
P(3,1) = betaincinv(0.025, 1+n_off, 1+n_bound, 'lower'); %Lower bound of confidence interval

% Calculate koff
k_obs = -log(1-P);
% Display the number of prey molecules for which no n_off was found
disp(['Number of prey molecules that remained bound throughout their intensity traces: ' num2str(noDisappearanceStep)]);
end

