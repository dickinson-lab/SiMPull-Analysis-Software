% Function to update dialog box options for analyze_batch. 

function updateEnabled(h)
    % Get values of currently selected parameters
    nd2 = strcmp( get( get(h(2,1),'SelectedObject'), 'String'), 'Nikon ND2');
    blue = get(h(4,1),'Value');
    green = get(h(5,1),'Value');
    red = get(h(6,1),'Value');
    farRed = get(h(7,1),'Value');
    
    % Enable or disable stuff based on values
    if nd2 && blue
        set( [h(8,1) h(12,1)],'Enable','on');
    else
        set( [h(8,1) h(12,1)],'Enable','off');
    end
    
    if nd2 && green
        set( [h(9,1) h(13,1)],'Enable','on');
    else
        set( [h(9,1) h(13,1)],'Enable','off');
    end
    
    if nd2 && red
        set( [h(10,1) h(14,1)],'Enable','on');
    else
        set( [h(10,1) h(14,1)],'Enable','off');
    end

    if nd2 && farRed
        set( [h(11,1) h(15,1)],'Enable','on');
    else
        set( [h(11,1) h(15,1)],'Enable','off');
    end
    
    if blue
        set( h(17,1),'Enable','on');
        set( h(18,1),'Enable','on');
        set( h(25,1),'Enable','on');
    else
        set( h(17,1),'Enable','off');
        set( h(18,1),'Enable','off');
        set( h(25,1),'Enable','off');
    end
    
    if green
        set( h(19,1),'Enable','on');
        set( h(20,1),'Enable','on');
        set( h(26,1),'Enable','on');
    else
        set( h(19,1),'Enable','off');
        set( h(20,1),'Enable','off');
        set( h(26,1),'Enable','off');
    end
    
    if red
        set( h(21,1),'Enable','on');
        set( h(22,1),'Enable','on');
        set( h(27,1),'Enable','on');
    else
        set( h(21,1),'Enable','off');
        set( h(22,1),'Enable','off');
        set( h(27,1),'Enable','off');
    end
    
    if farRed
        set( h(23,1),'Enable','on');
        set( h(24,1),'Enable','on');
        set( h(28,1),'Enable','on');
    else
        set( h(23,1),'Enable','off');
        set( h(24,1),'Enable','off');
        set( h(28,1),'Enable','off');
    end
end