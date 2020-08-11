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
    
    Prompt(1,:) = {'\fontsize{14}Enter Channel Information',[],[]};
    Formats(1,1).type = 'text';
    Formats(1,1).span = [1 3];
    
    Formats(1,4).span = [1 1];
    
    Prompt(2,:) = {'\fontsize{12}Left Dual-View Channel:',[],[]};
    Formats(2,1).type = 'text';
    Formats(2,1).span = [1 2];
    
    Prompt(3,:) = {'\fontsize{12}Right Dual-View Channel:',[],[]};
    Formats(2,3).type = 'text';
    Formats(2,3).span = [1 2];    
    
    Prompt(4,:) = {[], 'LeftChannel',[]};
    Formats(3,1).type = 'list';
    Formats(3,1).format = 'text';
    Formats(3,1).style = 'radiobutton';
    Formats(3,1).items = {'Blue'; 'Green'; 'Red'; 'FarRed'};
    Formats(3,1).size = [25 25];
    Formats(3,1).span = [1 2];
    DefAns(1).LeftChannel = 'FarRed';

    Prompt(5,:) = {[], 'RightChannel',[]};
    Formats(3,3).type = 'list';
    Formats(3,3).format = 'text';
    Formats(3,3).style = 'radiobutton';
    Formats(3,3).items = {'Blue'; 'Green'; 'Red'; 'FarRed'};
    Formats(3,3).span = [1 2];
    DefAns.RightChannel = 'Green';
    
    Prompt(6,:) = {'\fontsize{12}Bait Channel:',[],[]};
    Formats(4,1).type = 'text';
    Formats(4,1).span = [1 4];    
    
    Prompt(7,:) = {[], 'BaitPos',[]};
    Formats(5,1).type = 'list';
    Formats(5,1).format = 'text';
    Formats(5,1).style = 'radiobutton';
    Formats(5,1).items = {'Left' 'Right'};
    Formats(5,1).span = [1 4];
    DefAns.BaitPos = 'Right';
    
    Prompt(8,:) = {'',[],[]};
    Formats(6,1).type = 'text';
    Formats(6,1).span = [1 4];
    
    Prompt(9,:) = {'\fontsize{12}Choose a representative image to perform dual-view registration. This registration will then be applied across all of your images.',[],[]};
    Formats(7,1).type = 'text';
    Formats(7,1).span = [1 4];

    Prompt(10,:) = {'\fontsize{12}You should choose an image that has distinct spots (not too dense) and a lot of colocalized signal. Control data (e.g. mNG::Halo) or bead images work best.',[],[]};
    Formats(8,1).type = 'text';
    Formats(8,1).span = [1 4];
    
    Prompt(11,:) = {'\fontsize{12}Image File:','regFile',[]};
    Formats(9,1).type = 'edit';
    Formats(9,1).format = 'file';
    Formats(9,1).limits = [0 1];
    Formats(9,1).required = 'on';
    Formats(9,1).size = [0 25];
    Formats(9,1).span = [1 4];
    DefAns.regFile = expDir;

    Prompt(12,:) = {'\fontsize{12}Frames to average for image registration:',[],[]};
    Formats(10,1).type = 'text';
    Formats(10,1).span = [1 4];

    Prompt(13,:) = {'    ','RegWindow1',[]};
    Formats(11,1).type = 'edit';
    Formats(11,1).format = 'integer';
    Formats(11,1).limits = [1 inf];
    Formats(11,1).size = [25 25];
    Formats(11,1).unitsloc = 'bottomleft';
    Formats(11,1).span = [1 1];
    DefAns.RegWindow1 = 6;

    Prompt(14,:) = {'\fontsize{12} to ','RegWindow2',[]};
    Formats(11,2).type = 'edit';
    Formats(11,2).format = 'integer';
    Formats(11,2).limits = [1 inf];
    Formats(11,2).size = [25 25];
    Formats(11,2).unitsloc = 'bottomleft';
    Formats(11,2).span = [1 1];
    DefAns.RegWindow2 = 50;
    
    Prompt(15,:) = {'\fontsize{12}Pixel size (nm)','pixelSize',[]};
    Formats(12,1).type = 'edit';
    Formats(12,1).format = 'integer';
    Formats(12,1).limits = [1 inf];
    Formats(12,1).size = [25 25];
    Formats(12,1).unitsloc = 'bottomleft';
    Formats(12,1).enable = 'on';
    Formats(12,1).span = [1 2];
    DefAns.pixelSize = 110;

    [Answer,Cancelled] = inputsdlg(Prompt,Title,Formats,DefAns,Options);
end
