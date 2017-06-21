% Extracts the initial intensities of spots in a SiMPull experiment.  

% Note, this function returns intensities for a single channel only.  To
% get paired intensities of colocalized spots, use getColocIntensities.m
% instead.

% Parameters:
% gridData is the dataset to be queried
% channel is the imaging channel ('green', 'red', 'farRed' etc.)
% nStepsCutoff is the number of steps a spot must have in order to be
%   considered.  Enter '0' to consider all spots.
% includeRejected decides whether to include rejected traces.  Default is false.
% mode is an optional parameter that can have values 'all', 'coloc' or 'notColoc' 
%   (Default is 'all').  Only spots that match the description are considered.
% colocChannel is the second color to be analyzed when colocalization is considered. 
%   This parameter is ignored when mode is set to 'all'.  If mode is not
%   'all', this parameter is required.

function [goodSpots, intensities] = getIntensities(gridData,channel,varargin)
    % Check inputs with inputparser
    p = inputParser;
    
    validModes = {'all', 'coloc', 'notColoc'};
    
    addRequired(p,'gridData',@isstruct);
    addRequired(p,'channel',@ischar);
    addParamValue(p,'nStepsCutoff',0,@isnumeric);
    addParamValue(p,'includeRejected','true',@islogical);
    addParamValue(p,'intMode','all', @(x) any(validatestring(x,validModes)) );
    addParamValue(p,'colocChannel','',@ischar);
    
    parse(p,gridData,channel,varargin{:});
    
    v2struct(p.Results);
    
    % Make sure the colocChannel (if needed) is specified and capitalized
    if (~strcmp(intMode,'all'))
        if (exist('colocChannel','var'))
            colocChannel = regexprep(colocChannel,'(\<\w)','${upper($1)}');
        else
            error('A coloclization channel must be specified in order to filter colocalized spots')
        end
    end

    % Gather the spot data from all images in the dataset
    index2 = zeros(numel(gridData),1);
    for b = 1:numel(gridData)
        index2(b) = isfield(gridData(b).([channel 'SpotData']),'nSteps');
    end
    nImages = sum(index2);
    if nImages == 0
        goodSpots = 0;
        intensities = []; 
        return
    end
    index2 = logical(index2);
    spotData = {gridData(index2).([channel 'SpotData'])};
    spotData = vertcat(spotData{ cellfun(@length, spotData) > 1 }); % The argument inside {} tosses images with no spots
    
    % Filter spots based on input parameters
    if nStepsCutoff > 0
        nStepsIdx = arrayfun(@(x) isnumeric(x.nSteps) && x.nSteps>=nStepsCutoff,  spotData);
    else
        nStepsIdx = true(length(spotData), 1);
    end
    
    if includeRejected
        rejectedIdx = arrayfun(@(x) strcmp(x.nSteps,'Rejected'), spotData);
    else
        rejectedIdx = false(length(spotData), 1);
    end
    
    includeIdx = nStepsIdx | rejectedIdx;
    
    switch intMode
        case 'all'
            colocIdx = true(length(spotData), 1);
        case 'coloc'
            colocIdx = arrayfun(@(x) x.(['coloc' colocChannel]), spotData);
        case 'notColoc'
            colocIdx = arrayfun(@(x) ~x.(['coloc' colocChannel]), spotData);
        otherwise
            error('Invalid choice for mode parameter: options are "all", "coloc" or "notColoc"');
    end
    index = includeIdx & colocIdx;
    goodSpots = spotData(index);
    intensities = zeros(length(goodSpots),1);
    for a = 1:length(goodSpots);
        try
            intensities(a) = goodSpots(a).steplevels(1);
        catch
            intensities(a) = [];
            %fprintf(['Failed at iteration ' num2str(a) ' of ' num2str(length(goodSpots)) '\n']);
        end
    end
    return;
    
