%Exptracts and displays the time to bleach (i.e., the length of time a
%fluor is active before bleaching) based on an exponential fit. 

clear all;
%close all;

%Get the data from the spot counter
[matFile matPath] = uigetfile('*.mat','Choose a .mat file with data from the spot counter');
load([matPath filesep matFile]);

foundData = 0;
for b = 1:nChannels
    channel = channels{b};
    figHandles.(channel) = figure('Name',[channel ' Channel Bleaching Times'],'NextPlot','add');
    
    % Get the data
    if ~isfield(statsByColor, [channel 'StepHist'])
        continue
    end
    foundData = 1;
    
    tmax = length(gridData(1).([channel 'SpotData'])(1).intensityTrace); %This assumes all trajectories have the same length - not bulletproof but good enough for my purposes.
    bleachTimes = getBleachTimes(gridData, channel);
    
    % Convert to fraction of live fluorophores
    activeFluors = zeros(tmax,1);
    for a = 1:tmax
        activeFluors(a) = sum(a<bleachTimes);
    end
    
    %Fit and Plot 
    xaxis = (1:tmax)';
    
    expdecay = fittype('c+a*exp(b*x)',...
                       'independent','x',...
                       'coefficients',{'a','b','c'});
    f = fit(xaxis,activeFluors,expdecay,'StartPoint',[length(bleachTimes) -0.1 0]);
    
    hold on
    plot(f, xaxis, activeFluors);
    set(gca,'XLim',[0 length(xaxis)]);
    ylabel(gca,'Fraction of Active Fluors');  
    
    params = coeffvalues(f);
    text( length(xaxis)*0.5, length(bleachTimes)*0.5, {['t1/2 = ' num2str( log(0.5)/ params(2) )]; ['k = ' num2str(-params(2))]} );
    
end

if ~foundData
    msgbox('This program requires photobleaching step data.  Please run the step counter first');
end