%
% Re-does image registration for a SiMPull experiment and re-calculates summary
% tables. 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [gridData, summary] = redo_registration(varargin) % Typical arguments: matPath, matFile, selection (selection = number of image to use for re-registration)
    if nargin < 2
        [matFile matPath] = uigetfile('*.mat','Choose a .mat file with data from the spot counter');
    else
        matPath = varargin{1};
        matFile = varargin{2};
    end

    load([matPath filesep matFile]);
    if exist('gridData', 'var') ~= 1
        msgbox('This script requires SiMPull data from the spot counter.');
        return
    end

    imageNames = {gridData.imageName};
    
    if nargin < 3    
        [selection, ok] = listdlg('PromptString', 'Select Image to use for re-registration',...
                                  'SelectionMode', 'single',...
                                  'ListSize', [300 300],...
                                  'ListString', imageNames);
        if ~ok
            return
        end
    else
        selection = varargin{3};
    end

    [gridData, statsByColor, summary] = reRegister(gridData, channels, nChannels, params, statsByColor, matPath, matFile, selection);
    msgbox('Completed Successfully');
