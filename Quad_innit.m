clc
clear all
%% Parameters
m = 2; g = 9.81; 
Ix = 1.25; Iy = 1.25; Iz = 2.5; Ip = 5e-5;  %(kg-m^2)
b = 2.5e-5; l = 0.25; d = 0.5e-6;

xd = 36;
yd = 15;
zd = 50;
psi_d = 0;
%% State-space model for X and Y
A = [0 1 0; 0 0 1; 0 0 0]; B = [0; 0; 1]; % X = [x; x1; x2]; U = [x3]
C = eye(3); D = zeros(3,1);

% Try W = [x; x1]; U = [x2]
% A = [0 1; 0 0]; B = [0; 1];
% C = eye(2); D = zeros(2,1);

%% MPC matrix approach
T = 0.01; % Sample Time #### controls the magnitude of overshoot
I = eye(3);
A_bar = I+(T*A);
B_bar = (T*B);
p = 5; %prediction horizon #### dampens the response
v = p; % control horizon

%% Desired Trajectory
x=[xd;0;0];
Xd = repmat(x,p,1);

y = [yd;0;0];
Yd = repmat(y,p,1);

%% PSI matrix
Psi = C*A_bar;
for i = 2:p
    Psi_temp = cat(1, Psi, (C*A_bar.^(i)));
    Psi = Psi_temp;
end

%% THETA matrix
sz = size(B_bar);

for i = 1:p
    for j = 1:p
        if (j == 1)
            Theta_row = C*(A_bar.^(i-j))*B_bar;
        elseif (i < j)
            Theta_row = cat(2, Theta_row, zeros(sz));
        else
            Theta_row = cat(2, Theta_row, C*(A_bar.^(i-j))*B_bar);
        end
    end
    if (i == 1) 
        Theta = Theta_row;
    else
        Theta = cat(1, Theta, Theta_row);
    end
end

%% W1 matrix
I = eye(1); N = zeros(1);
%sz = size(C*B_bar);
%Theta = zeros(sz);
%Theta_row = zeros(sz);
for i = 1:p
    W1_row = 0;
    for j = 1:p
        if (j == 1)
            if (j == i)
                W1_row = I;
            elseif (j == i-1)
                W1_row = -I;
            else
                W1_row = N;
            end
        else
            if (j == i)
                W1_row = cat(2,W1_row,I);
            elseif (j == i-1)
                W1_row = cat(2,W1_row,-I);
            else
                W1_row = cat(2,W1_row,N);
            end
        end
    end
    if (i == 1)
        W1 = W1_row;
    else
        W1 = cat(1, W1, W1_row);
    end
end

%% W2 matrix
F = 0.01 * eye(1);
N = zeros(1);
for i = 1:p
    for j = 1:p
        if (j == 1)
            if (i == 1)
                W2_row = F;
            else
                W2_row = N;
            end
        else
            if (j == i)
                W2_row = cat(2,W2_row,F);
            else
                W2_row = cat(2,W2_row,N);
            end
        end  
    end
    if (i == 1)
        W2 = W2_row;
    else
        W2 = cat(1, W2, W2_row);
    end
end

%% W4 matrix

Q = [25 0 0; 0 6 0; 0 0 1.5];
N = zeros(3);

% (For C1)
% Q = 10 * eye(1);
% N = zeros(1);

for i = 1:p
    for j = 1:p
        if (j == 1)
            if (i == 1)
                W4_row = Q;
            else
                W4_row = N;
            end
        else
            if (j == i)
                W4_row = cat(2,W4_row,Q);
            else
                W4_row = cat(2,W4_row,N);
            end
        end  
    end
    if (i == 1)
        W4 = W4_row;
    else
        W4 = cat(1, W4, W4_row);
    end
end
% W3 matrix
W3 = (W1.')*W2*W1;
adjoint(W3);

T = Theta.';
H = (T*W4*Theta)+W2;

%% State-space matrices (Altitude)
 Az = [0 1 0; 0 0 1; 0 0 0]; Bz = [0; 0; 1]; % W = [z; z1; z2]; U = [J3]
 Cz = eye(3); Dz = zeros(3,1);

C1 = [1 0 0 0];

%% MPC matrix approach
Tz = 0.01; % Sample Time #### controls the magnitude of overshoot (0.65)
Iz = eye(3);
Az_bar = Iz+(Tz*Az);
Bz_bar = (Tz*Bz);
pz = 5; %prediction horizon #### dampens the response (5)
vz = pz; % control horizon

%% Desired Trajectory
z=[zd;0;0];
Zd = repmat(z,pz,1);

%% PSI matrix

Psi_z = Cz*Az_bar;
for i = 2:pz
    Psi_temp = cat(1, Psi_z, Cz*(Az_bar.^(i)));
    Psi_z = Psi_temp;
end

%% THETA matrix

sz = size(Cz*Bz_bar);

for i = 1:pz
    for j = 1:pz
        if (j == 1)
            Theta_row = Cz*(Az_bar.^(i-j))*Bz_bar;
        elseif (i < j)
            Theta_row = cat(2, Theta_row, zeros(sz));
        else
            Theta_row = cat(2, Theta_row, Cz*(Az_bar.^(i-j))*Bz_bar);
        end
    end
    if (i == 1) 
        Theta_z = Theta_row;
    else
        Theta_z = cat(1, Theta_z, Theta_row);
    end
end
%% W1 matrix
Iz = eye(1); N = zeros(1);
%sz = size(C*B_bar);
%Theta = zeros(sz);
%Theta_row = zeros(sz);
for i = 1:pz
    W1_row = 0;
    for j = 1:pz
        if (j == 1)
            if (j == i)
                W1_row = Iz;
            elseif (j == i-1)
                W1_row = -Iz;
            else
                W1_row = N;
            end
        else
            if (j == i)
                W1_row = cat(2,W1_row,Iz);
            elseif (j == i-1)
                W1_row = cat(2,W1_row,-Iz);
            else
                W1_row = cat(2,W1_row,N);
            end
        end
    end
    if (i == 1)
        W1_z = W1_row;
    else
        W1_z = cat(1, W1_z, W1_row);
    end
end

%% W2 matrix
Fz = 0.01 * eye(1);
N = zeros(1);
for i = 1:pz
    for j = 1:pz
        if (j == 1)
            if (i == 1)
                W2_row = Fz;
            else
                W2_row = N;
            end
        else
            if (j == i)
                W2_row = cat(2,W2_row,Fz);
            else
                W2_row = cat(2,W2_row,N);
            end
        end  
    end
    if (i == 1)
        W2_z = W2_row;
    else
        W2_z = cat(1, W2_z, W2_row);
    end
end

%% W4 matrix

Qz = [30 0 0; 0 7 0; 0 0 3];
N = zeros(3);

% (For C1)
% Q = 10 * eye(1);
% N = zeros(1);

for i = 1:pz
    for j = 1:pz
        if (j == 1)
            if (i == 1)
                W4_row = Qz;
            else
                W4_row = N;
            end
        else
            if (j == i)
                W4_row = cat(2,W4_row,Qz);
            else
                W4_row = cat(2,W4_row,N);
            end
        end  
    end
    if (i == 1)
        W4_z = W4_row;
    else
        W4_z = cat(1, W4_z, W4_row);
    end
end
% W3 matrix
W3_z = (W1_z.')*W2_z*W1_z;
adjoint(W3_z);

Tz = Theta_z.';
Hz = (Tz*W4_z*Theta_z)+W2_z;

%%  ##############################################################################################################  %%
%% State-space matrices (Heading)
Ah = [0 1 0; 0 0 1; 0 0 0]; Bh = [0; 0; 1]; % W = [psi; psi1; psi2]; U = [V4] -> V4 = psi3 = r2 = dot(U4/Iz)
Ch = eye(3); Dh = zeros(3,1);
% A = [0 1 ; 0 0]; B = [0; 1]; % W = [psi; psi1]; U = [V4] -> V4 = psi2 = r1 = (U4/Iz)
% C = eye(2); D = zeros(2,1);
C1 = [1 0];

%% MPC matrix approach
Th = 0.6;
Ih = eye(3);
Ah_bar = Ih+(Th*Ah);
Bh_bar = (Th*Bh);
ph = 5; %prediction horizon
vh = ph; % control horizon

%% Desired Trajectory
psi=[psi_d;0;0];
psid = repmat(psi,ph,1);

%% PSI matrix

Psi_h = Ch*Ah_bar;
for i = 2:ph
    Psi_temp = cat(1, Psi_h, Ch*(Ah_bar.^(i)));
    Psi_h = Psi_temp;
end

%% THETA matrix

sz = size(Ch*Bh_bar);
%Theta = zeros(sz);
%Theta_row = zeros(sz);
for i = 1:ph
    for j = 1:ph
        if (j == 1)
            Theta_row = Ch*(Ah_bar.^(i-j))*Bh_bar;
        elseif (i < j)
            Theta_row = cat(2, Theta_row, zeros(sz));
        else
            Theta_row = cat(2, Theta_row, Ch*(Ah_bar.^(i-j))*Bh_bar);
        end
    end
    if (i == 1) 
        Theta_h = Theta_row;
    else
        Theta_h = cat(1, Theta_h, Theta_row);
    end
end
%% W1 matrix
Ih = eye(1); N = zeros(1);
%sz = size(C*B_bar);
%Theta = zeros(sz);
%Theta_row = zeros(sz);
for i = 1:ph
    W1_row = 0;
    for j = 1:ph
        if (j == 1)
            if (j == i)
                W1_row = Ih;
            elseif (j == i-1)
                W1_row = -Ih;
            else
                W1_row = N;
            end
        else
            if (j == i)
                W1_row = cat(2,W1_row,Ih);
            elseif (j == i-1)
                W1_row = cat(2,W1_row,-Ih);
            else
                W1_row = cat(2,W1_row,N);
            end
        end
    end
    if (i == 1)
        W1_h = W1_row;
    else
        W1_h = cat(1, W1_h, W1_row);
    end
end

%% W2 matrix
Fh = 0.01 * eye(1);
N = zeros(1);
for i = 1:ph
    for j = 1:ph
        if (j == 1)
            if (i == 1)
                W2_row = Fh;
            else
                W2_row = N;
            end
        else
            if (j == i)
                W2_row = cat(2,W2_row,Fh);
            else
                W2_row = cat(2,W2_row,N);
            end
        end  
    end
    if (i == 1)
        W2_h = W2_row;
    else
        W2_h = cat(1, W2_h, W2_row);
    end
end

%% W4 matrix

Qh = 10 * eye(3);
N = zeros(3);

% (For C1)
% Q = 10 * eye(1);
% N = zeros(1);

for i = 1:ph
    for j = 1:ph
        if (j == 1)
            if (i == 1)
                W4_row = Qh;
            else
                W4_row = N;
            end
        else
            if (j == i)
                W4_row = cat(2,W4_row,Qh);
            else
                W4_row = cat(2,W4_row,N);
            end
        end  
    end
    if (i == 1)
        W4_h = W4_row;
    else
        W4_h = cat(1, W4_h, W4_row);
    end
end
% W3 matrix
W3_h = (W1_h.')*W2_h*W1_h;
adjoint(W3_h);

Th = Theta_h.';
Hh = (Th*W4_h*Theta_h)+W2_h;
