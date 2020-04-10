% Dialog box for analyze_batch.  This dialog box gets an image to use for
% dual-view registration.

function [Answer, Cancelled] = dataFilterDlg()
    Title = 'Program Options';
    Options.Resize = 'on';
    Options.Interpreter = 'tex';
    Options.CancelButton = 'on';
    Options.ApplyButton = 'off';
    Options.ButtonNames = {'Continue','Cancel'}; 
    Prompt = {};
    Formats = {};
    DefAns = struct([]);

    Prompt(1,:) = {'Choose which channels to filter',[],[]};
    Formats(1,1).type = 'text';
    Formats(1,1).span = [1 4];  

    Prompt(2,:) = {'Blue','filterBlue',[]};
    Formats(2,1).type = 'check';
    DefAns(1).filterBlue = false;

    Prompt(3,:) = {'Green','filterGreen',[]};
    Formats(2,2).type = 'check';
    DefAns.filterGreen = true;

    Prompt(4,:) = {'Red','filterRed',[]};
    Formats(2,3).type = 'check';
    DefAns.filterRed = false;

    Prompt(5,:) = {'Far Red','filterFarRed',[]};
    Formats(2,4).type = 'check';
    DefAns.filterFarRed = false;

    Prompt(6,:) = {' ',[],[]};
    Formats(3,1).type = 'text';
    Formats(3,1).span = [1 4];

    Prompt(7,:) = {'Filter based on photobleaching step size to reject dim noise?','applyIntFilt',[]};
    Formats(4,1).type = 'check';
    Formats(4,1).span = [1 4];
    DefAns.applyIntFilt = true;

    Prompt(8,:) = {'Choose how to apply step size filter',[],[]};
    Formats(5,1).type = 'text';
    Formats(5,1).span = [1 4];

    Prompt(9,:) = {'','intFiltMode',[]};
    Formats(6,1).type = 'list';
    Formats(6,1).format = 'text';
    Formats(6,1).style = 'radiobutton';
    Formats(6,1).items = {'Calculate threshold separately for each experiment' 'Use threshold from a reference sample for all data' 'Calculate a global threshold by pooling all data'};
    Formats(6,1).size = [0 25];
    Formats(6,1).span = [1 4];  
    DefAns.intFiltMode = 'Calculate a global threshold by pooling all data';

    Prompt(10,:) = {'Step size filter strength:',[],[]};
    Formats(7,1).type = 'text';
    Formats(7,1).span = [1 4];

    Prompt(11,:) = {'','intFiltStrength',[]};
    Formats(8,1).type = 'list';
    Formats(8,1).format = 'text';
    Formats(8,1).style = 'radiobutton';
    Formats(8,1).items = {'Aggressive' 'Moderate' 'Conservative'};
    Formats(8,1).size = [0 25];
    Formats(8,1).span = [1 4];  
    DefAns.intFiltStrength = 'Moderate';

    Prompt(12,:) = {' ',[],[]};
    Formats(9,1).type = 'text';
    Formats(9,1).span = [1 4];

    Prompt(13,:) = {'Filter based on number of photobleaching steps per spot?','applyStepFilt',[]};
    Formats(10,1).type = 'check';
    Formats(10,1).span = [1 4];
    DefAns.applyStepFilt = true;

    Prompt(14,:) = {'Keep data with >= this many photobleaching steps:','stepCutoff',[]};
    Formats(11,1).type = 'edit';
    Formats(11,1).format = 'integer';
    Formats(11,1).limits = [0 inf];
    Formats(11,1).size = [40 25];
    Formats(11,1).span = [1 4];  
    Formats(11,1).unitsloc = 'bottomleft';
    Formats(11,1).enable = 'on';
    DefAns.stepCutoff = 1;

    Prompt(15,:) = {'Retain spots that show a step up in intensity?','includeRejected',[]};
    Formats(12,1).type = 'check';
    Formats(12,1).enable = 'on';
    Formats(12,1).span = [1 4];  
    DefAns.includeRejected = true;

    [FilterParams,Cancelled] = inputsdlg(Prompt,Title,Formats,DefAns,Options);
end
