%Plots percent colocolization as a function of (windowed) appearance time
%for dynamic SiMPull data.

function coAppearanceByWindow_editedForFigureMaking(dynData, baitChannel, preyChannel, trendWindow)

% Get data and apply filters
colocData = {dynData.([baitChannel 'SpotData']).(['appears_w_' preyChannel])};
% Manualy set based on desired filters
blinkerFilter = true;
lateAppearanceFilter = true;
nspots = length(colocData);
filterIndex = true(1,nspots);
if blinkerFilter == true
    blinker = cellfun(@(x) isnumeric(x) && ~isnan(x) && length(x)==1 && x<2500, {dynData.([baitChannel 'SpotData']).nFramesSinceLastApp});
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
for a = 1:lastWindow
    index = cell2mat({dynData.([baitChannel 'SpotData']).appearedInWindow}) == a & filterIndex;
    baitsCounted(a) = sum(~cellfun(@(x) isempty(x) || isnan(x), colocData(index)));
    coAppearing(a) = sum(cellfun(@(x) ~isempty(x) && x==true, colocData(index)));
    
end

pctColoc = 100 * (coAppearing ./ baitsCounted);

% Calculate moving (weighted) mean
baitTrend = movsum(baitsCounted,trendWindow,'omitnan');
preyTrend = movsum(coAppearing,trendWindow,'omitnan');
colocTrend = 100 * (preyTrend ./ baitTrend);

% Plot
figure
title('Co-Appearance over Time for Control Molecules (mNG::Halo)')
xlabel('Time elapsed since lysis (sec)')
x = (2.5*[1:lastWindow]);
x = bsxfun(@plus, x, 5);
yyaxis right
ylabel('Density of molecules detected with 488 nm laser')
%ylabel('Number of molecules detected with 488 nm laser')
set(gca,'ycolor','0.65,0.65,0.65')
hold on
plot(x,(baitsCounted ./ (600*600*(110^2))),'-','LineWidth',0.5,'Color','0.90,0.90,0.905')
%plot(x,baitsCounted,'-','LineWidth',0.5,'Color','0.90,0.90,0.905')
yyaxis left
ylabel('Percent Co-Appearance')
set(gca,'ycolor','k')
hold on
plot(x,pctColoc,'o','MarkerSize',2.5,'Color','k')
hold on
plot(x,colocTrend,'-','LineWidth',1,'Color','k')
end

