%Re-formats data analyzed by older versions of the SiMPull software so that
%it can be read by updated visualization tools. 

clear all;

% Choose a .mat file 
[matFile matPath] = uigetfile('*.mat','Choose a .mat file with SiMPull Data');
load([matPath filesep matFile]);

% Check data
if ~exist('gridData')
    msgbox('The selected .mat file does not appear to contain SiMPull Data.');
    return
end
% if exist('statsByColor') && isfield(statsByColor,'GreenStepHist') && length(statsByColor.GreenStepHist) == 20
%     msgbox('It looks like the selected file already uses the up-to-date data format');
%     return
% end

% Make variables into structure so I can use dynamic field names
allData = v2struct;

% Create the list of channels
gridFields = fieldnames(gridData);
indices = strfind(gridFields, 'SpotData');
channels = cell(1, nChannels);
counter = 1;
for a = 1:length(indices)
    if ~isempty(indices{a})
        channels{counter} = gridFields{a}( 1 : indices{a}-1 );
        counter = counter + 1;
    end
end

% Generate the statsByColor structure
if ~exist('statsByColor')
    statsByColor = struct;
    for b = 1:nChannels
        color = channels{b};
        try
            statsByColor.(['total' color 'Spots']) = allData.(['totalSpots' regexprep(color,'(\<[a-z])','${upper($1)}')]);
        catch
            statsByColor.(['total' color 'Spots']) = allData.([color 'Stats']).totalSpots;
        end
        try
            statsByColor.(['avg' color 'Spots']) = allData.(['avgSpots' regexprep(color,'(\<[a-z])','${upper($1)}')]);
        catch
            statsByColor.(['avg' color 'Spots']) = allData.([color 'Stats']).avgSpots;
        end
        try
            statsByColor.([color 'BadSpots']) = allData.(['totalBad' regexprep(color,'(\<[a-z])','${upper($1)}') 'Spots']);
        catch
            statsByColor.([color 'BadSpots']) = allData.([color 'Stats']).badSpots;
        end
        try
            statsByColor.([color 'TracesAnalyzed']) = allData.(['totalBad' regexprep(color,'(\<[a-z])','${upper($1)}') 'Spots']) + sum(allData.([color 'StepHist']));
        catch
            statsByColor.([color 'TracesAnalyzed']) = allData.([color 'Stats']).tracesAnalyzed;
        end
        statsByColor.([color 'StepHist']) = allData.([color 'StepHist']);
    end
end

% Make the step histogram 20 fields long instead of 10
for c = 1:nChannels
    color = channels{c};
    if length(statsByColor.([color 'StepHist'])) < 20
        statsByColor.([color 'StepHist'])(end+1:20) = 0;
        statsByColor.([color 'StepHist']) = statsByColor.([color 'StepHist'])';
    end
    for d = 1:length(gridData)
        if length(gridData(d).([color 'StepDist'])) < 20
            gridData(d).([color 'StepDist'])(end+1:20) = 0;
            gridData(d).([color 'StepDist']) = gridData(d).([color 'StepDist'])';
        end
    end   
end

% Save Data
save([matPath filesep matFile],'channels','statsByColor','-append');
msgbox('Data file updated successfully');
