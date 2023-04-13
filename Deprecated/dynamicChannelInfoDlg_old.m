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
    
    Prompt(1,:) = {'\fontsize{14}Data Type and Channel Information:',[],[]};
    Formats(1,1).type = 'text';
    Formats(1,1).span = [1 3];
    
    Formats(1,4).span = [1 1];
    
    Prompt(2,:) = {'\fontsize{12}', 'DataType', []};
    Formats(2,1).type = 'list';
    Formats(2,1).format = 'text';
    Formats(2,1).style = 'radiobutton';
    Formats(2,1).items = {'Dual-view Data' 'Composite Data'};
    Formats(2,1).span = [1 4];
    DefAns(1).DataType = 'Composite Data';
        
    Prompt(3,:) = {'\fontsize{12}Left Dual-View Channel:',[],[]};
    Formats(3,1).type = 'text';
    Formats(3,1).span = [1 1];
    
    Prompt(4,:) = {'\fontsize{12}Right Dual-View Channel:',[],[]};
    Formats(3,2).type = 'text';
    Formats(3,2).span = [1 1];
    
    Prompt(5,:) = {'\fontsize{12}Composite Channels:',[],[]};
    Formats(3,3).type = 'text';
    Formats(3,3).span = [1 2];
    
    Prompt(6,:) = {[], 'LeftChannel',[]};
    Formats(4,1).type = 'list';
    Formats(4,1).format = 'text';
    Formats(4,1).style = 'radiobutton';
    Formats(4,1).items = {'Blue'; 'Green'; 'Red'; 'FarRed'};
    Formats(4,1).size = [25 25];
    Formats(4,1).span = [2 1];
    DefAns.LeftChannel = 'FarRed';

    Prompt(7,:) = {[], 'RightChannel',[]};
    Formats(4,2).type = 'list';
    Formats(4,2).format = 'text';
    Formats(4,2).style = 'radiobutton';
    Formats(4,2).items = {'Blue'; 'Green'; 'Red'; 'FarRed'};
    Formats(4,2).span = [2 1];
    DefAns.RightChannel = 'Green';
    
    Prompt(8,:) = {'Number of Channels:',[],[]};
    Formats(4,3).type = 'text';
    Formats(4,3).span = [1 1];
    
    Prompt(9,:) = {[],'nChannels',[]};
    Formats(4,4).type = 'edit';
    Formats(4,4).format = 'integer';
    Formats(4,4).limits = [1 4];
    Formats(4,4).size = [25 25];
    Formats(4,4).unitsloc = 'bottomleft';
    Formats(4,4).span = [1 1];
    DefAns.nChannels = 3;
    
    Prompt(10,:) = {'Bait Channel:',[],[]};
    Formats(5,3).type = 'text';
    Formats(5,3).span = [1 1];
    
    Prompt(11,:) = {[],'baitChNum',[]};
    Formats(5,4).type = 'edit';
    Formats(5,4).format = 'integer';
    Formats(5,4).limits = [1 4];
    Formats(5,4).size = [25 25];
    Formats(5,4).unitsloc = 'bottomleft';
    Formats(5,4).span = [1 1];
    DefAns.baitChNum = 1;

    Prompt(12,:) = {'\fontsize{12}Bait Channel:',[],[]};
    Formats(6,1).type = 'text';
    Formats(6,1).span = [1 4];    
    
    Prompt(13,:) = {[], 'BaitPos',[]};
    Formats(7,1).type = 'list';
    Formats(7,1).format = 'text';
    Formats(7,1).style = 'radiobutton';
    Formats(7,1).items = {'Left' 'Right'};
    Formats(7,1).span = [1 2];
    DefAns.BaitPos = 'Right';
    
    Prompt(14,:) = {'',[],[]};
    Formats(7,3).type = 'text';
    Formats(7,3).span = [1 2];
   
    Prompt(15,:) = {'',[],[]};
    Formats(8,1).type = 'text';
    Formats(8,1).span = [1 4];
    
    Prompt(16,:) = {'\fontsize{12}Choose a representative image to perform dual-view registration. This registration will then be applied across all of your images.',[],[]};
    Formats(9,1).type = 'text';
    Formats(9,1).span = [1 4];

    Prompt(17,:) = {'\fontsize{12}You should choose an image that has distinct spots (not too dense) and a lot of colocalized signal. Control data (e.g. mNG::Halo) or bead images work best.',[],[]};
    Formats(10,1).type = 'text';
    Formats(10,1).span = [1 4];
    
    Prompt(18,:) = {'\fontsize{12}Image File:','regFile',[]};
    Formats(11,1).type = 'edit';
    Formats(11,1).format = 'file';
    Formats(11,1).limits = [0 1];
    Formats(11,1).required = 'on';
    Formats(11,1).size = [0 25];
    Formats(11,1).span = [1 4];
    %DefAns.regFile = expDir;

    Prompt(19,:) = {'\fontsize{12}Frames to average for image registration:',[],[]};
    Formats(12,1).type = 'text';
    Formats(12,1).span = [1 4];

    Prompt(20,:) = {'    ','RegWindow1',[]};
    Formats(13,1).type = 'edit';
    Formats(13,1).format = 'integer';
    Formats(13,1).limits = [1 inf];
    Formats(13,1).size = [25 25];
    Formats(13,1).unitsloc = 'bottomleft';
    Formats(13,1).span = [1 1];
    DefAns.RegWindow1 = 6;

    Prompt(21,:) = {'\fontsize{12} to ','RegWindow2',[]};
    Formats(13,2).type = 'edit';
    Formats(13,2).format = 'integer';
    Formats(13,2).limits = [1 inf];
    Formats(13,2).size = [25 25];
    Formats(13,2).unitsloc = 'bottomleft';
    Formats(13,2).span = [1 1];
    DefAns.RegWindow2 = 50;
    
    Prompt(22,:) = {'',[],[]};
    Formats(13,3).type = 'text';
    Formats(13,3).span = [1 2];
    
    Prompt(23,:) = {'\fontsize{12}Pixel size (nm)','pixelSize',[]};
    Formats(14,1).type = 'edit';
    Formats(14,1).format = 'float';
    Formats(14,1).limits = [1 inf];
    Formats(14,1).size = [25 25];
    Formats(14,1).unitsloc = 'bottomleft';
    Formats(14,1).enable = 'on';
    Formats(14,1).span = [1 4];
    DefAns.pixelSize = 113.5;
    
    Prompt(24,:) = {'',[],[]};
    Formats(15,1).type = 'text';
    Formats(15,1).span = [1 4];

    [Answer,Cancelled] = inputsdlg(Prompt,Title,Formats,DefAns,Options);
end
