% Wrapper script to reprocess multiple .mat files of dymamic SiMPull data

%% Set up

% Ask user for image folders
matFiles = uipickfiles('Prompt','Select data files to analyze','Type',{'*.mat'});

% Ask what to do
mode = questdlg('What kind of re-processing do you want to do?','Type of analysis','Re-count Changepoints','Re-count co-appearance','Get Longer Traces','Get Longer Traces');

if strcmp(mode,'Get Longer Traces')
    % Ask for desired new trace length
    answer = inputdlg('Enter desired fluorescence intensity trace length','Trace Length',1,{'1000'});
    traceLength = str2double(answer);
end

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
    if strcmp(mode,'Get Longer Traces')
        getLongerIntensityTraces(fileName,expDir,traceLength);
    else
        if strcmp(reReg,'Yes')
            detectCoAppearance_greedy_reprocess(fileName,expDir,mode,reReg,regData);
        else
            detectCoAppearance_greedy_reprocess(fileName,expDir,mode);
        end
    end
end

close(statusbar)