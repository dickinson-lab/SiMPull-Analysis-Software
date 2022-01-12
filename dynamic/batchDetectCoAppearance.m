% batchDetectCoAppearance.m
% 
% Small wrapper script that gets folder and channel information for several
% experiments and then runs detectCoAppearance.m in batch mode.  This is
% best suited for processing several datasets from the same experiment in
% parallel; if you have just a single dataset, or different channels in
% different datasets, run detectCoAppearance() directly. 

%% Set up

% Ask user for image folders
imgDir = uipickfiles('Prompt','Select directories containing image files to analyze','Type',{'Directory'});

% Options dialog box
[Answer,Cancelled] = dynamicChannelInfoDlg(imgDir{1});
if Cancelled 
    return
else
    v2struct(Answer);
end

% Image registration
params.regFile = regFile; % Save the name of the image used for registration
regImg = TIFFStack(regFile);
subImg = regImg(:,:,RegWindow1:RegWindow2);
avgImg = mean(subImg, 3);
[~, xmax] = size(avgImg);
leftImg = avgImg(:,1:(xmax/2));
rightImg = avgImg(:,(xmax/2)+1:xmax);
regData = registerImages(rightImg, leftImg);

% Loop over image directories and call detectCoAppearance on each one
statusbar = waitbar(0);
for a = 1:length(imgDir)
    waitbar((a-1)/length(imgDir),statusbar,strrep(['Analyzing Experiment ' imgDir{a}],'_','\_'));
    % The imgFile struct lists only .ome.tif files such that difference and average images are excluded. This filtering intentionally accomdates images saved through micromanager which adds ome tags to tif files. 
    % Should another software be used during data acquisition, the uipickfiles syntax should be altered. 
    d = uipickfiles_subs.filtered_dir([imgDir{a} filesep '*.tif'],'',false,@(x,c)uipickfiles_subs.file_sort(x,[1 0 0],c)); % See comments in uipickfiles_subs for syntax here
    imgFile = arrayfun(@(x) [x.folder filesep x.name], d, 'UniformOutput', false);
    
    detectCoAppearance(imgFile, Answer, regData);
    
end
close(statusbar)