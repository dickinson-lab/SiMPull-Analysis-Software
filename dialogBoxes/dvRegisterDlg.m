% Dialog box for analyze_batch.  This dialog box gets an image to use for
% dual-view registration.

function [Answer, Cancelled] = dvRegisterDlg(expDir)
    Title = 'Dual-view Registration';
    Options.Resize = 'off';
    Options.Interpreter = 'tex';
    Options.CancelButton = 'on';
    Options.ApplyButton = 'off';
    Options.ButtonNames = {'Continue','Cancel'}; 
    Prompt = {};
    Formats = {};
    DefAns = struct([]);

    Prompt(1,:) = {'\fontsize{14}Choose a representative image to perform dual-view registration. This registration will then be applied across all of your images.',[],[]};
    Formats(1,1).type = 'text';
    Formats(1,1).span = [1 2];

    Prompt(2,:) = {'\fontsize{14}You should choose an image that has distinct spots (not too dense) and a lot of colocalized signal. Control data (e.g. mNG::Halo) or bead images work best.',[],[]};
    Formats(2,1).type = 'text';
    Formats(2,1).span = [1 2];
    
    Prompt(3,:) = {'\fontsize{12}Image File:','regFile',[]};
    Formats(3,1).type = 'edit';
    Formats(3,1).format = 'file';
    Formats(3,1).limits = [0 1];
    Formats(3,1).required = 'on';
    Formats(3,1).size = [0 25];
    Formats(3,1).span = [1 2];
    DefAns(1).regFile = expDir;

    Prompt(4,:) = {'\fontsize{12}Frames to average for image registration:',[],[]};
    Formats(4,1).type = 'text';
    Formats(4,1).span = [1 2];

    Prompt(5,:) = {' ','RegWindow1',[]};
    Formats(5,1).type = 'edit';
    Formats(5,1).format = 'integer';
    Formats(5,1).limits = [1 inf];
    Formats(5,1).size = [25 25];
    Formats(5,1).unitsloc = 'bottomleft';
    Formats(5,1).span = [1 1];
    DefAns.RegWindow1 = 6;

    Prompt(6,:) = {'\fontsize{12} to ','RegWindow2',[]};
    Formats(5,2).type = 'edit';
    Formats(5,2).format = 'integer';
    Formats(5,2).limits = [1 inf];
    Formats(5,2).size = [25 25];
    Formats(5,2).unitsloc = 'bottomleft';
    Formats(5,2).span = [1 1];
    DefAns.RegWindow2 = 50;

    [Answer,Cancelled] = inputsdlg(Prompt,Title,Formats,DefAns,Options);
end
