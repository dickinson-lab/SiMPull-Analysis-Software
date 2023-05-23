function [fh,ih] = labelShow(lblImg,bgImg,addNumber)
%LABELSHOW is a utility to show a labeled image
%
% SYNOPSIS: [fh,ih] = labelShow(lblImg,bgImg,addNumber)
%
% INPUT lblImg: Either a labeled image (as returned by bwlabel), or a logical image
%       bgImg : (opt) image, over which the labels should be overlayed.
%                Default: []
%       addNumber : (opt) if 1, the label number is printed over the
%                image. If 2, there is a black background around the label.
%                Default: 0.
%
%
% OUTPUT fh : handle to figure
%        ih : handle to image
%
% REMARKS
%
% SEE ALSO dimshow, label2rgb, bwlabel
%
% created with MATLAB ver.: 7.10.0.499 (R2010a) on Mac OS X  Version: 10.6.3 Build: 10D573
%
% created by: Jonas Dorn
% DATE: 10-Jun-2010
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


if nargin < 1 || isempty(lblImg)
    error('please supply a nonempty label image to labelShow')
end
if nargin < 2
    bgImg = [];
end
if nargin < 3 || isempty(addNumber)
    addNumber = false;
end

if ndims(lblImg) > 2
    % try to save the day
    lblImg = squeeze(lblImg);
    if ndims(lblImg) > 2
        error('please pass a 2d labeled image to labelShow');
    end
end

if islogical(lblImg);
    lblImg = bwlabel(lblImg);
end

if max(lblImg(:))==1
    addNumber = 0;
end

% show
if isempty(bgImg)
    [figH,ih] = dimshow(label2rgb(lblImg,'jet','k','shuffle'));
else
    rgb = double(label2rgb(lblImg,'jet','k','shuffle'));
    rgb = min(bsxfun(@plus,rgb/255,norm01(bgImg)),1);
    [figH,ih] = dimshow(rgb);
end

if addNumber
    positions = regionprops(lblImg,'Centroid');
    hold on
    for p = 1:length(positions)
        th = text(positions(p).Centroid(1),positions(p).Centroid(2),num2str(p),...
            'Color','w','FontWeight','bold','fontSize',14,'verticalAlignment','middle',...
            'HorizontalAlignment','center'); %'BackgroundColor',[0.3,0.3,0.3]
        if addNumber == 2
            set(th,'BackgroundColor','k')
        end
    end
end

if nargout > 0
    fh = figH;
end