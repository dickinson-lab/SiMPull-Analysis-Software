% Runs the spot counting and step detection algorithms in batch mode for
% several experiments in a single folder.  The folder selected should
% contain subfolders named e.g. Exp1, Exp2, Exp3, etc., with each folder
% containing raw images from a single experiment.  The program saves the
% results of each experiment as a .mat file named Exp1.mat, Exp2.mat, etc.,
% and also creates a summary file consisting of a cell array listing the spot 
% counts from each experiment. 

% Only works if the channel information (i.e. which frames correspond to
% which channel) is the same for all images. 

% Note: The spot detection routine currently assumes a 1.49 NA TIRF 
% objective - will need to adjust code if using a different objective. 

clear all
close all


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
wavelengths.FarRed = {'633' '640' '645'};                                                   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%% Options Dialog Box using inputsdlg
Title = 'Program Options';
Options.Resize = 'on';
Options.Interpreter = 'tex';
Options.CancelButton = 'on';
Options.ApplyButton = 'off';
Options.ButtonNames = {'Continue','Cancel'}; 
Prompt = {};
Formats = {};
DefAns = struct([]);

Prompt(1,:) = {'Select folder containig data to analyze','expDir',[]};
Formats(1,1).type = 'edit';
Formats(1,1).format = 'dir';
Formats(1,1).required = 'on';
Formats(1,1).size = [0 25];
Formats(1,1).span = [1 8];
DefAns(1).expDir = [];

Prompt(2,:) = {'  Input Data Type:','dataType',[]};
Formats(2,1).type = 'list';
Formats(2,1).format = 'text';
Formats(2,1).style = 'radiobutton';
Formats(2,1).items = {'MetaMorph TIFF' 'Nikon ND2'};
Formats(2,1).size = [0 25];
Formats(2,1).span = [1 5];  
Formats(2,1).callback = @(~,~,h,~) updateEnabled(h); %UpdateEnabled is a custom function specific to this dialog box (with hard-coded values). Need to update if reformatting dialog box.
DefAns.dataType = 'MetaMorph TIFF';

Prompt(3,:) = {'Pixel size (nm)','pixelSize',[]};
Formats(2,6).type = 'edit';
Formats(2,6).format = 'integer';
Formats(2,6).limits = [1 inf];
Formats(2,6).size = [25 25];
Formats(2,6).unitsloc = 'bottomleft';
Formats(2,6).enable = 'on';
Formats(2,6).span = [1 3];
DefAns.pixelSize = 65;

Prompt(4,:) = {'Enter Channel Information',[],[]};
Formats(3,1).type = 'text';
Formats(3,1).span = [1 8];

Prompt(5,:) = {'Blue Channel','haveBlue',[]};
Formats(5,1).type = 'check';
Formats(5,1).span = [1 2];
Formats(5,1).callback = @(~,~,h,~) updateEnabled(h); %UpdateEnabled is a custom function specific to this dialog box (with hard-coded values). Need to update if reformatting dialog box.
DefAns.haveBlue = false;

Prompt(6,:) = {'Green Channel','haveGreen',[]};
Formats(5,3).type = 'check';
Formats(5,3).span = [1 2];
Formats(5,3).callback = @(~,~,h,~) updateEnabled(h); %UpdateEnabled is a custom function specific to this dialog box (with hard-coded values). Need to update if reformatting dialog box.
DefAns.haveGreen = true;

Prompt(7,:) = {'Red Channel','haveRed',[]};
Formats(5,5).type = 'check';
Formats(5,5).span = [1 2];
Formats(5,5).callback = @(~,~,h,~) updateEnabled(h); %UpdateEnabled is a custom function specific to this dialog box (with hard-coded values). Need to update if reformatting dialog box.
DefAns.haveRed = false;

Prompt(8,:) = {'Far Red Channel','haveFarRed',[]};
Formats(5,7).type = 'check';
Formats(5,7).span = [1 2];
Formats(5,7).callback = @(~,~,h,~) updateEnabled(h); %UpdateEnabled is a custom function specific to this dialog box (with hard-coded values). Need to update if reformatting dialog box.
DefAns.haveFarRed = false;

Prompt(9,:) = {'First Frame:','BlueRange1',[]};
Formats(6,1).type = 'edit';
Formats(6,1).format = 'integer';
Formats(6,1).limits = [1 inf];
Formats(6,1).size = [40 25];
Formats(6,1).unitsloc = 'bottomleft';
Formats(6,1).enable = 'off';
Formats(6,1).span = [1 2];
DefAns.BlueRange1 = 1;

Prompt(10,:) = {'First Frame:','GreenRange1',[]};
Formats(6,3).type = 'edit';
Formats(6,3).format = 'integer';
Formats(6,3).limits = [1 inf];
Formats(6,3).size = [40 25];
Formats(6,3).unitsloc = 'bottomleft';
Formats(6,3).enable = 'off';
Formats(6,3).span = [1 2];
DefAns.GreenRange1 = 1;

Prompt(11,:) = {'First Frame:','RedRange1',[]};
Formats(6,5).type = 'edit';
Formats(6,5).format = 'integer';
Formats(6,5).limits = [1 inf];
Formats(6,5).size = [40 25];
Formats(6,5).unitsloc = 'bottomleft';
Formats(6,5).enable = 'off';
Formats(6,5).span = [1 2];
DefAns.RedRange1 = 1;

Prompt(12,:) = {'First Frame:','FarRedRange1',[]};
Formats(6,7).type = 'edit';
Formats(6,7).format = 'integer';
Formats(6,7).limits = [1 inf];
Formats(6,7).size = [40 25];
Formats(6,7).unitsloc = 'bottomleft';
Formats(6,7).enable = 'off';
Formats(6,7).span = [1 2];
DefAns.FarRedRange1 = 1;

Prompt(13,:) = {'Last Frame:','BlueRange2',[]};
Formats(7,1).type = 'edit';
Formats(7,1).format = 'integer';
Formats(7,1).limits = [1 inf];
Formats(7,1).size = [40 25];
Formats(7,1).unitsloc = 'bottomleft';
Formats(7,1).enable = 'off';
Formats(7,1).span = [1 2];
DefAns.BlueRange2 = 1200;

Prompt(14,:) = {'Last Frame:','GreenRange2',[]};
Formats(7,3).type = 'edit';
Formats(7,3).format = 'integer';
Formats(7,3).limits = [1 inf];
Formats(7,3).size = [40 25];
Formats(7,3).unitsloc = 'bottomleft';
Formats(7,3).enable = 'off';
Formats(7,3).span = [1 2];
DefAns.GreenRange2 = 1200;

Prompt(15,:) = {'Last Frame:','RedRange2',[]};
Formats(7,5).type = 'edit';
Formats(7,5).format = 'integer';
Formats(7,5).limits = [1 inf];
Formats(7,5).size = [40 25];
Formats(7,5).unitsloc = 'bottomleft';
Formats(7,5).enable = 'off';
Formats(7,5).span = [1 2];
DefAns.RedRange2 = 1200;

Prompt(16,:) = {'Last Frame:','FarRedRange2',[]};
Formats(7,7).type = 'edit';
Formats(7,7).format = 'integer';
Formats(7,7).limits = [1 inf];
Formats(7,7).size = [40 25];
Formats(7,7).unitsloc = 'bottomleft';
Formats(7,7).enable = 'off';
Formats(7,7).span = [1 2];
DefAns.FarRedRange2 = 1200;

Prompt(17,:) = {'Window to average for spot detection:',[],[]};
Formats(8,1).type = 'text';
Formats(8,1).span = [1 8];

Prompt(18,:) = {' ','BlueWindow1',[]};
Formats(9,1).type = 'edit';
Formats(9,1).format = 'integer';
Formats(9,1).limits = [1 inf];
Formats(9,1).size = [25 25];
Formats(9,1).unitsloc = 'bottomleft';
Formats(9,1).enable = 'off';
Formats(9,1).span = [1 1];
DefAns.BlueWindow1 = 6;

Prompt(19,:) = {' to ','BlueWindow2',[]};
Formats(9,2).type = 'edit';
Formats(9,2).format = 'integer';
Formats(9,2).limits = [1 inf];
Formats(9,2).size = [25 25];
Formats(9,2).unitsloc = 'bottomleft';
Formats(9,2).enable = 'off';
Formats(9,2).span = [1 1];
DefAns.BlueWindow2 = 50;

Prompt(20,:) = {' ','GreenWindow1',[]};
Formats(9,3).type = 'edit';
Formats(9,3).format = 'integer';
Formats(9,3).limits = [1 inf];
Formats(9,3).size = [25 25];
Formats(9,3).unitsloc = 'bottomleft';
Formats(9,3).enable = 'on';
Formats(9,3).span = [1 1];
DefAns.GreenWindow1 = 6;

Prompt(21,:) = {' to ','GreenWindow2',[]};
Formats(9,4).type = 'edit';
Formats(9,4).format = 'integer';
Formats(9,4).limits = [1 inf];
Formats(9,4).size = [25 25];
Formats(9,4).unitsloc = 'bottomleft';
Formats(9,4).enable = 'on';
Formats(9,4).span = [1 1];
DefAns.GreenWindow2 = 50;

Prompt(22,:) = {' ','RedWindow1',[]};
Formats(9,5).type = 'edit';
Formats(9,5).format = 'integer';
Formats(9,5).limits = [1 inf];
Formats(9,5).size = [25 25];
Formats(9,5).unitsloc = 'bottomleft';
Formats(9,5).enable = 'off';
Formats(9,5).span = [1 1];
DefAns.RedWindow1 = 6;

Prompt(23,:) = {' to ','RedWindow2',[]};
Formats(9,6).type = 'edit';
Formats(9,6).format = 'integer';
Formats(9,6).limits = [1 inf];
Formats(9,6).size = [25 25];
Formats(9,6).unitsloc = 'bottomleft';
Formats(9,6).enable = 'off';
Formats(9,6).span = [1 1];
DefAns.RedWindow2 = 50;

Prompt(24,:) = {' ','FarRedWindow1',[]};
Formats(9,7).type = 'edit';
Formats(9,7).format = 'integer';
Formats(9,7).limits = [1 inf];
Formats(9,7).size = [25 25];
Formats(9,7).unitsloc = 'bottomleft';
Formats(9,7).enable = 'off';
Formats(9,7).span = [1 1];
DefAns.FarRedWindow1 = 1;

Prompt(25,:) = {' to ','FarRedWindow2',[]};
Formats(9,8).type = 'edit';
Formats(9,8).format = 'integer';
Formats(9,8).limits = [1 inf];
Formats(9,8).size = [25 25];
Formats(9,8).unitsloc = 'bottomleft';
Formats(9,8).enable = 'off';
Formats(9,8).span = [1 1];
DefAns.FarRedWindow2 = 10;

Prompt(26,:) = {'Count steps?','countBlueSteps',[]};
Formats(10,1).type = 'check';
Formats(10,1).enable = 'off';
Formats(10,1).span = [1 2];
DefAns.countBlueSteps = true;

Prompt(27,:) = {'Count steps?','countGreenSteps',[]};
Formats(10,3).type = 'check';
Formats(10,3).enable = 'on';
Formats(10,3).span = [1 2];
DefAns.countGreenSteps = true;

Prompt(28,:) = {'Count steps?','countRedSteps',[]};
Formats(10,5).type = 'check';
Formats(10,5).enable = 'off';
Formats(10,5).span = [1 2];
DefAns.countRedSteps = true;

Prompt(29,:) = {'Count steps?','countFarRedSteps',[]};
Formats(10,7).type = 'check';
Formats(10,7).enable = 'off';
Formats(10,7).span = [1 2];
DefAns.countFarRedSteps = false;

[Answer,Cancelled] = inputsdlg(Prompt,Title,Formats,DefAns,Options);
clear Prompt Title Formats DefAns Options
%%%% End of dialog box

% Check input
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

dirList = ListSubfolders(expDir);

channels = {'Blue' 'Green' 'Red' 'FarRed'};
channelsPresent = logical([haveBlue haveGreen haveRed haveFarRed]);
channels = channels(channelsPresent);
nChannels = sum(channelsPresent);

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

bigwb = waitbar(0);
for a=1:length(dirList)
    waitbar((a-1)/length(dirList),bigwb,strrep(['Analyzing Experiment ' dirList{a}],'_','\_'));
    nd2Dir = [expDir filesep dirList{a}];
    if strcmp(dataType, 'MetaMorph TIFF')
        fileList = dir([nd2Dir filesep '*.tif']);
    else
        fileList=dir([nd2Dir filesep '*.nd2']);
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
    
    
    %%% Run the spot counter %%%
    if countSpots
        % Set up 
        if strcmp(dataType, 'MetaMorph TIFF')
            nPositions = length(fileList) / nChannels;
            fileCounter = 1;
        else
            nPositions = length(fileList);
        end
        gridHeight = ceil(nPositions/gridWidth);
        gridData(1:gridHeight,1:gridWidth) = struct('nd2Dir',nd2Dir,...
                                                    'tiffDir',nd2Dir,...
                                                    'imageName',[],...
                                                    'imageSize',[]);
        index = serpind(size(gridData));

        params.psfSize = psfSize;
        params.fpExp = fpExp;
        params.poissonNoise = poissonNoise;
        params.pixelSize = pixelSize;

        %Get Images and Find Spots
        spotwb = waitbar(0, 'Finding Spots...');
        for b = 1:nPositions
            if strcmp(dataType, 'Nikon ND2') % For Nikon files, load data here.  Metamorph TIFF files are loaded for each channel individually, below
                imageName = fileList(b).name;
                rawImage = squeeze(bfread([nd2Dir filesep fileList(b).name],1,'Timepoints','all','ShowProgress',false));
                if iscell(rawImage) % bfread sometimes returns a cell array, for reasons that are unclear - check and convert if needed
                    rawImage = cat(3, thisImage{:}); 
                end
                [ymax,xmax,tmax] = size(rawImage);
                gridData(index(b)).imageSize = [ymax xmax];
                params.imageName = imageName(1:(length(imageName)-4));
                gridData(index(b)).imageName = params.imageName;
            end

            for i = 1:nChannels
                color = channels{i};
                if strcmp(dataType, 'MetaMorph TIFF') %Load MetaMorph TIFF Data
                    imageName = fileList(fileCounter).name;
                    waitbar( (b-1)/nPositions, spotwb, ['Finding ' color ' Spots in image ' strrep(imageName,'_','\_') '...'] );
                    imObj = TIFFStack([nd2Dir filesep fileList(fileCounter).name]);
                    thisImage = imObj(:,:,:);
                    %thisImage = squeeze(bfread([nd2Dir filesep fileList(fileCounter).name],1,'Timepoints','all','ShowProgress',false));
                    fileCounter = fileCounter + 1;
                    %if iscell(thisImage) % bfread sometimes returns a cell array, for reasons that are unclear - check and convert if needed
                    %    thisImage = cat(3, thisImage{:}); 
                    %end
                    [ymax,xmax,tmax] = size(thisImage);
                    gridData(index(b)).imageSize = [ymax xmax];
                    imageLength = tmax; %For MetaMorph TIFF files that are separated by wavelength, the whole timeseries will be analyzed
                    %Make sure we've loaded an image of the correct color
                    wavePos = strfind( imageName, wavelengths.(color){1} );
                    if isempty(wavePos) %If the first wavelength wasn't found, try the second (could make this a loop in the future if support for more wavelengths is needed)
                        wavePos = strfind( imageName, wavelengths.(color){2} );
                    end
                    if isempty(wavePos) 
                        errordlg('An image of the wrong channel was loaded');
                        close(bigwb);
                        close(spotwb);
                        return
                    end
                    params.imageName = imageName( 1:(wavePos-2) );
                    gridData(index(b)).imageName = params.imageName;
                end
                if strcmp(dataType, 'Nikon ND2')
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
                    thisImage = rawImage{timeRange1:min(timeRange2,tmax)};
                end
                
                % Determine the window to average over
                if imageLength <= lastTime.(color)    %If only a few frames were captured, use the whole timeseries 
                    params.firstTime = 1;
                    params.lastTime = imageLength;
                else                    %Otherwise, use the range specified above
                    if firstTime.(color) < 1 
                        params.firstTime = 1;
                    else
                        params.firstTime = firstTime.(color);
                    end
                    if lastTime.(color) > imageLength
                        params.lastTime = imageLength;
                    else
                        params.lastTime = lastTime.(color);
                    end
                end
                
                % Actually do the spot counting
                resultsStruct = spotcount_ps(color,thisImage,params,gridData(index(b)));
                gridData(index(b)).([color 'SpotData']) = resultsStruct.([color 'SpotData']);
                gridData(index(b)).([color 'SpotCount']) = resultsStruct.([color 'SpotCount']);
                clear resultsStruct;
            end

        end %of loop b; Loop over images in the data set for spot counting
        close(spotwb)

        % Calculate summary statistics and save results
        statsByColor = struct;
        for j = 1:nChannels
            color = channels{j};
            spotCount = cell(size(gridData));
            [spotCount{:}] = gridData.([color 'SpotCount']);
            spotCount = cell2mat(spotCount);
            statsByColor.(['total' color 'Spots']) = sum(sum(spotCount));
            statsByColor.(['avg' color 'Spots']) = sum(sum(spotCount)) / nPositions;
        end
        save([nd2Dir '.mat'],'gridData','nChannels', 'channels', 'nPositions', 'statsByColor');
    end % End of spot counting
    
    
    
    % Check if colocalization data exist
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
    
    
    %%% Calculate colocalization %%%
    if (nChannels > 1 && countColoc)
        for k = 1:nChannels 
            color1 = channels{k};
            [gridData, results] = coloc_spots(gridData, color1);
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
    save([nd2Dir '.mat'], 'statsByColor', 'gridData', '-append');
    
    
    
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
                     % Calculate the maximum spot density to allow for colocalization and step counting
                     imgArea = gridData(c).imageSize(1) * gridData(c).imageSize(2) * pixelSize^2;
                     maxSpots = imgArea / 3e6;  % The 3e12 factor comes from my finding that 1000 spots is approximately the max for a 512x512 EMCCD chip at 150X,
                                                % which translates to a sensor area of 3e9 square nanometers (1000 molecules / 3e9 nm^2 = 1 molecule / 3e6 nm^2)
                    
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
    
    
    %%% Add Data to the Summary Table %%%
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