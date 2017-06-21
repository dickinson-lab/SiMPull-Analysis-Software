function img = myMedfilt2(img,filterSize,padMode)
%MYMEDFILT2 performs median filtering with padding and integer conversion (for speed)
%
% SYNOPSIS: img = myMedfilt2(img,filterSize)
%
% INPUT img : 2D-3D image. Preferentially integer format, because this speeds up filtering
%		filterSize: [filterX,filterY] size of filter. Should be odd.
%       padMode: padding mode: 'mirror' (default), 'anti-mirror', or 
%                number
%
% OUTPUT img : median-filtered image of same size and class as original
%
% REMARKS For 3D input, image is filtered z-slice by z-slice
%
% SEE ALSO
%

% created with MATLAB ver.: 7.12.0.62 (R2011a) on Mac OS X  Version: 10.6.5 Build: 10H574
%
% created by: Jonas Dorn
% DATE: 20-Jan-2011
%
% Last revision $Rev: 2465 $ $Date: 2012-01-17 16:01:25 -0500 (Tue, 17 Jan 2012) $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 2 || isempty(img) || isempty(filterSize)
    error('please supply two nonempty inputs to myMedfilt2')
end
if nargin < 3 || isempty(padMode)
    padMode = 'mirror';
end

imSize = size(img);

% try to convert to int b/c it makes median filtering a lot faster
if ~isinteger(img) && min(diff(img(:))) == 1
    oldClass = class(img);
    [img,offset] = double2int(img,[],1);
else
    oldClass = [];
end


otherCoord = cell(length(imSize));
otherCoord{1} = 1:imSize(1);
otherCoord{2} = 1:imSize(2);
halfFilter = floor(filterSize(:)'/2);
for zall = 1:prod(imSize(3:end))
    [otherCoord{3:end}] = ind2sub(imSize(3:end),zall);
    img = double(img);
    tmp = addBorder(img(otherCoord{:}),halfFilter,[],padMode);
    tmp = medfilt2(tmp,filterSize);
    img(otherCoord{:}) = tmp(halfFilter(1)+1:end-halfFilter(1),...
        halfFilter(2)+1:end-halfFilter(2));
end

if ~isempty(oldClass) && nargout > 1
    % cast back to avoid problems for the user
    img = cast(img,oldClass) + offset;
end