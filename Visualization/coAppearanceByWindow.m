%Plots percent colocolization as a function of (windowed) appearance time
%for dynamic SiMPull data.

function coAppearanceByWindow(dynData, baitChannel, preyChannel, trendWindow)

% Calculate % colocalization for molecules appearing in each time window
colocData = {dynData.([baitChannel 'SpotData']).(['appears_w_' preyChannel])};
lastWindow = max(cell2mat({dynData.([baitChannel 'SpotData']).appearedInWindow}));
baitsCounted = zeros(1, lastWindow);
coAppearing = zeros(1,lastWindow);
for a = 1:lastWindow
    index = cell2mat({dynData.([baitChannel 'SpotData']).appearedInWindow}) == a;
    baitsCounted(a) = sum(~cellfun(@isnan, colocData(index)));
    coAppearing(a) = sum(cellfun(@(x) x==true, colocData(index)));
    
end
pctColoc = 100 * (coAppearing ./ baitsCounted);

% Calculate moving (weighted) mean
x = 1:lastWindow;
baitTrend = movsum(baitsCounted,trendWindow,'omitnan');
preyTrend = movsum(coAppearing,trendWindow,'omitnan');
colocTrend = 100 * (preyTrend ./ baitTrend);

% Plot
plot(x,pctColoc,'o')
hold on
plot(x,colocTrend,'-')

end

