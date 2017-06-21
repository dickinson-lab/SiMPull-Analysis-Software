function [borderList,lblList] = labelBorders(lblImg,n,holes)
%LABELBORDERS runs bwperim on a labeled image
%
% SYNOPSIS: borderList = labelBorders(lblImg,n,holes)
%
% INPUT lblImg: 2D labeled image as e.g. obtained by bwlabel.
%        n : number of spots that should be taken along the border.
%            Optional. Default: inf (i.e. all spots are taken)
%        holes : if 1, labelBorders also returns borders around holes.
%            Optional. Default: 1 (hole-borders are returned)
%
% OUTPUT borderList: nObjects-by-1 cell array with borders of each labeled
%            region as [x,y]. If there are holes inside an object, they are
%            appended to the outline, separated by a row of NaNs
%        lblList: number of the cell a specific border belongs to
%
% REMARKS
%
% SEE ALSO bwboundaries, borderOverlay
%

% created with MATLAB ver.: 7.11.0.584 (R2010b) on Mac OS X  Version: 10.6.4 Build: 10F569
%
% created by: Jonas Dorn
% DATE: 06-Oct-2010
%
% Last revision $Rev: 3092 $ $Date: 2012-09-25 11:30:28 -0400 (Tue, 25 Sep 2012) $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% test input
if nargin < 1 || isempty(lblImg) || ndims(lblImg)>2
    error('lblImg has to be a nonempty labeled 2D image')
end
if nargin < 2 || isempty(n)
    n = inf;
end
if nargin < 3 || isempty(holes)
    holes = true;
end
if holes
    holeOpt = 'holes';
else
    holeOpt = 'noholes';
end

% for each label: get external and internal boundaries, cat with NaN.
lblList = unique(lblImg(:));
lblList(lblList==0) = []; % zero is background

borderList = cell(length(lblList),1);

% don't continue if there's nothing to be found.
if isempty(lblList)
    return
end

% if we were interested in the border pixels only, not in an ordered list,
% we could simply write
% ei = imerode(lblImg,circleMask([3 3]));
% di = imdilate(lblImg,circleMask([3 3]));
% boundaries = ei~=lblImg | di~=lblImg;

for lbl = lblList'
    % use 8-connectivity (Matlab default) for smoother boundary
    border = bwboundaries(lblImg==lbl,8,holeOpt);
    
    % reduce length of outer border if requested
    if isfinite(n)
        bb = border{1};
        nb = size(bb,1);
        idx = unique(round(linspace(1,nb,min(n,nb))));
        bb = bb(idx,:);
        border{1} = bb;
    end
    
    
    % augment with separating NaNs if necessary
    if length(border) > 1
        [border{:,2}] = deal(NaN(1,2));
        border = border';
        border = border(:);
        border = {cat(1,border{:})};
    end
    
    % store in list
    borderList(lbl==lblList) = border;
end
