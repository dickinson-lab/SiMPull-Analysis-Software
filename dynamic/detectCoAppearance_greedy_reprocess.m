% Find spots that appear at the same time. Here a "greedy" algorithm is
% used that counts any up-step in prey intensity coincinding with bait appearance as a co-appearance
% event, regardless of whether it's the first up-step in the prey channel

% This code is similar to the last part of detectCoAppearance_greedy.m but
% is meant for re-processing existing data (so code to read images and find spots is
% not included). 

% Arguments: If called with no arguments, this function queries the user to get the location of the file 
% to be re-processed and to ask whether to re-detect changepoints. This information can also be provided
% with the functional call (to allow batch processing) by calling 
% detectCoAppearance_greedy_reprocess(fileName,expDir,reDetect)

function dynData = detectCoAppearance_greedy_reprocess(varargin)
    if nargin == 0
        % Get data file from user
        [fileName, expDir] = uigetfile('*.mat','Choose .mat file to re-process',pwd);
        % Ask whether to re-detect changepoints
        reDetect = questdlg('Do you want to re-detect changepoints or just re-count co-appearance?','Type of analysis','Changepoints','Just co-appearance','Just co-appearance');
        load([expDir filesep fileName]);
    elseif nargin == 3
        fileName = varargin{1};
        expDir = varargin{2};
        reDetect = varargin{3};
        load([expDir filesep fileName '.mat']);
    else
        errorDlg('Wrong number of input arguments');
    end
    
    %Check for necessary parameters, get from dialog box if missing
    if ~isfield(params, 'BaitPos')
        [Answer,Cancelled] = dynamicChannelInfoDlg_short;
        if Cancelled 
            return
        else
            v2struct(Answer);
            params.LeftChannel = LeftChannel;
            params.RightChannel = RightChannel;
            params.BaitPos = BaitPos;
        end
    end
    if ~isfield(params,'BaitChannel')        
        params.BaitChannel = params.([params.BaitPos 'Channel']);
        if strcmp(params.BaitPos,'Right')
            params.PreyChannel = params.LeftChannel;
        else
            params.PreyChannel = params.RightChannel;
        end
    end
    baitChannel = params.BaitChannel;
    preyChannel = params.PreyChannel;
    
    if strcmp(reDetect,'Changepoints')
        %Re-find appearance times for the bait channel
        dynData = findAppearanceTimes(dynData, baitChannel);
        
        %Detect Changepoints in the prey channel
        wb = waitbar(0,['Finding changepoints in the ' preyChannel ' channel']);
        for d = 1:dynData.([baitChannel 'SpotCount'])
            waitbar((d-1)/dynData.([baitChannel 'SpotCount']),wb);
            traj = dynData.([preyChannel 'SpotData'])(d).intensityTrace;
            [results, error] = find_changepoints_c(traj,2);
            dynData.([preyChannel 'SpotData'])(d).changepoints = results.changepoints;
            dynData.([preyChannel 'SpotData'])(d).steplevels = results.steplevels;
            dynData.([preyChannel 'SpotData'])(d).stepstdev = results.stepstdev;
            if error
                dynData.([preyChannel 'SpotData'])(d).appearTime = 'Analysis Failed';
                continue
            end
        end
        close(wb);
    end
    
    for c = 1:dynData.([baitChannel 'SpotCount'])
        
        %Look for an upstep at the appearance time
        if isnumeric(dynData.([baitChannel 'SpotData'])(c).appearTime)
            baitAppearTime = dynData.([baitChannel 'SpotData'])(c).appearTime;
            
            % Make sure there is a step to be tested 
            if ~isempty(dynData.([preyChannel 'SpotData'])(c).changepoints)
                preyStepTimes = dynData.([preyChannel 'SpotData'])(c).changepoints(:,1) + dynData.avgWindow * (dynData.([preyChannel 'SpotData'])(c).appearedInWindow - 1);
            else
                % If there are no steps in the prey channel, we're done - it can't co-appear
                dynData.([baitChannel 'SpotData'])(c).(['appears_w_' preyChannel]) = false;
                continue 
            end
            matchingStep = find( abs(baitAppearTime - preyStepTimes) <= 4 );  %Spots appearing within 4 frames of each other are considered simultaneous
            
            if ~isempty(matchingStep) && dynData.([preyChannel 'SpotData'])(c).steplevels(max(matchingStep)+1) > dynData.([preyChannel 'SpotData'])(c).steplevels(min(matchingStep)) % && the intensity has to increase (otherwise it's not an appearance event)
                                                                                                                                                                                     % The "min" and "max" avoid crashing when more than one step matches.
                dynData.([baitChannel 'SpotData'])(c).(['appears_w_' preyChannel]) = true;
            else
                dynData.([baitChannel 'SpotData'])(c).(['appears_w_' preyChannel]) = false;
            end

        else
            dynData.([baitChannel 'SpotData'])(c).(['appears_w_' preyChannel]) = NaN;
        end
    end

    % Tally results
    dynData.([baitChannel 'AppearanceFound']) = sum( ~isnan([ dynData.([baitChannel 'SpotData']).(['appears_w_' preyChannel]) ]) ) ;
    dynData.([baitChannel preyChannel 'CoAppearing']) = sum([ dynData.([baitChannel 'SpotData']).(['appears_w_' preyChannel]) ], 'omitnan');


    %% Save data
    imgName = fileName(1 : strfind(fileName,'.mat')-1);
    save([expDir filesep imgName '_greedyCoApp.mat'], 'dynData','params');

end
