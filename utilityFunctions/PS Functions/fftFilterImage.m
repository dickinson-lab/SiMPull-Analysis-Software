function [img,filter] = fftFilterImage(img, filter, filterOptions,calcFilterOnly)
%FFTFILTERIMAGE filters 2/3ND-images in fourier space
%
% SYNOPSIS: [img,filter] = fftFilterImage(img, filter, filterOptions,calcFilterOnly)
%
% INPUT img: 2-3D image. Image size should be odd and finite. If it isn't,
%            fftFilterImage augments the image size by 1 where necessary,
%            and it replaces NaNs with some local intensity average. The
%            output image is of the same size as the input.
%		filter: either fourier-transformed image the same size as img (or
%               odd-sized img), or
%               string indicating which filter to use. Optional.
%               Currently allowed
%                   - 'gauss' : Gaussian filter (default)
%                   - 'average' : local average filter
%		filterOptions: options regarding the filter. Disregarded if input
%               argument filter is numeric.
%               'gauss' : scalar, or 1-by-n array with sx,sy,(sz) [width of
%                         Gaussian]. Default: 2*ones(1,ndims(img))
%               'average' : scalar, or 1-by-n array with wx,wy,(wz) [size
%                         of average filter], or array of the same
%                         dimensionality as the image containing the mask,
%                         e.g. created by circleMask. Default: 5
%       calcFilterOnly : optional. If true, image is returned unfiltered.
%            use this if you need the correctly sized filter mask. Default:
%            false.
%
% OUTPUT img: filtered image
%        filter: fourier-transformed filter
%
% REMARKS 1. If you supply an odd-sized image and the corresponding filter,
%            fftFilterImage works with any number of dimensions.
%         2. fftFilterImage is faster than separated fastGauss3D, the
%            larger both image and filterMask become. For small 2D
%            problems, it is slower, but then, both algorithms take less
%            than a second in these cases, so the absolute gain is minimal.
%            To increase speed even more (for repetitive filtering), store
%            the filterMask. This should allow the execution time of
%            fftFilterImage to decrease by ~30%.
%         3. fftFilterImage can produce artifacts: (1) if there is a region
%            of intense pixels close to the border, it may "bleed" into the
%            image from the opposite border. (2) fftFilterImage adds
%            numerical errors of the order of eps to the image. To reduce
%            this effect, fftFilterImage sets image regions to zero that
%            were zero in the original image and whose absolute value is
%            below 1e-15 in the result.
%
%
%
% created with MATLAB ver.: 7.9.0.529 (R2009b) on Mac OS X  Version: 10.6.1 Build: 10B504
%
% created by: jonas
% DATE: 03-Oct-2009
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% CHECK INPUT
if nargin < 1 || isempty(img)
    error('please supply a nonempty image')
end
imgSize = size(img);
imgDims = length(imgSize);
% do not check for dimensions - if the correct filter has been supplied,
% any number of dimensions should work

% remember zeros for final correction before changing image size
zeroIdx = img==0;

% make sure image has the correct size - we need the size to check the mask
evenDims = isEven(imgSize);
if any(evenDims)
    img = addBorder(img,[evenDims;zeros(1,imgDims)]);
    % n-d version, not tested yet
    % img = padarray(img,evenDims,'symmetric',pre);
end
imgSize = imgSize + evenDims;

% check for empty filter, correct size of numeric filter. We check
% filternames later
if nargin < 2 || isempty(filter)
    filter = 'gauss';
elseif isnumeric(filter)
    if size(filter) ~= imgSize;
        error('transformed filter and image need to have the same size')
    end
end
if nargin < 3
    filterOptions = [];
end
if nargin < 4 || isempty(calcFilterOnly)
    calcFilterOnly = false;
end



%% CREATE FILTER
if isnumeric(filter)
    % all is well
else
    switch lower(filter)
        case 'gauss'
            % check for filterOptions
            if isempty(filterOptions)
                sigma = 2*ones(1,imgDims);
            else
                % check whether we need to expand
                if isscalar(filterOptions)
                    sigma = filterOptions * ones(1,imgDims);
                elseif length(filterOptions) ~= imgDims
                    error('sigma has to be either a scalar or a vector with an element for every dimension of the image')
                else
                    sigma = filterOptions;
                end
            end
            
            % create mask
            if imgDims == 2
                filter = GaussMask2D(sigma,imgSize,[],1);
            elseif imgDims == 3
                filter = GaussMask3D(sigma,imgSize,[],1);
            else
                error('cannot create n-d Gaussian');
            end
            
            % fft
            filter = fftn(filter);
            
        case 'average'
            % check filterOptions
            msk = [];
            if isempty(filterOptions)
                width = 5*ones(1,imgDims);
            elseif imgDims > 1 && sum(size(filterOptions)>1)>1
                % nd mask
                if any(isEven(size(filterOptions)))
                    error('n-d filter has to be odd-sized')
                end
                msk = filterOptions;
                width = size(msk);
            else
                % check whether we need to expand
                if isscalar(filterOptions)
                    width = filterOptions * ones(1,imgDims);
                elseif length(filterOptions) ~= imgDims
                    % check for trailing 1's
                    if length(filterOptions)>imgDims && all(filterOptions(imgDims+1:end)==1)
                        width = filterOptions(1:imgDims);
                    else
                        error('sigma has to be either a scalar or a vector with an element for every dimension of the image')
                    end
                else
                    width = filterOptions;
                end
            end
            
            % create mask if necessary
            if isempty(msk)
                wc = num2cell(width);
                msk = ones(wc{:})/prod(width);
            else
                %Make sure the sum of the mask = 1;
                msk = msk/sum(msk(:));
            end
            
            % put mask into image
            filter = zeros(imgSize);
            halfImg = ceil(imgSize/2);
            range = cell(imgDims,1);
            halfWidth = floor(width/2);
            for d = 1:imgDims
                range{d} = halfImg(d)-halfWidth(d):halfImg(d)+halfWidth(d);
            end
            filter(range{:}) = msk;
            
            
            
            %             % create mask
            %             if imgDims == 2
            %                 filter = zeros(imgSize);
            %                 halfImg = ceil(imgSize/2);
            %                 halfWidth = floor(width/2);
            %                 filter(halfImg(1)-halfWidth(1):halfImg(1)+halfWidth(1),...
            %                     halfImg(2)-halfWidth(2):halfImg(2)+halfWidth(2)) = ...
            %                     1/prod(width);
            %             else
            %                 filter = zeros(imgSize);
            %                 halfImg = ceil(imgSize/2);
            %                 halfWidth = floor(width/2);
            %                 filter(halfImg(1)-halfWidth(1):halfImg(1)+halfWidth(1),...
            %                     halfImg(2)-halfWidth(2):halfImg(2)+halfWidth(2),...
            %                     halfImg(3)-halfWidth(3):halfImg(3)+halfWidth(3)) = ...
            %                     1/prod(width);
            %             end
            
            % fft
            filter = fftn(filter);
            
            
        otherwise
            error('filter %s not implemented yet',filter)
    end
end % create filter

if calcFilterOnly
    % quit here
    return
end

%% mask NaNs
nanMask = isnan(img);
% for now, try to use median
if any(nanMask(:))
    img(nanMask) = median(img(~nanMask));
    isNan = true;
else
    isNan = false;
end

%% FILTER IMAGE

% image should be double, otherwise fft is going to give weird results
img = double(img);

img = fftn(img) .* filter;
% fftshift is needed to put the image back correctly
img = ifftshift(ifftn(img));

%% FINISH
if isNan
    img(nanMask) = NaN;
end
if any(evenDims)
    
    range = cell(imgDims,1);
    for d = 1:imgDims
        range{d} = evenDims(d)+1:imgSize(d);
    end
    
    img = img(range{:});
    
end

% zero-correction
img(zeroIdx) = img(zeroIdx) .* double(abs(img(zeroIdx)) > 1e-15);

