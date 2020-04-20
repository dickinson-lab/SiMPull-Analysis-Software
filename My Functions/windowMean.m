function [avgImg] = windowMean(img, window)
%WINDOWMEAN takes an image series (a 3d matrix with time in the third
%dimension) and produces a smaller image series where each frame is an
%average of a number of frames specified by window. The result is similar
%to what one would have gotten by acquiring images using a longer exposure. 

[ymax, xmax, tmax] = size(img);
nMeans = floor(tmax/window); %Here floor is used to average only windows that fit evenly into the image length
avgImg = zeros(ymax,xmax,nMeans);
progress = waitbar(0,'Calculating windowed average (this may take a while)');
for a = 1:nMeans
    waitbar((a-1)/nMeans,progress);
    avgImg(:,:,a) = mean(img(:,:, ( (a-1)*window + 1 ) : a*window ), 3);
end
close(progress);

if mod(tmax,window) ~= 0 %If there are extra frames, average them and append to the end of the average image
    avgImg(:,:,end+1) = mean(img(:,:, (nMeans*window + 1):end), 3);
end

end

