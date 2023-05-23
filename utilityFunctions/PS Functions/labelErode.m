function erodedLblImg = labelErode(lblImg,nHood)
%LABELERODE erodes a label mask by eroding each connected component individually
%
% SYNOPSIS: erodedLblImg = labelErode(lblImg,nHood)
%
% INPUT lblImg: labeled image, as returned by bwlabeln
%		nHood: neighborhood for erosion. n-d array or strel  
%
% OUTPUT erodedLblImg: labeled eroded image
%
% REMARKS   If you want to erode the image without necessarily creating a
%           separation between touching features, use imerode instead of
%           labelErode
%
% SEE ALSO  imerode, strel, labelDilate
%
% created with MATLAB ver.: 7.10.0.499 (R2010a) on Microsoft Windows 7 Version 6.1 (Build 7600)
%
% created by: Jonas Dorn
% DATE: 09-Jun-2010
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% check input

if nargin < 1 || isempty(lblImg) || isempty(nHood) || islogical(lblImg)
    error('labelERode requires a nonempty labeled image as well as a nonempty neighborhood')
end


% loop through features to erode
lblList = unique(lblImg(:));
lblList(lblList==0) = []; % zero is background

erodedLblImg = zeros(size(lblImg));

for lbl = lblList(:)'
    erodedLblImg = erodedLblImg + double(imerode(lblImg==lbl,nHood))*double(lbl);
end