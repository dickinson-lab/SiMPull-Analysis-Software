%
% Re-does image registration for a SiMPull dataset and re-calculates summary
% tables. Data is passed in through (lots of) arguments to avoid overhead
% of re-loading from disk. Not intendend to be called directly - use
% redo_registration.m instead.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [gridData, statsByColor, summary] = reRegister(gridData, channels, nChannels, params, statsByColor, matPath, matFile, selection) 

    % Check for correct data type
    if nChannels < 2 
        msgBox('At least two channels are required for image registration.');
        return
    end
    color = channels{1};
    if ~isfield(statsByColor,[color 'DVposition'])
        msgBox('This dataset does not appear to contain dual-view images. Re-run analyze_batch if necessary.');
        return
    end
    
    %locate image folder
    nameIdx = strfind(matFile,'_filtered.mat');
    if ~isempty(nameIdx)
        imgPath = [matPath matFile(1:nameIdx-1)];
    else
        imgPath = [matPath filesep matFile(1:end-4)];
    end
    
    % Load selected images and re-do registration
    leftImg = [];
    rightImg = [];
    if nChannels == 2
        for c = 1:length(channels)
            color = channels{c};
            if strcmp(statsByColor.([color 'DVposition']), 'Left')
                leftImageName = [gridData(selection).imageName '_' color 'avg.tif'];
                leftImg = double(imread([imgPath filesep leftImageName]));
            elseif strcmp(statsByColor.([color 'DVposition']), 'Right')
                rightImageName = [gridData(selection).imageName '_' color 'avg.tif'];
                rightImg = double(imread([imgPath filesep rightImageName]));
            end
        end
        if isempty(leftImg) || isempty(rightImg)
            msgbox('Could not load images!');
            return
        end
    else
       msgbox('More than two channels are not supported yet.');
       return
    end
    regData = registerImages(rightImg, leftImg);

    % Recalculate colocalization and update summary statistics
    for a = 1:length(channels)
        color1 = channels{a};
        if strcmp(statsByColor.([color1 'DVposition']), 'Right')
            statsByColor.([color1 'RegistrationData']) = regData;
        end
        
        [gridData, results] = coloc_spots(gridData, statsByColor, color1, params.maxSpots); %statsByColor is included to pass registration information
        for m = 1:nChannels
            color2 = channels{m};
            if strcmp(color1, color2)
                continue
            end
            statsByColor.([color1 color2 'SpotsTested']) = results.([color1 color2 'SpotsTested']);
            statsByColor.(['pct' color1 'Coloc_w_' color2]) = 100*results.([color1 color2 'ColocSpots']) / results.([color1 color2 'SpotsTested']);
        end
    end

    % Save data
    varToSave = {'gridData', 'statsByColor'};
    save([matPath filesep matFile], varToSave{:}, '-append');
    summary = updateSummaryTable(matFile, matPath, statsByColor);
    msgbox('Completed Successfully');
