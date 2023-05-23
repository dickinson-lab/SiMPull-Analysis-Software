function [background, bgModel] = psEstimateBackground(img, varargin)
%PSESTIMATEBACKGROUND estimates background shading using functions, as well as probabilisticSegmentation
%
% SYNOPSIS: [background, bgModel] = psEstimateBackground(img, parameterName, parameterValue...)
%
% INPUT img: the image for which the background should be estimated
%		parameterName, parameterValue: options for psEstimateBackground
%		- bgFilter : median filter for initial background estimation. Default: [11 11].
%		- model: model specification for the background. Currently implemented: 'linear', 'quadratic'  
%
% OUTPUT background: array of the same size as img with background values
%			bgModel : linearModel object with the fitting information         
%
% REMARKS
%
% SEE ALSO probabilisticSegmentation, LinearModel
%
% EXAMPLE
%

% created with MATLAB ver.: 8.0.0.783 (R2012b) on Microsoft Windows 7 Version 6.1 (Build 7601: Service Pack 1)
%
% created by: Jonas.Dorn
% DATE: 08-Dec-2012
%
% Last revision $Rev: 3238 $ $Date: 2013-02-09 10:51:55 -0500 (Sat, 09 Feb 2013) $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

def.bgFilter = [11 11];
def.model = 'quadratic';
def.robust = 'off';
def.usePS = true;

if nargin < 1 || isempty(img)
    [background,bgModel] = deal([]);
    return
end

if isinteger(img)
   img = double(img); 
end

% Parameters Validation 
ip = inputParser;
ip.FunctionName = mfilename;
for fn = fieldnames(def)'
    ip.addParamValue(fn{1},def.(fn{1}));
end
ip.parse(varargin{:});
opt = ip.Results;
%

%% run bg-est

% mask signal
if opt.usePS
si = probabilisticSegmentation(img,'bgFilter',opt.bgFilter);
else
    si = false(size(img));
end

% create coordinate grid. Make this dimension-independent
imSize = size(img);
nd = length(imSize);
cc = cell(1,nd);
ccLists = arrayfun(@(x)1:x,imSize,'uni',false);
[cc{:}] = ndgrid(ccLists{:});
cc = cellfun(@(x)x(:),cc,'uni',false); % linearize coord-arrays
coords = cat(2,cc{:});

% fit model. Note that LinearModel is only available since 2012a
% but it's just so convenient!
% use only non-signal pixels to estimate background
bgModel = LinearModel.fit(coords(~si,:),img(~si),opt.model,'robustOpt',opt.robust);

% predict background
background = img;
background(:) = predict(bgModel,coords);