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
% analyzed are 1:1 heterodimers.  It is not designed to deal with oligomers. 
% If one wishes to analyze data from a complex that is expected to be oligomeric, 
% there are two possibilities: 
    % If photobleach step counting has been performed, set "maxBaitSteps"
    % to 1 to only consider the monomeric pool. 
    % If photobleach step counting has not been performed, the code will
    % still run but will ignore any photobleaching behavior. If this is a concern, 
    % run the photobleach step counter first. 
% In either case, note that the program only considers the oligomeric state
% of the bait protein.  The rationale for this is that if a monomeric bait
% protein interacts with an oligomeric prey, there will still be a single
% observable k_off when the entire oligomeric prey complex dissociates from
% a single bait. However, an oligomeric bait protein might have multiple
% binidng sites for prey proteins, which would behave independently,
% complicating the interpretation of k_obs. 

% Usage: [dynData, summary] = dwellTime_koff(maxBaitSteps, matFiles, printResults, dynData, params)
% Parameters (all optional): 
    % maxBaitSteps: Maximum number of steps a trace can have in order to be analyzed.
    % This avoids analyzing nonsensical traces in dense regions of the data.
    % Filter is disabled if 0 or blank

    % matFiles: List of data files to be analyzed. Cell array of strings,
    % each containing a path to one .mat file. If left blank, user is
    % prompted to select files. 

    % printResults: Logical that determines whether to display the results
    % on the command line. Default: true.

    % dynData, params: Data to analyze. If this is passed in, the function will not
    % load new data from disk. Instead, it will analyze the dynData
    % structure it was given and will save the results in the path given by
    % 'matFiles'. Both dynData and params must be passed or the function
    % will give an error. This syntax only supports analyzing a single dataset. 

function [dynData, koff_summary, koff_results] = dwellTime_koff(varargin)
    %Parse user input
    if nargin == 0
        maxBaitSteps = 0;
        matFiles = {};
        printResults = true;
        dynData = [];
        loadData = true;
    elseif nargin == 1
        maxBaitSteps = varargin{1};
        matFiles = {}; 
        printResults = true;
        dynData = [];
        loadData = true;
    elseif nargin == 2
        maxBaitSteps = varargin{1};
        matFiles = varargin{2};
        printResults = true;
        dynData = [];
        loadData = true;
    elseif nargin == 3
        maxBaitSteps = varargin{1};
        matFiles = varargin{2};
        printResults = varargin{3};
        dynData = [];
        loadData = true;
    elseif nargin == 5
        maxBaitSteps = varargin{1};
        matFiles = varargin{2};
        printResults = varargin{3};
        dynData = varargin{4};
        params = varargin{5};
        loadData = false;
        if length(matFiles) ~= 1
            error('Only a single file name is allowed if dynData is passed in');
        end
    else
        error('Wrong number of input arguments');
    end
    
    if isempty(matFiles)
        % Ask user for data files
        matFiles = uipickfiles('Prompt','Select data files or folders to analyze','Type',{'*.mat'});
    end
    
    % Summary structure for results - this facilitates copying into Excel
    koff_summary = struct('Sample_name',[]); 
    
    if length(matFiles) > 1
        statusbar = waitbar(0);
    end
    for a = 1:length(matFiles)
        % Get file name
        slash = strfind(matFiles{a},filesep);
        fileName = matFiles{a}(slash(end)+1:end); 
    
        % Get Directory
        if isfolder(matFiles{a})
            fileName = [fileName '.mat'];
            expDir = matFiles{a};
            if ~isfile([expDir filesep fileName])
                warndlg(['No .mat file found for selected folder ' expDir]);
                continue
            end
        else
            expDir = matFiles{a}(1:slash(end));
        end
        
        if length(matFiles) > 1
            waitbar((a-1)/length(matFiles),statusbar,strrep(['Loading ' fileName],'_','\_'));
        end
        
        % Load data
        if loadData
            load([expDir filesep fileName]);
        end
        BaitChannel = params.BaitChannel; %Extract channel info - this is just for code readability
        % Warn if the maxBaitSteps parameter was set but photobleaching data aren't present
        if maxBaitSteps && ~isfield(dynData.([BaitChannel 'SpotData']),'nFluors')
            warning(['The maxBaitSteps parameter was supplied but this dataset does not have photobleaching analysis.\n'...
                     'Continuing analysis of traces with ' num2str(maxBaitSteps) ' steps.\n'...
                     'Ensure that this is the desired behavior or run countDynamicBleaching.m first']);
        end
        
        if length(matFiles) > 1
            waitbar((a-1)/length(matFiles),statusbar,strrep(['Finding Dwell Times for ' fileName],'_','\_'));
        end
 
        %% Loop over spots, find dwell times for each
        for c = 1:length(dynData.([BaitChannel 'SpotData']))     
            if isfield(dynData.([BaitChannel 'SpotData']),'nFluors')
                nBaitSteps = dynData.([BaitChannel 'SpotData'])(c).nFluors;
            else
                [nBaitSteps, ~] = size(dynData.([BaitChannel 'SpotData'])(c).changepoints);
            end
            if maxBaitSteps && nBaitSteps > maxBaitSteps
                %Skip analyzing this trace if it's too complicated
                dynData.([BaitChannel 'SpotData'])(c).dwellTime = NaN;
                dynData.([BaitChannel 'SpotData'])(c).noDisappearance = NaN;
                dynData.([PreyChannel 'SpotData'])(c).dwellTime = NaN;
                dynData.([PreyChannel 'SpotData'])(c).noDisappearance = NaN;
            else
                %Otherwise, continue
                % Bait channel
                [dynData.([BaitChannel 'SpotData'])(c).dwellTime, dynData.([BaitChannel 'SpotData'])(c).noDisappearance] = calculateDwellTime(dynData.([BaitChannel 'SpotData'])(c));
    
                % Prey channel(s)
                if ~strcmp(params.DataType, 'Composite Data')
                    PreyChannel = params.PreyChannel;
                    [dynData.([PreyChannel 'SpotData'])(c).dwellTime, dynData.([PreyChannel 'SpotData'])(c).noDisappearance] = calculateDwellTime(dynData.([PreyChannel 'SpotData'])(c));
                else
                    for d = 1:length(params.preyChNums)
                        PreyChannel = ['PreyCh' num2str(params.preyChNums(d))]; 
                        [dynData.([PreyChannel 'SpotData'])(c).dwellTime, dynData.([PreyChannel 'SpotData'])(c).noDisappearance] = calculateDwellTime(dynData.([PreyChannel 'SpotData'])(c));
                    end
                end
            end
        end
        
        %% Use the dwell time information to calculate k_off
        if length(matFiles) > 1
            waitbar((a-1)/length(matFiles),statusbar,strrep(['Calculating k_off for ' fileName],'_','\_'));
        end
        koff_summary(a).Sample_name = fileName;
        koff_summary(a).maxStepsUsed = maxBaitSteps; % Save information about the sizes of complexes that were considered.

        for e = 1:length(params.preyChNums)
            PreyChannel = ['PreyCh' num2str(params.preyChNums(e))]; 
        
            % Pull out co-appearing spots - that's all we're interested in for this calculation
            nonSkippedIndex = ~cellfun(@isnan, {dynData.([BaitChannel 'SpotData']).dwellTime});
            coAppIndex = cellfun(@(x) ~isempty(x) && ~isnan(x) && x==true, {dynData.([BaitChannel 'SpotData']).(['appears_w_' PreyChannel])});
            hasStepIndex = ~cellfun(@isnan, {dynData.([PreyChannel 'SpotData']).dwellTime});
            index = nonSkippedIndex & coAppIndex & hasStepIndex;
            baitStruct = dynData.([BaitChannel 'SpotData'])(index); 
            preyStruct = dynData.([PreyChannel 'SpotData'])(index); 
            
            % Count non-disappearing spots - if this is a large number, we might need to re-process data to pull longer intensity traces
            baitNoDisappearance = sum(cell2mat({baitStruct.noDisappearance}));
            preyNoDisappearance = sum(cell2mat({preyStruct.noDisappearance}));
            
            % Count up the number of spots observed and the number of observations of the complex remaining intact 
            n = sum(index); % Number of complexes analyzed
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
        
            % Calculate k_obs
            k_obs = -log(1-P);
            
            %% Display the results
            if printResults
                disp(['Results for ' fileName ', ' PreyChannel ' channel:']);
                disp(['Analyzed data for ' num2str(n) ' co-appearing spots']);
                disp(['Prey channel k_obs = ' num2str(k_obs(2)) ' (' num2str(k_obs(3)) ', ' num2str(k_obs(1)) ')']);
                disp([ num2str(baitNoDisappearance) ' bait molecules that remained bound throughout their intensity traces' ]);
                disp([ num2str(preyNoDisappearance) ' prey molecules that remained bound throughout their intensity traces' ]);
                disp([ num2str(sum(~index2)) ' bait and prey molecules disappeared simultaneously']);
                disp(newline);
            end
            
            %Add results to summary structure
            koff_summary(a).([PreyChannel '_k_obs_lower']) = k_obs(3);
            koff_summary(a).([PreyChannel '_k_obs']) = k_obs(2);
            koff_summary(a).([PreyChannel '_k_obs_upper']) = k_obs(1);
            koff_summary(a).([PreyChannel '_n']) = n;
            koff_summary(a).([PreyChannel '_n_off']) = n_off;
            koff_summary(a).([PreyChannel '_n_bound']) = n_bound;
            koff_summary(a).([PreyChannel '_non_disappearing']) = preyNoDisappearance; 
        
            dynData.([PreyChannel '_P_off']) = P;
            dynData.([PreyChannel '_k_obs']) = k_obs;
        end
        
        %Save 
        if length(matFiles) > 1
            waitbar((a-1)/length(matFiles),statusbar,strrep(['Saving ' fileName],'_','\_'));
        end
        koff_results = koff_summary(a);
        save([expDir filesep fileName], 'dynData','params','koff_results',"-append");
    end
    if length(matFiles) > 1
        close(statusbar)
    end
end

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
            if ( ( spotData.steplevels(b+1) - spotData.steplevels(appearanceStep) ) < spotData.stepstdev(b+1) ) || ( spotData.steplevels(b+1) - spotData.steplevels(1) ) < spotData.stepstdev(b+1)
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
