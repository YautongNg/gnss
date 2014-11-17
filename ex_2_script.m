% Constants
% Speed of light (m/s)
c = 299792458;
% Earth rotation rate (rad/s)
earth_rot_rate = 7.2921151467E-5;
% A priori receiver coordinates (m)
wank_xr = 4235956.688;
wank_yr = 834342.467;
wank_zr = 4681540.682;
% Recorded data
wank_c1 = importdata('WANK_C1');
wank_satt = importdata('WANK_SATT');
wank_xs_raw = importdata('WANK_SATX');
wank_ys_raw = importdata('WANK_SATY');
wank_zs_raw = importdata('WANK_SATZ');
epochs = importdata('Epochs.txt');
epochs = epochs(:,1);
% 3 (a): Correct satellite positions for Earth rotation during light
% travel time.
% Raw geometric distance:
rho_sr_raw = sqrt((wank_xs_raw - wank_xr).^2 ...
+ (wank_ys_raw - wank_yr).^2 + (wank_zs_raw - wank_zr).^2);
dOmega = rho_sr_raw * earth_rot_rate / c;
% Correct the coordinates.
wank_xs = wank_xs_raw .* cos(dOmega) + wank_ys_raw .* sin(dOmega);
wank_ys = - wank_xs_raw .* sin(dOmega) + wank_ys_raw .* cos(dOmega);
wank_zs = wank_zs_raw;
% Recompute the geometric distance.
rho_sr = sqrt((wank_xs - wank_xr).^2 ...
+ (wank_ys - wank_yr).^2 + (wank_zs - wank_zr).^2);
% 3 (b) Compute the derivates of the observation equation.
zeros= [0 0 0 0 0 0 0];
dPdt = c;
cs =[c c c c c c c];
dPdx = -(wank_xs - wank_xr) ./ abs(rho_sr);
dPdy = -(wank_ys - wank_yr) ./ abs(rho_sr);
dPdz = -(wank_zs - wank_zr) ./ abs(rho_sr);
% Correct pseudorange data with satellite clock correction.
c1_corrected = wank_c1 - (c .* wank_satt);
for i=1:length(epochs);
    % Setup the grand design matrix A for every epoch.
    A(:,1)=dPdx(i,:);
    A(:,2)=dPdy(i,:);
    A(:,3)=dPdz(i,:);
    A(:,4)=cs;
    % Solve normal equation.
    deltay = c1_corrected(i,:);
    atransp = transpose(A);
    N = atransp*A;
    %Q = inv(N);
    deltap(:,i) = (N \ atransp) * transpose(deltay);
    % Compute the residuals.
    epsilon(:,i) = transpose(deltay) - (A * deltap(:,i));
    m0(:,i) = sqrt(transpose(epsilon(:,i)) * epsilon(:,i) ./ 3);
    sigmax(:,i) = m0(:,i) * Q(1,1);
    sigmay(:,i) = m0(:,i) * Q(2,2);
    sigmaz(:,i) = m0(:,i) * Q(3,3);
    sigmat(:,i) = m0(:,i) * Q(4,4);
end