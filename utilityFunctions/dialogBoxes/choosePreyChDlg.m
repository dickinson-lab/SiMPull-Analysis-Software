function [PreyCh, remember] = choosePreyChDlg(preyChNums)
    Title = 'Channel Selection';
    Options.Resize = 'off';
    Options.Interpreter = 'tex';
    Options.CancelButton = 'on';
    Options.ApplyButton = 'off';
    Options.ButtonNames = {'Continue','Cancel'}; 
    Prompt = {};
    Formats = {};
    DefAns = struct([]);
    
    Prompt(1,:) = {'Only one channel can be analyzed with this script. Which one do you want to analyze?',[],[]};
    Formats(1,1).type = 'text';
    
    Prompt(2,:) = {[],'choice',[]};
    Formats(2,1).type = 'list';
    Formats(2,1).format = 'text';
    Formats(2,1).style = 'radiobutton';
    Formats(2,1).items = {};
    for e = preyChNums
        Formats(2,1).items{end+1} = num2str(e);
    end
    DefAns(1).choice = Formats(2,1).items{1};
    
    Prompt(3,:) = {'Remember Selection?','remember',[]};
    Formats(3,1).type = 'check';
    DefAns.remember = true;

    [Answer,Cancelled] = inputsdlg(Prompt,Title,Formats,DefAns,Options);
    v2struct(Answer);
    PreyCh = ['PreyCh' choice];
end