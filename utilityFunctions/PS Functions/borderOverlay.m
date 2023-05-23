function [fh,ah] = borderOverlay(varargin)
%BORDEROVERLAY overlays the border of a labeled or logical image on another image
%
% SYNOPSIS: borderOverlay(overlay,img,usePlot,addNumber)
%           borderOverlay(ah,...)
%           [fh,ah] = borderOverlay(...)
%
% INPUT overlay: either logical array or labelMask
%		img : grayscale image of the same size as overlay
%       usePlot : if true, border is calculated via bwboundaries and added
%                 onto the image using the plot command. If false, border
%                 is 'burnt' into a RGB image. Default: false
%                 If usePlot is an integer > 1, colors are chosen as if
%                 there were usePlots different objects in the image.
%       addNumber : if true, number corresponding to label is added.
%                 Default: 1 if usePlot is 0, 0 if usePlot is 1 (due to 
%                 backward compatibility). No label is shown if input was
%                 logical. 
%       ah : axes handle into which to plot. If not supplied, borderOverlay
%            opens a new figure. Currently only supported with usePlot==1
%
% OUTPUT fh : handle to figure
%        ah : handle to axes
%
% REMARKS
%
% SEE ALSO
%
% created with MATLAB ver.: 7.10.0.499 (R2010a) on Mac OS X  Version: 10.6.4 Build: 10F569
%
% created by: Jonas Dorn
% DATE: 12-Aug-2010
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin > 0 && ~isempty(varargin{1}) && isscalar(varargin{1}) && ...
        ishandle(varargin{1}) && strcmp(get(varargin{1},'type'),'axes')
    ah = varargin{1};
    varargin(1) = [];
    numargin = nargin - 1;
else
    ah = [];
    numargin = nargin;
end

% check input
if numargin < 2 || isempty(varargin{1}) || isempty(varargin{2}) || ...
        any(size(varargin{1})~=size(varargin{2}))
    error('please supply two nonempty images of the same size');
else
    overlay = varargin{1};
    img = varargin{2};
end
if numargin < 3 || isempty(varargin{3})
    usePlot = false;
else
    usePlot = varargin{3};
end
if numargin < 4 || isempty(varargin{4})
    % showNumber used to be possible only with doPlot = 0
    showNumber = ~usePlot;
else
    showNumber = varargin{4};
end

if ~isempty(ah) && ~usePlot
    error('usePlot==0 with specific axes handles is not supported yet')
end

if usePlot
    [borders,labels] = labelBorders(overlay);
    if isempty(ah)
    dimshow(img)
    ah = gca;
    end
    
      % make sure the hold state is right
    set(ah,'NextPlot','add')
    
    % check for image
    if isempty(findall(ah,'type','image'))
        imshow(img,[],'parent',ah)
    end
       
    if usePlot > 1
        if length(borders) > usePlot
            error('there are %i objects, but you only specified %i colors!',...
                length(borders),usePlot)
        end
        cmap = randomColors(usePlot);
        
    else
        cmap = randomColors(length(borders));
    end
    for b = 1:length(borders)
        plot(ah,borders{b}(:,2),borders{b}(:,1),'color',cmap(b,:),'LineWidth',3)
        if showNumber
            text(nanmean(borders{b}(:,2)),nanmean(borders{b}(:,1)),num2str(labels(b)),...
                'parent',ah,'Color','w','FontWeight','bold','fontSize',14,'verticalAlignment','middle',...
            'HorizontalAlignment','center');
        end
    end
else
    % erode so that there is a 2-pixel border
    % check image type.
    if islogical(overlay)
        tmp = imerode(overlay,strel('disk',2));
    else
        tmp = labelErode(overlay,strel('disk',2));
    end
    % remove eroded image from overlay to make border
    overlay(tmp>0) = 0;
    
    % display
    if islogical(overlay)
        dimshow(img,overlay,'wr');
    else
        labelShow(overlay,img,showNumber);
    end
end

if nargout > 0
    if isempty(ah)
        ah = gca;
    end
    fh = get(ah,'Parent');
end