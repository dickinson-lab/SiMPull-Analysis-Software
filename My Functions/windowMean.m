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

% Check input
if nargin == 2
    img = varargin{1};
    window = varargin{2};
elseif nargin == 3
    img = varargin{1};
    window = varargin{2};
    xyPortion = varargin{3};
else
    error('Wrong number of arguments given for windowMean');
end

% Figure out what portion of the image we're going to work with and set x indices accordingly
[ymax, xmax, tmax] = size(img);
if strcmp(xyPortion, 'Left')
    xmin = 1;
    xmax = xmax/2;
elseif strcmp(xyPortion, 'Right')
    xmin = xmax/2 + 1;
else
    xmin = 1;
end

% Do the averaging
nMeans = floor(tmax/window); %Here floor is used to average only windows that fit evenly into the image length
avgImg = zeros(ymax,xmax-xmin+1,nMeans);
progress = waitbar(0,'Calculating windowed average (this may take a while)');
for a = 1:nMeans
    waitbar((a-1)/nMeans,progress);
    avgImg(:,:,a) = mean(img(:,xmin:xmax, ( (a-1)*window + 1 ) : a*window ), 3);
end
close(progress);

if mod(tmax,window) ~= 0 %If there are extra frames, average them and append to the end of the average image
    avgImg(:,:,end+1) = mean(img(:,xmin:xmax, (nMeans*window + 1):end), 3);
end

end

