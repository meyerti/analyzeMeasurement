function color=getColor(cmap, Val, Min, Max)
    %
    if Min > Max                
      % reverse sorting
      %cr = relativ position %
      cr  = min(1, 1- (Val - Max) / (Min - Max)) ;                 
    else
      % max is 100%
      cr  = min(1,    (Val - Min) / (Max - Min)) ;                
    end
    %
    cn = max( 1,  floor(cr*length(cmap)) );
    %[frcData(3) peak.height frcData(4) cr cn]                 
    color  = cmap(cn,:);
end
