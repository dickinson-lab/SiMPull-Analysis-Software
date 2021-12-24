function [avgImg] = windowMean(varargin)
%WINDOWMEAN takes an image series (a 3d matrix with time in the third
%dimension) and produces a smaller image series where each frame is an
%average of a number of frames specified by window. The result is similar
%to what one would have gotten by acquiring images using a longer exposure. 

% Usage: 
% >> [avgImg] = windowMean(image, window) 
%       averages the entire stack in bins specified by window

% >> [avgImg] = windowMean(image, window, xyPortion) 
%       averages only a portion of the stack - used for dual-view images. 
%       xyPortion is a string that specifies which portion of the image to
%       process - can be 'Left' or 'Right' for dual-view images, or 'All' (default)

% >> [avgImg] = windowMean(image, window, xyPortion, channel)
%       averages a single channel of a 4D hyperstack. 
%       xyPortion is usually 'All' in this usage - for now, side-by-side
%       splits of composite images are not supported.

% Check input
if nargin == 2
    img = varargin{1};
    window = varargin{2};
    xyPortion = 'All';
elseif nargin == 3
    img = varargin{1};
    window = varargin{2};
    xyPortion = varargin{3};
elseif nargin == 4
    img = varargin{1};
    window = varargin{2};
    xyPortion = varargin{3};
    channel = varargin{4};
else
    error('Wrong number of arguments given for windowMean');
end

% Figure out what portion of the image we're going to work with. Set x indices accordingly and initialize empty averaged image.
if ndims(img) == 3
    [ymax, xmax, tmax] = size(img);
    nMeans = floor(tmax/window); %Here floor is used to average only windows that fit evenly into the image length
    if strcmp(xyPortion, 'Left')
        xmin = 1;
        xmax = xmax/2;
    elseif strcmp(xyPortion, 'Right')
        xmin = xmax/2 + 1;
    else
        xmin = 1;
    end
    avgImg = zeros(ymax,xmax-xmin+1,nMeans);
elseif ndims(img) == 4
    [ymax, xmax, nChannels, tmax] = size(img);
    nMeans = floor(tmax/window); %Here floor is used to average only windows that fit evenly into the image length
    if nargin < 4
        channel = 1:nChannels;
    end
    avgImg = zeros(ymax,xmax,nChannels,nMeans);
else
    error('Image passed to windowMean has the wrong number of dimensions');
end

% Do the averaging
progress = waitbar(0,'Calculating windowed average...');
for a = 1:nMeans
    waitbar((a-1)/nMeans,progress);
    if ndims(img) == 3
        avgImg(:,:,a) = mean(img(:,xmin:xmax, ( (a-1)*window + 1 ) : a*window ), 3);
    else
        for b = channel
            avgImg(:,:,b,a) = mean(img(:,:, b, ( (a-1)*window + 1 ) : a*window ), 4);
        end
    end
end
close(progress);

if mod(tmax,window) ~= 0 %If there are extra frames, average them and append to the end of the average image
    if ndims(img) == 3
        avgImg(:,:,end+1) = mean(img(:,xmin:xmax, (nMeans*window + 1):end), 3);
    else
        for b = channel
            avgImg(:,:,b,end+1) = mean(img(:,:, b, (nMeans*window + 1):end), 4);
        end
    end
end

end

