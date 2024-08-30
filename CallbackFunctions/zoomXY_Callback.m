function zoomXY_Callback(hFig, eventdata)
    %
    % if the mouse is currently over an axis object zoom into that axis
    %
    move=eventdata.VerticalScrollCount*0.1;  %move 10% per click
    %
    hAxes=getChild(hFig, 'Axes');
    %            
    %
    pos=get(hAxes,'CurrentPoint');
    xpos=pos(1,1);
    ypos=pos(1,2);
    %
    XLim=get(hAxes, 'XLim');
    YLim=get(hAxes, 'YLim');
    %
    newL=XLim(1)+(XLim(1)-xpos)*move;
    newR=XLim(2)+(XLim(2)-xpos)*move;
    newT=YLim(1)+(YLim(1)-ypos)*move;
    newB=YLim(2)+(YLim(2)-ypos)*move;
    %
    switch get(hFig,'selectiontype')
        case 'normal'
            hAxes.XLim = [newL newR];
        case 'alt'
            hAxes.YLim = [newT newB];
        otherwise
            hAxes.XLim = [newL newR];
            hAxes.YLim = [newT newB];
    end
    %            
end
