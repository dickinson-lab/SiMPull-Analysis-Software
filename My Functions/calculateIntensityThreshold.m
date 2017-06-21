function [threshold, aborted] = calculateIntensityThreshold(gridData, channel, mode)
%Calculates a threshold for intensity filtering of SiMPull data

%Get the distribution of step sizes from the processed data
[stepSizes, aborted] = getStepSizes(gridData, channel, 1, 20); 
if aborted 
    warndlg('Could not get distribution of photobleaching step sizes');
    threshold = 0;
    return
end

%Fit the distribution to the sum of two log-normal distributions to estimate fluorophore intensity
[noiseFrac, mu1, mu2, sigma, localmin] = intFitLogNormMixture(stepSizes,0.2,false);

%Calculate intensity threshold
if strcmp(mode, 'Conservative') % Conservative filtering keeps 99% of the real signal
    threshold = logninv(0.01, mu2, sigma);     
elseif strcmp(mode, 'Moderate') % Moderate filtering draws the thereshold at the local minimum between the noise and signal peaks
    threshold = localmin;    
elseif strcmp(mode, 'Aggressive') % Aggressive filtering discards 99% of the noise peak
    threshold = logninv(0.99, mu1, sigma);
else
    warndlg('Invalid choice for mode parameter. Choices are "Conservative," "Moderate" or "Aggressive".');
    threshold = 0;
    aborted = true;
    return
end

%Warn if fit looks abnormal
if noiseFrac > 0.99 || noiseFrac < 0.01 || abs(mu1-mu2) < sigma 
    button = questdlg(['The data appear to be best fit by a single population. Continue with filtering?\n'...
                       'Fit parameters: ' num2str([noiseFrac mu1 mu2 sigma])],'Warning','Yes','No','No');
    if strcmp(button,'No')
        threshold = 0;
        aborted = true;
        return
    end
end
aborted = false;