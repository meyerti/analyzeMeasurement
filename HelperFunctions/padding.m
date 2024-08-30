%PADDING Adds padding to a vector
%   Detailed explanation goes here
function A = padding(A,n,val)
    [r,c]=size(A);
    l=numel(A);
    P=ones(1,n)*val;
    if (l==r)
        A=[P A' P];
    elseif l==c
        A=[P A P];
    else
        error('padding: works only with 1D vectors')
    end
end