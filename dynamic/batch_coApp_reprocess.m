% Wrapper script to reprocess multiple .mat files of dymamic SiMPull data

%% Set up

% Ask user for image folders
matFiles = uipickfiles('Prompt','Select directories containing image files to analyze','Type',{'*.mat'});

% Ask whether to re-do changepoint detection
reDetect = questdlg('Do you want to re-detect changepoints or just re-count co-appearance?','Type of analysis','Changepoints','Just co-appearance','Just co-appearance');

statusbar = waitbar(0);
for a = 1:length(matFiles)
    % Get image name and root directory
    slash = strfind(matFiles{1},filesep);
    fileName = matFiles{1}(slash(end)+1:end); 
    expDir = matFiles{1}(1:slash(end));
    
    waitbar((a-1)/length(matFiles),statusbar,strrep(['Reprocessing ' fileName],'_','\_'));
    
    % Reprocess
    detectCoAppearance_greedy_reprocess(fileName,expDir,reDetect);
end

close(statusbar)