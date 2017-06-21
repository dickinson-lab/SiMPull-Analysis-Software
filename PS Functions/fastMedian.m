function med = fastMedian(data,dim)
%FASTMEDIAN is a wrapper for fast_median
%
% SYNOPSIS: med = fastMedian(data,dim)
%
% INPUT data: n-d numeric array
%		dim : dimension along which the median should be calculated.
%             Optional. Default: 1
%
% OUTPUT med: median. Note that NaN in the input will lead to NaN in the output
%
% REMARKS
%
% SEE ALSO median, fast_median
%

% created with MATLAB ver.: 7.12.0.635 (R2011a) on Mac OS X  Version: 10.6.7 Build: 10J869 
%
% created by: Jonas Dorn
% DATE: 04-May-2011
%
% Last revision $Rev: 2495 $ $Date: 2012-02-21 17:06:36 -0500 (Tue, 21 Feb 2012) $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% check input
if nargin < 1 || ~isnumeric(data)
    error('data needs to be numeric');
elseif isempty(data)
    med = [];return
end

if nargin < 2 || isempty(dim)
    dim = 1;
end

try
% check dimensions. If 2, we can use fast_median directly
numDims = ndims(data);

if numDims == 2
    if dim == 1
        med = fast_median(data);
    else
        med = fast_median(data')';
    end
else
    % reshape/reorder data such that it becomes a 2d array of which we can
    % take the median along the first dimension
    dimOrder = [dim,1:dim-1,dim+1:numDims];
    dataSize = size(data);
    data = reshape(permute(data,dimOrder),dataSize(dim),[]);
    med = fast_median(data);
    dataSizeR = dataSize(dimOrder);
    med = reshape(med,[1,dataSizeR(2:end)]);
    med = permute(med,dimOrder(dimOrder));
end
catch me
    if strcmp(me.identifier,'MATLAB:scriptNotAFunction')
        % R2008b issue (I guess)
        med = median(data,dim);
    else
        rethrow(me)
    end
end