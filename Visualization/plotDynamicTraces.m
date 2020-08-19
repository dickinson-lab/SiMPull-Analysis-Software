function plotDynamicTraces(dynData,index)
figure
greenStart = (dynData.GreenSpotData(index).appearedInWindow - 1)*50 + 1;
greenLength = length(dynData.GreenSpotData(index).intensityTrace);
plot(greenStart:greenStart+greenLength-1,dynData.GreenSpotData(index).intensityTrace,'g');
hold on
plot(greenStart:greenStart+greenLength-1,dynData.FarRedSpotData(index).intensityTrace,'m');
end

