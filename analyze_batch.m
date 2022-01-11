% Runs the spot counting and step detection algorithms in batch mode for
% several experiments in a single folder.  The folder selected should
% contain subfolders named e.g. Exp1, Exp2, Exp3, etc., with each folder
% containing raw images from a single experiment.  The program saves the
% results of each experiment as a .mat file named Exp1.mat, Exp2.mat, etc.,
% and also creates a summary file consisting of a cell array listing the spot 
% counts from each experiment. 

% For Nikon ND2 files, this script only works if the channel information 
% (i.e. which frames correspond to which channel) is the same for all images. 

clear all
close all
warning off %Prevents unnecessary warnings loading TIFF files

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Adjustable parameters for spot detection are here                                         %
gridWidth = 1; % Set to 1 for a single row of images in a microfluidic channel              %
psfSize = 1;                                                                                %
fpExp = 1e-5; %Expectation value for false positive objects in probabilistic segmentation   %
poissonNoise = 0; %Set this option to 1 to account for poissionNoise in the background      %
                                                                                            %
% These parameters determine the relationship between laser wavelength and "color"          %
wavelengths.Blue = {'405' '445'};                                                           %
wavelengths.Green = {'488' '505' '514'};                                                    %
wavelengths.Red = {'561' '594'};                                                            %
wavelengths.FarRed = {'633' '638' '640' '645'};                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Options Dialog Box 
[Answer, Cancelled] = analyzeBatchDlg;

if Cancelled 
    return
elseif ~isdir(Answer.expDir)
    fprintf('No folder of input data was selected');
    return
elseif ~(Answer.haveBlue || Answer.haveGreen || Answer.haveRed || Answer.haveFarRed)
    fprintf('At least one channel must be selected');
    return
else
    v2struct(Answer);
end

%% Set Up
dirList = ListSubfolders(expDir);

channels = {'Blue' 'Green' 'Red' 'FarRed'};
channelsPresent = logical([haveBlue haveGreen haveRed haveFarRed]);
channels = channels(channelsPresent);
nChannels = sum(channelsPresent);

dv = strcmp(dataType, 'Dual-View TIFF');
dvPositions = {BlueDualViewPos GreenDualViewPos RedDualViewPos FarRedDualViewPos};
dvPositions = dvPositions(channelsPresent);

comp = strcmp(dataType, 'Composite TIFF');

firstTime.Blue = BlueWindow1; clear BlueWindow1;
firstTime.Green = GreenWindow1; clear GreenWindow1;
firstTime.Red = RedWindow1; clear RedWindow1;
firstTime.FarRed = FarRedWindow1; clear FarRedWindow1;

lastTime.Blue = BlueWindow2; clear BlueWindow2;
lastTime.Green = GreenWindow2; clear GreenWindow2;
lastTime.Red = RedWindow2; clear RedWindow2;
lastTime.FarRed = FarRedWindow2; clear FarRedWindow2;

countSteps.Blue = countBlueSteps; clear countBlueSteps;
countSteps.Green = countGreenSteps; clear countGreenSteps;
countSteps.Red = countRedSteps; clear countRedSteps;
countSteps.FarRed = countFarRedSteps; clear countFarRedSteps;

% Set up summary table
summary = cell((nChannels+1)*length(dirList), 28);
summary(1,:) = {'Experiment','Spots per Image','% Coloc w/ Blue', '% Coloc w/ Green','% Coloc w/ Red','% Coloc w/ FarRed','Traces Analyzed','% 1 step','% 2 step','% 3 step','% 4 step','% 5 step','% 6 step','% 7 step','% 8 step','% 9 step','% 10 step','% 11 step ','% 12 step','% 13 step','% 14 step','% 15 step','% 16 step','% 17 step','% 18 step','% 19 step','% 20 step','% Rejected'};
rowcounter = 2;

%% Register Dual-view images
if dv && any(strcmp(dvPositions, 'Left')) && any(strcmp(dvPositions,'Right')) % Registration is only required if the dataset has signal both left and right
    %% Decide whether to use existing registration or do a new one
    useExistingReg = false;
    % Check if data have already been analyzed and if so, whether registration data exist
    if exist([expDir filesep dirList{1} '.mat'], 'file')
        existing = load([expDir filesep dirList{1} '.mat'], 'statsByColor');
        if any(cell2mat(regexp(fieldnames(existing.statsByColor),'RegistrationData')))
            %Ask the user whether to re-register or use existing
            ans1 = questdlg('Image registration data appear to already exist for this dataset. What do you want to do?',...
                            'Found Existing Registration',...   %Title
                            'Do new registration',...           %Option 1
                            'Use existing',...                  %Option 2
                            'Use existing');                    %Default
            if strcmp(ans1,'Use existing')
                useExistingReg = true;
            end
        end
    end
    
    %% Proceed with new image registration 
    if ~useExistingReg
        % Dialog box
        [Answer,Cancelled] = dvRegisterDlg(expDir);
        if Cancelled 
            return
        else
            v2struct(Answer);
        end

        % Open the image file, make an average image and perform 2D registration
        regImg = TIFFStack(regFile);
        subImg = regImg(:,:,RegWindow1:RegWindow2);
        avgImg = mean(subImg, 3);
        [ymax, xmax] = size(avgImg);
        leftImg = avgImg(:,1:(xmax/2));
        rightImg = avgImg(:,(xmax/2)+1:xmax);
        regData = registerImages(rightImg, leftImg);
        % We don't save the registration info here because it's saved as part of each individual file below.  
        % Instead we just hang on to the regData variable for later use.
    end
end

%% Register Composite images
if comp
    %% Decide whether to use existing registration or do a new one
    useExistingReg = false;
    % Check if data have already been analyzed and if so, whether registration data exist
    if exist([expDir filesep dirList{1} '.mat'], 'file')
        existing = load([expDir filesep dirList{1} '.mat'], 'statsByColor');
        if any(cell2mat(regexp(fieldnames(existing.statsByColor),'RegistrationData')))
            %Ask the user whether to re-register or use existing
            ans1 = questdlg('Image registration data appear to already exist for this dataset. What do you want to do?',...
                            'Found Existing Registration',...   %Title
                            'Do new registration',...           %Option 1
                            'Use existing',...                  %Option 2
                            'Use existing');                    %Default
            if strcmp(ans1,'Use existing')
                useExistingReg = true;
            end
        end
    end
    
    %% Proceed with new image registration 
    if ~useExistingReg
        % Ask user if registration is required
        ans2 = questdlg('Do your images require registration?',...
                        'Image registration?',...   %Title
                        'Yes','No','Yes');          %Options
        if strcmp(ans2,'Yes') 
            % Dialog box
            [Answer,Cancelled] = dvRegisterDlg(expDir);
            if Cancelled 
                return
            else
                v2struct(Answer);
            end
    
            % Open the image file, make an average image and perform 2D registration
            regImg = TIFFStack(regFile,[],nChannels);
            subImg = regImg(:,:,:,RegWindow1:RegWindow2);
            avgImg = mean(subImg, 4);
            for g = 2:nChannels 
                regData(g) = registerImages( avgImg(:,:,g), avgImg(:,:,1) ); % Each channel is registered against channel 1
            end
            % We don't save the registration info here because it's saved as part of each individual file below.  
            % Instead we just hang on to the regData variable for later use.
        end
    end
end

%% Loop over all folders in the data set (each corresponds to one experiment)
bigwb = waitbar(0);
for a=1:length(dirList)
    waitbar((a-1)/length(dirList),bigwb,strrep(['Analyzing Experiment ' dirList{a}],'_','\_'));
    nd2Dir = [expDir filesep dirList{a}];
    if strcmp(dataType, 'Nikon ND2')
        fileList=dir([nd2Dir filesep '*.nd2']);
    else
        fileList = dir([nd2Dir filesep '*.tif']);
    end
    if isempty(fileList)
        continue
    end
    
    %Prevents the program from trying to analyze average images from a previous analysis
    fileIdx = arrayfun(@(x) isempty(strfind(x.name, 'avg.tif')), fileList);
    fileList = fileList(fileIdx);
    
    countSpots = true;
    countColoc = true;
    countSteps.any = true;
    
    %If the data have already been analyzed, ask the user whether to keep the existing data
    if exist([expDir filesep dirList{a} '.mat'], 'file')
        if exist('rememOverwriteSpots','var')
            overwriteSpots = rememOverwriteSpots;
        else
            %Dialog Box
            Title = 'Overwrte Data?';
            Options.Resize = 'on';
            Options.Interpreter = 'tex';
            Options.CancelButton = 'on';
            Options.ApplyButton = 'off';
            Options.ButtonNames = {'Continue','Cancel'}; 
            Prompt = {};
            Formats = {};
            DefAns = struct([]);
            
            Prompt(1,:) = {strrep(['Spot count data already exist for experiment ' dirList{a} '. How do you want to proceed?'],'_','\_'),[],[]};
            Formats(1,1).type = 'text';
            Formats(1,1).size = [0 25];
            
            Prompt(2,:) = {'','overwriteSpots',[]};
            Formats(2,1).type = 'list';
            Formats(2,1).format = 'text';
            Formats(2,1).style = 'radiobutton';
            Formats(2,1).items = {'Skip this Experiment' 'Use spot data for other analyses' 'Count again and overwrite data'};
            Formats(2,1).size = [0 25];
            DefAns(1).overwriteSpots = 'Count again and overwrite data';
            
            Prompt(3,:) = {'Remember this selection for all experiments in this dataset','remember',[]};
            Formats(3,1).type = 'check';
            DefAns.remember = false;

            [Answer,Cancelled] = inputsdlg(Prompt,Title,Formats,DefAns,Options);
            clear Prompt Title Formats DefAns Options
            %%%% End of dialog box

            % Check input
            if Cancelled 
                return
            else
                v2struct(Answer);
            end
            
            if remember
                rememOverwriteSpots = overwriteSpots;
            end
        end
        
        if strcmp(overwriteSpots,'Skip this Experiment')
            load([expDir filesep dirList{a} '.mat']);
            countSpots = false;
            countColoc = false;
            countSteps.any = false;
        elseif strcmp(overwriteSpots,'Use spot data for other analyses')
            load([expDir filesep dirList{a} '.mat']);
            countSpots = false;
        end
    end
    
    
    %%  Run the spot counter %%
    if countSpots
        %% Set up
        % Figure out how many stage positions we have
        if strcmp(dataType, 'Nikon ND2') || strcmp(dataType, 'Composite TIFF')
            nPositions = length(fileList);
        else
            posNames = cellfun(@(x) regexp(x,'_?[0-9\-]+.tif','split'), {fileList.name}, 'UniformOutput', false); %The regexp finds the wavelength designator at the end of each file name
            posNames = unique(cellfun(@(x) x{1}, posNames, 'UniformOutput', false));
            nPositions = length(posNames);
        end
        
        % Initialize the gridData structure that will hold the results
        gridHeight = ceil(nPositions/gridWidth);
        gridData(1:gridHeight,1:gridWidth) = struct('nd2Dir',nd2Dir,...
                                                    'tiffDir',nd2Dir,...
                                                    'imageName',[],...
                                                    'imageSize',[],...
                                                    'excludedRegions',{{'None'}},...
                                                    'regionsOfInterest', {{'All'}});
        index = serpind(size(gridData));
        %Put parameter values in the params structure
        params.psfSize = psfSize;
        params.fpExp = fpExp;
        params.poissonNoise = poissonNoise;
        params.pixelSize = pixelSize;

        %Get Images
        spotwb = waitbar(0, 'Finding Spots...');
        
        %% This section is for Nikon files %%
        if strcmp(dataType, 'Nikon ND2') 
            %% Loop through each image (state position) in the dataset
            for b = 1:nPositions
                imageName = fileList(b).name;
                rawImage = squeeze(bfread([nd2Dir filesep fileList(b).name],1,'Timepoints','all','ShowProgress',false));
                if iscell(rawImage) % bfread sometimes returns a cell array, for reasons that are unclear - check and convert if needed
                    rawImage = cat(3, rawImage{:}); 
                end
                [ymax,xmax,tmax] = size(rawImage);
                gridData(index(b)).imageSize = [ymax xmax];
                params.imageName = imageName(1:(length(imageName)-4));
                gridData(index(b)).imageName = params.imageName;
                
                %% Perform spot counting for each channel of this image
                for i = 1:nChannels 
                    color = channels{i};                    
                    waitbar( (b-1)/nPositions, spotwb, ['Finding ' color ' Spots in image ' strrep(imageName,'_','\_') '...'] );
 
                    % Check that the selected range of times is present in the data (only required for Nikon ND2 files)
                    timeRange1 = Answer.([color 'Range1']);
                    timeRange2 = Answer.([color 'Range2']);
                    if timeRange2 > tmax
                        warning(['The time range entered for the green channel is outside the limits of the data for image' strrep(imageName,'_','\_')]);
                        imageLength = tmax + 1 - timeRange1;
                    else
                        imageLength = timeRange2 + 1 - timeRange1;
                    end

                    % Grab the appropriate portion of the image
                    thisImage = rawImage(:,:, timeRange1:min(timeRange2,tmax)  );

                    % Generate average image for spot counting
                    params.firstTime = firstTime.(color);
                    params.lastTime = lastTime.(color);
                    avgImage = averageImage(thisImage, color, params);
                    %Save average image for later reference
                    imwrite(avgImage,[nd2Dir filesep params.imageName '_' color 'avg.tif'],'tiff');
                    
                    % Actually do the spot counting
                    gridData = spotcount_ps(color, avgImage, params, gridData, index(b));
                    
                    % Extract and save intensity traces for found spots
                    gridData(index(b)) = extractIntensityTraces(color, thisImage, params, gridData(index(b)));
                    
                end %Loop i over channels
                
            end %Loop b over images 
        
        elseif strcmp(dataType, 'Composite TIFF')
        %% This section is for composite TIFF files %%    
            %% Loop through each image (state position) in the dataset
            for b = 1:nPositions
                imageName = fileList(b).name;
                % Load Image
                imObj = TIFFStack([nd2Dir filesep fileList(b).name],[],nChannels);
                [ymax,xmax,~,tmax] = size(imObj);
                gridData(index(b)).imageSize = [ymax xmax];
                params.imageName = imageName(1:(length(imageName)-4));
                gridData(index(b)).imageName = params.imageName;
                
                %% Perform spot counting for each channel of this image
                for i = 1:nChannels 
                    color = channels{i};                    
                    waitbar( (b-1)/nPositions, spotwb, ['Finding ' color ' Spots in image ' strrep(imageName,'_','\_') '...'] );
                    
                    % Load the appropriate portion of the image into memory
                    thisImage = squeeze(imObj(:,:,i,:));

                    % Generate average image for spot counting
                    params.firstTime = firstTime.(color);
                    params.lastTime = lastTime.(color);
                    avgImage = averageImage(thisImage, color, params);
                    %Save average image for later reference
                    imwrite(avgImage,[nd2Dir filesep params.imageName '_' color 'avg.tif'],'tiff');
                    
                    % Actually do the spot counting
                    gridData = spotcount_ps(color, avgImage, params, gridData, index(b));
                    
                    % Extract and save intensity traces for found spots
                    gridData(index(b)) = extractIntensityTraces(color, thisImage, params, gridData(index(b)));
                    
                end %Loop i over channels
            end %Loop b over images 

        else 
        %% This section is for single-channel and dual-view TIFF files %%
            %% Loop over Channels first
            for i = 1:nChannels
                %Figure out which files we need to load
                color = channels{i};
                colorIndex = false(1,length(fileList));
                for r = 1:length(wavelengths.(color))
                    ptrn = ['_[\d-]*' wavelengths.(color){r} '[\d-]*\.tif$'];
                    colorIndex = colorIndex | ~cellfun(@isempty, regexp({fileList.name}, ptrn)); 
                end
                imagesOfThisColor = fileList(colorIndex);
                
                %% Perform spot counting for each image
                for b = 1:length(imagesOfThisColor)
                                        
                    % Get position name
                    imageName = imagesOfThisColor(b).name;
                    posName = regexp(imageName, '(\S+)_[0-9\-]+.tif','tokens');
                    posName = posName{1}{1};
                    params.imageName = posName;
                    gridData(index(b)).imageName = params.imageName;
                    
                    % Load Image
                    waitbar( ( (i-1)*nPositions + (b-1) ) / (nChannels*nPositions), spotwb, ['Finding ' color ' Spots in image ' strrep(imageName,'_','\_') '...'] );
                    imObj = TIFFStack([nd2Dir filesep imagesOfThisColor(b).name]);
                    [~,xmax,~] = size(imObj);
                    if dv %For dual-view images, load just the half of the image we want to analyze
                        if strcmp(dvPositions{i}, 'Left')
                            thisImage = imObj(:,1:xmax/2,:);
                        else
                            thisImage = imObj(:,(xmax/2)+1:xmax,:);
                        end
                    else %For single-channel images, load the whole thing
                        thisImage = imObj(:,:,:);
                    end
                    [ymax,xmax,tmax] = size(thisImage);
                    gridData(index(b)).imageSize = [ymax xmax];
                    
                    % Generate average image for spot counting
                    params.firstTime = firstTime.(color);
                    params.lastTime = lastTime.(color);
                    avgImage = averageImage(thisImage, color, params);
                    %Save average image for later reference
                    imwrite(avgImage,[nd2Dir filesep params.imageName '_' color 'avg.tif'],'tiff');
                    
                    % Actually do the spot counting
                    gridData = spotcount_ps(color, avgImage, params, gridData, index(b));
                    
                    % Extract and save intensity traces for found spots
                    gridData(index(b)) = extractIntensityTraces(color, thisImage, params, gridData(index(b)));
                    
                end % Loop b over images
                
            end % Loop i over channels
            
        end % If statement for data type
        close(spotwb)

        %% Calculate summary statistics and save results
        statsByColor = struct;
        for j = 1:nChannels
            color = channels{j};
            spotCount = cell(size(gridData));
            [spotCount{:}] = gridData.([color 'SpotCount']);
            spotCount = cell2mat(spotCount);
            statsByColor.(['total' color 'Spots']) = sum(sum(spotCount));
            statsByColor.(['avg' color 'Spots']) = sum(sum(spotCount)) / nPositions;
            if dv
                statsByColor.([color 'DVposition']) = dvPositions{j};
                if useExistingReg
                    % If we're going to use existing registration data, load and copy it
                    % Note: This step will fail if the first sample in the dataset had registration data that the user asked to
                    % reuse, but registration data is missing for other samples. However, that would only happen if the user 
                    % has done something very strange. 
                    existing = load([expDir filesep dirList{a} '.mat'], 'statsByColor');
                    statsByColor.([color 'RegistrationData']) = existing.statsByColor.([color 'RegistrationData']);
                elseif strcmp(dvPositions{j}, 'Right') && exist('regData','var')
                    % Or if we did registration above, save this new registration info
                    statsByColor.([color 'RegistrationData']) = regData;
                else
                    % Otherwise, create an empty registration structure (this also applies to the fixed (left) image)
                    statsByColor.([color 'RegistrationData']) = struct('Transformation', affine2d,...
                                                                       'RegisteredImage',[],...
                                                                       'SpatialRefObj',imref2d([ymax xmax]));
                end
            elseif comp
                if useExistingReg
                    % If we're going to use existing registration data, load and copy it
                    % Note: This step will fail if the first sample in the dataset had registration data that the user asked to
                    % reuse, but registration data is missing for other samples. However, that would only happen if the user 
                    % has done something very strange. 
                    existing = load([expDir filesep dirList{a} '.mat'], 'statsByColor');
                    statsByColor.([color 'RegistrationData']) = existing.statsByColor.([color 'RegistrationData']);
                elseif exist('regData','var') && j ~= 1 
                    % Or if we did registration above, save this new registration info
                    statsByColor.([color 'RegistrationData']) = regData(j);
                else
                    % Otherwise, create an empty registration structure (this also applies to the fixed (first) image)
                    statsByColor.([color 'RegistrationData']) = struct('Transformation', affine2d,...
                                                                       'RegisteredImage',[],...
                                                                       'SpatialRefObj',imref2d([ymax xmax]));
                end
            end
        end
        save([nd2Dir '.mat'],'gridData','nChannels', 'channels', 'nPositions', 'statsByColor', 'params');
    end % End of spot counting
    
    %% Colocalization Analysis
    
    %Check if colocalization data exist
    if (nChannels > 1 && countColoc)
        if ( ~isempty(cell2mat(strfind(fieldnames(statsByColor), 'Coloc'))) )
            if exist('rememOverwriteColoc','var')
                overwriteColoc = rememOverwriteColoc;
            else
                %Dialog Box
                Title = 'Overwrte Data?';
                Options.Resize = 'on';
                Options.Interpreter = 'tex';
                Options.CancelButton = 'on';
                Options.ApplyButton = 'off';
                Options.ButtonNames = {'Continue','Cancel'}; 
                Prompt = {};
                Formats = {};
                DefAns = struct([]);

                Prompt(1,:) = {strrep(['Colocalization data already exist for experiment ' dirList{a} '. How do you want to proceed?'],'_','\_'),[],[]};
                Formats(1,1).type = 'text';
                Formats(1,1).size = [0 25];

                Prompt(2,:) = {'','overwriteColoc',[]};
                Formats(2,1).type = 'list';
                Formats(2,1).format = 'text';
                Formats(2,1).style = 'radiobutton';
                Formats(2,1).items = {'Skip colocalization' 'Analyze again and overwrite data'};
                Formats(2,1).size = [0 25];
                DefAns(1).overwriteColoc = 'Skip colocalization';

                Prompt(3,:) = {'Remember this selection for all experiments in this dataset','remember',[]};
                Formats(3,1).type = 'check';
                DefAns.remember = false;

                [Answer,Cancelled] = inputsdlg(Prompt,Title,Formats,DefAns,Options);
                clear Prompt Title Formats DefAns Options
                %%%% End of dialog box

                % Check input
                if Cancelled 
                    return
                else
                    v2struct(Answer);
                end

                if remember
                    rememOverwriteColoc = overwriteColoc;
                end
            end            
            
            if strcmp(overwriteColoc,'Skip colocalization')
                countColoc = false;
            end
        end
    end
    
 
    % Calculate the maximum spot density to allow for colocalization and step counting
    imgArea = gridData(1).imageSize(1) * gridData(1).imageSize(2) * pixelSize^2;
    maxSpots = imgArea / 3e6;  % The 3e6 factor comes from my experimental finding that 1000 spots is approximately the max for a 512x512 EMCCD chip at
                               % 150X,which translates to a sensor area of 3e9 square nanometers (1000 molecules / 3e9 nm^2 = 1 molecule / 3e6 nm^2).
                               % Note that this calculation assumes a 1.49 NA TIRF objective and doesn't account for possible differences in
                               % optical resolution between setups - I may wish to do something more sophisticated in the future. 
    params.maxSpots = maxSpots;
                               
    %%% Calculate colocalization %%%
    if (nChannels > 1 && countColoc)
        for k = 1:nChannels 
            color1 = channels{k};
            [gridData, results] = coloc_spots(gridData, statsByColor, color1, maxSpots); %statsByColor is included to pass registration information
            for m = 1:nChannels
                color2 = channels{m};
                if strcmp(color1, color2)
                    continue
                end
                statsByColor.([color1 color2 'SpotsTested']) = results.([color1 color2 'SpotsTested']);
                statsByColor.(['pct' color1 'Coloc_w_' color2]) = 100*results.([color1 color2 'ColocSpots']) / results.([color1 color2 'SpotsTested']);
            end
        end
    end
    save([nd2Dir '.mat'], 'statsByColor', 'gridData', 'params', '-append');
    
    
    %% Photobleaching Analysis
    %Check if step count data already exist
    if countSteps.any
        if ( ~isempty(cell2mat(strfind(fieldnames(statsByColor), 'StepHist'))) )             
            if exist('rememOverwriteSteps','var')
                overwriteSteps = rememOverwriteSteps;
            else
                %Dialog Box
                Title = 'Overwrte Data?';
                Options.Resize = 'on';
                Options.Interpreter = 'tex';
                Options.CancelButton = 'on';
                Options.ApplyButton = 'off';
                Options.ButtonNames = {'Continue','Cancel'}; 
                Prompt = {};
                Formats = {};
                DefAns = struct([]);

                Prompt(1,:) = {strrep(['Photobleaching step data already exist for experiment ' dirList{a} '. How do you want to proceed?'],'_','\_'),[],[]};
                Formats(1,1).type = 'text';
                Formats(1,1).size = [0 25];

                Prompt(2,:) = {'','overwriteSteps',[]};
                Formats(2,1).type = 'list';
                Formats(2,1).format = 'text';
                Formats(2,1).style = 'radiobutton';
                Formats(2,1).items = {'Skip step counting' 'Analyze again and overwrite data'};
                Formats(2,1).size = [0 25];
                DefAns(1).overwriteSteps = 'Skip step counting';

                Prompt(3,:) = {'Remember this selection for all experiments in this dataset','remember',[]};
                Formats(3,1).type = 'check';
                DefAns.remember = false;

                [Answer,Cancelled] = inputsdlg(Prompt,Title,Formats,DefAns,Options);
                clear Prompt Title Formats DefAns Options
                %%%% End of dialog box

                % Check input
                if Cancelled 
                    return
                else
                    v2struct(Answer);
                end

                if remember
                    rememOverwriteSteps = overwriteSteps;
                end
            end
            
            if strcmp(overwriteSteps,'Skip step counting')
                countSteps.any = false;
            end
        end
    end
    
    %%% Run the step counter %%%
    
    if countSteps.any
        for p = 1:nChannels
            color = channels{p};
            if countSteps.(color)
                statsByColor.([color 'BadSpots']) = 0;
                statsByColor.([color 'TracesAnalyzed']) = 0;
                statsByColor.([color 'StepHist']) = zeros(20,1);
                allTraces = [];
                allStepCounts = []; 
                [ gridData.([color 'StepDist']) ] = deal(zeros(20,1));  %Will contain the number of trajectories with a given number of steps

                wbg = waitbar(0, ['Counting Steps in ' color ' Traces...'] );
                for c = 1:nPositions
                                                
                    %Skip this image if it has too many spots
                    if gridData(c).([color 'SpotCount']) > maxSpots
                        gridData(c).([color 'GoodSpotCount']) = 'Too Many Spots to Analyze';
                        waitbar(c/nPositions,wbg);
                        continue
                    end

                    %Add necessary fields to store the data
                    [gridData(c).([color 'SpotData']).nSteps] = deal(0);
                    gridData(c).([color 'SpotData'])(1).changepoints = [];
                    gridData(c).([color 'SpotData'])(1).steplevels = [];

                    %Analyze the Data
                    spots = gridData(c).([color 'SpotCount']);
                    gridData(c) = count_steps_c(gridData(c), color);
                    counts = {gridData(c).([color 'SpotData']).nSteps};
                    nosteps = cellfun(@(x) any(x(:)==0),counts);
                    rejected = strcmp(counts,'Rejected');
                    badspots = sum(rejected) + sum(nosteps);
                    gridData(c).([color 'GoodSpotCount']) = spots - badspots;

                    %Tabulate the spot counts
                    statsByColor.([color 'BadSpots']) = statsByColor.([color 'BadSpots']) + badspots;
                    statsByColor.([color 'TracesAnalyzed']) = statsByColor.([color 'TracesAnalyzed']) + gridData(c).([color 'SpotCount']);
                    statsByColor.([color 'StepHist'])(1:length(gridData(c).([color 'StepDist']))) = statsByColor.([color 'StepHist'])(1:length(gridData(c).([color 'StepDist']))) + gridData(c).([color 'StepDist']);

                    waitbar(c/nPositions,wbg);
                end
                statsByColor.([color 'StepHist']) = statsByColor.([color 'StepHist'])';
                close(wbg)
            end
        end
        save([nd2Dir '.mat'], 'gridData', 'statsByColor', '-append');
    end
    
    
    %% Add Data to the Summary Table %%
    for q = 1:nChannels 
        color = channels{q};
        summary{rowcounter, 1} = [dirList{a} ' ' color];
        summary{rowcounter, 2} = statsByColor.(['avg' color 'Spots']);
        if isfield(statsByColor, ['pct' color 'Coloc_w_Blue'])
            summary{rowcounter, 3} = statsByColor.(['pct' color 'Coloc_w_Blue']);
        else
            summary{rowcounter, 3} = '-';
        end
        if isfield(statsByColor, ['pct' color 'Coloc_w_Green'])
            summary{rowcounter, 4} = statsByColor.(['pct' color 'Coloc_w_Green']);
        else
            summary{rowcounter, 4} = '-';
        end
        if isfield(statsByColor, ['pct' color 'Coloc_w_Red'])
            summary{rowcounter, 5} = statsByColor.(['pct' color 'Coloc_w_Red']);
        else
            summary{rowcounter, 5} = '-';
        end
        if isfield(statsByColor, ['pct' color 'Coloc_w_FarRed'])
            summary{rowcounter, 6} = statsByColor.(['pct' color 'Coloc_w_FarRed']);
        else
            summary{rowcounter, 6} = '-';
        end
        if isfield(statsByColor, [color 'StepHist'])
            summary{rowcounter, 7} = statsByColor.([color 'TracesAnalyzed']);
            summary(rowcounter, 8:27) = num2cell( 100 * statsByColor.([color 'StepHist'])' / statsByColor.([color 'TracesAnalyzed']) );
            summary{rowcounter, 28} = 100 * statsByColor.([color 'BadSpots']) / statsByColor.([color 'TracesAnalyzed']);
        else
            [summary{rowcounter, 7:28}] = deal('-');
        end
        rowcounter = rowcounter + 1;
    end
    
    rowcounter = rowcounter + 1; %Leaves a blank row between samples for easier readability
    clear statsByColor gridData
end %of loop a; looping over experiments
close(bigwb);

%% Clean up and Save
% Condense summary table by removing empty columns
emptyColumns = [];
cellfind = @(string)(@(cell_contents)(strcmp(string,cell_contents)));
for f = 3:6
    slashCells = cellfun(cellfind('-'),summary(2:end,f));
    blankCells = cellfun(@(x) isempty(x), summary(2:end,f));
    emptyCells = slashCells | blankCells;
    if min(emptyCells) == 1 
        emptyColumns(end+1) = f;
    end
end
for g = 8:27
    emptyCells = logical(cellfun(cellfind('-'),summary(2:end,g)));
    column = summary(2:end,g);
    column = cell2mat(column(~emptyCells));
    if max(column) == 0
        emptyColumns(end+1) = g;
    end
end
summary(:,emptyColumns) = [];

% Save summary table
slash = strfind(expDir,filesep);
expName = expDir(slash(end)+1:end);
save([expDir filesep expName '_summary.mat'],'summary');

% Clear variables, keeping only summary table
clearvars -except summary