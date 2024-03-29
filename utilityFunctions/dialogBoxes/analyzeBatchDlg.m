% Dialog box for analyze_batch.  This is the master dialog that is used 
% to set all of the analysis parameters.

function [Answer, Cancelled] = analyzeBatchDlg()
Title = 'Program Options';
Options.Resize = 'on';
Options.Interpreter = 'tex';
Options.CancelButton = 'on';
Options.ApplyButton = 'off';
Options.ButtonNames = {'Continue','Cancel'}; 
Prompt = {};
Formats = {};
DefAns = struct([]);

Prompt(1,:) = {'Select folder containig data to analyze','expDir',[]};
Formats(1,1).type = 'edit';
Formats(1,1).format = 'dir';
Formats(1,1).required = 'on';
Formats(1,1).size = [0 25];
Formats(1,1).span = [1 8];
DefAns(1).expDir = [];

Prompt(2,:) = {'  Input Data Type:','dataType',[]};
Formats(2,1).type = 'list';
Formats(2,1).format = 'text';
Formats(2,1).style = 'radiobutton';
Formats(2,1).items = {'Single-Channel TIFF' 'Dual-View TIFF' 'Composite TIFF' 'Nikon ND2'};
Formats(2,1).size = [0 40];
Formats(2,1).span = [1 5];  
Formats(2,1).callback = @(~,~,h,~) updateEnabled(h); %UpdateEnabled is a custom function specific to this dialog box (with hard-coded values). Need to update if reformatting dialog box.
DefAns.dataType = 'Single-Channel TIFF';

Prompt(3,:) = {'Pixel size (nm)','pixelSize',[]};
Formats(2,6).type = 'edit';
Formats(2,6).format = 'float';
Formats(2,6).limits = [1 inf];
Formats(2,6).size = [50 25];
Formats(2,6).unitsloc = 'bottomleft';
Formats(2,6).enable = 'on';
Formats(2,6).span = [1 3];
DefAns.pixelSize = 108.3;

Prompt(4,:) = {'Enter Channel Information',[],[]};
Formats(3,1).type = 'text';
Formats(3,1).span = [1 8];

Prompt(5,:) = {'Blue Channel','haveBlue',[]};
Formats(5,1).type = 'check';
Formats(5,1).span = [1 2];
Formats(5,1).callback = @(~,~,h,~) updateEnabled(h); %UpdateEnabled is a custom function specific to this dialog box (with hard-coded values). Need to update if reformatting dialog box.
DefAns.haveBlue = false;

Prompt(6,:) = {'Green Channel','haveGreen',[]};
Formats(5,3).type = 'check';
Formats(5,3).span = [1 2];
Formats(5,3).callback = @(~,~,h,~) updateEnabled(h); %UpdateEnabled is a custom function specific to this dialog box (with hard-coded values). Need to update if reformatting dialog box.
DefAns.haveGreen = true;

Prompt(7,:) = {'Red Channel','haveRed',[]};
Formats(5,5).type = 'check';
Formats(5,5).span = [1 2];
Formats(5,5).callback = @(~,~,h,~) updateEnabled(h); %UpdateEnabled is a custom function specific to this dialog box (with hard-coded values). Need to update if reformatting dialog box.
DefAns.haveRed = false;

Prompt(8,:) = {'Far Red Channel','haveFarRed',[]};
Formats(5,7).type = 'check';
Formats(5,7).span = [1 2];
Formats(5,7).callback = @(~,~,h,~) updateEnabled(h); %UpdateEnabled is a custom function specific to this dialog box (with hard-coded values). Need to update if reformatting dialog box.
DefAns.haveFarRed = false;

Prompt(9,:) = {'Dual-View Position:', [],[]};
Formats(6,1).type = 'text';
Formats(6,1).span = [1 2];

Prompt(10,:) = {'Dual-View Position:', [],[]};
Formats(6,3).type = 'text';
Formats(6,3).span = [1 2];

Prompt(11,:) = {'Dual-View Position:', [],[]};
Formats(6,5).type = 'text';
Formats(6,5).span = [1 2];

Prompt(12,:) = {'Dual-View Position:', [],[]};
Formats(6,7).type = 'text';
Formats(6,7).span = [1 2];

Prompt(13,:) = {[], 'BlueDualViewPos',[]};
Formats(7,1).type = 'list';
Formats(7,1).format = 'text';
Formats(7,1).style = 'radiobutton';
Formats(7,1).items = {'Left' 'Right'};
Formats(7,1).enable = 'off';
Formats(7,1).span = [1 2];
DefAns.BlueDualViewPos = 'Left';

Prompt(14,:) = {[], 'GreenDualViewPos',[]};
Formats(7,3).type = 'list';
Formats(7,3).format = 'text';
Formats(7,3).style = 'radiobutton';
Formats(7,3).items = {'Left' 'Right'};
Formats(7,3).enable = 'off';
Formats(7,3).span = [1 2];
DefAns.GreenDualViewPos = 'Left';

Prompt(15,:) = {[], 'RedDualViewPos',[]};
Formats(7,5).type = 'list';
Formats(7,5).format = 'text';
Formats(7,5).style = 'radiobutton';
Formats(7,5).items = {'Left' 'Right'};
Formats(7,5).enable = 'off';
Formats(7,5).span = [1 2];
DefAns.RedDualViewPos = 'Right';

Prompt(16,:) = {[], 'FarRedDualViewPos',[]};
Formats(7,7).type = 'list';
Formats(7,7).format = 'text';
Formats(7,7).style = 'radiobutton';
Formats(7,7).items = {'Left' 'Right'};
Formats(7,7).enable = 'off';
Formats(7,7).span = [1 2];
DefAns.FarRedDualViewPos = 'Right';

Prompt(17,:) = {'Frames to average for spot detection:',[],[]};
Formats(8,1).type = 'text';
Formats(8,1).span = [1 8];

Prompt(18,:) = {' ','BlueWindow1',[]};
Formats(9,1).type = 'edit';
Formats(9,1).format = 'integer';
Formats(9,1).limits = [1 inf];
Formats(9,1).size = [25 25];
Formats(9,1).unitsloc = 'bottomleft';
Formats(9,1).enable = 'off';
Formats(9,1).span = [1 1];
DefAns.BlueWindow1 = 6;

Prompt(19,:) = {' to ','BlueWindow2',[]};
Formats(9,2).type = 'edit';
Formats(9,2).format = 'integer';
Formats(9,2).limits = [1 inf];
Formats(9,2).size = [25 25];
Formats(9,2).unitsloc = 'bottomleft';
Formats(9,2).enable = 'off';
Formats(9,2).span = [1 1];
DefAns.BlueWindow2 = 50;

Prompt(20,:) = {' ','GreenWindow1',[]};
Formats(9,3).type = 'edit';
Formats(9,3).format = 'integer';
Formats(9,3).limits = [1 inf];
Formats(9,3).size = [25 25];
Formats(9,3).unitsloc = 'bottomleft';
Formats(9,3).enable = 'on';
Formats(9,3).span = [1 1];
DefAns.GreenWindow1 = 6;

Prompt(21,:) = {' to ','GreenWindow2',[]};
Formats(9,4).type = 'edit';
Formats(9,4).format = 'integer';
Formats(9,4).limits = [1 inf];
Formats(9,4).size = [25 25];
Formats(9,4).unitsloc = 'bottomleft';
Formats(9,4).enable = 'on';
Formats(9,4).span = [1 1];
DefAns.GreenWindow2 = 50;

Prompt(22,:) = {' ','RedWindow1',[]};
Formats(9,5).type = 'edit';
Formats(9,5).format = 'integer';
Formats(9,5).limits = [1 inf];
Formats(9,5).size = [25 25];
Formats(9,5).unitsloc = 'bottomleft';
Formats(9,5).enable = 'off';
Formats(9,5).span = [1 1];
DefAns.RedWindow1 = 6;

Prompt(23,:) = {' to ','RedWindow2',[]};
Formats(9,6).type = 'edit';
Formats(9,6).format = 'integer';
Formats(9,6).limits = [1 inf];
Formats(9,6).size = [25 25];
Formats(9,6).unitsloc = 'bottomleft';
Formats(9,6).enable = 'off';
Formats(9,6).span = [1 1];
DefAns.RedWindow2 = 50;

Prompt(24,:) = {' ','FarRedWindow1',[]};
Formats(9,7).type = 'edit';
Formats(9,7).format = 'integer';
Formats(9,7).limits = [1 inf];
Formats(9,7).size = [25 25];
Formats(9,7).unitsloc = 'bottomleft';
Formats(9,7).enable = 'off';
Formats(9,7).span = [1 1];
DefAns.FarRedWindow1 = 6;

Prompt(25,:) = {' to ','FarRedWindow2',[]};
Formats(9,8).type = 'edit';
Formats(9,8).format = 'integer';
Formats(9,8).limits = [1 inf];
Formats(9,8).size = [25 25];
Formats(9,8).unitsloc = 'bottomleft';
Formats(9,8).enable = 'off';
Formats(9,8).span = [1 1];
DefAns.FarRedWindow2 = 50;

Prompt(26,:) = {'Count steps?','countBlueSteps',[]};
Formats(10,1).type = 'check';
Formats(10,1).enable = 'off';
Formats(10,1).span = [1 2];
DefAns.countBlueSteps = true;

Prompt(27,:) = {'Count steps?','countGreenSteps',[]};
Formats(10,3).type = 'check';
Formats(10,3).enable = 'on';
Formats(10,3).span = [1 2];
DefAns.countGreenSteps = true;

Prompt(28,:) = {'Count steps?','countRedSteps',[]};
Formats(10,5).type = 'check';
Formats(10,5).enable = 'off';
Formats(10,5).span = [1 2];
DefAns.countRedSteps = true;

Prompt(29,:) = {'Count steps?','countFarRedSteps',[]};
Formats(10,7).type = 'check';
Formats(10,7).enable = 'off';
Formats(10,7).span = [1 2];
DefAns.countFarRedSteps = true;

[Answer,Cancelled] = inputsdlg(Prompt,Title,Formats,DefAns,Options);
end


% Function to update dialog box options for analyze_batch. 

function updateEnabled(h)
    % Get values of currently selected parameters
    nd2 = strcmp( get( get(h(2,1),'SelectedObject'), 'String'), 'Nikon ND2');
    dv = strcmp( get ( get(h(2,1),'SelectedObject'), 'String'), 'Dual-View TIFF');
    blue = get(h(5,1),'Value');
    green = get(h(6,1),'Value');
    red = get(h(7,1),'Value');
    farRed = get(h(8,1),'Value');
    
    % Enable or disable stuff based on values

    if dv && blue
        set( findall( h(13,1), '-property', 'Enable'), 'Enable', 'on');
    else
        set( findall( h(13,1), '-property', 'Enable'), 'Enable', 'off');
    end
    
    if dv && green
        set( findall( h(14,1), '-property', 'Enable'), 'Enable', 'on');
    else
        set( findall( h(14,1), '-property', 'Enable'), 'Enable', 'off');
    end
    
    if dv && red
        set( findall( h(15,1), '-property', 'Enable'), 'Enable', 'on');
    else
        set( findall( h(15,1), '-property', 'Enable'), 'Enable', 'off');
    end

    if dv && farRed
        set( findall( h(16,1), '-property', 'Enable'), 'Enable', 'on');
    else
        set( findall( h(16,1), '-property', 'Enable'), 'Enable', 'off');
    end
       
    if blue
        set( h(18,1),'Enable','on');
        set( h(19,1),'Enable','on');
        set( h(26,1),'Enable','on');
    else
        set( h(18,1),'Enable','off');
        set( h(19,1),'Enable','off');
        set( h(26,1),'Enable','off');
    end
    
    if green
        set( h(20,1),'Enable','on');
        set( h(21,1),'Enable','on');
        set( h(27,1),'Enable','on');
    else
        set( h(20,1),'Enable','off');
        set( h(21,1),'Enable','off');
        set( h(27,1),'Enable','off');
    end
    
    if red
        set( h(22,1),'Enable','on');
        set( h(23,1),'Enable','on');
        set( h(28,1),'Enable','on');
    else
        set( h(22,1),'Enable','off');
        set( h(23,1),'Enable','off');
        set( h(28,1),'Enable','off');
    end
    
    if farRed
        set( h(24,1),'Enable','on');
        set( h(25,1),'Enable','on');
        set( h(29,1),'Enable','on');
    else
        set( h(24,1),'Enable','off');
        set( h(25,1),'Enable','off');
        set( h(29,1),'Enable','off');
    end
end