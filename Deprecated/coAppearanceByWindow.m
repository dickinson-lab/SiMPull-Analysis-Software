%Plots percent colocolization as a function of (windowed) appearance time
%for dynamic SiMPull data.

function coAppearanceByWindow(dynData,params)
% Set an arbirtary trendWindow.
trendWindow = 50;

% Calculate % colocalization for molecules appearing in each time window
colocData = {dynData.([baitChannel 'SpotData']).(['appears_w_' preyChannel])};
lastWindow = max(cell2mat({dynData.([baitChannel 'SpotData']).appearedInWindow}));
baitsCounted = zeros(1, lastWindow);
coAppearing = zeros(1,lastWindow);
for a = 1:lastWindow
    index = cell2mat({dynData.([baitChannel 'SpotData']).appearedInWindow}) == a;
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
xlabel('Time (sec)')
x = (2.5*[1:lastWindow]);
yyaxis right
ylabel('Number of Bait Spots')
set(gca,'ycolor','0.65,0.65,0.65')
hold on
plot(x,baitsCounted,'-','LineWidth',0.5,'Color','0.90,0.90,0.905')
yyaxis left
ylabel('Percent Co-Appearance')
set(gca,'ycolor','k')
hold on
plot(x,pctColoc,'o','MarkerSize',2.5,'Color','k')
hold on
plot(x,colocTrend,'-','LineWidth',1,'Color','k')
end

