% Wrapper script to reprocess multiple .mat files of dymamic SiMPull data

%% Set up

% Ask user for image folders
matFiles = uipickfiles('Prompt','Select data files to analyze','Type',{'*.mat'});

% Ask whether to re-do changepoint detection
reDetect = questdlg('Do you want to re-detect changepoints or just re-count co-appearance?','Type of analysis','Changepoints','Just co-appearance','Just co-appearance');

% Ask whether to re-register
reReg = questdlg('Do you want to redo image registration?','Registration','Yes','No','Yes');

if strcmp(reReg,'Yes')
    % Registration dialog box
    [Answer,Cancelled] = dvRegisterDlg(matFiles{1});
    if Cancelled 
        return
    else
        v2struct(Answer);
    end

    % Image registration
    regImg = TIFFStack(regFile);
    subImg = regImg(:,:,RegWindow1:RegWindow2);
    avgImg = mean(subImg, 3);
    [~, xmax] = size(avgImg);
    leftImg = avgImg(:,1:(xmax/2));
    rightImg = avgImg(:,(xmax/2)+1:xmax);
    regData = registerImages(rightImg, leftImg);
end

statusbar = waitbar(0);
for a = 1:length(matFiles)
    % Get image name and root directory
    slash = strfind(matFiles{a},filesep);
    fileName = matFiles{a}(slash(end)+1:end); 
    expDir = matFiles{a}(1:slash(end));
    
    waitbar((a-1)/length(matFiles),statusbar,strrep(['Reprocessing ' fileName],'_','\_'));
    
    % Reprocess
    if strcmp(reReg,'Yes')
        detectCoAppearance_greedy_reprocess(fileName,expDir,reDetect,reReg,regData);
    else
        detectCoAppearance_greedy_reprocess(fileName,expDir,reDetect);
    end
end

close(statusbar)