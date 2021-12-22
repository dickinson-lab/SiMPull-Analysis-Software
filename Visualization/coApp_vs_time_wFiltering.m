% Plots percent coAppearance as a function of (windowed) appearance time for dynamic SiMPull 
% but differs from coApp_vs_time.m in offering various ways to filter the data.
% This function can be run in two modes: If called with no arguments, the
% user is asked to select files to analyze and set options; this works well 
% for processing a single dataset. Alternatively, the function may be called by batchCoApp_vs_time.m. 

function coApp_vs_time_filtered = coApp_vs_time_wFiltering(varargin)
if nargin == 0 
    % Ask user for images. Multiselect is used here because sometimes Micro-Manager splits long time series into pieces. 
    imgFile = uipickfiles('Prompt','Select mat file containing coAppearance data to plot over time','Type',{'*.mat'});

    % Get image name and root directory
    slash = strfind(imgFile{1},filesep);
    expDir = imgFile{1}(1:slash(end));
    imgName = imgFile{f}(slash(end)+1:end); 
    
    % Filtering options dialog box
    [Answer,Cancelled] = dynamicChannelInfoDlg_short;
    if Cancelled
        return
    else
        v2struct(Answer);
        params.LeftChannel = LeftChannel;
        params.RightChannel = RightChannel;
        params.BaitPos = BaitPos;
        
    end
end
end