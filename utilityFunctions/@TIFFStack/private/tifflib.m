function varargout = tifflib(varargin)
%Shim to tifflib, which is built-in in versions starting with R2024b
try
    [varargout{1:nargout}] = matlab.internal.imagesci.tifflib(varargin{:});
catch
    [varargout{1:nargout}] = tifflib(varargin{:});
end
end