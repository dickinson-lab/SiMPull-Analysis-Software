function [coordinates, intensities, bg, spotMsk, psStats] = psDetectSpots(img,bgFilter,sigmaGauss,varargin)
%PSDETECTSPOTS performs spot detection using probabilistic segmentation
%
% SYNOPSIS: [coordinates, intensities, bg, spotMsk, psStats] = psDetectSpots(img,bgFilter,sigmaGauss,varargin)
%
% INPUT img: 2D or 3D image
%       bgFilter : 1-by-2 array with [sizX,sizY] of filter mask for local
%          background subtraction. Mask is ideally larger than a spot. Pass
%          empty if you do not want do perform background subtraction (i.e.
%          if background is homogeneous).
%       sigmaGauss : sigma of the gaussian for filtering before local
%          maximum detection. Suggested: ~1 pixels (the noise varies by
%          pixels, whereas your signal varies more slowly), or ~1*psf
%          Alternatively, a filter mask the same size of the image (padded
%          to odd size) of the fourier transform of the filter can be
%          supplied in sigmaGauss.
%		propertyName/propertyValue: name/value pairs to customize
%		   psDetectSpots. All are optional.
%		   psDetectSpots accepts all properties accepted by
%		   probabilisticSegmentation. In addition, it takes the follwoing:
%             rmBorder - 1-by-nDims array with border width. Features that
%                    are at least partially part of the border are removed.
%                    Default: zeros(1,nDims)
%                    Alternatively, rmBorder can be a logical array of the
%                    same size as the image with 0's wherever the signal
%                    should be removed.
%                    Note that psDetectSpots will remove spots (but that are
%                    exactly at the border (x,y, or z being equal to 1 or
%                    imageSize) regardless of rmBorder. rmBorder settings
%                    affect the regions returned by
%                    probabilisticSegmentation.
%             minSize - minimum size (in voxels) of PS features. Def.: 0
%             maxSize - maximum size (in voxels) of PS features. Def.: inf
%             keepAll - for ps-features with no local maximum, retain the
%                    largest value. Default: true
%             closeMsk - mask for morphological closure that is applied
%                        before checking for minSize/maxSize, but after
%                        removing border. Default [], i.e. no closing
%             intFilter- 2-element vector with [filterX,filterY] for
%                        background filtering for intensity estimation. To
%                        remove false positives, it may be necessary to use
%                        a relatively small bgFilter for
%                        probabilisticSegmentation. However, this will
%                        lead to an underestimation of intensities. Thus,
%                        you can supply intFilter (~2x the size of
%                        imgFilter) for a better estimation of background
%                        (and thus signal) intensities.
%             betterIntEst - Can be either 0, or an array with length of
%                        the number of image dimensions containing sigmas
%                        for a Gaussian approximation to the spot. This
%                        approximation will be used to improve the
%                        intensity estimate. Note that it is a good idea to
%                        set intFilter, because accurate intensity
%                        estimation is dependent on accurate estimation of
%                        background. Default: 0
%             blobMode - in blob mode, psDetectSpots uses
%                        probabilisticSegmentation to find blobs rather
%                        than spots. In this mode, spotMsk contains a
%                        labeled image.
%
%
%
%
%
% OUTPUT coordinates: nSpots-by-nDimensions array of spot coordinates (pixels).
%	     intensities: nSpots-by-2 array with [signal Intensity,local background]
%        bg : array of same size as image with estimated background
%        spotMsk : segmentation by probabilisticSegmentation (for debug
%           purposes)
%
% REMARKS psDetectSpots first runs probabilisticSegmentation to estimate
%         the location of signal in the image. Then, it performs Gaussina
%         filtering of the intensities before running a local maximum
%         detection. It will only retain maxima that overlap with the
%         signal mask from probabilisticSegmentation.
%
% SEE ALSO
%

% created with MATLAB ver.: 7.11.0.584 (R2010b) on Mac OS X  Version: 10.6.5 Build: 10H574
%
% created by: Jonas Dorn
% DATE: 12-Jan-2011
%
% Last revision $Rev: 3239 $ $Date: 2013-10-22 by Dan Dickinson $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% use ps-defaults for all ps-parameters
% note: subPixPos is still in the list to allow comparison testing, but
% it's not advertised in the help, since it currently leads to massive
% pixel-locking. This pseudo sub-pixel localization is worse than on-pixel
% localization because it makes people believe they get accuracy they
% don't have.
psDefaults = struct('nseMult',[],'fpExp',[],...
    'fpThresh',[],'nse',[],'imgFilter',[],...
    'imgFilterMask',[],'circleMask',[],'poissonNoise',[],...
    'option',[],'verbose',[],'bgFun',[],'absImg',[],'bgFilter',[]);
psdsDefaults = struct(...
    'rmBorder',[0 0 0],'minSize',0,'maxSize',inf,'keepAll',true,...
    'closeMsk',[],'intFilter',[],'subPixPos',false,'betterIntEst',false,...
    'blobMode',false);


%% test input

if nargin < 1 || isempty(img) || ndims(img) > 3
    error('please supply a nonempty 2D or 3D image')
end
if nargin < 2
    bgFilter = [];
end
if nargin < 3 || isempty(sigmaGauss)
    error('please supply nonempty sigma for Gaussian')
end

% use inputParser - for simplicity, keep old default structure
psParser = inputParser;
psParser.FunctionName = 'probabilisticSegmentation';
psParser.KeepUnmatched = true; % don't complain if something doesn't match
for fn = fieldnames(psDefaults)'
    psParser.addParamValue(fn{1},psDefaults.(fn{1}));
end
psParser.parse(varargin{:});
psParameters = psParser.Results;
psParameters.bgFilter = bgFilter;

psdsParser = inputParser;
psdsParser.FunctionName = 'psDetectSpots';
psdsParser.KeepUnmatched = true;
for fn = fieldnames(psdsDefaults)'
    psdsParser.addParamValue(fn{1},psdsDefaults.(fn{1}));
end
psdsParser.parse(varargin{:});
parameters = psdsParser.Results;

% check for unmatched
unmatchedParameters = fieldnames(psdsParser.Unmatched);
bothBad = intersect(unmatchedParameters,fieldnames(psParser.Unmatched));
if ~isempty(bothBad)
    error('unknown input parameter %s\n',bothBad{:});
end



% additional testing

if psParameters.absImg
    error('psDetectSpots most likely won''t work for DIC images')
end
if parameters.betterIntEst(1) > 0
    sigmaGauss = parameters.betterIntEst;
    parameters.betterIntEst = true;
end




%% run PS
[spotMsk,bg,~,psStats] = probabilisticSegmentation(img,psParameters);

% for signal, filter again if requested
if ~isempty(parameters.intFilter)
    bg = myMedfilt2(img,parameters.intFilter);
end


imgSize = ones(1,3);
imgDims = ndims(img);
imgSize(1:imgDims) = size(img);


% eliminate spotMsk-parts that are at the border etc
if ~isempty(parameters.rmBorder) && any(parameters.rmBorder(:))
    if ~isvector(parameters.rmBorder) && ndims(parameters.rmBorder) == imgDims && all(size(parameters.rmBorder) == imgSize(1:imgDims))
        spotMsk = spotMsk & parameters.rmBorder;
    else
        borderMsk = false(imgSize);
        rmBorder = zeros(1,3); % make sure rmBorder has entries for 3d
        rmBorder(1:length(parameters.rmBorder)) = parameters.rmBorder;
        borderMsk(1+rmBorder(1):end-rmBorder(1),...
            1+rmBorder(2):end-rmBorder(2),...
            1+rmBorder(3):end-rmBorder(3)) = true;
        spotMsk = spotMsk & borderMsk;
    end
end

if ~isempty(parameters.closeMsk)
    spotMsk = imclose(spotMsk,parameters.closeMsk);
end

if parameters.minSize > 0
    spotMsk = bwareaopen(spotMsk,parameters.minSize);
end

if parameters.maxSize < inf && ~parameters.blobMode
    % there is no bwareaclose, so we label, count, and eliminate
    lblMsk = bwlabeln(spotMsk);
    cts = accumarray(lblMsk(lblMsk>0),1,[],@sum);
    highCts = find(cts>parameters.maxSize);
    if ~isempty(highCts)
        lblMsk(ismember(lblMsk,highCts)) = 0;
    end
    spotMsk = lblMsk > 0;
end



if all(spotMsk(:)==0)
    % there will be no maximum because there is no signal
    coordinates = [];
    intensities = [];
else
    
    % get coordinates
    
    % split "spots" according to locMax
    % modify labelSplitLocMax so that it only returns positions (or mk
    % labelDetectLocMax)
    %spotMsk = labelSplitLocMax(spotMsk,img,0.8*PSF);
    
    % avoid turning bg, img, into doubles
    % filter @0.8 to preserve locMax as much as possible
    if isempty(bg)
        bg = ones(size(img))*fastMedian(img(:));
    else
        img = double(img); % otherwise min returns an error in R2013a
        bg = min(bg,img); % this should be ok, since wherever there is signal, the image is > bg
    end
    signal = img-bg;
    if isvector(sigmaGauss)
        fim = fftFilterImage(double(signal),'gauss',sigmaGauss);
    else
        fim = fftFilterImage(double(signal),sigmaGauss);
    end
    
    % get local maxima. Imdilate is much faster than loc_max3Df
    % nowadays. I'm not entirely sure about performance here, but
    % the 3D filter also works on 2D images
    % note that it is possible that the maximum comes to lie just outside
    % the pixel region. Thus, it may be a good idea to use 'keepAll' by
    % default
    ff = true(3,3,3);
    ff(2,2,2) = false;
    if parameters.keepAll
        % this guarantees that the intensities under the spotMsk are above
        % the ps-determined background
        fim(spotMsk) = fim(spotMsk)+max(fim(:));
        
            % make sure that weird edge effects won't make us lose some obvious
    % locmax/locmin. This also ensures that there won't be any
    % locMax/locMin at the very border
    % with this step, we ideally add a "remove border-touching
    % vesicles"-step somewhere later in the code
    if imgDims > 2
    fim(:,:,[1 end]) = 0;
    end
    fim(:,[1 end],:) = 0;
    fim([1 end],:,:) = 0;
        
    end
    

    
    maxIdx = find(fim > imdilate(fim,ff));
    maxIdx = maxIdx(spotMsk(maxIdx)); % keep only good local maxima
    
        [lm(:,1),lm(:,2),lm(:,3)] = ind2sub(imgSize,maxIdx);
    % eliminate maxima at +/- z, as well as at x,y-border, both to avoid
    % edge effects and to make our lives easier when we want to use 3x3(x3)
    % masks to calculate centroid and intensity below
    badIdx = any(lm(:,1:imgDims)==1,2) | any(bsxfun(@eq,lm(:,1:imgDims),imgSize(:,1:imgDims)),2);
    
    maxIdx(badIdx) = [];


    if parameters.blobMode
        lblImg = labelSplitLocMax(spotMsk,maxIdx);
        % check for min/max size again
        if parameters.minSize > 0 || parameters.maxSize < inf
            idxList = lblImg(lblImg>0);
            blobSize = accumarray(idxList,ones(size(idxList)),[],@sum);
            badIdx = blobSize < parameters.minSize | blobSize > parameters.maxSize;
        
        lblImg(ismember(lblImg,find(badIdx))) = 0;
        lblImg = labelRelabel(lblImg);
        end
        
        % find maxima of the blobs - not entirely sure this is required if
        % we don't go checking for min/max size
        maxIdx = zeros(max(lblImg(:)),1);
        for lbl = 1:length(maxIdx)
            idxList = find(lblImg==lbl);
            [~,mi] = max(signal(idxList));
            maxIdx(lbl) = idxList(mi);
        end
        clear lm
         [lm(:,1),lm(:,2),lm(:,3)] = ind2sub(imgSize,maxIdx);
            coordinates = lm(:,1:imgDims);

    else
            coordinates = lm(~badIdx,1:imgDims);

    end
    
    
    if isempty(maxIdx)
        intensities = [];
        return
    end
    
    
    % define intensity array using background
    intensities(:,2) = bg(maxIdx);
    
    if parameters.subPixPos || parameters.betterIntEst
        nCoords = size(coordinates,1);
        % since we're no longer using subPixelPos, we can calculate the
        % gaussMask here for speed
        switch imgDims
            case 2
                [x,y] = ndgrid(-1:1,-1:1);
                gaussCoords = [x(:),y(:)];
            case 3
                [x,y,z] = ndgrid(-1:1,-1:1,-1:1);
                gaussCoords = [x(:),y(:),z(:)];
        end
        gm = GaussListND(gaussCoords,sigmaGauss,[],0);
        
        for c = 1:nCoords
            
            % read subImage. Don't worry about going outside of the frame,
            % because we have removed at-edge-maxima above
            switch imgDims
                case 2
                    subImg = signal(coordinates(c,1)-1:coordinates(c,1)+1,...
                        coordinates(c,2)-1:coordinates(c,2)+1);
                    
                case 3
                    subImg = signal(coordinates(c,1)-1:coordinates(c,1)+1,...
                        coordinates(c,2)-1:coordinates(c,2)+1,...
                        coordinates(c,3)-1:coordinates(c,3)+1);
                    
                otherwise
                    error('parameters.centroids is not implemented for images of %i dimensions')
            end
            
            if parameters.subPixPos
                tmp = centroid3D(subImg);
                subPixelCoords = tmp(1:imgDims) - 2*ones(1,imgDims);
                coordinates(c,:) = coordinates(c,:) + subPixelCoords;
            else
                %subPixelCoords = zeros(1,imgDims);
            end
            
            
            if parameters.betterIntEst
                % do it the "slow" way for now. Later, we might want to
                % calculate 3-6 (2/3d) estimates of Gaussians, after which we
                % can interpolate to get the right result. While most likely
                % faster, this is also more complicated than simply dividing
                % (note that one could also run least squares here, with which
                % to update background as well)
                %gm = GaussListND(gaussCoords,sigmaGauss,subPixelCoords,0);
                
                intensities(c,1) = sum(subImg(:))./sum(gm);
            end
            
        end
    end
    
    
    % if we haven't done so, read intensities - take the value of the max-intensity pixel
    if ~parameters.betterIntEst
        intensities(:,1) = signal(maxIdx);
    end
    
    if parameters.blobMode
        % return relabeled image - make sure that we get the labels right!
        %referenceImg = zeros(size(spotMsk));
        %referenceImg(maxIdx) = 1:length(maxIdx);
        %spotMsk = labelRelabel(lblImg,referenceImg);
        spotMsk = lblImg;
    end
    
end