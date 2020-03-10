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


%% Options Dialog Box using inputsdlg %%
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
Formats(2,1).items = {'Single-Channel TIFF' 'Dual-View TIFF' 'Nikon ND2'};
Formats(2,1).size = [0 40];
Formats(2,1).span = [1 5];  
Formats(2,1).callback = @(~,~,h,~) updateEnabled(h); %UpdateEnabled is a custom function specific to this dialog box (with hard-coded values). Need to update if reformatting dialog box.
DefAns.dataType = 'Single-Channel TIFF';

Prompt(3,:) = {'Pixel size (nm)','pixelSize',[]};
Formats(2,6).type = 'edit';
Formats(2,6).format = 'integer';
Formats(2,6).limits = [1 inf];
Formats(2,6).size = [25 25];
Formats(2,6).unitsloc = 'bottomleft';
Formats(2,6).enable = 'on';
Formats(2,6).span = [1 3];
DefAns.pixelSize = 110;

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

Prompt(9,:) = {'Dual-View Position:', [],[]};
Formats(6,1).type = 'text';
Formats(6,1).span = [1 2];

Prompt(10,:) = {'Dual-View Position:', [],[]};
Formats(6,3).type = 'text';
Formats(6,3).span = [1 2];

Prompt(11,:) = {'Dual-View Position:', [],[]};
Formats(6,5).type = 'text';
Formats(6,5).span = [1 2];

Prompt(12,:) = {'Dual-View Position:', [],[]};
Formats(6,7).type = 'text';
Formats(6,7).span = [1 2];

Prompt(13,:) = {[], 'BlueDualViewPos',[]};
Formats(7,1).type = 'list';
Formats(7,1).format = 'text';
Formats(7,1).style = 'radiobutton';
Formats(7,1).items = {'Left' 'Right'};
Formats(7,1).enable = 'off';
Formats(7,1).span = [1 2];
DefAns.BlueDualViewPos = 'Left';

Prompt(14,:) = {[], 'GreenDualViewPos',[]};
Formats(7,3).type = 'list';
Formats(7,3).format = 'text';
Formats(7,3).style = 'radiobutton';
Formats(7,3).items = {'Left' 'Right'};
Formats(7,3).enable = 'off';
Formats(7,3).span = [1 2];
DefAns.GreenDualViewPos = 'Left';

Prompt(15,:) = {[], 'RedDualViewPos',[]};
Formats(7,5).type = 'list';
Formats(7,5).format = 'text';
Formats(7,5).style = 'radiobutton';
Formats(7,5).items = {'Left' 'Right'};
Formats(7,5).enable = 'off';
Formats(7,5).span = [1 2];
DefAns.RedDualViewPos = 'Right';

Prompt(16,:) = {[], 'FarRedDualViewPos',[]};
Formats(7,7).type = 'list';
Formats(7,7).format = 'text';
Formats(7,7).style = 'radiobutton';
Formats(7,7).items = {'Left' 'Right'};
Formats(7,7).enable = 'off';
Formats(7,7).span = [1 2];
DefAns.FarRedDualViewPos = 'Right';

Prompt(17,:) = {'First Frame:','BlueRange1',[]};
Formats(8,1).type = 'edit';
Formats(8,1).format = 'integer';
Formats(8,1).limits = [1 inf];
Formats(8,1).size = [40 25];
Formats(8,1).unitsloc = 'bottomleft';
Formats(8,1).enable = 'off';
Formats(8,1).span = [1 2];
DefAns.BlueRange1 = 1;

Prompt(18,:) = {'First Frame:','GreenRange1',[]};
Formats(8,3).type = 'edit';
Formats(8,3).format = 'integer';
Formats(8,3).limits = [1 inf];
Formats(8,3).size = [40 25];
Formats(8,3).unitsloc = 'bottomleft';
Formats(8,3).enable = 'off';
Formats(8,3).span = [1 2];
DefAns.GreenRange1 = 1;

Prompt(19,:) = {'First Frame:','RedRange1',[]};
Formats(8,5).type = 'edit';
Formats(8,5).format = 'integer';
Formats(8,5).limits = [1 inf];
Formats(8,5).size = [40 25];
Formats(8,5).unitsloc = 'bottomleft';
Formats(8,5).enable = 'off';
Formats(8,5).span = [1 2];
DefAns.RedRange1 = 1;

Prompt(20,:) = {'First Frame:','FarRedRange1',[]};
Formats(8,7).type = 'edit';
Formats(8,7).format = 'integer';
Formats(8,7).limits = [1 inf];
Formats(8,7).size = [40 25];
Formats(8,7).unitsloc = 'bottomleft';
Formats(8,7).enable = 'off';
Formats(8,7).span = [1 2];
DefAns.FarRedRange1 = 1;

Prompt(21,:) = {'Last Frame:','BlueRange2',[]};
Formats(9,1).type = 'edit';
Formats(9,1).format = 'integer';
Formats(9,1).limits = [1 inf];
Formats(9,1).size = [40 25];
Formats(9,1).unitsloc = 'bottomleft';
Formats(9,1).enable = 'off';
Formats(9,1).span = [1 2];
DefAns.BlueRange2 = 1200;

Prompt(22,:) = {'Last Frame:','GreenRange2',[]};
Formats(9,3).type = 'edit';
Formats(9,3).format = 'integer';
Formats(9,3).limits = [1 inf];
Formats(9,3).size = [40 25];
Formats(9,3).unitsloc = 'bottomleft';
Formats(9,3).enable = 'off';
Formats(9,3).span = [1 2];
DefAns.GreenRange2 = 1200;

Prompt(23,:) = {'Last Frame:','RedRange2',[]};
Formats(9,5).type = 'edit';
Formats(9,5).format = 'integer';
Formats(9,5).limits = [1 inf];
Formats(9,5).size = [40 25];
Formats(9,5).unitsloc = 'bottomleft';
Formats(9,5).enable = 'off';
Formats(9,5).span = [1 2];
DefAns.RedRange2 = 1200;

Prompt(24,:) = {'Last Frame:','FarRedRange2',[]};
Formats(9,7).type = 'edit';
Formats(9,7).format = 'integer';
Formats(9,7).limits = [1 inf];
Formats(9,7).size = [40 25];
Formats(9,7).unitsloc = 'bottomleft';
Formats(9,7).enable = 'off';
Formats(9,7).span = [1 2];
DefAns.FarRedRange2 = 1200;

Prompt(25,:) = {'Frames to average for spot detection:',[],[]};
Formats(10,1).type = 'text';
Formats(10,1).span = [1 8];

Prompt(26,:) = {' ','BlueWindow1',[]};
Formats(11,1).type = 'edit';
Formats(11,1).format = 'integer';
Formats(11,1).limits = [1 inf];
Formats(11,1).size = [25 25];
Formats(11,1).unitsloc = 'bottomleft';
Formats(11,1).enable = 'off';
Formats(11,1).span = [1 1];
DefAns.BlueWindow1 = 6;

Prompt(27,:) = {' to ','BlueWindow2',[]};
Formats(11,2).type = 'edit';
Formats(11,2).format = 'integer';
Formats(11,2).limits = [1 inf];
Formats(11,2).size = [25 25];
Formats(11,2).unitsloc = 'bottomleft';
Formats(11,2).enable = 'off';
Formats(11,2).span = [1 1];
DefAns.BlueWindow2 = 50;

Prompt(28,:) = {' ','GreenWindow1',[]};
Formats(11,3).type = 'edit';
Formats(11,3).format = 'integer';
Formats(11,3).limits = [1 inf];
Formats(11,3).size = [25 25];
Formats(11,3).unitsloc = 'bottomleft';
Formats(11,3).enable = 'on';
Formats(11,3).span = [1 1];
DefAns.GreenWindow1 = 6;

Prompt(29,:) = {' to ','GreenWindow2',[]};
Formats(11,4).type = 'edit';
Formats(11,4).format = 'integer';
Formats(11,4).limits = [1 inf];
Formats(11,4).size = [25 25];
Formats(11,4).unitsloc = 'bottomleft';
Formats(11,4).enable = 'on';
Formats(11,4).span = [1 1];
DefAns.GreenWindow2 = 50;

Prompt(30,:) = {' ','RedWindow1',[]};
Formats(11,5).type = 'edit';
Formats(11,5).format = 'integer';
Formats(11,5).limits = [1 inf];
Formats(11,5).size = [25 25];
Formats(11,5).unitsloc = 'bottomleft';
Formats(11,5).enable = 'off';
Formats(11,5).span = [1 1];
DefAns.RedWindow1 = 6;

Prompt(31,:) = {' to ','RedWindow2',[]};
Formats(11,6).type = 'edit';
Formats(11,6).format = 'integer';
Formats(11,6).limits = [1 inf];
Formats(11,6).size = [25 25];
Formats(11,6).unitsloc = 'bottomleft';
Formats(11,6).enable = 'off';
Formats(11,6).span = [1 1];
DefAns.RedWindow2 = 50;

Prompt(32,:) = {' ','FarRedWindow1',[]};
Formats(11,7).type = 'edit';
Formats(11,7).format = 'integer';
Formats(11,7).limits = [1 inf];
Formats(11,7).size = [25 25];
Formats(11,7).unitsloc = 'bottomleft';
Formats(11,7).enable = 'off';
Formats(11,7).span = [1 1];
DefAns.FarRedWindow1 = 6;

Prompt(33,:) = {' to ','FarRedWindow2',[]};
Formats(11,8).type = 'edit';
Formats(11,8).format = 'integer';
Formats(11,8).limits = [1 inf];
Formats(11,8).size = [25 25];
Formats(11,8).unitsloc = 'bottomleft';
Formats(11,8).enable = 'off';
Formats(11,8).span = [1 1];
DefAns.FarRedWindow2 = 50;

Prompt(34,:) = {'Count steps?','countBlueSteps',[]};
Formats(12,1).type = 'check';
Formats(12,1).enable = 'off';
Formats(12,1).span = [1 2];
DefAns.countBlueSteps = true;

Prompt(35,:) = {'Count steps?','countGreenSteps',[]};
Formats(12,3).type = 'check';
Formats(12,3).enable = 'on';
Formats(12,3).span = [1 2];
DefAns.countGreenSteps = true;

Prompt(36,:) = {'Count steps?','countRedSteps',[]};
Formats(12,5).type = 'check';
Formats(12,5).enable = 'off';
Formats(12,5).span = [1 2];
DefAns.countRedSteps = true;

Prompt(37,:) = {'Count steps?','countFarRedSteps',[]};
Formats(12,7).type = 'check';
Formats(12,7).enable = 'off';
Formats(12,7).span = [1 2];
DefAns.countFarRedSteps = true;

[Answer,Cancelled] = inputsdlg(Prompt,Title,Formats,DefAns,Options);
clear Prompt Title Formats DefAns Options
%%%% End of dialog box

%% Check input
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
    %% Ask user to choose the file
    Title = 'Dual-view Registration';
    Options.Resize = 'off';
    Options.Interpreter = 'tex';
    Options.CancelButton = 'on';
    Options.ApplyButton = 'off';
    Options.ButtonNames = {'Continue','Cancel'}; 
    Prompt = {};
    Formats = {};
    DefAns = struct([]);

    Prompt(1,:) = {'\fontsize{14}Choose a representative image to perform dual-view registration. This registration will then be applied across all of your images.',[],[]};
    Formats(1,1).type = 'text';
    Formats(1,1).span = [1 2];

    Prompt(2,:) = {'\fontsize{14}You should choose an image that has distinct spots (not too dense) and a lot of colocalized signal. Control data (e.g. mNG::Halo) or bead images work best.',[],[]};
    Formats(2,1).type = 'text';
    Formats(2,1).span = [1 2];
    
    Prompt(3,:) = {'\fontsize{12}Image File:','regFile',[]};
    Formats(3,1).type = 'edit';
    Formats(3,1).format = 'file';
    Formats(3,1).limits = [0 1];
    Formats(3,1).required = 'on';
    Formats(3,1).size = [0 25];
    Formats(3,1).span = [1 2];
    DefAns(1).regFile = expDir;

    Prompt(4,:) = {'\fontsize{12}Frames to average for image registration:',[],[]};
    Formats(4,1).type = 'text';
    Formats(4,1).span = [1 2];

    Prompt(5,:) = {' ','RegWindow1',[]};
    Formats(5,1).type = 'edit';
    Formats(5,1).format = 'integer';
    Formats(5,1).limits = [1 inf];
    Formats(5,1).size = [25 25];
    Formats(5,1).unitsloc = 'bottomleft';
    Formats(5,1).span = [1 1];
    DefAns.RegWindow1 = 6;

    Prompt(6,:) = {'\fontsize{12} to ','RegWindow2',[]};
    Formats(5,2).type = 'edit';
    Formats(5,2).format = 'integer';
    Formats(5,2).limits = [1 inf];
    Formats(5,2).size = [25 25];
    Formats(5,2).unitsloc = 'bottomleft';
    Formats(5,2).span = [1 1];
    DefAns.RegWindow2 = 50;

    [Answer,Cancelled] = inputsdlg(Prompt,Title,Formats,DefAns,Options);
    clear Prompt Title Formats DefAns Options
    %%%% End of dialog box

    % Check input
    if Cancelled 
        return
    else
        v2struct(Answer);
    end
    
    %% Open the image file, make an average image and perform 2D registration
    regImg = TIFFStack(regFile);
    subImg = regImg(:,:,RegWindow1:RegWindow2);
    avgImg = mean(subImg, 3);
    [ymax, xmax] = size(avgImg);
    leftImg = avgImg(:,1:(xmax/2));
    rightImg = avgImg(:,(xmax/2)+1:xmax);
    regData = registerImages(rightImg, leftImg);
    
% else %If registration isn't required, create a registration structure that doesn't do anything
%     regData = struct('Transformation', affine2d,...
%                      'RegisteredImage',[],...
%                      'SpatialRefObj',imref2d(size(leftImg)));
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
        if strcmp(dataType, 'Nikon ND2')
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
                                                    'imageSize',[]);
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
                    rawImage = cat(3, thisImage{:}); 
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
                    thisImage = rawImage{timeRange1:min(timeRange2,tmax)};

                    % Add parameters for averaging window
                    params.firstTime = firstTime.(color);
                    params.lastTime = lastTime.(color);
                    
                    % Actually do the spot counting
                    resultsStruct = spotcount_ps(color,thisImage,params,gridData(index(b)));
                    gridData(index(b)).([color 'SpotData']) = resultsStruct.([color 'SpotData']);
                    gridData(index(b)).([color 'SpotCount']) = resultsStruct.([color 'SpotCount']);
                    clear resultsStruct;
                    
                end %Loop i over channels
                
            end %Loop b over images 
                    
        else 
        %% This section is for TIFF files %%
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
                    
                    % Add parameters for averaging window
                    params.firstTime = firstTime.(color);
                    params.lastTime = lastTime.(color);
                    
                    % Actually do the spot counting
                    resultsStruct = spotcount_ps(color,thisImage,params,gridData(index(b)));
                    gridData(index(b)).([color 'SpotData']) = resultsStruct.([color 'SpotData']);
                    gridData(index(b)).([color 'SpotCount']) = resultsStruct.([color 'SpotCount']);
                    clear resultsStruct;
                end % Loop b over images
                
            end % Loop i over channels
            
        end % If statement for nd2 vs. tiff files 
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
                if strcmp(dvPositions{j}, 'Right') && exist('regData','var')
                    statsByColor.([color 'RegistrationData']) = regData;
                else
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