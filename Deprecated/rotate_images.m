% Ask user for images. Multiselect is used here because sometimes Micro-Manager splits long time series into pieces. 
imgDir = uipickfiles('Prompt','Select directories containing image files to analyze','Type',{'Directory'});
statusbar = waitbar(0);
for a = 1:length(imgDir)
    waitbar((a-1)/length(imgDir),statusbar,strrep(['Analyzing Experiment ' imgDir{a}],'_','\_'));
    % The imgFile struct lists only .ome.tif files such that difference and average images are excluded. This filtering intentionally accomdates images saved through micromanager which adds ome tags to tif files. 
    % Should another software be used during data acquisition, the uipickfiles syntax should be altered. 
    d = uipickfiles_subs.filtered_dir([imgDir{a} filesep '*.ome.tif'],'',false,@(x,c)uipickfiles_subs.file_sort(x,[1 0 0],c)); % See comments in uipickfiles_subs for syntax here
    imgFile = arrayfun(@(x) [x.folder filesep x.name], d, 'UniformOutput', false);
    % Get image name and root directory
    slash = strfind(imgFile{1},filesep);
    imgName = imgFile{1}(slash(end)+1:strfind(imgFile{1},'_MMStack')-1); 
    expDir = imgFile{1}(1:slash(end));
    %% Load images
    wb = waitbar(0,'Loading Images...','Name',strrep(['Rotating Experiment ' expDir],'_','\_'));
    warning('off'); %Prevent unnecessary warnings from libtiff
    if length(imgFile) > 1 %if the user selected multiple files
        nFiles = length(imgFile);
        for a = 1:nFiles
            stackObj = TIFFStack(imgFile{a});
            [~,~,nFrames] = size(stackObj);
            for n = 1:nFrames
                rotatedImage = imrotate(uint16(stackObj(:,:,n)),90,'bilinear'); 
                imwrite(uint16(rotatedImage),[expDir filesep imgName '_rotated_' num2str(a) '.tif'],'tif','WriteMode','append','Compression','none');
            end
        end
    else
        % If there's just a single TIFF file, it's simpler
        stackObj = TIFFStack(imgFile{1});
        [~,~,nFrames] = size(stackObj);
        for n = 1:nFrames
           rotatedImage = imrotate(uint16(stackObj(:,:,n)),90,'bilinear');
           imwrite(uint16(rotatedImage),[expDir filesep imgName '_rotated_' num2str(a) '.tif'],'tif','WriteMode','append','Compression','none');
        end
    end
    
end