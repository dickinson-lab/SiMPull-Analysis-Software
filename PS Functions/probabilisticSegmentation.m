function [segImg, bgImg,imgFilterMask,stats ] = probabilisticSegmentation(img, varargin)
%PROBABILISTICSEGMENTATION segments an image by calculating feature probabilities from noise statistics
%
% The algorihm distinguishes signal from noise, requiring basically no
% parameter adjustment, and no prior knowledge about signal shape, making
% it robust and versatile, and, most of all, very convenient.
% Using the background filter option, it can do limited selection of small
% features over large features. It cannot distinguish overlapping features
% from one another. However, since the algorithm correctly identifies
% signal with high fidelity, its output can be used to replace the possibly
% unstable thresholding step of other algorithms. For example, to find
% spot-like features, probabilisticSegmentation can be used to identify the
% local intensity maxima in the image that correspond to actual signal.
%
%
% SYNOPSIS: [segImg, bgImg, imgFilterMask, stats] = probabilisticSegmentation(img, propertyName, propertyValue,...)
%
% INPUT img : 2-d or 3d  grayscale image. In case background subtraction is
%             necessary, the image is ideally passed in integer format
%             to speed up calculations. uint8 can be several times faster
%             than doubles, and even uint16 brings a speed increse.
%
%             If needed, the algorithm could be extended to higher
%             dimensionality. However, if you want to e.g. use multiple
%             timepoints at once, you might be better off passing
%             time-averaged images to probabilisticSegmentation.
%
%
%       The following propertyName/propertyValue pairs are supported:
%
%       Basic parameters
%
%		- bgFilter: filter mask size for median filter to subtract
%		    background. Filter size should be at least 1.5 times the diameter
%		    of  circular features, or 3 times the diameter of  linear features.
%		    Default: [], i.e. no background subtraction. Currently, only 2D
%		    filters are supported (each z-slice is filtered independantly).
%           If empty the median will be subtracted from the image to
%           compensate for offset before thresholding. If you do not want
%           to have the median subtracted, pass -1 for bgFilter.
%           Note that a local median filter is powerful and robust, but
%           slows down the code significantly. probabilisticSegmentation
%           thus tries to convert the image data to integer format, if the
%           minimum difference between adjacent pixels is found to be 1.
%
%           bgFilter is most likely the only parameter that you'll have to
%           set.
%
%       - fpExp : target maximum expected number of false positives per
%           image.  Default: 0.5
%           Note: For Gaussian noise and constant background, fpExp is
%           exact. For poisson noise on top of a strongly variable
%           background, fpExp might underestimate the number of false
%           positive pixels. Normally, the false positives will be
%           isolated, so if the features are sufficiently large, the false
%           positives can easily be eliminated by size. Also note that if
%           fpExp is very large or very small, the calculation for the
%           binomial probabilities saturates, meaning that different
%           extreme values of fpExp might yield the same segmentation
%           results.
%		- imgFilter: filter mask for determining true positives. Vector
%		    containing the filter size for all the dimensions of the filter
%		    mask. Must be odd. Default: [5 5].
%           Note: a larger imgFilter will be able to detect features of
%           lower SNR, as long as they're at least as large as the filter.
%           However, a larger filter also leads to an overestimation of the
%           feature size, which may have to be corrected via an erosion
%           step. A good alternative value for imgFilter with larger
%           features is [9 9] with 'circleMask' set to 1.
%       - circleMask: if 1, the image filter is a circle instead of a
%           square
%       - verbose : switch whether or not to display segmentation results
%           and intermediate results (2D images only).
%           0 - no plotting (default)
%           1 - show result of segmentation
%           2 - as 1, but also show intermediate results
%       - poissonNoise : whether or not to estimate noise levels as
%           function of background intensity. If 1, noise is estimated as
%           the local standard deviation of the image in a window of size
%           bgFilter. Has no effect if bgFilter is empty. Default: 0
%
%       Advanced parameters
%
%       - nseMult: noise multiplier - pixels are initially accepted if
%           they're at least nseMult*sigma above background. Default:1.3
%           Note: The segmentation result doesn't depend heavily on this
%           parameter, however, probabilisticSegmentation will have
%           difficulties in finding objects with a SNR lower than nseMult.
%           Thus, you can use a high nseMult to eliminate weak features
%           that you may not be interested in.
%       - bgFun: handle to a function that estimates the background. The
%           function is called 'bgImg = bgFun(img)'. Create an anonymous
%           function if your background estimation routine requires
%           multiple parameters. If both bgFilter and bgFun are supplied,
%           bgFun has precedence.
%           Note: Use this input if you are using a faster method for
%           estimating the background than bgFilter. Unless you want to use
%           the option 'poissonNoise', you can alternatively pass an
%           already background-subtracted image to
%           probabilisticSegmentation.
%       - imgFilterMask N-d array of the Fourier transform of the
%           imgFilter (odd image size). For a 5x5 mask and a 1024x1024
%           image, imgFilterMask is the fourier transform of an 1025x1025
%           image with 0's everywhere but the center 5x5 area which is
%           filled with 1/25. If empty, it is calculated by
%           probabilisticSegmentation (and can be returned as output). To
%           speed up your segmentation (in case you aren't using slow
%           median filtering for background estimation, and in case you're
%           segmenting a batch of equally sized images), you can
%           pre-calculate the Fourier-transform of the filter in order to
%           reduce the number of Fourier-transforms done by
%           probabilisticSegmentation from 3 to 2.
%       -absImg : perform the thresholding on the absolute of the image,
%           which can be useful for dealing with DIC images. Default: 0
%           Note that you may want to test the features for whether they're
%           beyond some multiple of the noise level both in terms of
%           positive as well as negative intensities, to only select
%           features that have truly high contrast. You may also want to
%           use a larger imgFilter.
%       -filterNse: whether or not to filter the Poisson-level estimate. If
%           1, the noise is filtered with an filter mask the size of the 
%           bgFilter. This can be very useful if there are few true 
%           graylevels in the noise. If 0, no filtering is done. Default: 0
%           If 2, filtering is done using fftFilterImage, which is faster,
%           but which might have adverse border effects (1 uses fastGauss3D
%           with anti-mirror-padding). Instead of option 2, you can pass a
%           Fourier-transformed filter mask. 
%
%
%       Experimental parameters - either not fully supported yet, or not
%           yet fully tested
%
%       - fpThresh: threshold used to accept/reject a pixel to reach
%           fpExp. Default: NaN (will be calculated by the program)
%       - nse : noise. Default: NaN (will be calculated by the program)
%       - option : Post-processing option consisting of an array.
%             [option number, Threshold of pixel size to be keep]
%             0 - No post processing - Default.
%             1 - post processing with bwareaopen.
%             2 - post processing with bwareaopen and imclose.
%             3 - post processing with bwareaopen and imopen.
%       - padMode: how the image is padded for background filtering
%           'mirror' - image is mirrored. Default
%           'anti-mirror' - image is mirrored and inversed. This preserves
%               the local gradient of the image. For example, the sequence
%               [1 3 5] gets mirror-padded to [1 3 5 3 1], and anti-mirror
%               padded to [1 3 5 7 9]
%
%
%
% OUTPUT segImg: binary segmented image.
%        bgImg: estimated background (same size and class as input image)
%		 imgFilterMask: Fourier-transform of the image filter that can be
%           used as input for the next iteration
%        stats: [nseMult,fpExp,fpThresh,nse] (see input for details)
%
%
% REMARKS
%
% created with MATLAB ver.: 7.10.0.499 (R2010a) on Mac OS X  Version: 10.6.2 Build: 10C540
%
% created by: Jonas Dorn
% DATE: 28-Mar-2010

% Last revision: $Rev: 3393 $ $Date: 2013-07-24 12:51:16 -0400 (Wed, 24 Jul 2013) $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Defaults
% do not set defaults to non-empty if empty has a significance, since we
% don't allow overwriting parameters with emtpy values
def = struct('nseMult',1.3,'fpExp',0.5,...
    'fpThresh',NaN,'nse',NaN,'bgFilter',[],'imgFilter',[5,5],...
    'imgFilterMask',[],'circleMask',0,'poissonNoise',0,...
    'option',[0,0],'verbose',0,'bgFun',[],'absImg',0,'padMode','mirror',...
    'filterNse',0);

%% TEST INPUT
if nargin < 1 || isempty(img)
    error('please pass a nonempty image to probabilisticSegmentation')
end
imSize = size(img);
if length(imSize) < 3
    tmp = imSize;
    imSize = ones(1,3);
    imSize(1:length(tmp)) = tmp;
elseif length(imSize) == 3
    def.imgFilter = [5,5,3];
end

parserObj = inputParser;
parserObj.FunctionName = 'probabilisticSegmentation';

fn = fieldnames(def);
for ff = fn(:)'
    parserObj.addParamValue(ff{1},def.(ff{1}));
end

parserObj.parse(varargin{:});
para = parserObj.Results;

% overwrite empties - this means that there is a problem if there are
% meaningful empties that override non-empty defaults. However, this is
% what allows me to call the function from psDetectSpots.
for ff = fn(:)'
    if isempty(para.(ff{1}))
        para.(ff{1}) = def.(ff{1});
    end
end


if any(isEven(para.imgFilter))
    error('The image filter needs to be odd sized.');
end
if para.circleMask == 1
    para.imgFilter = circleMask(para.imgFilter);
else
    para.imgFilter = ones(para.imgFilter);
end

% if bgFun has been supplied: set bgFilter to nonempty so that it will do
% all the background estimation stuff
if ~isempty(para.bgFun)
    para.bgFilter = 1;
end

if para.verbose > 0
    % check dimensionality - don't do 3D images (yet)
    if imSize(3) > 1
        warning('PROBABILISTICSEGMENTATION:NOVERBOSITY',...
            'display of results has not been implemented yet for 3D images')
        para.verbose = 0;
    else
        % check whether show exists on the path
        if isempty(which('show'))
            show = @(im){figure,imshow(im,[])};
            % if show doesn't exist, borderOverlay won't exist, either
            overlay = 0;
        else
            show = @(im)dimshow(im);
            overlay = 1;
        end
    end
end
if para.verbose > 1
    % show raw if we're also showing intermediates, because in this case,
    % we're most likely interested in showing a series of
    % raw->threshold->segmented->overlay
    show(img);
    set(gcf,'Name','raw image')
end

%% THRESHOLD PARAMETERS
pSinglePixel = 1-normcdf(para.nseMult,0,1);
if isnan(para.fpThresh)
    %
    if para.fpExp > 1.87e5
        warning('PROBABILISTICSEGMENTATION:SATURATEDBINOCDF',...
            'fpExp higher than maximun value');
    elseif para.fpExp < 5.82e-11
        warning('PROBABILISTICSEGMENTATION:SATURATEDBINOCDF',...
            'fpExp lower than minimun value');
    end
    
    avgMaskSize = sum(para.imgFilter(:));
    expectedFT = (1-binocdf(1:avgMaskSize,avgMaskSize,pSinglePixel))...
        *prod(imSize)*(para.absImg+1);
    % find first value below 1
    para.fpThresh = find(expectedFT<para.fpExp,1,'first')/avgMaskSize;
end

%% ESTIMATE BACKGROUND

if ~isempty(para.bgFilter)
    if all(para.bgFilter > 0)
        if isempty(para.bgFun)
            
            % use median filter to estimate background
            bgImg = myMedfilt2(img,para.bgFilter,para.padMode);
            
            if para.verbose > 1
                show(bgImg)
                set(gcf,'name','background image')
            end
            
        else
            % use user-defined function for background subtraction
            bgImg = para.bgFun(img);
        end
        % cast as double because output could be negative (could be using
        % signed integers, though)
        
        bgVal = 0;
        
        if para.poissonNoise
            % original first hack, for comparison with old results
            %oldWarn = warning;
            %warning off stats:robustfit:RankDeficient
            % estimate local standard deviation
            %sdImg = stdfilt(img,ones(5));
            % robustly fit background to noise variance, since with poisson
            % noise, the variance should equal the mean.
            %u = robustfit(double(bgImg(:)),double(sdImg(:)).^2);
            %para.nse = bgImg;
            %para.nse(:) = sqrt(([ones(numel(bgImg),1),double(bgImg(:))]*u)*0.90);
            %warning(oldWarn)
            
            % estimate the Poisson noise. Since the signal may have
            % been transformed (shifted and scaled) we need to estimate the
            % "true" variance and mean by regressing the local variance
            % onto the local me(di)an signal.
            
            % To reduce the impact of non-Gaussian residuals, and to be
            % able to control the multiplicity of the data points, we
            % calculate the average variance for each background value
            
            [id,dummy,idVal] = grp2idx(bgImg(:));
            cts = accumarray(id,ones(size(id)),[],@sum);
            
            % since we're using local variance, we may not need to
            % difference the image first (also, this makes the fitting a
            % bit easier), though this leads to a slight overestimation of
            % the variance.
            varImg = stdfilt(img,ones(3)).^2;
            meanVar = accumarray(id,1:length(id),[],@(x)mean(varImg(x)));
            
            % fit variance to background. We use a sigmoid (with perfectly
            % sharp transition) at 1% of the maximum number of counts
            A = [idVal,ones(size(idVal))];
            [u,su] = lscov(double(A),meanVar,double(cts>0.01*max(cts)));
            
            % as an alternative, we could test for the significance of
            % parameters, or attempt to fit higher order polynomials to
            % guess the true signal transformation (testing for the
            % significant reduction in the residuals when changing the
            % number of free parameters using the F-statistic). In
            % anecdotal testing, this seems indeed to improve the quality
            % of the segmentation a bit.
            
            if para.verbose > 1
                dfig('name','variance regression')
                plot(idVal,meanVar,'.')
                hold on, plot(idVal, A*u,'r')
                idx = cts>0.01*max(cts);
                plot(idVal(idx),meanVar(idx),'or')
            end
            
            % calculate the "real" mu from the background image
            muMed = (double(bgImg) + u(2)/u(1))/u(1);
            
            % put intensity threshold into para.nse for simplicity
            threshold = poissinv(1-pSinglePixel,muMed);
            
            para.nse = (threshold * u(1)) - u(2)/u(1); % backtransform
            para.nse = para.nse/para.nseMult; % we'll be multiplying by nseMult below
            
            % if there are too few graylevels, the result will look pretty
            % bad. Filtering helps
            if isscalar(para.filterNse)
                if para.filterNse == 2
                    para.nse = fftFilterImage(para.nse,'gauss',para.bgFilter);
                elseif para.filterNse == 1
                    para.nse = fastGauss3D(para.nse,para.bgFilter,[],'anti-mirror');
                end
            else
                % mask has been passed
                para.nse = fftFilterImage(para.nse,para.filterNse);
            end
            
        else
            img = double(img) - double(bgImg);
        end
        
    else
        bgVal = 0;
        bgImg = [];
    end
else
    bgImg = [];
    bgVal = nanmedian(img(:));
end

%% ESTIMATE NOISE

if isnan(para.nse)
    % use all dimensions of the image that are more than 5 pixels long
    goodDim = find(imSize>5);
    if isempty(goodDim)
        error('image too small')
    end
    deltaImg = double(img); % if not double, diff fails silently to take into account negative values!
    
    for d = goodDim(:)'
        deltaImg = diff(deltaImg,3,d);  % Takes the third derivative of the image
    end
    % noise is sqrt of variance divided by 20^n (Gaussian error
    % propagation)
    % noise is standard deviation divided by sqrt(20^n)
    [dummy,stdev] = robustMean(deltaImg(isfinite(deltaImg)));
    para.nse = stdev/sqrt(20)^length(goodDim); 
    
end

%% THRESHOLD AND REFINE
if para.absImg
    segImg = abs(img) > (bgVal + para.nseMult*para.nse);
else
    segImg = img > (bgVal + para.nseMult*para.nse); % Does the thresholding; maintains pixels that are brighter than 1.3*noise above the background (median intensity by default)
end
if para.verbose > 1
    % show thresholded image
    show(segImg);
    set(gcf,'Name','thresholded image')
end
% Pre processing step, eliminate lone pixels found. - Doesn't seem to
% improve things, and could be problematic
%segImg = bwareaopen(segImg,1);

% remove false positives and fill in 'missing' pixels
if ~isempty(para.imgFilterMask)
    [segImg,imgFilterMask] = fftFilterImage(double(segImg),para.imgFilterMask);
else
    [segImg,imgFilterMask] = fftFilterImage(double(segImg),'average',para.imgFilter);
end

if para.verbose > 1
    show(segImg)
    set(gcf,'Name','filtered threshold')
end

segImg = segImg > para.fpThresh;

if para.verbose > 0
    % show cleaned image
    if para.verbose > 1 || ~overlay
        show(segImg);
        set(gcf,'Name','segmented image')
    else
        % show borderOverlay
        borderOverlay(segImg,img)
        set(gcf,'Name','segmented image')
    end
end

stats = {para.nseMult,para.fpExp,para.fpThresh,para.nse};


%% Post-Processing
switch para.option(1)
    case 1
        segImg = bwareaopen(segImg,para.option(2));
    case 2
        segImg = bwareaopen(segImg,para.option(2));
        segImg = imclose(segImg,para.imgFilter);
        segImg = bwareaopen(segImg,para.option(2));
    case 3
        segImg = bwareaopen(segImg,para.option(2));
        segImg = imopen(segImg,para.imgFilter);
        segImg = bwareaopen(segImg,para.option(2));
end

