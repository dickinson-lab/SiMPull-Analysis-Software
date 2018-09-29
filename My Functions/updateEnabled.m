% Function to update dialog box options for analyze_batch. 

function updateEnabled(h)
    % Get values of currently selected parameters
    nd2 = strcmp( get( get(h(2,1),'SelectedObject'), 'String'), 'Nikon ND2');
    blue = get(h(5,1),'Value');
    green = get(h(6,1),'Value');
    red = get(h(7,1),'Value');
    farRed = get(h(8,1),'Value');
    
    % Enable or disable stuff based on values
    if nd2 && blue
        set( [h(9,1) h(13,1)],'Enable','on');
    else
        set( [h(9,1) h(13,1)],'Enable','off');
    end
    
    if nd2 && green
        set( [h(10,1) h(14,1)],'Enable','on');
    else
        set( [h(10,1) h(14,1)],'Enable','off');
    end
    
    if nd2 && red
        set( [h(11,1) h(15,1)],'Enable','on');
    else
        set( [h(11,1) h(15,1)],'Enable','off');
    end

    if nd2 && farRed
        set( [h(12,1) h(16,1)],'Enable','on');
    else
        set( [h(12,1) h(16,1)],'Enable','off');
    end
    
    if blue
        set( h(18,1),'Enable','on');
        set( h(19,1),'Enable','on');
        set( h(26,1),'Enable','on');
    else
        set( h(18,1),'Enable','off');
        set( h(19,1),'Enable','off');
        set( h(26,1),'Enable','off');
    end
    
    if green
        set( h(20,1),'Enable','on');
        set( h(21,1),'Enable','on');
        set( h(27,1),'Enable','on');
    else
        set( h(20,1),'Enable','off');
        set( h(21,1),'Enable','off');
        set( h(27,1),'Enable','off');
    end
    
    if red
        set( h(22,1),'Enable','on');
        set( h(23,1),'Enable','on');
        set( h(28,1),'Enable','on');
    else
        set( h(22,1),'Enable','off');
        set( h(23,1),'Enable','off');
        set( h(28,1),'Enable','off');
    end
    
    if farRed
        set( h(24,1),'Enable','on');
        set( h(25,1),'Enable','on');
        set( h(29,1),'Enable','on');
    else
        set( h(24,1),'Enable','off');
        set( h(25,1),'Enable','off');
        set( h(29,1),'Enable','off');
    end
end