% Averages several frames of an image time series to produce a single 2d
% image with higher signal:noise. The "params" input structure must at a
% minimum include the following fielsds: 
%   -firstTime (start of averaging window) 
%   -lastTime (end of averaging window)
%   -imageName (can be any string; for saving)

function [avgImage] = averageImage(rawImage, channel, params)
    [ymax, xmax, tmax] = size(rawImage);
    
    % Double check that our averaging window exists
    if tmax <= params.lastTime    %If only a few frames were captured, use the whole timeseries 
        params.firstTime = 1;
        params.lastTime = tmax;
    else                    %Otherwise, use the range specified in the input
        if params.firstTime < 1 
            params.firstTime = 1;
        end
        if params.lastTime > tmax
            params.lastTime = tmax;
        end
    end
    
    %Make average image 
    avgImage = uint16( mean( rawImage(:,:,params.firstTime:params.lastTime), 3) );

end

