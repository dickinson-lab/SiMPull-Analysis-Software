% Dialog box for image registration and channel localization in dynamic analysis.  
% This dialog box allows user to specify which channel is which and gets an image 
% to use for dual-view registration.

function [Answer, Cancelled] = dynamicChannelInfoDlg(expDir)
    Title = 'Channel Info and Registration';
    Options.Resize = 'off';
    Options.Interpreter = 'tex';
    Options.CancelButton = 'on';
    Options.ApplyButton = 'off';
    Options.ButtonNames = {'Continue','Cancel'}; 
    Prompt = {};
    Formats = {};
    DefAns = struct([]);
    
    Prompt(1,:) = {'\fontsize{12}Number of Channels in Composite Image:',[],[]};
    Formats(1,1).type = 'text';
    Formats(1,1).span = [1 2];
    
    Prompt(2,:) = {[],'nChannels',[]};
    Formats(1,3).type = 'edit';
    Formats(1,3).format = 'integer';
    Formats(1,3).limits = [1 4];
    Formats(1,3).size = [25 25];
    Formats(1,3).unitsloc = 'bottomleft';
    Formats(1,3).span = [1 1];
    DefAns(1).nChannels = 2;

    Prompt(3,:) = {' ','',[]};
    Formats(1,4).type = 'text';
    Formats(1,4).span = [1 1];
    
    Prompt(4,:) = {'\fontsize{12}Bait Channel:',[],[]};
    Formats(2,1).type = 'text';
    Formats(2,1).span = [1 2];
    
    Prompt(5,:) = {[],'baitChNum',[]};
    Formats(2,3).type = 'edit';
    Formats(2,3).format = 'integer';
    Formats(2,3).limits = [1 4];
    Formats(2,3).size = [25 25];
    Formats(2,3).unitsloc = 'bottomleft';
    Formats(2,3).span = [1 2];
    DefAns.baitChNum = 1;
    
    Prompt(6,:) = {' ',[],[]};
    Formats(3,1).type = 'text';
    Formats(3,1).span = [1 4];

    Prompt(7,:) = {'\fontsize{12}Choose a representative image to perform dual-view registration. This registration will then be applied across all of your images.',[],[]};
    Formats(4,1).type = 'text';
    Formats(4,1).span = [1 4];

    Prompt(8,:) = {'\fontsize{12}You should choose an image that has distinct spots (not too dense) and a lot of colocalized signal. Control data (e.g. mNG::Halo) or bead images work best.',[],[]};
    Formats(5,1).type = 'text';
    Formats(5,1).span = [1 4];
    
    Prompt(9,:) = {'\fontsize{12}Image File:','regFile',[]};
    Formats(6,1).type = 'edit';
    Formats(6,1).format = 'file';
    Formats(6,1).limits = [0 1];
    Formats(6,1).required = 'on';
    Formats(6,1).size = [0 25];
    Formats(6,1).span = [1 4];
    %DefAns.regFile = expDir;

    Prompt(10,:) = {'\fontsize{12}Frames to average for image registration:',[],[]};
    Formats(7,1).type = 'text';
    Formats(7,1).span = [1 4];

    Prompt(11,:) = {'    ','RegWindow1',[]};
    Formats(8,1).type = 'edit';
    Formats(8,1).format = 'integer';
    Formats(8,1).limits = [1 inf];
    Formats(8,1).size = [25 25];
    Formats(8,1).unitsloc = 'bottomleft';
    Formats(8,1).span = [1 1];
    DefAns.RegWindow1 = 1;

    Prompt(12,:) = {'\fontsize{12} to ','RegWindow2',[]};
    Formats(8,2).type = 'edit';
    Formats(8,2).format = 'integer';
    Formats(8,2).limits = [1 inf];
    Formats(8,2).size = [25 25];
    Formats(8,2).unitsloc = 'bottomleft';
    Formats(8,2).span = [1 1];
    DefAns.RegWindow2 = 1;
    
    Prompt(13,:) = {'',[],[]};
    Formats(8,3).type = 'text';
    Formats(8,3).span = [1 2];
    
    Prompt(14,:) = {'\fontsize{12}Pixel size (nm):',[],[]};
    Formats(9,1).type = 'text';
    Formats(9,1).span = [1 4];

    Prompt(15,:) = {'','pixelSizeChoice',[]};    
    Formats(10,1).type = 'list';
    Formats(10,1).format = 'text';
    Formats(10,1).style = 'radiobutton';
    Formats(10,1).items = {'121.9 nm    ' '110 nm    ' 'Other'};
    Formats(10,1).span = [1 2];
    DefAns.pixelSizeChoice = '121.9 nm    ';
    
    Prompt(16,:) = {'Other pixel size:','pixelSize',[]};
    Formats(10,3).type = 'edit';
    Formats(10,3).format = 'float';
    Formats(10,3).limits = [1 inf];
    Formats(10,3).size = [50 25];
    Formats(10,3).unitsloc = 'bottomleft';
    Formats(10,3).span = [1 2];
    DefAns.pixelSize = 100;

    Prompt(17,:) = {' ',[],[]};
    Formats(11,1).type = 'text';
    Formats(11,1).span = [1 4];

    Prompt(18,:) = {' ',[],[]};
    Formats(12,1).type = 'text';
    Formats(12,1).span = [1 4];


    [Answer,Cancelled] = inputsdlg(Prompt,Title,Formats,DefAns,Options);
end
