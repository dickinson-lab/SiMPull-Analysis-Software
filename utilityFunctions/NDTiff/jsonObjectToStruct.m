function mdStruct = jsonObjectToStruct(md)
    keys = md.keys;
    mdStruct = struct();
    while keys.hasNext()
        key = keys.next();
        value = md.get(key);
        safeField = strrep(key,' ', '_');

        % Convert Java types to MATLAB types if needed
        if isa(value, 'mmcorej.org.json.JSONObject')
            % Recursively convert nested JSONObject
            mdStruct.(safeField) = jsonObjectToStruct(value);
        elseif isa(value, 'mmcorej.org.json.JSONArray')
            % Convert JSONArray to cell array
            mdStruct.(safeField) = jsonArrayToCell(value);
        else
            mdStruct.(safeField) = value;
        end
    end
end