
function toggleEnable(hctl,htgt)
    if get(hctl,'Value') 
        set(htgt,'Enable','on'); 
    else 
        set(htgt,'Enable','off');
    end
end