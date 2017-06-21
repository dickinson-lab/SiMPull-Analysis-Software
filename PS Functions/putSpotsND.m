function [image,bgImage] = putSpotsND(coordList, ampList, imSize, sigma, cutoff, bgList,rotation,addFcn)
%PUTSPOTSND fills an ND-volume with Gaussians
%
% SYNOPSIS: image = putSpotsND(coordList, ampList, imSize, sigma, cutoff,bgList,rotation)
%
% INPUT coordList : nCoords-by-nDims coordinate list.
%       ampList :   nCoords-by-1 amplitude list. If empty, it will be set to
%                   ones(nCoords,1)
%		imSize :    1-by-nDims size of image
%		sigma :     scalar or 1-by-nDims sigma of Gaussian. Can be
%		            different for each coordinate.
%       cutoff :    (opt) number of sigmas over which to calculate Gaussian
%                   Default: 5
%       bgList :    (opt) Local background intensities. Default:
%                   zeros(nCoords,1) - best left unused
%       rotation:   (opt) Rotation to be applied to the spots. 1 for random. 0
%                   for no rotation. Note : rotation in degrees
%                   and not radians.
%       addFcn :    (opt) function used to add new gaussians to image.
%                   Has to take two vector arguments and to return a
%                   vector of the same size. Default: @plus. One possibly
%                   interesting alternative is @max
% OUTPUT image : Image with Gaussians
%        bgImage : background (if requested)
%
% REMARKS units are always pixels
%
% created with MATLAB ver.: 7.5.0.342 (R2007b) on Windows_NT
%
% created by: Jonas Dorn
% DATE: 07-Mar-2008
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%=================
%% TEST INPUT
%=================

if nargin < 4 || isempty(coordList) || isempty(imSize) || isempty(sigma)
    error('putSpotsND needs three nonempty input arguments!')
end

% check for NaN in coordList
coordList(any(isnan(coordList),2),:) = [];

if isempty(coordList)
    error('coordList contains only NaNs')
end

% check dims
[nCoords, nDims] = size(coordList);

if length(imSize) ~= nDims
    error('image and coordinates must have the same dimension')
end

% check amps
if isempty(ampList)
    ampList = ones(nCoords,1);
end
if isscalar(ampList)
    ampList = repmat(ampList,nCoords,1);
end

% check sigma
if isscalar(sigma)
    sigma = repmat(sigma,1,nDims);
end
% repeat sigma for every coordinate, if necessary

if size(sigma,1) == 1 || (nDims ~=1 && size(sigma,2) == 1)
    sigma = repmat(sigma(:)', nCoords,1);
elseif size(sigma,1) ~= nCoords
    error('sigma needs to have either one row or as many rows as there are coordinates')
end

% check cutoff
if nargin < 5 || isempty(cutoff)
    cutoff = 5;
end

% check bg
if nargin < 6 || isempty(bgList)
    bgList = zeros(nCoords,1);
end

%check Rotation
if nargin < 7 || isempty(rotation)
    rotation = zeros(nCoords,1);
end
if length(rotation) == 1
    rotation = repmat(rotation,nCoords,1);
end

% check fcn
if nargin < 8 || isempty(addFcn)
    addFcn = @plus;
end
%=================



%=================
%% CREATE IMAGE
%=================

% make empty image
image = zeros(imSize);

if any(ampList>0)
    
    gaussCoords = cell(nDims,1);
    
    % loop through coords and cut
    for c = 1:nCoords
        
        % create coordinate list for GaussListND. Take coordinate +/-
        % sigma*cutoff, create ndgrid and assemble into coordinate array
        nVox = 1;
        msig = sigma(c,:);
        if rotation(c) ~= 0
            % use max sigma xy
            msig(1:2) = max(msig(1:2));
        end
        for d = 1:nDims
            minD = round(max(coordList(c,d) - cutoff*msig(d),1));
            maxD = round(min(coordList(c,d) + cutoff*msig(d),imSize(d)));
            gaussCoords{d} = minD:maxD;
            nVox = nVox * length(gaussCoords{d});
        end
        % look what I can do with Matlab!
        [gaussCoords{:}] = ndgrid(gaussCoords{:});
        gaussListCoords = cat(nDims+1,gaussCoords{:});
        gaussListCoords = reshape(gaussListCoords,nVox,nDims);
        
        gaussList = GaussListND(gaussListCoords,sigma(c,:),coordList(c,:),0,rotation(c));
        
        % transform gaussListCoords into indices into image
        idx  = sub2ind(imSize,gaussCoords{:}); % idx is an n-d array
        image(idx) = addFcn(image(idx(:)),gaussList * ampList(c));
        
    end
    
end

% if there are backgrounds, we cannot add them with the spots. Instead, we
% have to add them as one. Since the background has to be equal for all
% jointly fitted spots, we use nearest neighbor interpolation. To avoid
% ugly steps, we smoothen the result afterwards
if any(bgList>0)
    bgImage = zeros(size(image));
    [xx,yy,zz] = ndgrid(1:imSize(1),1:imSize(2),1:imSize(3));
    F = TriScatteredInterp(coordList(:,1),coordList(:,2),coordList(:,3),bgList,'nearest');
    bgImage(:) = F(xx(:),yy(:),zz(:));
    bgImage = fastGauss3D(bgImage,3*sigma);
    image = image + bgImage;
else
    bgImage = [];
end

if nargout > 1 && isempty(bgImage)
    bgImage = zeros(size(image));
end