% Dialog box for image registration and channel localization in dynamic analysis.  
% This dialog box allows user to specify which channel is which and gets an image 
% to use for dual-view registration.

function [Answer, Cancelled] = dynamicFilteringDlg()
    Title = 'Filtering Options';
    Options.Resize = 'off';
    Options.Interpreter = 'tex';
    Options.CancelButton = 'on';
    Options.ApplyButton = 'off';
    Options.ButtonNames = {'Continue','Cancel'}; 
    Prompt = {};
    Formats = {};
    DefAns = struct([]);
    
    Prompt(1,:) = {'\fontsize{14}Select Filters:',[],[]};
    Formats(1,1).type = 'text';
    Formats(1,1).span = [1 3];
    
    Formats(1,4).span = [1 1];
   
    Prompt(2,:) = {'\fontsize{12}Exclude blinking bait molecules?',[],[]};
    Formats(2,1).type = 'text';
    Formats(2,1).span = [1 2];
    
    Prompt(3,:) = {[], 'BlinkerFilter',[]};
    Formats(2,3).type = 'list';
    Formats(2,3).format = 'text';
    Formats(2,3).style = 'radiobutton';
    Formats(2,3).items = {'Yes'; 'No'};
%     Formats(2,2).span = [2 1];
    DefAns(1).BlinkerFilter = 'Yes';
    
    Prompt(4,:) = {'\fontsize{12}Exclude late appearing bait molecules?',[],[]};
    Formats(3,1).type = 'text';
    Formats(3,1).span = [1 2];
    
    Prompt(5,:) = {[], 'LateAppFilter',[]};
    Formats(3,3).type = 'list';
    Formats(3,3).format = 'text';
    Formats(3,3).style = 'radiobutton';
    Formats(3,3).items = {'Yes'; 'No'};
%     Formats(4,1).span = [1 4];
    DefAns.LateAppFilter = 'Yes';
    
    Prompt(6,:) = {'\fontsize{12}Exclude images with less than ?',[],[]};
    Formats(3,1).type = 'text';
    Formats(3,1).span = [1 2];
    
    Prompt(5,:) = {[], 'LateAppFilter',[]};
    Formats(3,3).type = 'list';
    Formats(3,3).format = 'text';
    Formats(3,3).style = 'radiobutton';
    Formats(3,3).items = {'Yes'; 'No'};
%     Formats(4,1).span = [1 4];
    DefAns.LateAppFilter = 'Yes';


    [Answer,Cancelled] = inputsdlg(Prompt,Title,Formats,DefAns,Options);
end
