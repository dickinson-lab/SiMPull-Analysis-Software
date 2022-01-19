%Plots percent colocolization as a function of (windowed) appearance time
%for dynamic SiMPull data.

% Call coAppearanceByWindow_expFit(dynData, params, tOffset) to run using data in the workspace.
% The tOffset parameter is optional - default = 0
% Call coAppearanceByWindow_expFit(tOffset) or simply coAppearanceByWindow_expFit() to ask the user for a file to analyze. 

function coAppearanceByWindow_expFit(varargin)

% Manualy set based on desired filters
blinkerFilter = true;
lateAppearanceFilter = true;
lowDensityFilter = true;
highDensityFilter = false;

% Check input, get file if necessary
if nargin == 0
    [matFile, matPath] = uigetfile('*.mat','Choose a .mat file with dynamic data from the automated analysis');
    load([matPath filesep matFile]);
    tOffset = 0;
elseif nargin == 3 
    dynData = varargin{1}; params = varargin{2}; tOffset = varargin{3};
elseif nargin == 2
    dynData = varargin{1}; params = varargin{2};
    tOffset = 0;
elseif nargin == 1 && isnumeric(varargin{1})
    [matFile, matPath] = uigetfile('*.mat','Choose a .mat file with dynamic data from the automated analysis');
    load([matPath filesep matFile]);
    tOffset = varargin{1};    
else 
    error('Wrong number of input arguments.');
end
baitChannel = params.BaitChannel; preyChannel = params.PreyChannel;
imgArea = params.RegistrationData.SpatialRefObj.ImageSize(1) * params.RegistrationData.SpatialRefObj.ImageSize(2) * params.pixelSize^2;

% Get data and apply filters
colocData = {dynData.([baitChannel 'SpotData']).(['appears_w_' preyChannel])};
nspots = length(colocData);
filterIndex = true(1,nspots);
if blinkerFilter == true
    blinker = cellfun(@(x) isnumeric(x) && length(x)==1 && ~isnan(x) && x<2500, {dynData.([baitChannel 'SpotData']).nFramesSinceLastApp});
    filterIndex = filterIndex & ~blinker;
end
if lateAppearanceFilter
    late = false(1,nspots);
    for b = 1:nspots
        late(b) = isnumeric(dynData.([baitChannel 'SpotData'])(b).appearTime) && dynData.([baitChannel 'SpotData'])(b).appearTime > 50 * (dynData.([baitChannel 'SpotData'])(b).appearedInWindow + 1);
    end
    filterIndex = filterIndex & ~late;
end

% Calculate % colocalization for molecules appearing in each time window
lastWindow = max(cell2mat({dynData.([baitChannel 'SpotData']).appearedInWindow}));
baitsCounted = zeros(1, lastWindow);
coAppearing = zeros(1,lastWindow);
dBDensity = zeros(1,lastWindow);
for a = 1:lastWindow
    index = cell2mat({dynData.([baitChannel 'SpotData']).appearedInWindow}) == a & filterIndex;
    baitsCounted(a) = sum(~cellfun(@(x) isempty(x) || isnan(x), colocData(index)));
    coAppearing(a) = sum(cellfun(@(x) ~isempty(x) && x==true, colocData(index)));
    dBDensity(a) = (sum(index))/imgArea;
end

% Filter out the appropriate windows if filtering by density
if lowDensityFilter == true
    for a = 1:lastWindow
        if dBDensity(a) < 2e-9
            baitsCounted(a) = NaN;
            coAppearing(a) = NaN;
        end
    end
end


pctColoc = 100 * (coAppearing ./ baitsCounted);
index = ~isnan(pctColoc);

% Plot
figure
title('Co-Appearance over Time')
xlabel('Time elapsed since lysis (sec)')
x = (2.5*[1:lastWindow]);
x = bsxfun(@plus, x, tOffset);
ylabel('Percent Co-Appearance')
set(gca,'ycolor','k')
hold on
% plot(x(index),pctColoc(index),'o','MarkerSize',2.5,'Color','k')

% Exponential fit

% Original version using ezyfit
% fit = showfit('a*exp(-b*x) + c; a=50; b=.001; c=1');

% if fit.m(3) < 0
%     fit = showfit('a*exp(-b*x); a=50; b=.001','fitcolor','red');
%     disp('koff estimate:')
%     disp(['   koff = ' num2str( fit.m(2) ) ])
% else
%     disp('koff estimate:')
%     disp(['   Peq (uncorrected) = ' num2str( fit.m(3) ) '%'])
%     disp(['   koff = ' num2str( (1 - fit.m(3)/100)*fit.m(2) ) ])
% end

% New version using curve fitting toolbox (more rigorous)

opts = fitoptions('Method','NonlinearLeastSquares',...
               'Lower',[0,-inf,0],...
               'StartPoint',[50,0.001,1]);
expdecay = fittype('a*exp(-b*x)+c',...
                   'independent','x',...
                   'coefficients',{'a','b','c'},...
                   'options',opts);

% Fit all data
[f0, gof0] = fit(x(index)',pctColoc(index)',expdecay);
hold on
scatter(x(index), pctColoc(index),'o');
plot(f0,'predobs')
f0_CI = confint(f0);
disp('')
disp('Results for all data')
disp(['   Peq (uncorrected) = ' num2str( f0.c ) '%' ])
disp(['   koff = ' num2str( (1 - f0.c/100)*f0.b ) ' s^-1   (' num2str( (1 - f0.c/100)*f0_CI(1,2) ) ', ' num2str( (1 - f0.c/100)*f0_CI(2,2) ) ')'])
disp(['   R^2 = ' num2str(gof0.adjrsquare)])

% Fit starting 60 seconds after lysis
[f60, gof60] = fit(x(index)',pctColoc(index)',expdecay,'Exclude',x(index)<60);
plot(f60,'m','predobs');
f60_CI = confint(f60);
disp('')
disp('Results for data starting at 60s')
disp(['   Peq (uncorrected) = ' num2str( f60.c ) '%' ])
disp(['   koff = ' num2str( (1 - f60.c/100)*f60.b ) ' s^-1   (' num2str( (1 - f60.c/100)*f60_CI(1,2) ) ', ' num2str( (1 - f60.c/100)*f60_CI(2,2) ) ')'])
disp(['   R^2 = ' num2str(gof60.adjrsquare)])

end

