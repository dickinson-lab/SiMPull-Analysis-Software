% Function to update dialog box options for analyze_batch. 

function updateEnabled(h)
    % Get values of currently selected parameters
    nd2 = strcmp( get( get(h(2,1),'SelectedObject'), 'String'), 'Nikon ND2');
    dv = strcmp( get ( get(h(2,1),'SelectedObject'), 'String'), 'Dual-View TIFF');
    blue = get(h(5,1),'Value');
    green = get(h(6,1),'Value');
    red = get(h(7,1),'Value');
    farRed = get(h(8,1),'Value');
    
    % Enable or disable stuff based on values

    if dv && blue
        set( findall( h(13,1), '-property', 'Enable'), 'Enable', 'on');
    else
        set( findall( h(13,1), '-property', 'Enable'), 'Enable', 'off');
    end
    
    if dv && green
        set( findall( h(14,1), '-property', 'Enable'), 'Enable', 'on');
    else
        set( findall( h(14,1), '-property', 'Enable'), 'Enable', 'off');
    end
    
    if dv && red
        set( findall( h(15,1), '-property', 'Enable'), 'Enable', 'on');
    else
        set( findall( h(15,1), '-property', 'Enable'), 'Enable', 'off');
    end

    if dv && farRed
        set( findall( h(16,1), '-property', 'Enable'), 'Enable', 'on');
    else
        set( findall( h(16,1), '-property', 'Enable'), 'Enable', 'off');
    end
    
    
    if nd2 && blue
        set( [h(17,1) h(21,1)],'Enable','on');
    else
        set( [h(17,1) h(21,1)],'Enable','off');
    end
    
    if nd2 && green
        set( [h(18,1) h(22,1)],'Enable','on');
    else
        set( [h(18,1) h(22,1)],'Enable','off');
    end
    
    if nd2 && red
        set( [h(19,1) h(23,1)],'Enable','on');
    else
        set( [h(19,1) h(23,1)],'Enable','off');
    end

    if nd2 && farRed
        set( [h(20,1) h(24,1)],'Enable','on');
    else
        set( [h(20,1) h(24,1)],'Enable','off');
    end
    
    
    if blue
        set( h(26,1),'Enable','on');
        set( h(27,1),'Enable','on');
        set( h(34,1),'Enable','on');
    else
        set( h(26,1),'Enable','off');
        set( h(27,1),'Enable','off');
        set( h(34,1),'Enable','off');
    end
    
    if green
        set( h(28,1),'Enable','on');
        set( h(29,1),'Enable','on');
        set( h(35,1),'Enable','on');
    else
        set( h(28,1),'Enable','off');
        set( h(29,1),'Enable','off');
        set( h(35,1),'Enable','off');
    end
    
    if red
        set( h(30,1),'Enable','on');
        set( h(31,1),'Enable','on');
        set( h(36,1),'Enable','on');
    else
        set( h(30,1),'Enable','off');
        set( h(31,1),'Enable','off');
        set( h(36,1),'Enable','off');
    end
    
    if farRed
        set( h(32,1),'Enable','on');
        set( h(33,1),'Enable','on');
        set( h(37,1),'Enable','on');
    else
        set( h(32,1),'Enable','off');
        set( h(33,1),'Enable','off');
        set( h(37,1),'Enable','off');
    end
end