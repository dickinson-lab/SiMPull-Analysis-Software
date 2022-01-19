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
        reDetect = questdlg('Do you want to re-detect changepoints or just re-count co-appearance?','Type of analysis','Re-count Changepoints','Re-count co-appearance','Re-count co-appearance');
        
        % Ask whether to re-register
        reReg = questdlg('Do you want to redo image registration?','Registration','Yes','No','Yes');

        if strcmp(reReg,'Yes')
            % Registration dialog box
            [Answer,Cancelled] = dvRegisterDlg(expDir);
            if Cancelled 
                return
            else
                v2struct(Answer);
            end

            % Image registration
            warning('off'); %Prevent unnecessary warnings from libtiff
            regImg = TIFFStack(regFile);
            subImg = regImg(:,:,RegWindow1:RegWindow2);
            avgImg = mean(subImg, 3);
            [~, xmax] = size(avgImg);
            leftImg = avgImg(:,1:(xmax/2));
            rightImg = avgImg(:,(xmax/2)+1:xmax);
            regData = registerImages(rightImg, leftImg);
        end
        
        load([expDir filesep fileName]);
        
    elseif nargin == 3
        fileName = varargin{1};
        expDir = varargin{2};
        reDetect = varargin{3};
        reReg = 'No';
        load([expDir filesep fileName]);
    elseif nargin == 5
        fileName = varargin{1};
        expDir = varargin{2};
        reDetect = varargin{3};
        reReg = varargin{4};
        regData = varargin{5};
        load([expDir filesep fileName]);
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
    
    %% Re-find appearance times for the bait channel
    if strcmp(reDetect,'Re-count Changepoints')
        dynData = findAppearanceTimes(dynData, baitChannel);
    end
    
    %% Re-pull traces from the prey channel with new registration, if applicable
    if strcmp(reReg,'Yes')
        % Load images
        wb = waitbar(0,'Loading Images...','Name',strrep(['Analyzing Experiment ' expDir],'_','\_'));
        
        warning('off'); %Prevent unnecessary warnings from libtiff
        d = uipickfiles_subs.filtered_dir([expDir filesep '*.ome.tif'],'',false,@(x,c)uipickfiles_subs.file_sort(x,[1 0 0],c)); % See comments in uipickfiles_subs for syntax here
        imgFile = arrayfun(@(x) [x.folder filesep x.name], d, 'UniformOutput', false);
        if length(imgFile) > 1 %if the diretory contains multiple files
            nFiles = length(imgFile);
            stackOfStacks = cell(nFiles,1);
            % Each file will be loaded as a TIFFStack object, then concatenated together.
            % Order is determined by the user via uipickfiles
            for a = 1:nFiles
                stackOfStacks{a} = TIFFStack(imgFile{a});
            end
            stackObj = TensorStack(3, stackOfStacks{:});
        else
            % If there's just a single TIFF file, it's simpler
            stackObj = TIFFStack(imgFile{1});
        end
        
        % Find co-appearing spots in the prey channel
        % First, copy the locations of the bait spots into the new prey struct
        waitbar(0,wb,'Finding co-appearing prey spots...');
        dynData.([preyChannel 'SpotData']) = struct('spotLocation',[]);
        index = true(dynData.([baitChannel 'SpotCount']),1);
        % Figure out what portion of the image we're going to work with and set x indices accordingly
        [ymax, xmax, ~] = size(stackObj);
        if strcmp(params.BaitPos, 'Left')
            xmin = 1;
            xmax = xmax/2;
        elseif strcmp(params.BaitPos, 'Right')
            xmin = xmax/2 + 1;
        end       
        for d = 1:dynData.([baitChannel 'SpotCount'])
            if strcmp(params.BaitPos, 'Left')

                % Inverse affine transformation if bait channel is on the left
                preySpotLocation = round( transformPointsInverse(regData.Transformation, dynData.([baitChannel 'SpotData'])(d).spotLocation) );
            else
                % Forward affine transformation if bait channel is on the right
                preySpotLocation = round( transformPointsForward(regData.Transformation, dynData.([baitChannel 'SpotData'])(d).spotLocation) );
            end
            if preySpotLocation(1) < 5 || preySpotLocation(1) > (xmax - xmin + 1)-5 || preySpotLocation(2) < 5 || preySpotLocation(2) > ymax-5
                index(d) = false; %Ignore this spot if it doesn't map within the prey image or is too close to the edge
            else
                dynData.([preyChannel 'SpotData'])(d,1).spotLocation = preySpotLocation; %Add this location to the places to check for prey
            end
        end
        % Ignore spots that are too close to the edge
        dynData.([baitChannel 'SpotData']) = dynData.([baitChannel 'SpotData'])(index);
        dynData.([preyChannel 'SpotData']) = dynData.([preyChannel 'SpotData'])(index);
        [dynData.([baitChannel 'SpotCount']),~] = size(dynData.([baitChannel 'SpotData'])); %Count how many bait spots are left

        params.RegistrationData = regData; %Save Registration info


        % Pull intensity traces for the prey
        % Figure out x indices - opposite logic to the code above to get the opposite half
        if dynData.([baitChannel 'SpotCount']) > 0 %This if statement prevents crashing if no spots were found
            [ymax, xmax, tmax] = size(stackObj);
            if strcmp(params.BaitPos, 'Right')
                xmin = 1;
                xmax = xmax/2;
            elseif strcmp(params.BaitPos, 'Left')
                xmin = xmax/2 + 1;
            end
            nWindows = dynData.([baitChannel 'SpotData'])(end).appearedInWindow;
            for e = 1:nWindows
                waitbar((e-1)/nWindows,wb);
                % Load the appropriate portion of the image into memory
                if e==1
                    % The first time through the loop, we just want the first 500 frames
                    subStack = stackObj(:,xmin:xmax,1:500);
                else
                    % On subsequent iterations, shift the portion of the image in memory by 1 window
                    startTime = (e-1) * dynData.avgWindow + 451;
                    endTime = min(e * dynData.avgWindow + 450, tmax);
                    subStack = cat(3, subStack(:,:,dynData.avgWindow+1:end), stackObj(:,xmin:xmax,startTime:endTime));
                end
                index = e==cell2mat({dynData.([baitChannel 'SpotData']).appearedInWindow});
                [dynData.([preyChannel 'SpotData'])(index).appearedInWindow] = deal(e);
                dynData = extractIntensityTraces(preyChannel, subStack, params, dynData, index);
            end
        end
    end
    
    %% Detect Changepoints in the prey channel
    if strcmp(reDetect,'Re-count Changepoints') || strcmp(reReg,'Yes')
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
    if strcmp(reReg,'Yes')
        save([expDir filesep imgName '_reReg.mat'], 'dynData','params');
    else
        save([expDir filesep imgName '_greedyCoApp.mat'], 'dynData','params');
    end

end

