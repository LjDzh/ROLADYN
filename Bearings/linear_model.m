function [F,V,S] = linear_model(B, j, States) 
xBearing = [States.qi; States.qo];
dxBearing = [States.qidot; States.qodot];

fb = B.Kb{j}*xBearing + B.Cb{j}*dxBearing;

NPts = size(xBearing,2);
F.F = fb;
F.Fi = fb(1:4,:);
F.Fo = fb(5:8,:);
F.FInt     = zeros(0,NPts);
F.xInt     = zeros(0,NPts);
F.xdotInt  = zeros(0,NPts);
F.xddotInt = zeros(0,NPts);

V = struct();

if nargout > 2
    S.K = repmat(B.Kb{j},1,1,NPts);
    S.C = repmat(B.Cb{j},1,1,NPts);
    
    S.Kqq = S.K;
    S.Cqq = S.C;
    
    S.Kqx = zeros(8,0,NPts);
    S.Kxq = zeros(0,8,NPts);
    S.Kxx = zeros(0,0,NPts);

    S.Cqx = zeros(8,0,NPts);
    S.Cxq = zeros(0,8,NPts);
    S.Cxx = zeros(0,0,NPts);
end
