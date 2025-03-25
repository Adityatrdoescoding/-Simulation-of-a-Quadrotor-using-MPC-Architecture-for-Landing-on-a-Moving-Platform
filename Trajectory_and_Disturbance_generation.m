clc

R = 2;
w = 0.1*3.14;
p = 5;
pz = 5;
h = 0.5;
del_t = 0.01;
u = 0:del_t:50
%% Circular spiral Trajectory
x_func = @(u) R*sin(u*w);
y_func = @(u) R - r(u)*cos(u*w);
z_func = @(u) 0.5*u;

x_v_func = @(u) R*w*(cos(u*w));
y_v_func = @(u) R*w*(sin(u*w));
z_v_func = @(u) 0.5;

x_a_func = @(u) -R*w^2 *(sin(u*w));%-r*w^2 *sin(u*w);
y_a_func = @(u) R*w^2 *(cos(u*w));
z_a_func = @(u) 0;

%% Conical spiral Trajectory
r = @(u) u*pi/100;
x_func = @(u) r(u)*cos(u*w);
y_func = @(u) r(u)*sin(u*w);
z_func = @(u) 0.5*u;

x_v_func = @(u) -r(u)*w*(sin(u*w));
y_v_func = @(u) r(u)*w*(cos(u*w));
z_v_func = @(u) 0.5;

x_a_func = @(u) -r(u)*w^2 *(cos(u*w));%-r*w^2 *sin(u*w);
y_a_func = @(u) -r(u)*w^2 *(sin(u*w));
z_a_func = @(u) 0;

%% Disturbance generation (W is to be generated using Random func)
dwx =@(u) (2*sin(W*pi*u));
dwy =@(u) -1*sin(W*pi*u);
dwz =@(u) 0.8*sin(W*pi*u);
%% Trajectory Generation
xd = zeros(p*3, 1);
yd = zeros(p*3, 1);
zd = zeros(p*3, 1);

flag = 1;
for i = 0:p-1
    xd(flag) = x_func(t + i*del_t);
    xd(flag + 1) = x_v_func(t + i*del_t);
    xd(flag + 2) = x_a_func(t+ i*del_t);

    yd(flag ) = y_func(t+ i*del_t);
    yd(flag + 1) = y_v_func(t+ i*del_t);
    yd(flag +2) = y_a_func(t+ i*del_t);

    zd(flag  ) = z_func(t+ i*del_t);
    zd(flag + 1) = z_v_func(t+ i*del_t);
    zd(flag + 2) = z_a_func(t+ i*del_t);

    flag = flag + 3;
end
%% Desired values given to Plant
x_d = xd;
y_d = yd;
z_d = zd;

x_plot = xd(1);
y_plot = yd(1);
z_plot = zd(1);

%% without disturbance
% Dwx = 0;
% Dwy = 0;
% Dwz = 0;
%% with disturbance
Dwx = dwx(t);
Dwy = dwy(t);
Dwz = dwz(t);

