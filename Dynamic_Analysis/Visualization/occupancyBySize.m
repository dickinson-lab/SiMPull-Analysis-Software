% Compares the number of fluorophores counted in bait vs prey channels for
% co-appearing spots

% Ask user for data files and tabulate co-appearance
matFiles = uipickfiles('Prompt','Select data files to analyze','Type',{'*.mat'});
table = tabulateCoAppearance(matFiles);
nFiles = length(matFiles);

%% Condense and Plot results
for c = fieldnames(table.totalCounted) %This loops over prey channels   
    preyChannel = c{1};
    coApp = zeros(nFiles,5);
    nPrey = zeros(nFiles,5);
    countedSpots = zeros(nFiles,5);
    countedMolecules = zeros(nFiles,5);
    % Calculate stats for complexes with 1-4 subunits separately
    for d = 1:4 
        coApp(:,d) = sum(table.totalCoApp.(preyChannel)(:,:,d),2,'omitnan');
        nPrey(:,d) = sum(table.total_nPrey.(preyChannel)(:,:,d),2,'omitnan');
        countedSpots(:,d) = sum(table.totalCounted.(preyChannel)(:,:,d),2,'omitnan');
        countedMolecules(:,d) = d*countedSpots(:,d);
        disp(['N(' num2str(d) ')=' num2str(sum(countedSpots(:,d)))]);
    end
    % Pool complexes with 5+ subunits since these are rarer
    [~,~,maxSize] = size(table.totalCoApp.(preyChannel));

    for d = 5:maxSize
        coApp(:,5) = coApp(:,5) + sum(table.totalCoApp.(preyChannel)(:,:,d),2,'omitnan');
        nPrey(:,5) = nPrey(:,5) + sum(table.total_nPrey.(preyChannel)(:,:,d),2,'omitnan');
        countedSpots(:,5) = countedSpots(:,5) + sum(table.totalCounted.(preyChannel)(:,:,d),2,'omitnan');
        countedMolecules(:,5) = countedMolecules(:,5) + d*sum(table.totalCounted.(preyChannel)(:,:,d),2,'omitnan');
    end
    pctCoApp = 100 * (coApp ./ countedSpots );
    Occupancy = nPrey ./ countedMolecules;
    disp(['N(5+)=' num2str(sum(countedSpots(:,5)))]);
    % Plot
    plotSpreadBubble(pctCoApp,'showWeightedMean',true);
    title('Percent Co-Appearance');
    plotSpreadBubble(Occupancy,'showWeightedMean',true);
    title('Average prey molecules per bait molecule');
end