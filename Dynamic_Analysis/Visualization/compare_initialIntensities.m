% Measures the distribution of initial brightness for each channel in a
% dynamic SiMPull dataset

% Ask user for data files
matFiles = uipickfiles('Prompt','Select data files to analyze','Type',{'*.mat'});

sampleNames = {a};
baitIntensities = {};
preyIntensities = {};
fileBar = waitbar(0);
for a = 1:length(matFiles)  
    % Get file name
    slash = strfind(matFiles{a},filesep);
    fileName = matFiles{a}(slash(end)+1:end); 
    sampleNames{a} = strrep(fileName,'_','\_');

    % Get Directory
    if isfolder(matFiles{a})
        fileName = [fileName '.mat'];
        expDir = matFiles{a};
        if ~isfile([expDir filesep fileName])
            warndlg(['No .mat file found for selected folder ' expDir]);
            continue
        end
    else
        expDir = matFiles{a}(1:slash(end));
    end

    waitbar((a-1)/length(matFiles),fileBar,strrep(['Loading ' fileName],'_','\_'));

    % Load data structure
    load([expDir filesep fileName],'dynData','params');

    %Extract channel info - this is just for code readability
    BaitChannel = params.BaitChannel;

    % Check if we have photobleaching data
    maxSteps = 1;
    if isfield(dynData.BaitSpotData,'nFluors')
        if maxSteps < max([dynData.BaitSpotData.nFluors])
            maxSteps = max([dynData.BaitSpotData.nFluors]);
        end
    else
        warning(['Dataset ' fileName ' is missing photobleaching step data.' newline 'Please run countDynamicBleaching first.']);
        continue
    end  
    
    % Get the intensities for the bait channel 
    levelIdx = cellfun(@(x) length(x)>1, {dynData.BaitSpotData.steplevels} );
     tempData= cellfun(@(x) x(2) - x(1), {dynData.BaitSpotData(levelIdx).steplevels});
     baitIntensities{a} = tempData(tempData>0);

    % Get the intensities counts for coappearing spots
    for b = params.preyChNums
        coAppIdx = cellfun(@(x) islogical(x) && x==true, {dynData.BaitSpotData.(['appears_w_PreyCh' num2str(b)])} );
        levelIdx = cellfun(@(x) length(x)>1, {dynData.(['PreyCh' num2str(b) 'SpotData']).steplevels} );
         tempData = cellfun(@(x) x(2) - x(1), {dynData.(['PreyCh' num2str(b) 'SpotData'])(coAppIdx & levelIdx).steplevels});
         preyIntensities{b}{a} = tempData(tempData>0);
    end
end
close(fileBar)

% Plot results
figure('Name','Bait Intensity Histogram')
distributionPlot(baitIntensities, 'showMM',6, 'xyOri','flipped', 'xNames',sampleNames, 'histOpt',1.1, 'globalNorm',0);

for c = params.preyChNums
    figure('Name',['Prey Channel ' num2str(c) ' Intensity Histogram'])
    distributionPlot(preyIntensities{c}, 'showMM',6, 'xyOri','flipped', 'xNames',sampleNames, 'histOpt',1.1, 'globalNorm',0);
end