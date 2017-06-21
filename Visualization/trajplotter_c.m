function [nSteps, steplevels] = trajplotter_c(traj, logodds)
    [nSteps, changepoint_pos, bayes_factors] = cpdetect_c('Gaussian', single(traj), logodds);
    changepoint_pos = changepoint_pos(1:nSteps);
    bayes_factors = bayes_factors(1:nSteps);
    changepoints = horzcat(changepoint_pos, bayes_factors);
    if nSteps>0 
        changepoints = sortrows(changepoints, 1);
    end
    lastchangepoint = 1;
    tmax = length(traj);
    fit = zeros(1,tmax);
    bars = zeros(tmax,1);
    steplevels = zeros(nSteps+1,1);
    for a = 1:nSteps+1
        if a>nSteps
            changepoint = tmax;
        else 
            changepoint = changepoints(a,1);
        end
        if changepoint == 0
            continue
        end
        subtraj = traj(lastchangepoint:changepoint);
        level = mean(subtraj);
        fit(lastchangepoint:changepoint) = level;
        if a<=nSteps 
            bars(changepoints(a,1)) = changepoints(a,2);
        end
        steplevels(a) = level;
        stdev = std(subtraj);
        
        %Throw out steps that are (erroneously) detected after the spot has bleached to 0
        if (level-stdev) < 0
            nSteps = a-1; 
            subtraj = traj(lastchangepoint:end);
            level = mean(subtraj);
            steplevels(a) = level;
            break
        end

        lastchangepoint = changepoint+1; %"+1" just keeps the segments from overlapping
    end
    xaxis = 1:length(traj);
    % [AX,H1,H2] = plotyy(xaxis,traj,xaxis,bars,@line,@bar);
    % set(H2,'FaceColor','g','EdgeColor','none','Barwidth',0.5);
    % hold on
    % plot(xaxis,fit,'r','LineWidth',3);

    axes1 = axes('Box','off','YTick',[]);
    bar(axes1,xaxis,bars,'FaceColor','g','EdgeColor','none','Barwidth',0.5);
    set(axes1,'YAxisLocation','right','Box','off');
    set(axes1,'XLim',[0 tmax]);
    ylabel(axes1,'Changepoint Log Odds');  %# Add a label to the right y axis
    title(axes1,[num2str(nSteps) ' Steps']);

    axesPosition = get(gca,'Position');          %# Get the current axes position
    axes2 = axes('Position',axesPosition);  %# Place a new axes on top...
    plot(axes2,xaxis,traj);
    hold on
    plot(axes2,xaxis,fit,'r','LineWidth',3);
    ylabel(axes2,'Fluorescence Intensity');  
    set(axes2,'Color','none','Box','off');
    set(axes2,'XLim',[0 tmax]);