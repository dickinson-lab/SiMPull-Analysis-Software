        % Set up 
        if strcmp(dataType, 'MetaMorph TIFF')
            nPositions = length(fileList) / nChannels;
            fileCounter = 1;
        else
            nPositions = length(fileList);
        end
        gridHeight = ceil(nPositions/gridWidth);
        gridData(1:gridHeight,1:gridWidth) = struct('nd2Dir',nd2Dir,...
                                                    'tiffDir',nd2Dir,...
                                                    'imageName',[]);
        index = serpind(size(gridData));

        params.psfSize = psfSize;
        params.fpExp = fpExp;
        params.poissonNoise = poissonNoise;

        %Get Images and Find Spots
        spotwb = waitbar(0, 'Finding Spots...');
        for b = 1:nPositions
            if strcmp(dataType, 'Nikon ND2') % For Nikon files, load data here.  Metamorph TIFF files are loaded for each channel individually, below
                imageName = fileList(b).name;
                rawImage = squeeze(bfread([nd2Dir filesep fileList(b).name],1,'Timepoints','all','ShowProgress',false));
                [ymax, xmax, tmax] = size(rawImage);
                params.imageName = imageName(1:(length(imageName)-4));
                gridData(index(b)).imageName = params.imageName;
            end

            for i = 1:nChannels % This loop finds spots in the reference channel
                color = channels{i};
                if strcmp(color, refChannel) % Only detect spots for the reference channel
                    if strcmp(dataType, 'MetaMorph TIFF') %Load MetaMorph TIFF Data
                        imageName = fileList(fileCounter).name;
                        waitbar( (b-1)/nPositions, spotwb, ['Finding ' color ' Spots in image ' strrep(imageName,'_','\_') '...'] );
                        thisImage = squeeze(bfread([nd2Dir filesep fileList(fileCounter).name],1,'Timepoints','all','ShowProgress',false));
                        fileCounter = fileCounter + 1;
                        [ymax, xmax, tmax] = size(thisImage);
                        imageLength = tmax; %For MetaMorph TIFF files that are separated by wavelength, the whole timeseries will be analyzed
                        %Make sure we've loaded an image of the correct color
                        wavePos = strfind( imageName, wavelengths.(color){1} );
                        if isempty(wavePos) %If the first wavelength wasn't found, try the second (could make this a loop in the future if support for more wavelengths is needed)
                            wavePos = strfind( imageName, wavelengths.(color){2} );
                        end
                        if isempty(wavePos) 
                            errordlg('An image of the wrong channel was loaded');
                            close(bigwb);
                            close(spotwb);
                            return
                        end
                        params.imageName = imageName( 1:(wavePos-2) );
                        gridData(index(b)).imageName = params.imageName;
                    end
                    if strcmp(dataType, 'Nikon ND2')
                        waitbar( (b-1)/nPositions, spotwb, ['Finding ' color ' Spots in image ' strrep(imageName,'_','\_') '...'] );
                        % Check that the selected range of times is present in the data (only required for Nikon ND2 files)
                        timeRange1 = Answer.([color 'Range1']);
                        timeRange2 = Answer.([color 'Range2']);
                        if timeRange2 > tmax
                            warning(['The time range entered for the green channel is outside the limits of the data for image' strrep(imageName,'_','\_')]);
                            imageLength = tmax + 1 - timeRange1;
                        else
                            imageLength = timeRange2 + 1 - timeRange1;
                        end
                        % Grab the appropriate portion of the image
                        thisImage = rawImage(:,:,timeRange1:min(timeRange2,tmax));
                    end
                    % Determine the window to average over 
                    if firstTime < 1 
                        params.firstTime = 1;
                    else
                        params.firstTime = firstTime;
                    end
                    if lastTime > imageLength
                        params.lastTime = imageLength;
                    else
                        params.lastTime = lastTime;
                    end
                    % Actually do the spot counting
                    resultsStruct = spotcount_ps(color,thisImage,params,gridData(index(b)));
                    gridData(index(b)).([color 'SpotData']) = resultsStruct.([color 'SpotData']);
                    gridData(index(b)).([color 'SpotCount']) = resultsStruct.([color 'SpotCount']);
                    clear resultsStruct;
                end
            end
            for ii = 1:nChannels % This loop extracts intensity traces for the non-reference channels
                color = channels{ii};
                if strcmp(color, refChannel) % Skips the reference channel
                    continue
                end
                % Get image data
                if strcmp(dataType, 'Nikon ND2')
                    waitbar( (b-1)/nPositions, spotwb, ['Extracting ' color ' intensity traces from image ' strrep(imageName,'_','\_') '...'] );
                    % Check that the selected range of times is present in the data (only required for Nikon ND2 files)
                    timeRange1 = Answer.([color 'Range1']);
                    timeRange2 = Answer.([color 'Range2']);
                    if timeRange2 > tmax
                        warning(['The time range entered for the green channel is outside the limits of the data for image' strrep(imageName,'_','\_')]);
                        imageLength = tmax + 1 - timeRange1;
                    else
                        imageLength = timeRange2 + 1 - timeRange1;
                    end
                    % Grab the appropriate portion of the image
                    thisImage = rawImage(:,:,timeRange1:min(timeRange2,tmax));
                end
                % Extract intensity traces
                nPeaks = gridData(index(b)).([refChannel 'SpotCount']);
                if nPeaks > 0 
                    for e = 1:nPeaks
                        xcoord = gridData(index(b)).([refChannel 'SpotData'])(e).spotLocation(1);
                        ycoord = gridData(index(b)).([refChannel 'SpotData'])(e).spotLocation(2);
                        spotMat = thisImage(ycoord-2:ycoord+2,xcoord-2:xcoord+2,:);
                        trace5x5 = squeeze(sum(sum(spotMat,1),2));
                        BGMat = thisImage(ycoord-4:ycoord+4,xcoord-4:xcoord+4,:);
                        trace9x9 = squeeze(sum(sum(BGMat,1),2));
                        traceAvgBG = (trace9x9 - trace5x5)/(81-25);
                        trace5x5MBG = trace5x5-traceAvgBG*25;
                        gridData(index(b)).([refChannel 'SpotData'])(e).([color 'IntensityTrace']) = transpose(trace5x5MBG);
                    end
                end

            end

        end %of loop b; Loop over images in the data set for spot counting
        close(spotwb)