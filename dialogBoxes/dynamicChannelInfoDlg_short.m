% Dialog box for image registration and channel localization in dynamic analysis.  
% This dialog box allows user to specify which channel is which and gets an image 
% to use for dual-view registration.

function [Answer, Cancelled] = dynamicChannelInfoDlg_short()
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

    [Answer,Cancelled] = inputsdlg(Prompt,Title,Formats,DefAns,Options);
end
