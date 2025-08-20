
function sortedS = concurrentHashMapToStruct(axesSet)
    axesArray = axesSet.toArray();
    numCoords = length(axesArray);
    s = struct();
    for a = 1:numCoords
        axes1 = axesArray(a);
        keys = axes1.keySet().toArray();
        for i = 1:length(keys)
            key = keys(i);
            value = axes1.get(key);
    
            % Convert Java types to MATLAB types
            if isa(value, 'java.util.concurrent.ConcurrentHashMap')
                s(a).(key) = concurrentHashMapToStruct(value);  % Recursive
            elseif isa(value, 'org.json.JSONObject')
                s(a).(key) = jsonObjectToStruct(value);  % Use previous helper
            elseif isa(value, 'org.json.JSONArray')
                s(a).(key) = jsonArrayToCell(value);     % Use previous helper
            else
                s(a).(key) = value;
            end
        end
    end
    
    sortvars = {};
    if ~isempty(max(cell2mat({s.position}))); sortvars{end+1}='position'; end
    if ~isempty(max(cell2mat({s.time}))); sortvars{end+1}='time'; end
    if ~isempty(max(cell2mat({s.channel}))); sortvars{end+1}='channel'; end
    if ~isempty(max(cell2mat({s.z}))); sortvars{end+1}='z'; end
    T = struct2table(s); % convert the struct array to a table
    sortedT = sortrows(T, sortvars); % sort the table by image dimensions. Might need to choose names programmatically later.
    sortedS = table2struct(sortedT); % change it back to struct array if necessary

end
