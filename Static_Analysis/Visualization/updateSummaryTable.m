% Updates the summary table after excluding / modifying some data in an
% existing analysis.  This function is not intended to be called directly
% by the user. 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function summary = updateSummaryTable(matFile, matPath, statsByColor)    

    slash = strfind(matPath,filesep);
    expName = matPath(slash(end-1)+1 : end-1);
    if ~isempty(strfind(matFile, 'filtered'))
        suffix = '_summary_filtered.mat';
    else
        suffix = '_summary.mat';
    end
        
    try 
        load([matPath filesep expName suffix]);
    catch
        msgbox('Could not load summary table file!');
        return
    end

    changeLines = find(cellfun(@(x) strncmp( x, matFile(1:end-4), length(matFile)-4 ), summary));
    [~, width] = size(summary);

    for y = changeLines'
        rowname = strsplit(summary{y,1});
        color1 = rowname{end};

        for x = 2:width

            %Spotcount column
            if strcmp(summary{1,x},'Spots per Image') 
                summary{y,x} = statsByColor.(['avg' color1 'Spots']);
            end

            %Colocalization columns        
            if ~isempty(strfind(summary{1,x}, '% Coloc'))
                colname = strsplit(summary{1,x});
                color2 = colname{end};
                if isfield(statsByColor, ['pct' color1 'Coloc_w_' color2])
                    summary{y,x} = statsByColor.(['pct' color1 'Coloc_w_' color2]);
                else
                    summary{y,x} = '-';
                end
            end

            %Traces Analyzed Column
            if strcmp(summary{1,x}, 'Traces Analyzed')
                if isfield(statsByColor, [color1 'TracesAnalyzed'])
                   summary{y,x} = statsByColor.([color1 'TracesAnalyzed']);
                else
                    summary{y,x} = '-';
                end
            end

            %Photobleaching columns
            if ~isempty(strfind(summary{1,x}, 'step'))
                num = str2num(summary{1,x}(3:4));
                if isfield(statsByColor, [color1 'StepHist'])
                    summary{y,x} = 100 * statsByColor.([color1 'StepHist'])(num) / statsByColor.([color1 'TracesAnalyzed']);
                else
                    summary{y,x} = '-';
                end
            end

            % Bad Spots column
            if strcmp(summary{1,x}, '% Rejected')
                if isfield(statsByColor, [color1 'BadSpots'])
                    summary{y,x} = 100 * statsByColor.([color1 'BadSpots']) / statsByColor.([color1 'TracesAnalyzed']);
                else
                    summary{y,x} = '-';
                end
            end

        end
    end
    
    %Save summary table
    save([matPath filesep expName suffix],'summary');
    
    %Post to workspace
    assignin('base','summary',summary);