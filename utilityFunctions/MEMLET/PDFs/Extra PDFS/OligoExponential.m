function [probability] = OligoExponential(x,A1,alpha,varargin)
if nargin==3
   probability = A1*alpha.^(x-1);
else
    if nargin==4;
        tmin=varargin{1};
        tmax=50;
    elseif nargin==5;
        tmin=varargin{1};
        tmax=varargin{2};
    end 
% custom PDF for oligomer exponential distribution
%   Detailed explanation goes here

% is there a pre-defined constant for pi?
%if not

% pi = 3.14159265359;

probability = A1*alpha.^(x-1);
dataWindow = tmin:tmax;
probability=probability/( sum(A1*alpha.^(dataWindow-1)) ); %Normalize PDF
end 
end

