function [p,ip,m] = serpind(s)
% Return serpentine indexing list for array size s.
%
% syntax:
%   p = serpind(s);
%   [p,ip] = serpind(s);
%   [p,ip,m] = serpind(s);
%
% input arg:
%
%   s (size-[1,N] array of non-negative integers): array size
%
% output args:
%
%   p (size-[M,1] array of non-negative integers; M = prod(s)): flat indexing list for
%   serpentine array traversal (p is a permutation of (1:M).'.)
%
%   ip (size-[M,1] array of non-negative integers; optional output): inverse permutation
%   of p
%
%   m (size-[M,N] array of non-negative integers; optional output): N-dimensional array
%   subscripts corresponding to p
%
% Each element p(j) corresponds to a multidimensional array subscript list m(j,1:N)
% defined by
%   [m(j,1), m(j,2), ... m(j,N)] = ind2sub(s,p(j))
% The subscript lists m(1,:), m(2,:), ... traverse the set of all indices for a size-s
% array (i.e., 1 <= m(j,k) <= s(k) for each j = 1:M, k = 1:N). The "serpentine"
% traversal order has the property that m(j,:) and m(j+1,:) differ in only one dimension
% index, and the difference in that index is either +1 or -1.
%
% The index list p is a permutation of (1:M).', and its inverse is ip (i.e., p(ip) =
% (1:M).'). Thus, for an array A, the two sequential operations
%   A = A(p);
%   A = A(ip);
% are equivalent to
%   A = A(:);
%
% The elements of a size-s array A can be sequenced in serpentine order as follows,
%   s = size(A);
%   [p,ip] = serpind(s);
%   A = A(p);
% The original array can then be reconstructed as follows:
%   A = reshape(A(ip),s);
%
% Version 04/09/2006
% Author: Kenneth C. Johnson
% software.kjinnovation.com
%
% See ZipInterp.pdf, Section 9.4 ("Seed chaining"), on the KJ Innovation website for an
% application example illustrating the use of serpind.m.
%

N = length(s);
M = prod(s);
p = zeros(M,1);
if M==0
    if nargout>=2
        ip = p;
        if nargout>=3
            m = zeros(0,N);
        end
    end
    return
end
p(1) = 1;
len = 1;
stride = 1;
for k = 1:N
    L = len;
    for j=2:s(k)
        p(len+1:len+L) = p(len:-1:len-L+1)+stride;
        len = len+L;
    end
    stride = stride*s(k);
end
if nargout>=2
    ip(p,1) = (1:M).';
    if nargout>=3
        [m{1:N}] = ind2sub(s,p);
        m = cell2mat(m);
    end
end
