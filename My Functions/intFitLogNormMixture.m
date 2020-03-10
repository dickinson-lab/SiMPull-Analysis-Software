%Fits a histrogram to a mixture of two binomial distributions.
%Inputs: data, estimated noise fraction p1, show plots (logical)
function [noiseFrac, mu1, mu2, sigma, localmin] = intFitLogNormMixture(varargin)
    %Parse Input
    if nargin < 1
        % Get data from user if not supplied on command line
        [filename,pathname] = uigetfile(pwd,'Select a .mat file with data from the spot counter');
        infile = [pathname filesep filename];
        load(infile);
        if nChannels > 1
            color = questdlg('Multi-Channel Data Found. Select Channel to Display',...
                               'Select Channel',...
                               channels{:},channels{1});
        else
            color = channels{1};
        end
        [data, aborted] = getStepSizes(gridData, color, 1, 20); 
    else
        data = varargin{1};
    end
    if nargin < 2
        p1Start = 0.2;
    else
        p1Start = varargin{2};
    end
    if nargin < 3
        plotResults = true;
    else
        plotResults = varargin{3};
    end

    logdata = log(data);
    pdf_mixture = @(x, p1, mu1, mu2, sigma)...
                    p1*lognpdf(x,mu1,sigma) + (1-p1)*lognpdf(x,mu2,sigma);

    %Parameters
    sigmaStart = sqrt(var(logdata));
    muStart = log(quantile(data,[.25 .75]));
    start = [p1Start muStart sigmaStart];
    lb = [0 0 0 0];
    ub = [1 Inf Inf Inf];
    options = statset('MaxIter',5000, 'MaxFunEvals',10000);
    
    %Rum MLE
    paramEsts = mle(data, 'pdf',pdf_mixture, 'start',start, 'lower',lb, 'upper',ub, 'options',options);
    if paramEsts(2) > paramEsts(3)
        noiseFrac = 1 - paramEsts(1);
    else
        noiseFrac = paramEsts(1);
    end
    mu1 = min(paramEsts(2:3));
    mu2 = max(paramEsts(2:3));
    sigma = paramEsts(4);
    
    %Find the local minimum between the noise peak and the signal peak
    pdf_fit = @(x) pdf_mixture(x, noiseFrac, mu1, mu2, sigma);
    localmin = fminbnd(pdf_fit, exp(mu1-sigma^2), exp(mu2-sigma^2));
    
    if plotResults
        %Plot Results (PDF)
        figure;
        binwidth = round(max(data)/100);
        bins = [0:binwidth:max(data)];
        datahist = histc(data,bins);
        h = bar(bins,datahist);
        set(h,'FaceColor',[.9 .9 .9]);
        xgrid = linspace(min([0 0.9*min(data) 1.1*min(data)]),1.1*max(data),200);
        dist1pdfgrid = noiseFrac*lognpdf(xgrid,mu1,sigma);
        dist2pdfgrid = (1-noiseFrac)*lognpdf(xgrid,mu2,sigma);
        pdfgrid = pdf_fit(xgrid);
        %pdfgrid = pdf_mixture(xgrid,paramEsts(1),paramEsts(2),paramEsts(3),paramEsts(4));
        scale = max(datahist)/max(pdfgrid);
        hold on; 
            plot(xgrid,dist1pdfgrid.*scale,'-r','linewidth',2);
            plot(xgrid,dist2pdfgrid.*scale,'-r','linewidth',2);
            plot(xgrid,pdfgrid.*scale,'-','linewidth',2);
            bar(logninv(0.99,mu1,sigma), max(datahist), 'FaceColor',[0.5 0 0],'EdgeColor','none','Barwidth',10);
            bar(localmin,max(datahist),'FaceColor',[0.5 0.5 0],'EdgeColor','none','Barwidth',10);
            bar(logninv(0.01,mu2,sigma), max(datahist), 'FaceColor',[0 0.5 0],'EdgeColor','none','Barwidth',10);
        hold off
        xlabel('intensity'); ylabel('Probability Density');

        %Plot Results (CDF)
        figure;
        scale = max(cumsum(datahist))/max(cumsum(pdfgrid));
        hold on;
            plot(bins,cumsum(datahist),'ok','MarkerSize',8);
            plot(xgrid,cumsum(pdfgrid).*scale,'-b','linewidth',2);
        hold off
        xlabel('intensity'); ylabel('Cumulative Probability');
    end