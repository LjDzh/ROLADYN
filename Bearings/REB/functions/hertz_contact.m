function [Qi,Ki] = hertz_contact(Ki,n,dbi,tol)
if nargin < 4
    tol = 0;
end
if nargout > 1
    [Qi,d1] = sgn_power(dbi,n);
    Qi = Qi * Ki;
    d2 = maxSmoothDeriv(Qi,0,tol);
    Qi = maxSmooth(Qi,0,tol);
    Ki = Ki .* d1 .* d2;
else
    Qi = Ki*sgn_power(dbi,n);
    Qi = maxSmooth(Qi,0,tol);
end