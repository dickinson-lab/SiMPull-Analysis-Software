% Plots the percentage of spots colocalized for different numbers of
% photobleaching steps

%Get the data from the spot counter
[matFile matPath] = uigetfile('*.mat','Choose a .mat file with data from the spot counter');
load([matPath filesep matFile]);

if nChannels < 2
    msgbox('This program is intended for analyzing multicolor data.');
    return
end

for b = 1:nChannels
    color1 = channels{b};
    for c = 1:nChannels
        color2 = channels{c};
        if strcmp(color1, channels{c})
            continue
        end
        %Skip this channel if step counting wasn't done
        if ~isfield(statsByColor,[color1 'StepHist'])
            continue
        end
        %Guard against images with no spots  
        nSpots = cell(size(gridData));
        [nSpots{:}] = gridData.([color1 'SpotCount']);
        index1 = cellfun(@(x) ~isempty(x) && x>0, nSpots);
        %Guard against images with too many spots    
        colocSpots = cell(size(gridData));
        [colocSpots{:}] = gridData.([color1 color2 'ColocSpots']);
        index2 = cellfun(@isnumeric, colocSpots);
        index = index1 & index2;
        thisSpotData = {gridData(index).([color1 'SpotData'])};
        thisSpotData = vertcat(thisSpotData{:});
        thisColoc = zeros(nChannels-1,20); % The first row is for colocalization with red, the second row for far red
        % Add up the number of spots that are colocalized as a function of step count
        for a = 1:length(thisSpotData)
            if ( isfield(thisSpotData(a), 'nSteps') && isnumeric(thisSpotData(a).nSteps) && thisSpotData(a).nSteps > 0)
                if ( isfield(thisSpotData(a), ['coloc' color2] ) && ~isempty(thisSpotData(a).(['coloc' color2])) && thisSpotData(a).(['coloc' color2]) )
                    thisColoc(1,thisSpotData(a).nSteps) = thisColoc(1,thisSpotData(a).nSteps) + 1;
                end
            end
        end
        % Save results & convert to percentage
        colocN.([color1 '_vs_' color2]) = thisColoc(1,:);
        colocPct.([color1 '_vs_' color2]) = thisColoc(1,:)./statsByColor.([color1 'StepHist']);
        colocPct.([color1 '_vs_' color2]) = colocPct.([color1 '_vs_' color2]) * 100;
        %Plot
        figure;
        bar(colocPct.([color1 '_vs_' color2]));
        xlabel(['Number of ' color1 ' Steps']);
        ylabel(['Percent Colocalized w/ ' color2]);
    end
end