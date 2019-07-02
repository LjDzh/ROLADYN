function REB = SKF1208(model)

REB.Setup.Type = 'ball';
REB.Setup.Arrangement = 'double_alternating';
REB.Setup.Z = 18*2;
% REB.Setup.CbParallel = diag([0 0 0 0]);
% REB.Setup.KbParallel = diag([Inf 0 Inf 0]);

D = 2*4.3655E-3;
dm = 60.146E-3;
z0 = (9E-3)/2;

REB.Geometry.D  = D;
REB.Geometry.dm = dm;
REB.Geometry.z0 = z0;

REB.Geometry.cr = 0.05296261E-3;
REB.Geometry.cz = 0;

Ri = D/2 + 0.0001E-3;

% REB.Geometry.alpha0 = 0.5*14.58*pi/180;
% Ro = 39.89311820E-3;

REB.Geometry.alpha0 = atan(z0/(dm/2)); 
Ro = hypot(REB.Geometry.dm/2 + REB.Geometry.D/2*cos(REB.Geometry.alpha0), z0 + D/2*sin(REB.Geometry.alpha0));

REB.Geometry.RRaceo = Ro;
REB.Geometry.RRacei = Ri;

%steel
REB.Material.v = 0.3;
REB.Material.E = 210E9;
REB.Material.rho = 8000;
 
%ISO VG32 oil
REB.Fluid.eta0 = 0.02;
REB.Fluid.alpha = 1E-8;

REB.Race.Inner.w = 18E-3;
REB.Race.Inner.t = 5E-3;

REB.Race.Outer.w = 18E-3;
REB.Race.Outer.t = 5E-3;
 
REB.Options.Control = 'outer';
REB.Options.bComplexDynLoads = 0; %doesn't work if true
REB.Options.bRaceCompliance = 0;
REB.Options.bCentrifugal = 0;
REB.Options.bGyro = 0;
REB.Options.bVC = 0; %doesn't work with c.f. loads

if nargin < 1
    model = 'harris';
end
REB.Model.Name = model;

% REB1 = setupREB(REB);
% structdiff(REB,REB1)
% REB2 = setupREB(REB1);
% structdiff(REB,REB2)
% plot_REB(REB2);