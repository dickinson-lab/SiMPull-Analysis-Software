%
% Re-does image registration for a SiMPull experiment and re-calculates summary
% tables. 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function summary = batch_reRegister_static(varargin) % Typical arguments: fileList, regFile
    if nargin < 1
        matFile = uipickfiles('Prompt','Select image files to analyze and arrange them in order','Type',{'*.mat','MAT-file'});
    else
        matFile = varargin{1};
    end
    load(matFile{1});
    
    slash = strfind(matFile{1},filesep);
    expDir = matFile{1}(1:slash(end));
   
    if nargin < 2
        [Answer, Cancelled] = dvRegisterDlg(expDir);
        if Cancelled 
            return
        else
            v2struct(Answer);
        end
    end

    % Open the image file, make an average image and perform 2D registration
    regImg = TIFFStack(regFile,[],nChannels);  %Assume composite images!  Could make this more complicated later for backward compatibility
    subImg = regImg(:,:,:,RegWindow1:RegWindow2);
    avgImg = mean(subImg, 4);
    for g = 2:nChannels 
        regData(g) = registerImages( avgImg(:,:,g), avgImg(:,:,1) ); % Each channel is registered against channel 1
    end
    
    for b = 1:length(matFile)
        if b ~=1
            load(matFile{b}); %No need to load the first file since we already loaded it above
        end
        
        if exist('gridData', 'var') ~= 1
            msgbox('This script requires SiMPull data from the spot counter.');
            return
        end

        % Update registration information
        for c = 2:length(channels) %Registration doesn't change for channel 1
            color = channels{c};
            statsByColor.([color 'RegistrationData']) = regData(c);
        end
        
        % Recalculate colocalization and update summary statistics
        for a = 1:length(channels)
            color1 = channels{a};
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
        save(matFile{b}, varToSave{:}, '-append');
        summary = updateSummaryTable(matFile{b}(slash(end)+1:end), expDir, statsByColor);
    end
    msgbox('Completed Successfully');
