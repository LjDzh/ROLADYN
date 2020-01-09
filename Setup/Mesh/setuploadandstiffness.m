function P = setuploadandstiffness(P,O,A)
if nargin < 2 || isempty(O)
    O = 0;
end
if nargin < 3 || isempty(A)
    A = linspace(0,2*pi,100);
end

Fc = -(P.Mesh.R) \ (P.Mesh.K * P.Mesh.x0  - P.Mesh.Fg);

%% Begin with the rotors
NRotor = length(P.Rotor);
P.Mesh.Rotor.F0 = P.Mesh.Rotor.F0 + P.Mesh.Rotor.R*Fc;

for i = 1:NRotor
    P.Rotor{i}.F0 = zeros(P.Rotor{i}.NDof,1);
    xRotor = P.Rotor{i}.S * P.Mesh.x0;
    %deal with the shafts first
    for j = 1:length(P.Rotor{i}.Shaft)
        SShaft = P.Rotor{i}.Shaft{j}.S;
        
        for k = 1:(P.Rotor{i}.Shaft{j}.Mesh.Nz-1)
            %rotor->shaft element mapping matrix
            Se = P.Rotor{i}.Shaft{j}.Element{k}.S*SShaft;
            Re = P.Rotor{i}.Shaft{j}.Element{k}.R;
            P.Rotor{i}.Shaft{j}.Element{k}.F0 = P.Rotor{i}.Shaft{j}.Element{k}.K * Re * Se * xRotor;
            P.Rotor{i}.F0 = P.Rotor{i}.F0 + Se'*Re'*P.Rotor{i}.Shaft{j}.Element{k}.F0;
        end
    end
    
    %now deal with the discs
    for j = 1:length(P.Rotor{i}.Disc)
        %create rotor->disc mapping matrix
        SDisc = P.Rotor{i}.Disc{j}.S;
        
        SHub = P.Rotor{i}.Disc{j}.Hub.S*SDisc;
        SRoot = P.Rotor{i}.Disc{j}.Root.S*SDisc;
        
        if strcmp(P.Rotor{i}.Disc{j}.Type,'Flexible')
            %disc compliance
            for k = 1:P.Rotor{i}.Disc{j}.Mesh.Nt
                for l = 1:(P.Rotor{i}.Disc{j}.Mesh.Nr-1)
                    Se = P.Rotor{i}.Disc{j}.Element{k,l}.S;
                    Re = P.Rotor{i}.Disc{j}.Element{k,l}.R;
                    P.Rotor{i}.F0 = P.Rotor{i}.F0 + Se'*Re'*P.Rotor{i}.Disc{j}.Element{k,l}.F0;
                end
            end
        end
        
        %lump inertia at hub
        P.Rotor{i}.Disc{j}.Root.F0 = P.Rotor{i}.Disc{j}.Root.K * (SHub-SRoot) * xRotor;
        P.Rotor{i}.F0 = P.Rotor{i}.F0 + (SHub-SRoot)'*P.Rotor{i}.Disc{j}.Root.F0;
    end
end

%% And the stator
P.Mesh.Stator.F0 = P.Mesh.Stator.F0 + P.Mesh.Stator.R*Fc;

%% Move onto the bearings
NBearing = length(P.Bearing);
wons = 0*A + 1;
States.x = P.Mesh.Bearing.S*P.Mesh.x0*wons;
States.xdot = 0*States.x;
States.xddot = 0*States.x;
States.xInt = P.Mesh.xInt*wons;
States.xdotInt = 0*States.xInt;
States.xddotInt = 0*States.xInt;
States.u = 0*P.Mesh.Excite.uSync*wons;
States.udot = 0*P.Mesh.Excite.uSync*wons;
States.uddot = 0*P.Mesh.Excite.uSync*wons;
States.bSolve = 0;

for i = 1:NBearing
    Oshaft = repmat(0*O,3,1);
    Ashaft = repmat(0*A,3,1);
    for j = 1:2
        Oshaft(j,:) = P.Bearing{i}.Node{j}.Speed * O;
        Ashaft(j,:) = P.Bearing{i}.Node{j}.Speed * A;
    end
    
    %assemble inputs for current bearing
    StatesB = states_init_j(P.Bearing{i},Oshaft,Ashaft,States);
    
    switch P.Bearing{i}.Model
        case 'REB'
            [Forces,~,Stiffness] = REB_model(P.Bearing{i}.Params,StatesB);
            Stiffness.K   = Stiffness.K   + P.Bearing{i}.Params.KPar;
            Stiffness.Kqq = Stiffness.Kqq + P.Bearing{i}.Params.KPar;
            Stiffness.C   = Stiffness.C   + P.Bearing{i}.Params.CPar;
            Stiffness.Cqq = Stiffness.Cqq + P.Bearing{i}.Params.CPar;
            Forces.F = Forces.F + P.Bearing{i}.Params.KPar*[StatesB.qi; StatesB.qo] + P.Bearing{i}.Params.CPar*[StatesB.qidot;StatesB.qodot];
        case 'SFD'
            [Forces,~,Stiffness] = SFD_model(P.Bearing{i}.Params,StatesB);
            Stiffness.K = Stiffness.K + P.Bearing{i}.Params.KSq;
            Forces.F = Forces.F + P.Bearing{i}.Params.KSq*[StatesB.qi; StatesB.qo];
        case 'radial'
            [Forces,~,Stiffness] = radial_model(P.Bearing{i}.Params,StatesB);
            Forces.F = Forces.F + P.Bearing{i}.Params.KPar*[StatesB.qi; StatesB.qo];
        case 'piezo'
            [Forces,~,Stiffness] = piezo_model(P.Bearing{i}.Params,StatesB);
        case 'linear'
            [Forces,~,Stiffness] = linear_model(P.Bearing{i},StatesB);
        otherwise
            if nargout > 1
                [Forces,~,Stiffness] = empty_model(StatesB);
            else
                Forces = empty_model(StatesB);
            end
    end
    P.Bearing{i}.Kb = mean(Stiffness.K,3);
    P.Bearing{i}.Cb = mean(Stiffness.C,3);
    P.Bearing{i}.F = mean(Forces.F,2);
end

P.Mesh.Bearing.F0 = P.Mesh.Bearing.F0 + P.Mesh.Bearing.R*Fc;
P.Mesh.Bearing.Fb = P.Mesh.Bearing.Fb + P.Mesh.Bearing.Rb*Fc;

%% Combined
P.Mesh.F0  = P.Mesh.Rotor.F0  + P.Mesh.Bearing.F0  + P.Mesh.Stator.F0;

function StatesB = states_init_j(B,Oshaft,Ashaft,States)
StatesB.qo     = B.Ro * (B.Uo * States.x);
StatesB.qodot  = B.Ro * (B.Uo * States.xdot);
StatesB.qoddot = B.Ro * (B.Uo * States.xddot);

StatesB.qi     = B.Ri * (B.Ui * States.x);
StatesB.qidot  = B.Ri * (B.Ui * States.xdot);
StatesB.qiddot = B.Ri * (B.Ui * States.xddot);

StatesB.Oo = Oshaft(1,:); StatesB.Oi = Oshaft(2,:); 
StatesB.Ao = Ashaft(1,:); StatesB.Ai = Ashaft(2,:); 

StatesB.xInt     = B.V*States.xInt;
StatesB.xdotInt  = B.V*States.xdotInt;
StatesB.xddotInt = B.V*States.xddotInt;

StatesB.u     = B.Ue*States.u;
StatesB.udot  = B.Ue*States.udot;
StatesB.uddot = B.Ue*States.uddot;

StatesB.bSolve = States.bSolve;