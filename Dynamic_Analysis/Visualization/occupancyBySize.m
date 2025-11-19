% Compares the number of fluorophores counted in bait vs prey channels for
% co-appearing spots

% Ask user for data files and tabulate co-appearance
matFiles = uipickfiles('Prompt','Select data files to analyze','Type',{'*.mat'});
table = tabulateCoAppearance(matFiles);
nFiles = length(matFiles);

% Condense and Plot results
for c = fieldnames(table.totalCounted) %This loops over prey channels   
    preyChannel = c{1};
    pctCoApp = zeros(nFiles,1);
    pctOcc = zeros(nFiles,1);
    % Calculate stats for complexes with 1-4 subunits separately
    for d = 1:4 
        coApp = sum(table.totalCoApp.(preyChannel)(:,:,d),2,'omitnan');
        nPrey = sum(table.total_nPrey.(preyChannel)(:,:,d),2,'omitnan');
        counted = sum(table.totalCounted.(preyChannel)(:,:,d),2,'omitnan');
        countedMolecules = d*counted;
        pctCoApp(:,d) = 100 * (coApp ./ counted );
        pctOcc(:,d) = 100 * (nPrey ./ (countedMolecules) );
        disp(['N(' num2str(d) ')=' num2str(sum(counted))]);
    end
    % Pool complexes with 5+ subunits since these are rarer
    [~,~,maxSize] = size(table.totalCoApp.(preyChannel));
    coApp = zeros(nFiles,1);
    nPrey = zeros(nFiles,1);
    counted = zeros(nFiles,1);
    countedMolecules = zeros(nFiles,1);
    for d = 5:maxSize
        coApp = coApp + sum(table.totalCoApp.(preyChannel)(:,:,d),2,'omitnan');
        nPrey = nPrey + sum(table.total_nPrey.(preyChannel)(:,:,d),2,'omitnan');
        counted = counted + sum(table.totalCounted.(preyChannel)(:,:,d),2,'omitnan');
        countedMolecules = countedMolecules + d*sum(table.totalCounted.(preyChannel)(:,:,d),2,'omitnan');
    end
    pctCoApp(:,5) = 100 * (coApp ./ counted );
    pctOcc(:,5) = 100 * (nPrey ./ countedMolecules );
    % Plot
    plotSpreadBubble(pctCoApp,'showWeightedMean',true);
    title('Percent Co-Appearance');
    plotSpreadBubble(pctOcc,'showWeightedMean',true);
    title(['Fraction of binding sites occupied' newline '(assuming 1:1 stoichiometry)']);
end