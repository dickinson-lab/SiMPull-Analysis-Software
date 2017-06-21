function [nseImg,rawImage,statsImage,statsFNImage,coordinate] = createNoiseImage(varargin)
%CREATENOISEIMAGE create a noiseImage with a number of feature at a designated SNR.
%
% SYNOPSIS: [nseImg,rawImage,StatsImage,statsFNImage,coordinate] = createNoiseImage(varargin)
%
% INPUT 
%       
%
%       The following propertyName/propertyValue pairs are supported:
%
%        rawImage(opt) :   Image used to make noise on. If not given, create
%                         one from piece.
%
%       imageSize(opt) :  image size desired for the noisy image to be.
%                         Default:512x512
%
%       snr(opt) :        signal to noise ratio of the image to be created.
%                         Default:2
%
%       featureSize(opt) :Sigma used in the creating of the spots.
%                         Default:2
%       random(opt)   :   1 - ellipsoide and circle while be created.
%                         0 - no random feature generation.
%                         Def : 0
%       rotation(opt) :   1 - random rotation of the feature.
%                         0 - no rotation
%                         Def : 0
%
%       poissonNse(opt) : is a vector 1-2, where the second number is the
%                         ratio of poisson noise versus gaussian.
%                         0 - no poisson noise added.
%                         1 - add poissonNoise to feature.
%                         Def : 0
%
%       randomCoord(opt): 1 - centroid coordinates are random
%                         0 - centroid coordinates are fixed
%                         Def : 1
%
%       cluster(opt) :    1 - features are created in tight cluster
%                         0 - features are evenly space.
%       nCluster(opt) :   Number of clusters of features
%                         def : 4
%
%
% OUTPUT nseImg :            Image filtered with noise is given back to the caller.
%
%        rawImage(opt) :     The raw image used to create the nseImg.
%
%        statsImage(opt) :   The image used for the ground truth.
%
%        statsFNImage(opt) : The image used for the ground truth for false
%                            negatif check
%        coordinate(opt) :   The set of center coordinate of the feature.
% REMARKS
%
% SEE ALSO putSpotsND
%
% created with MATLAB ver.: 7.10.0.499 (R2010a) on Microsoft Windows 7 Version 6.1 (Build 7600)
%
% created by: Jacques Boisvert
% DATE: 20-May-2010
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%-------------------------------------
%% Default value of variable arguments
para = struct('imgSize' ,[512,512],...
    'featureSize', 2 ,...
    'snr' , 2 , ...
    'intensity',1,'random',0,'rotation',0,'poissonNse',0,'rawImage',[],...
    'randomCoord',1,'cluster',0,'nCluster',4);

fn = fieldnames(para);
%I loop through the variables names given in Parameters.
for i = 1:2:length(varargin)%(variables names are odd value of varargin
    if validatestring(varargin{i},fn)
        para.(varargin{i}) = varargin{i+1};
    end%If i find the value i replace the default value.
end

%% Creating coordinate of features.
%--------------------------------------------------------------------

%If cluster features - Create cluster coordinates
%Default nCluster = 4;
if para.cluster
    
    if para.randomCoord
        randomPt = rand(1,2) .*  ( para.imgSize - 25) + 1;
        while(size(randomPt,1) < para.nCluster)
           newP = rand(1,2) .* ( para.imgSize - 25) + 1;
           distMat = dist2Pt(randomPt,newP);
           if sum(distMat < 20) == 0
               randomPt = cat(1,randomPt,newP);
           end
        end
        co = randomPt;
    else
        %DOESN'T REALLY WORK ...
        %HACK TILL I FIX THIS
        if para.nCluster == 1
            xx = para.imgSize(1)/2;
            yy = para.imgSize(2)/2;
        else
            xx = (para.imgSize(1)/para.nCluster):(para.imgSize(1)/para.nCluster):(para.imgSize(1)-10);
            yy = (para.imgSize(2)/para.nCluster):(para.imgSize(2)/para.nCluster):(para.imgSize(2)-10);
        end
        [xx,yy] = ndgrid([xx(1),xx(end)],[yy(1),yy(end)]);
        
        co = [xx(:),yy(:)];
        
    end
    %TMP
    [clx,cly] = arrayfun(@(x,y)ndgrid(x-6:6:x+6,y-6:6:y+6),co(:,1),co(:,2),'UniformOutput',0);
    
    %[clx,cly] = arrayfun(@(x,y)ndgrid(x-10:10:x+10,y-10:10:y+10),co(:,1),co(:,2),'UniformOutput',0);
    coordinate = [];
    for idx = 1:para.nCluster
        tmpCoordinate = cat(2,clx{idx}(:),cly{idx}(:));
        coordinate = cat(1,coordinate,tmpCoordinate);
    end
    if para.randomCoord
        coordinate(:,1) = coordinate(:,1) + rand(size(coordinate(:,1),1),1) * 4 - 2;
        coordinate(:,2) = coordinate(:,2) + rand(size(coordinate(:,2),1),1) * 4 - 2;
    end
else
    %A matrix with grid 40x40 is created.
    [xx,yy] = ndgrid(24:64:(para.imgSize(1) - 10), 24:64:(para.imgSize(2)) - 10);
    %Then add a number bet1\ween -10 to 10 in x and y coordinate.
    if para.randomCoord
        xx = xx + rand(size(xx)) * 20 - 10;
        yy = yy + rand(size(yy)) * 20 - 10;
    end
    %Then created a row of coordinate.
    coordinate = [xx(:), yy(:)];
end
%--------------------------------------------------------------------
if para.random ~= 0
    %Creating sigmas.
    sigma = zeros(size(coordinate,1),2);
    for i = 1 : size(coordinate,1)
        if rand > 0.5
            sigma(i,:) = [featureSize,1];
        else
            sigma(i,:) = [featureSize,featureSize];
        end
    end
else
    sigma = para.featureSize;
end

%% Creating raw Image
if isempty(para.rawImage)
    rawImage = putSpotsND(coordinate,para.intensity,para.imgSize,sigma,[],[],para.rotation);
    rawImage(rawImage < para.intensity/10) = 0;
    
else %If the image was enter in input, coordinate set will be calculate.
    rawImage = para.rawImage;
    bwlbl = rawImage > 0.1;
    Struct = regionprops(bwlbl,'centroid');
    %regionprops give an array of structure with centroid
    coordinate = zeros(size(Struct,1),2);
    for i = 1:size(Struct,1)
        coordinate(i,:) = Struct(i,:).Centroid;
    end
end


%% Creating statistic image. Those are used for grounds truths.
statsImage = rawImage > para.intensity/10;
statsFNImage = rawImage > para.intensity/2;

if para.poissonNse(1) == 1
    sg = (1+para.poissonNse(2)) * (para.snr)^2;
    rawImagetmp = poissrnd(rawImage * sg);%Adding poisson Noise to the features.
% Adding poisson also in the background.
elseif para.poissonNse(1) == 2
    sg = (1+para.poissonNse(2)) * (para.snr)^2;
    rawImagetmp = rawImage + randn(rawImage);%Offset of 10 to add poisson inside the bg.
    rawImagetmp = poissrnd(rawImagetmp * sg);%Adding poisson Noise to the features.
end

%% Adding noise to the raw image.
if para.poissonNse(1) ~= 1
    nseImg = rawImage + randn(para.imgSize) * (para.intensity./para.snr) ;
else
    nseImg = rawImagetmp + randn(para.imgSize) * sqrt(para.poissonNse(2)*sg);
end
