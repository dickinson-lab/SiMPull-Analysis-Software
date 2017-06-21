% Plots a histogram of photobleaching step counts for colocalized spots only

%Get the data from the spot counter
[matFile matPath] = uigetfile('*.mat','Choose a .mat file with data from the spot counter');
load([matPath filesep matFile]);

if nChannels < 2
    msgbox('This program is intended for analyzing multicolor data.');
    return
end

[gridLength gridWidth] = size(gridData);

for b = 1:nChannels
    % Get channel information
    color1 = channels{b};
    if ~isfield(gridData, [color1 'StepDist'])
        continue
    end
    for c = 1:nChannels
        color2 = channels{c};
        if strcmp(color1, channels{c})
            continue
        end
        
        % Collect step data for colocalized spots
        filtStepHist = zeros(1,20);
        for d = 1:gridWidth
            for e = 1:gridLength
                % Skip positions with no spots
                if isequal(gridData(e,d).([color1 'SpotCount']), 0) || isempty(gridData(e,d).([color1 'SpotCount']))
                    continue
                end
                % Go through each spot, add up histogram for those that are colocalized
                for f = 1:length( gridData(e,d).([color1 'SpotData']) )
                    if gridData(e,d).([color1 'SpotData'])(f).(['coloc' color2])
                        nSteps = gridData(e,d).([color1 'SpotData'])(f).nSteps;
                        if isnumeric(nSteps) && nSteps > 0 
                            filtStepHist(nSteps) = filtStepHist(nSteps) + 1;
                        end
                    end
                end
            end
        end
        
        % Plot
        figure('Name',['Step distribution for ' color1 ' spots that colocalize with ' color2]);
        bar(100*filtStepHist/sum(filtStepHist));
        xlabel('Number of photobleaching steps');
        ylabel('% of spots');
    end  
end