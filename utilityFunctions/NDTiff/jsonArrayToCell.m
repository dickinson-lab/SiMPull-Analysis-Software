function c = jsonArrayToCell(jsonArray)
    len = jsonArray.length();
    c = cell(1, len);
    for i = 1:len
        item = jsonArray.get(i - 1);  % Java is 0-indexed
        if isa(item, 'org.json.JSONObject')
            c{i} = jsonObjectToStruct(item);
        elseif isa(item, 'org.json.JSONArray')
            c{i} = jsonArrayToCell(item);
        else
            c{i} = item;
        end
    end
end
