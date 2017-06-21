function cmap = randomColors(n, cmapName)
%RANDOMCOLORS shuffles a colormap, such that the same number of colors is always shuffled the same way
%
% SYNOPSIS: cmap = randomColors(n, cmapName)
%
% INPUT n: number of entries in the colormap. Optional. Default: 24
%		cmapName: name of colormap or function handle that returns a n-by-3
%		     colormap from input n. Optional. Default: 'jet'
%
% OUTPUT cmap: n-by-3 shuffled colormap
%
% REMARKS Uses the same shuffling parameters as label2rgb in R2010b
%
% SEE ALSO label2rgb, colormap
%

% created with MATLAB ver.: 7.11.0.584 (R2010b) on Mac OS X  Version: 10.6.4 Build: 10F569
%
% created by: Jonas Dorn
% DATE: 07-Oct-2010
%
% Last revision $Rev: 1511 $ $Date: 2010-10-10 22:20:35 -0400 (Sun, 10 Oct 2010) $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% check input
if nargin< 1 || isempty(n)
    n = 24;
end
if nargin < 2 || isempty(cmapName)
    cmapName = 'jet';
end

% create colormap
cmap = feval(cmapName,n);

% shuffle colormap
stream = RandStream('swb2712','seed',0);
index = randperm(stream,n);
cmap = cmap(index,:);
