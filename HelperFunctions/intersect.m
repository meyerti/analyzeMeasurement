function i = intersect( data, thresh )
  %INTERSECT takes vector and threshold, returns the first crossing point
  %   If no intersection can be found in data 0 is returned
  i=0;
  if ( min(data) <= thresh && max(data) >= thresh)
       if data(1)>thresh
           i=find(data <= thresh,1);
       else
           i=find(data >= thresh,1);
       end
  else
    fprintf('intersect: no intersection with thresh %.3f min %.3f max %.3f\n', thresh, min(data), max(data));
  end
  
  if isempty(i)
      fprintf('intersect: failed to find intersection with thresh %.3f min %.3f max %.3f\n', thresh, min(data), max(data));
      i=0;
  end
 
end

