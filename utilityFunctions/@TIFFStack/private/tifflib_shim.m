function varargout = tifflib(varargin)
%Shim to tifflib, which is built-in in versions starting with R2024b
if isMATLABReleaseOlderThan("R2024b")
    try
        [varargout{1:nargout}] = matlab.internal.imagesci.tifflib(varargin{:});
    catch ERR
        error(ERR.msg)
    end
end
end