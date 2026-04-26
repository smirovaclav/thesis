function results = dynamic_simul(data, add_residuals, remove_grpe,...
    remove_grpf, remove_vu, remove_shortage, remove_covid, update_graphs)

%% Readme
% A quick introduction on naming conventions:
% Variables with no suffixes, e.g. gw, gcpi, represent vars
% that are equal to the actual historical value. 
%
% Variables ending in _simul are those that are used in the dynamic
% simulation portion of this script. The first four values are initialized
% to equal actual historical data (since we are working with 4 lags). After
% that, shocks are removed at t=5, and the system is allowed to forward
% propogate based on initial conditions and shock values.
%
% Variables ending in _simul_orig are those that are used to model the
% economy with all shocks introduced. By removing one shock at a time and
% comparing it to the original simulation with all shocks included, we can
% derive the contribution each shock contributed to overall macroeconomic
% dynamics.


%% Get coefficients
gw_beta = readtable("eq_coefficients.xlsx", 'Sheet', "gw");
gcpi_beta = readtable("eq_coefficients.xlsx", 'Sheet', "gcpi");
cf1_beta = readtable("eq_coefficients.xlsx", 'Sheet', "cf1");
cf10_beta = readtable("eq_coefficients.xlsx", 'Sheet', "cf10");


%% Format data
% Inititialize variables showing historical data
data = data(data.period >= datetime(2018,10,1), :);
timesteps = size(data,1);
period = data.period.';

gw = data.gw.';
gcpi = data.gcpi.';
cf1 = data.cf1.';
cf10 = data.cf10.';
diffcpicf = data.diffcpicf.';

gw_residuals = data.gw_residuals.';
gcpi_residuals = data.gcpi_residuals.';
cf1_residuals = data.cf1_residuals.';
cf10_residuals = data.cf10_residuals.';

grpe = data.grpe.';
grpf = data.grpf.';
vu = data.vu.';
shortage = data.shortage.';
magpty = data.magpty.';

d_2020Q2 = data.d_2020Q2.';
d_2021Q1 = data.d_2021Q1.';
d_tariff = data.d_tariff.';

% Since we need 4 values before we can run the simulation (because we have
% 4 lags), we need to initialize the first 4 values of cf1_simul to the
% actual data
gw_simul = gw(1:4);
gcpi_simul(1:4) = gcpi(1:4);
cf1_simul(1:4) = cf1(1:4);
cf10_simul(1:4) = cf10(1:4);

% Initialize diffcpicf (we simulate this as well since gcpi and cf1 are
% endogenous)
diffcpicf_simul = diffcpicf(1:4);

% Initialize shock variables for simulation. We set values to zero if shock
% is removed.
grpe_simul = grpe;
grpf_simul = grpf;
vu_simul = vu;
shortage_simul = shortage;
d_2020Q2_simul = d_2020Q2;
d_2021Q1_simul = d_2021Q1;
d_tariff_simul = d_tariff;

% Initialize cell array of shocks added
shocks_removed = {};
step = 1;
if remove_grpe
    shocks_removed{step} = "grpe";
    step = step + 1;
end

if remove_grpf
    shocks_removed{step} = "grpf";
    step = step + 1;
end

if remove_vu
    shocks_removed{step} = "vu";
    step = step + 1;
end

if remove_shortage
    shocks_removed{step} = "shortage";
    step = step + 1;
end
if remove_covid
    shocks_removed{step} = "lockdown";
    step = step + 1;
end

% Run simulation with exogenous variables removed
if add_residuals
    for t = 5:timesteps
        % Set exogenous variables to desired value after initializing first
        % 4 data points if shocks are turned on
        if remove_grpe
            grpe_simul(t) = 0;
            d_tariff_simul(t) = 0;
        end

        if remove_grpf
            grpf_simul(t) = 0;
        end

        if remove_vu
            vu_simul(t) = data.vu(5);
        end

        if remove_shortage
            shortage_simul(t) = data.shortage(5);
        end
        
        if remove_covid
            d_2020Q2_simul(t) = 0;
            d_2021Q1_simul(t) = 0;
        end

        % Equation adding residuals in (should equal actual series)
        gw_simul(t) = gw_beta.beta(1)*gw_simul(t-1)+...
        gw_beta.beta(2)*gw_simul(t-2)+...
        gw_beta.beta(3)*gw_simul(t-3) +...
        gw_beta.beta(4)*gw_simul(t-4)+...
        gw_beta.beta(5)*cf1_simul(t-1) +...
        gw_beta.beta(6)*cf1_simul(t-2) +...
        gw_beta.beta(7)*cf1_simul(t-3) +...
        gw_beta.beta(8)*cf1_simul(t-4)+...
        gw_beta.beta(9)*magpty(t-1) + gw_beta.beta(10)*vu_simul(t-1) +...
        gw_beta.beta(11)*vu_simul(t-2)+...
        gw_beta.beta(12)*vu_simul(t-3) +...
        gw_beta.beta(13)*vu_simul(t-4) +...
        gw_beta.beta(14)*diffcpicf_simul(t-1) +...
        gw_beta.beta(15)*diffcpicf_simul(t-2)+...
        gw_beta.beta(16)*diffcpicf_simul(t-3)+...
        gw_beta.beta(17)*diffcpicf_simul(t-4) +...
        gw_beta.beta(18) + ...
        gw_beta.beta(19)*d_2020Q2_simul(t) + ...
        gw_beta.beta(20)*d_2021Q1_simul(t) + ...
        gw_residuals(t);

        gcpi_simul(t) =  gcpi_beta.beta(1)*magpty(t) +...
        gcpi_beta.beta(2)*gcpi_simul(t-1) +...
        gcpi_beta.beta(3)*gcpi_simul(t-2) +...
        gcpi_beta.beta(4)*gcpi_simul(t-3) +...
        gcpi_beta.beta(5)*gcpi_simul(t-4) + ...
        gcpi_beta.beta(6)*gw_simul(t) +...
        gcpi_beta.beta(7)*gw_simul(t-1)+...
        gcpi_beta.beta(8)*gw_simul(t-2) +...
        gcpi_beta.beta(9)*gw_simul(t-3) +...
        gcpi_beta.beta(10)*gw_simul(t-4) +...
        gcpi_beta.beta(11)*grpe_simul(t) +...
        gcpi_beta.beta(12)*grpe_simul(t-1) +...
        gcpi_beta.beta(13)*grpe_simul(t-2) +...
        gcpi_beta.beta(14)*grpe_simul(t-3) +...
        gcpi_beta.beta(15)*grpe_simul(t-4) +...
        gcpi_beta.beta(16)*grpf_simul(t) +...
        gcpi_beta.beta(17)*grpf_simul(t-1) +...
        gcpi_beta.beta(18)*grpf_simul(t-2) +...
        gcpi_beta.beta(19)*grpf_simul(t-3) +...
        gcpi_beta.beta(20)*grpf_simul(t-4) +...
        gcpi_beta.beta(21)*shortage_simul(t) +...
        gcpi_beta.beta(22)*shortage_simul(t-1) +...
        gcpi_beta.beta(23)*shortage_simul(t-2) +...
        gcpi_beta.beta(24)*shortage_simul(t-3) +...
        gcpi_beta.beta(25)*shortage_simul(t-4) +...
        gcpi_beta.beta(26) + ...
        gcpi_beta.beta(27)*d_tariff_simul(t) + ...
        gcpi_residuals(t);

        diffcpicf_simul(t) = 0.25*(gcpi_simul(t) + gcpi_simul(t-1) +...
        gcpi_simul(t-2) + gcpi_simul(t-3)) - cf1_simul(t-4);
        
        cf10_simul(t) = cf10_beta.beta(1)*cf10_simul(t-1) +...
        cf10_beta.beta(2)*cf10_simul(t-2) +...
        cf10_beta.beta(3)*cf10_simul(t-3) +...
        cf10_beta.beta(4)*cf10_simul(t-4) +...
        cf10_beta.beta(5)*gcpi_simul(t) +...
        cf10_beta.beta(6)*gcpi_simul(t-1) +...
        cf10_beta.beta(7)*gcpi_simul(t-2) +...
        cf10_beta.beta(8)*gcpi_simul(t-3) +...
        cf10_beta.beta(9)*gcpi_simul(t-4) + ...
        cf10_residuals(t);
        
        cf1_simul(t) = cf1_beta.beta(1)*cf1_simul(t-1)+...
        cf1_beta.beta(2)*cf1_simul(t-2)+...
        cf1_beta.beta(3)*cf1_simul(t-3) +...
        cf1_beta.beta(4)*cf1_simul(t-4)+...
        cf1_beta.beta(5)*cf10_simul(t) +...
        cf1_beta.beta(6)*cf10_simul(t-1)+...
        cf1_beta.beta(7)*cf10_simul(t-2)+...
        cf1_beta.beta(8)*cf10_simul(t-3) +...
        cf1_beta.beta(9)*cf10_simul(t-4)+...
        cf1_beta.beta(10)*gcpi_simul(t) +...
        cf1_beta.beta(11)*gcpi_simul(t-1) +...
        cf1_beta.beta(12)*gcpi_simul(t-2) +...
        cf1_beta.beta(13)*gcpi_simul(t-3) +...
        cf1_beta.beta(14)*gcpi_simul(t-4) +...
        cf1_residuals(t);
    end
else
    for t = 5:timesteps
        % Set exogenous variables to desired value after initializing first
        % 4 data points if shocks are turned on
        if remove_grpe
            grpe_simul(t) = 0;
            d_tariff_simul(t) = 0;
        end

        if remove_grpf
            grpf_simul(t) = 0;
        end

        if remove_vu
            vu_simul(t) = data.vu(5);
        end

        if remove_shortage
            shortage_simul(t) = data.shortage(5);
        end
        
        if remove_covid
            d_2020Q2_simul(t) = 0;
            d_2021Q1_simul(t) = 0;
        end
        % Equation not adding residuals in
        gw_simul(t) = gw_beta.beta(1)*gw_simul(t-1)+...
        gw_beta.beta(2)*gw_simul(t-2)+...
        gw_beta.beta(3)*gw_simul(t-3) +...
        gw_beta.beta(4)*gw_simul(t-4)+...
        gw_beta.beta(5)*cf1_simul(t-1) +...
        gw_beta.beta(6)*cf1_simul(t-2) +...
        gw_beta.beta(7)*cf1_simul(t-3) +...
        gw_beta.beta(8)*cf1_simul(t-4)+...
        gw_beta.beta(9)*magpty(t-1) + gw_beta.beta(10)*vu_simul(t-1) +...
        gw_beta.beta(11)*vu_simul(t-2)+...
        gw_beta.beta(12)*vu_simul(t-3) +...
        gw_beta.beta(13)*vu_simul(t-4) +...
        gw_beta.beta(14)*diffcpicf_simul(t-1) +...
        gw_beta.beta(15)*diffcpicf_simul(t-2)+...
        gw_beta.beta(16)*diffcpicf_simul(t-3)+...
        gw_beta.beta(17)*diffcpicf_simul(t-4) +...
        gw_beta.beta(18) + ...
        gw_beta.beta(19)*d_2020Q2_simul(t) + ...
        gw_beta.beta(20)*d_2021Q1_simul(t);



        gcpi_simul(t) =  gcpi_beta.beta(1)*magpty(t) +...
        gcpi_beta.beta(2)*gcpi_simul(t-1) +...
        gcpi_beta.beta(3)*gcpi_simul(t-2) +...
        gcpi_beta.beta(4)*gcpi_simul(t-3) +...
        gcpi_beta.beta(5)*gcpi_simul(t-4) + ...
        gcpi_beta.beta(6)*gw_simul(t)+ gcpi_beta.beta(7)*gw_simul(t-1)+...
        gcpi_beta.beta(8)*gw_simul(t-2) +...
        gcpi_beta.beta(9)*gw_simul(t-3) +...
        gcpi_beta.beta(10)*gw_simul(t-4) +...
        gcpi_beta.beta(11)*grpe_simul(t) +...
        gcpi_beta.beta(12)*grpe_simul(t-1) +...
        gcpi_beta.beta(13)*grpe_simul(t-2) +...
        gcpi_beta.beta(14)*grpe_simul(t-3) +...
        gcpi_beta.beta(15)*grpe_simul(t-4) +...
        gcpi_beta.beta(16)*grpf_simul(t) +...
        gcpi_beta.beta(17)*grpf_simul(t-1) +...
        gcpi_beta.beta(18)*grpf_simul(t-2) +...
        gcpi_beta.beta(19)*grpf_simul(t-3) +...
        gcpi_beta.beta(20)*grpf_simul(t-4) +...
        gcpi_beta.beta(21)*shortage_simul(t) +...
        gcpi_beta.beta(22)*shortage_simul(t-1) +...
        gcpi_beta.beta(23)*shortage_simul(t-2) +...
        gcpi_beta.beta(24)*shortage_simul(t-3) +...
        gcpi_beta.beta(25)*shortage_simul(t-4) +...
        gcpi_beta.beta(26) + ...
        gcpi_beta.beta(27)*d_tariff_simul(t);


        diffcpicf_simul(t) = 0.25*(gcpi_simul(t) + gcpi_simul(t-1) +...
        gcpi_simul(t-2) + gcpi_simul(t-3)) - cf1_simul(t-4);
        
        cf10_simul(t) = cf10_beta.beta(1)*cf10_simul(t-1) +...
        cf10_beta.beta(2)*cf10_simul(t-2) +...
        cf10_beta.beta(3)*cf10_simul(t-3) +...
        cf10_beta.beta(4)*cf10_simul(t-4) +...
        cf10_beta.beta(5)*gcpi_simul(t) +...
        cf10_beta.beta(6)*gcpi_simul(t-1) +...
        cf10_beta.beta(7)*gcpi_simul(t-2) +...
        cf10_beta.beta(8)*gcpi_simul(t-3) +...
        cf10_beta.beta(9)*gcpi_simul(t-4);
        
        cf1_simul(t) = cf1_beta.beta(1)*cf1_simul(t-1)+...
        cf1_beta.beta(2)*cf1_simul(t-2)+...
        cf1_beta.beta(3)*cf1_simul(t-3) +...
        cf1_beta.beta(4)*cf1_simul(t-4)+...
        cf1_beta.beta(5)*cf10_simul(t) +...
        cf1_beta.beta(6)*cf10_simul(t-1)+...
        cf1_beta.beta(7)*cf10_simul(t-2)+...
        cf1_beta.beta(8)*cf10_simul(t-3) +...
        cf1_beta.beta(9)*cf10_simul(t-4)+...
        cf1_beta.beta(10)*gcpi_simul(t) +...
        cf1_beta.beta(11)*gcpi_simul(t-1) +...
        cf1_beta.beta(12)*gcpi_simul(t-2) +...
        cf1_beta.beta(13)*gcpi_simul(t-3) +...
        cf1_beta.beta(14)*gcpi_simul(t-4);
    end
end

%% Run simulation with all exogenous variables included
gw_simul_orig = gw(1:4);
gcpi_simul_orig(1:4) = gcpi(1:4);
cf1_simul_orig(1:4) = cf1(1:4);
cf10_simul_orig(1:4) = cf10(1:4);
diffcpicf_simul_orig(1:4) = diffcpicf(1:4);

if add_residuals
    for t = 5:timesteps
        % Equation adding residuals in (should equal actual series)
        gw_simul_orig(t) = gw_beta.beta(1)*gw_simul_orig(t-1)+...
        gw_beta.beta(2)*gw_simul_orig(t-2)+...
        gw_beta.beta(3)*gw_simul_orig(t-3) +...
        gw_beta.beta(4)*gw_simul_orig(t-4)+...
        gw_beta.beta(5)*cf1_simul_orig(t-1) +...
        gw_beta.beta(6)*cf1_simul_orig(t-2) +...
        gw_beta.beta(7)*cf1_simul_orig(t-3) +...
        gw_beta.beta(8)*cf1_simul_orig(t-4)+...
        gw_beta.beta(9)*magpty(t-1) + gw_beta.beta(10)*vu(t-1) +...
        gw_beta.beta(11)*vu(t-2)+...
        gw_beta.beta(12)*vu(t-3) + gw_beta.beta(13)*vu(t-4) +...
        gw_beta.beta(14)*diffcpicf_simul_orig(t-1) +...
        gw_beta.beta(15)*diffcpicf_simul_orig(t-2)+...
        gw_beta.beta(16)*diffcpicf_simul_orig(t-3)+...
        gw_beta.beta(17)*diffcpicf_simul_orig(t-4) +...
        gw_beta.beta(18) +...
        gw_beta.beta(19)*d_2020Q2(t) + ... 
        gw_beta.beta(20)*d_2021Q1(t) + ...
        gw_residuals(t);        

        gcpi_simul_orig(t) =  gcpi_beta.beta(1)*magpty(t) +...
        gcpi_beta.beta(2)*gcpi_simul_orig(t-1) +...
        gcpi_beta.beta(3)*gcpi_simul_orig(t-2) +...
        gcpi_beta.beta(4)*gcpi_simul_orig(t-3) +...
        gcpi_beta.beta(5)*gcpi_simul_orig(t-4) + ...
        gcpi_beta.beta(6)*gw_simul_orig(t) +...
        gcpi_beta.beta(7)*gw_simul_orig(t-1)+...
        gcpi_beta.beta(8)*gw_simul_orig(t-2) +...
        gcpi_beta.beta(9)*gw_simul_orig(t-3) +...
        gcpi_beta.beta(10)*gw_simul_orig(t-4) +...
        gcpi_beta.beta(11)*grpe(t) +...
        gcpi_beta.beta(12)*grpe(t-1) +...
        gcpi_beta.beta(13)*grpe(t-2) + gcpi_beta.beta(14)*grpe(t-3) +...
        gcpi_beta.beta(15)*grpe(t-4) +...
        gcpi_beta.beta(16)*grpf(t) +...
        gcpi_beta.beta(17)*grpf(t-1) +...
        gcpi_beta.beta(18)*grpf(t-2) +...
        gcpi_beta.beta(19)*grpf(t-3) +...
        gcpi_beta.beta(20)*grpf(t-4) +...
        gcpi_beta.beta(21)*shortage(t) +...
        gcpi_beta.beta(22)*shortage(t-1) +...
        gcpi_beta.beta(23)*shortage(t-2) +...
        gcpi_beta.beta(24)*shortage(t-3) +...
        gcpi_beta.beta(25)*shortage(t-4) +...
        gcpi_beta.beta(26) +...
        gcpi_beta.beta(27)*d_tariff(t) +...
        gcpi_residuals(t);

        diffcpicf_simul_orig(t) = 0.25*(gcpi_simul_orig(t) +...
        gcpi_simul_orig(t-1) + gcpi_simul_orig(t-2) +...
        gcpi_simul_orig(t-3)) - cf1_simul_orig(t-4);
        
        cf10_simul_orig(t) = cf10_beta.beta(1)*cf10_simul_orig(t-1) +...
        cf10_beta.beta(2)*cf10_simul_orig(t-2) +...
        cf10_beta.beta(3)*cf10_simul_orig(t-3) +...
        cf10_beta.beta(4)*cf10_simul_orig(t-4) +...
        cf10_beta.beta(5)*gcpi_simul_orig(t) +...
        cf10_beta.beta(6)*gcpi_simul_orig(t-1) +...
        cf10_beta.beta(7)*gcpi_simul_orig(t-2) +...
        cf10_beta.beta(8)*gcpi_simul_orig(t-3) +...
        cf10_beta.beta(9)*gcpi_simul_orig(t-4) + ...
        cf10_residuals(t);
        
        cf1_simul_orig(t) = cf1_beta.beta(1)*cf1_simul_orig(t-1)+...
        cf1_beta.beta(2)*cf1_simul_orig(t-2)+...
        cf1_beta.beta(3)*cf1_simul_orig(t-3) +...
        cf1_beta.beta(4)*cf1_simul_orig(t-4)+...
        cf1_beta.beta(5)*cf10_simul_orig(t) +...
        cf1_beta.beta(6)*cf10_simul_orig(t-1)+...
        cf1_beta.beta(7)*cf10_simul_orig(t-2)+...
        cf1_beta.beta(8)*cf10_simul_orig(t-3) +...
        cf1_beta.beta(9)*cf10_simul_orig(t-4)+...
        cf1_beta.beta(10)*gcpi_simul_orig(t) +...
        cf1_beta.beta(11)*gcpi_simul_orig(t-1) +...
        cf1_beta.beta(12)*gcpi_simul_orig(t-2) +...
        cf1_beta.beta(13)*gcpi_simul_orig(t-3) +...
        cf1_beta.beta(14)*gcpi_simul_orig(t-4) +...
        cf1_residuals(t);
    end
else
    for t = 5:timesteps

        % Equation not adding residuals in
        gw_simul_orig(t) = gw_beta.beta(1)*gw_simul_orig(t-1)+...
        gw_beta.beta(2)*gw_simul_orig(t-2)+...
        gw_beta.beta(3)*gw_simul_orig(t-3) +...
        gw_beta.beta(4)*gw_simul_orig(t-4)+...
        gw_beta.beta(5)*cf1_simul_orig(t-1) +...
        gw_beta.beta(6)*cf1_simul_orig(t-2) +...
        gw_beta.beta(7)*cf1_simul_orig(t-3) +...
        gw_beta.beta(8)*cf1_simul_orig(t-4)+...
        gw_beta.beta(9)*magpty(t-1) + gw_beta.beta(10)*vu(t-1) +...
        gw_beta.beta(11)*vu(t-2)+...
        gw_beta.beta(12)*vu(t-3) + gw_beta.beta(13)*vu(t-4) +...
        gw_beta.beta(14)*diffcpicf_simul_orig(t-1) +...
        gw_beta.beta(15)*diffcpicf_simul_orig(t-2)+...
        gw_beta.beta(16)*diffcpicf_simul_orig(t-3)+...
        gw_beta.beta(17)*diffcpicf_simul_orig(t-4) +...
        gw_beta.beta(18) +...
        gw_beta.beta(19)*d_2020Q2(t) + ... 
        gw_beta.beta(20)*d_2021Q1(t);

        gcpi_simul_orig(t) =  gcpi_beta.beta(1)*magpty(t) +...
        gcpi_beta.beta(2)*gcpi_simul_orig(t-1) +...
        gcpi_beta.beta(3)*gcpi_simul_orig(t-2) +...
        gcpi_beta.beta(4)*gcpi_simul_orig(t-3) +...
        gcpi_beta.beta(5)*gcpi_simul_orig(t-4) + ...
        gcpi_beta.beta(6)*gw_simul_orig(t) +...
        gcpi_beta.beta(7)*gw_simul_orig(t-1)+...
        gcpi_beta.beta(8)*gw_simul_orig(t-2) +...
        gcpi_beta.beta(9)*gw_simul_orig(t-3) +...
        gcpi_beta.beta(10)*gw_simul_orig(t-4) +...
        gcpi_beta.beta(11)*grpe(t) +...
        gcpi_beta.beta(12)*grpe(t-1) +...
        gcpi_beta.beta(13)*grpe(t-2) + gcpi_beta.beta(14)*grpe(t-3) +...
        gcpi_beta.beta(15)*grpe(t-4) +...
        gcpi_beta.beta(16)*grpf(t) +...
        gcpi_beta.beta(17)*grpf(t-1) +...
        gcpi_beta.beta(18)*grpf(t-2) +...
        gcpi_beta.beta(19)*grpf(t-3) +...
        gcpi_beta.beta(20)*grpf(t-4) +...
        gcpi_beta.beta(21)*shortage(t) +...
        gcpi_beta.beta(22)*shortage(t-1) +...
        gcpi_beta.beta(23)*shortage(t-2) +...
        gcpi_beta.beta(24)*shortage(t-3) +...
        gcpi_beta.beta(25)*shortage(t-4) +...
        gcpi_beta.beta(26) +...
        gcpi_beta.beta(27)*d_tariff(t);

        diffcpicf_simul_orig(t) = 0.25*(gcpi_simul_orig(t) +...
            gcpi_simul_orig(t-1) +...
        gcpi_simul_orig(t-2) + gcpi_simul_orig(t-3)) -...
        cf1_simul_orig(t-4);
        
        cf10_simul_orig(t) = cf10_beta.beta(1)*cf10_simul_orig(t-1) +...
        cf10_beta.beta(2)*cf10_simul_orig(t-2) +...
        cf10_beta.beta(3)*cf10_simul_orig(t-3) +...
        cf10_beta.beta(4)*cf10_simul_orig(t-4) +...
        cf10_beta.beta(5)*gcpi_simul_orig(t) +...
        cf10_beta.beta(6)*gcpi_simul_orig(t-1) +...
        cf10_beta.beta(7)*gcpi_simul_orig(t-2) +...
        cf10_beta.beta(8)*gcpi_simul_orig(t-3) +...
        cf10_beta.beta(9)*gcpi_simul_orig(t-4);
        
        cf1_simul_orig(t) = cf1_beta.beta(1)*cf1_simul_orig(t-1)+...
        cf1_beta.beta(2)*cf1_simul_orig(t-2)+...
        cf1_beta.beta(3)*cf1_simul_orig(t-3) +...
        cf1_beta.beta(4)*cf1_simul_orig(t-4)+...
        cf1_beta.beta(5)*cf10_simul_orig(t) +...
        cf1_beta.beta(6)*cf10_simul_orig(t-1)+...
        cf1_beta.beta(7)*cf10_simul_orig(t-2)+...
        cf1_beta.beta(8)*cf10_simul_orig(t-3) +...
        cf1_beta.beta(9)*cf10_simul_orig(t-4)+...
        cf1_beta.beta(10)*gcpi_simul_orig(t) +...
        cf1_beta.beta(11)*gcpi_simul_orig(t-1) +...
        cf1_beta.beta(12)*gcpi_simul_orig(t-2) +...
        cf1_beta.beta(13)*gcpi_simul_orig(t-3) +...
        cf1_beta.beta(14)*gcpi_simul_orig(t-4);
    end
end
%% Creating lockdown variable
lockdown = d_2020Q2 + d_2021Q1;
lockdown_simul = d_2020Q2_simul + d_2021Q1_simul;
%% Export data
out_data = table(period.', gw.', gw_simul.', gw_simul_orig.',...
    gcpi.', gcpi_simul.', gcpi_simul_orig.',...
    cf1.', cf1_simul.', cf1_simul_orig.',...
    cf10.', cf10_simul.', cf10_simul_orig.',...
    grpe.', grpe_simul.',...
    grpf.', grpf_simul.',...
    vu.', vu_simul.',...
    shortage.', shortage_simul.',...
    lockdown.', lockdown_simul.',... 
    d_tariff.', d_tariff_simul.',...    
    'VariableNames',["period", "gw", "gw_simul", "gw_simul_orig",...
    "gcpi", "gcpi_simul", "gcpi_simul_orig",...
    "cf1", "cf1_simul", "cf1_simul_orig",...
    "cf10", "cf10_simul", "cf10_simul_orig",...
    "grpe", "grpe_simul",...
    "grpf", "grpf_simul",...
    "vu", "vu_simul",...
    "shortage", "shortage_simul",...
    "lockdown", "lockdown_simul",... 
    "d_tariff", "d_tariff_simul"]);

%% Calculate contribution of shocks
if size(shocks_removed, 2) == 1
    contr_gw = gw_simul_orig - gw_simul;
    contr_gcpi = gcpi_simul_orig - gcpi_simul;
    contr_cf1 = cf1_simul_orig - cf1_simul;
    contr_cf10 = cf10_simul_orig - cf10_simul;

    out_data_2 = table(contr_gw.', contr_gcpi.', contr_cf1.',...
        contr_cf10.', 'VariableNames',[shocks_removed{1} + "_contr_gw",...
        shocks_removed{1} + "_contr_gcpi", shocks_removed{1} +...
        "_contr_cf1", shocks_removed{1} + "_contr_cf10"]);
    out_data = [out_data out_data_2];
end

%% Store variables to results
% We transpose from rows to columns so that we can save more easily when
% exporting data

results.period = period.';
results.gw = gw.';
results.gw_simul = gw_simul.';
results.gw_simul_orig = gw_simul_orig.';

results.gcpi = gcpi.';
results.gcpi_simul = gcpi_simul.';
results.gcpi_simul_orig = gcpi_simul_orig.';

results.cf1 = cf1.';
results.cf1_simul = cf1_simul.';
results.cf1_simul_orig = cf1_simul_orig.';

results.cf10 = cf10.';
results.cf10_simul = cf10_simul.';
results.cf10_simul_orig = cf10_simul_orig.';

results.grpe = grpe.';
results.grpe_simul = grpe_simul.';

results.grpf = grpf_simul.';
results.grpf_simul = grpf_simul.';

results.vu = vu_simul.';
results.vu_simul = vu_simul.';

results.shortage = shortage.';
results.shortage_simul = shortage_simul.';

results.lockdown = (d_2020Q2 + d_2021Q1).';
results.lockdown_simul = (d_2020Q2_simul + d_2021Q1_simul).';
results.d_tariff = d_tariff.';
results.d_tariff_simul = d_tariff_simul.';

% results.magpty = magpty.';
% results.diffcpicf = diffcpicf.';
% results.gw_residuals = gw_residuals.';
% results.gcpi_residuals = gcpi_residuals.';
% results.cf1_residuals = cf1_residuals.';
% results.cf10_residuals = cf10_residuals.';
% results.diffcpicf = diffcpicf_simul.';
% results.shortage_simul = shortage_simul.';
% results.diffcpicf_simul_orig = diffcpicf_simul_orig.';
if remove_grpe | remove_grpf | remove_vu | remove_shortage | remove_covid
    results.contr_gw = (gw_simul_orig - gw_simul).';
    results.contr_gcpi = (gcpi_simul_orig - gcpi_simul).';
    results.contr_cf1 = (cf1_simul_orig - cf1_simul).';
    results.contr_cf10 = (cf10_simul_orig - cf10_simul).';
end

if update_graphs
%% Graph gw
plot(period, gw, 'LineWidth', 1.5)
hold on
plot(period, gw_simul, 'LineWidth', 1.5)
hold on
plot(period, gw_simul_orig, 'LineWidth',1.5)

% Convert period to quarterly labels
old_xlbls = xticklabels;
new_xlbls = {};
crosswalk = containers.Map(["Jan", "Apr", "Jul", "Oct"], [1, 2, 3, 4]);
for step = 1:size(old_xlbls, 1)
    lbl = old_xlbls{step};
    if isempty(lbl)
        new_xlbls{step} = lbl;
    else
        year = lbl(end-4+1:end);
        quarter = crosswalk(lbl(1:3));
        new_xlbls{step} = year + " Q" + quarter;
    end
end
xticklabels(new_xlbls)

legend({'Actual','Simulated (Removed)', 'Simulated (Original)'},...
    'FontSize', 12, 'Location', 'northwest')
xlabel('Period', 'FontSize', 12)
ylabel('Percent', 'FontSize', 12)
grid on

% Add text denoting what shocks were introduced:
removed_text = "Variables removed: ";

for step = 1:size(shocks_removed,2)
    removed_text = removed_text + shocks_removed(step) + "  ";
end

annotation('textbox',[.9 .75 .1 .2], ...
    'String', removed_text,'EdgeColor','none');

% Save figure
cd(base_dir)
cd("..\..\figures\pngs\decompositions")

removed_folder = "";
if size(shocks_removed, 2) ~= 0
    for step = 1:size(shocks_removed, 2)
        if step ==1

            removed_folder = removed_folder + shocks_removed{step};
        else
            removed_folder = removed_folder + "_" + shocks_removed{step};
        end
    end
    cd(removed_folder);
end

if removed_folder == ""
    cd("no_shocks_removed")
end

if add_residuals
    title('gw with residuals', 'FontSize', 14)
    print("gw_w_residuals", "-dpng", "-r150")
else
    title('gw without residuals', 'FontSize', 14)
    print("gw_wo_residuals", "-dpng", "-r150")
end

clf

%% Graph gcpi
plot(period, gcpi, 'LineWidth', 1.5)
hold on
plot(period, gcpi_simul, 'LineWidth', 1.5)
hold on
plot(period, gcpi_simul_orig, 'LineWidth',1.5)

% Convert period to quarterly labels
old_xlbls = xticklabels;
new_xlbls = {};
crosswalk = containers.Map(["Jan", "Apr", "Jul", "Oct"], [1, 2, 3, 4]);
for step = 1:size(old_xlbls, 1)
    lbl = old_xlbls{step};
    if isempty(lbl)
        new_xlbls{step} = lbl;
    else
        year = lbl(end-4+1:end);
        quarter = crosswalk(lbl(1:3));
        new_xlbls{step} = year + " Q" + quarter;
    end
end

xticklabels(new_xlbls)
legend({'Actual','Simulated (Removed)', 'Simulated (Original)'},...
    'FontSize', 12, 'Location', 'northwest')
xlabel('Period', 'FontSize', 12)
ylabel('Percent', 'FontSize', 12)
grid on

% Add text denoting what shocks were introduced:
removed_text = "shocks removed: ";

for step = 1:size(shocks_removed,2)
    removed_text = removed_text + shocks_removed(step) + "  ";
end

annotation('textbox',[.9 .75 .1 .2], ...
    'String', removed_text,'EdgeColor','none');

% Save figure
cd(base_dir)
cd("..\..\figures\pngs\decompositions")

removed_folder = "";
if size(shocks_removed, 2) ~= 0
    for step = 1:size(shocks_removed, 2)
        if step ==1

            removed_folder = removed_folder + shocks_removed{step};
        else
            removed_folder = removed_folder + "_" + shocks_removed{step};
        end
    end
    cd(removed_folder);
end

if removed_folder == ""
    cd("no_shocks_removed")
end

if add_residuals
    title('gcpi with residuals', 'FontSize', 14)
    print("gcpi_w_residuals", "-dpng", "-r150")
else
    title('gcpi without residuals', 'FontSize', 14)
    print("gcpi_wo_residuals", "-dpng", "-r150")
end
clf

%% Graph cf10
plot(period, cf10, 'LineWidth', 1.5)
hold on
plot(period, cf10_simul, 'LineWidth', 1.5)
hold on
plot(period, cf10_simul_orig, 'LineWidth',1.5)

% Convert period to quarterly labels
old_xlbls = xticklabels;
new_xlbls = {};
crosswalk = containers.Map(["Jan", "Apr", "Jul", "Oct"], [1, 2, 3, 4]);
for step = 1:size(old_xlbls, 1)
    lbl = old_xlbls{step};
    if isempty(lbl)
        new_xlbls{step} = lbl;
    else
        year = lbl(end-4+1:end);
        quarter = crosswalk(lbl(1:3));
        new_xlbls{step} = year + " Q" + quarter;
    end
end
xticklabels(new_xlbls)

legend({'Actual','Simulated (Removed)', 'Simulated (Original)'},...
    'FontSize', 12, 'Location', 'northwest')
xlabel('Period', 'FontSize', 12)
ylabel('Percent', 'FontSize', 12)
grid on

% Add text denoting what shocks were introduced:
removed_text = "shocks removed: ";

for step = 1:size(shocks_removed,2)
    removed_text = removed_text + shocks_removed(step) + "  ";
end

annotation('textbox',[.9 .75 .1 .2], ...
    'String', removed_text,'EdgeColor','none');

% Save figure
cd(base_dir)
cd("..\..\figures\pngs\decompositions")

removed_folder = "";
if size(shocks_removed, 2) ~= 0
    for step = 1:size(shocks_removed, 2)
        if step ==1
            removed_folder = removed_folder + shocks_removed{step};
        else
            removed_folder = removed_folder + "_" + shocks_removed{step};
        end
    end
    cd(removed_folder);
end

if removed_folder == ""
    cd("no_shocks_removed")
end

if add_residuals
    title('cf10 with residuals', 'FontSize', 14)
    print("cf10_w_residuals", "-dpng", "-r150")
else
    title('cf10 without residuals', 'FontSize', 14)
    print("cf10_wo_residuals", "-dpng", "-r150")
end
clf

%% Graph cf1
plot(period, cf1, 'LineWidth', 1.5)
hold on
plot(period, cf1_simul, 'LineWidth', 1.5)
hold on
plot(period, cf1_simul_orig, 'LineWidth',1.5)

% Convert period to quarterly labels
old_xlbls = xticklabels;
new_xlbls = {};
crosswalk = containers.Map(["Jan", "Apr", "Jul", "Oct"], [1, 2, 3, 4]);
for step = 1:size(old_xlbls, 1)
    lbl = old_xlbls{step};
    if isempty(lbl)
        new_xlbls{step} = lbl;
    else
        year = lbl(end-4+1:end);
        quarter = crosswalk(lbl(1:3));
        new_xlbls{step} = year + " Q" + quarter;
    end
end
xticklabels(new_xlbls)

legend({'Actual','Simulated (Removed)', 'Simulated (Original)'},...
    'FontSize', 12, 'Location', 'northwest')
xlabel('Period', 'FontSize', 12)
ylabel('Percent', 'FontSize', 12)
grid on

% Add text denoting what shocks were introduced:
removed_text = "shocks removed: ";

for step = 1:size(shocks_removed,2)
    removed_text = removed_text + shocks_removed(step) + "  ";
end

annotation('textbox',[.9 .75 .1 .2], ...
    'String', removed_text,'EdgeColor','none');

annotation('textbox',[.9 .75 .1 .2], ...
    'String', removed_text,'EdgeColor','none');

% Save figure
cd(base_dir)
cd("..\..\figures\pngs\decompositions")

removed_folder = "";
if size(shocks_removed, 2) ~= 0
    for step = 1:size(shocks_removed, 2)
        if step ==1

            removed_folder = removed_folder + shocks_removed{step};
        else
            removed_folder = removed_folder + "_" + shocks_removed{step};
        end
    end
    cd(removed_folder);
end

if removed_folder == ""
    cd("no_shocks_removed")
end

if add_residuals
    title('cf1 with residuals', 'FontSize', 14)
    print("cf1_w_residuals", "-dpng", "-r150")
else
    title('cf1 without residuals', 'FontSize', 14)
    print("cf1_wo_residuals", "-dpng", "-r150")
end
clf

%% Graph diffcpicf
plot(period, diffcpicf, 'LineWidth', 1.5)
hold on
plot(period, diffcpicf_simul, 'LineWidth', 1.5)
hold on
plot(period, diffcpicf_simul_orig, 'LineWidth',1.5)

% Convert period to quarterly labels
old_xlbls = xticklabels;
new_xlbls = {};
crosswalk = containers.Map(["Jan", "Apr", "Jul", "Oct"], [1, 2, 3, 4]);
for step = 1:size(old_xlbls, 1)
    lbl = old_xlbls{step};
    if isempty(lbl)
        new_xlbls{step} = lbl;
    else
        year = lbl(end-4+1:end);
        quarter = crosswalk(lbl(1:3));
        new_xlbls{step} = year + " Q" + quarter;
    end
end

xticklabels(new_xlbls)

legend({'Actual','Simulated (Removed)', 'Simulated (Original)'},...
    'FontSize', 12, 'Location', 'northwest')
xlabel('Period', 'FontSize', 12)
ylabel('Percent', 'FontSize', 12)
grid on

% Add text denoting what shocks were introduced:
removed_text = "shocks removed: ";

for step = 1:size(shocks_removed,2)
    removed_text = removed_text + shocks_removed(step) + "  ";
end

annotation('textbox',[.9 .75 .1 .2], ...
    'String', removed_text,'EdgeColor','none');

% Save figure
cd(base_dir)
cd("..\..\figures\pngs\decompositions")

removed_folder = "";
if size(shocks_removed, 2) ~= 0
    for step = 1:size(shocks_removed, 2)
        if step ==1

            removed_folder = removed_folder + shocks_removed{step};
        else
            removed_folder = removed_folder + "_" + shocks_removed{step};
        end
    end
    cd(removed_folder);
end

if removed_folder == ""
    cd("no_shocks_removed")
end

if add_residuals
    title('diffcpicf with residuals', 'FontSize', 14)
    print("diffcpicf_w_residuals", "-dpng", "-r150")
else
    title('diffcpicf without residuals', 'FontSize', 14)
    print("diffcpicf_wo_residuals", "-dpng", "-r150")
end
clf

%% Plot grpe
plot(period, grpe, 'LineWidth', 1.5)
hold on
plot(period, grpe_simul, 'LineWidth', 1.5)

% Convert period to quarterly labels
old_xlbls = xticklabels;
new_xlbls = {};
crosswalk = containers.Map(["Jan", "Apr", "Jul", "Oct"], [1, 2, 3, 4]);
for step = 1:size(old_xlbls, 1)
    lbl = old_xlbls{step};
    if isempty(lbl)
        new_xlbls{step} = lbl;
    else
        year = lbl(end-4+1:end);
        quarter = crosswalk(lbl(1:3));
        new_xlbls{step} = year + " Q" + quarter;
    end
end

xticklabels(new_xlbls)

legend({'Actual','Removed (if applicable)'}, 'FontSize', 12, 'Location',...
    'northwest')
xlabel('Period', 'FontSize', 12)
ylabel('Percent', 'FontSize', 12)
grid on

% Add text denoting what shocks were introduced:
removed_text = "shocks removed: ";

for step = 1:size(shocks_removed,2)
    removed_text = removed_text + shocks_removed(step) + "  ";
end

annotation('textbox',[.9 .75 .1 .2], ...
    'String', removed_text,'EdgeColor','none');

% Save figure
cd(base_dir)
cd("..\..\figures\pngs\decompositions")

removed_folder = ""; 
if size(shocks_removed, 2) ~= 0
    for step = 1:size(shocks_removed, 2)
        if step ==1

            removed_folder = removed_folder + shocks_removed{step};
        else
            removed_folder = removed_folder + "_" + shocks_removed{step};
        end
    end
    cd(removed_folder);
end

if removed_folder == ""
    cd("no_shocks_removed")
end

if add_residuals
    title('grpe with residuals', 'FontSize', 14)
    print("grpe_w_residuals", "-dpng", "-r150")
else
    title('grpe without residuals', 'FontSize', 14)
    print("grpe_wo_residuals", "-dpng", "-r150")
end
clf

%% Plot grpf
plot(period, grpf, 'LineWidth', 1.5)
hold on
plot(period, grpf_simul, 'LineWidth', 1.5)

% Convert period to quarterly labels
old_xlbls = xticklabels;
new_xlbls = {};
crosswalk = containers.Map(["Jan", "Apr", "Jul", "Oct"], [1, 2, 3, 4]);
for step = 1:size(old_xlbls, 1)
    lbl = old_xlbls{step};
    if isempty(lbl)
        new_xlbls{step} = lbl;
    else
        year = lbl(end-4+1:end);
        quarter = crosswalk(lbl(1:3));
        new_xlbls{step} = year + " Q" + quarter;
    end
end

xticklabels(new_xlbls)

legend({'Actual','Removed (if applicable)'}, 'FontSize', 12, 'Location',...
    'northwest')
xlabel('Period', 'FontSize', 12)
ylabel('Percent', 'FontSize', 12)
grid on

% Add text denoting what shocks were introduced:
removed_text = "shocks removed: ";

for step = 1:size(shocks_removed,2)
    removed_text = removed_text + shocks_removed(step) + "  ";
end

annotation('textbox',[.9 .75 .1 .2], ...
    'String', removed_text,'EdgeColor','none');

% Save figure
cd(base_dir)
cd("..\..\figures\pngs\decompositions")

removed_folder = "";
if size(shocks_removed, 2) ~= 0
    for step = 1:size(shocks_removed, 2)
        if step ==1

            removed_folder = removed_folder + shocks_removed{step};
        else
            removed_folder = removed_folder + "_" + shocks_removed{step};
        end
    end
    cd(removed_folder);
end

if removed_folder == ""
    cd("no_shocks_removed")
end

if add_residuals
    title('grpf with residuals', 'FontSize', 14)
    print("grpf_w_residuals", "-dpng", "-r150")
else
    title('grpf without residuals', 'FontSize', 14)
    print("grpf_wo_residuals", "-dpng", "-r150")
end
clf

%% Plot vu
plot(period, vu, 'LineWidth', 1.5)
hold on
plot(period, vu_simul, 'LineWidth', 1.5)

% Convert period to quarterly labels
old_xlbls = xticklabels;
new_xlbls = {};
crosswalk = containers.Map(["Jan", "Apr", "Jul", "Oct"], [1, 2, 3, 4]);
for step = 1:size(old_xlbls, 1)
    lbl = old_xlbls{step};
    if isempty(lbl)
        new_xlbls{step} = lbl;
    else
        year = lbl(end-4+1:end);
        quarter = crosswalk(lbl(1:3));
        new_xlbls{step} = year + " Q" + quarter;
    end
end

xticklabels(new_xlbls)

legend({'Actual','Removed (if applicable)'}, 'FontSize', 12, 'Location',...
    'northwest')
xlabel('Period', 'FontSize', 12)
ylabel('Percent', 'FontSize', 12)
grid on

% Add text denoting what shocks were introduced:
removed_text = "shocks removed: ";

for step = 1:size(shocks_removed,2)
    removed_text = removed_text + shocks_removed(step) + "  ";
end

annotation('textbox',[.9 .75 .1 .2], ...
    'String', removed_text,'EdgeColor','none');

% Save figure
cd(base_dir)
cd("..\..\figures\pngs\decompositions")

removed_folder = "";
if size(shocks_removed, 2) ~= 0
    for step = 1:size(shocks_removed, 2)
        if step ==1

            removed_folder = removed_folder + shocks_removed{step};
        else
            removed_folder = removed_folder + "_" + shocks_removed{step};
        end
    end
    cd(removed_folder);
end

if removed_folder == ""
    cd("no_shocks_removed")
end

if add_residuals
    title('vu with residuals', 'FontSize', 14)
    print("vu_w_residuals", "-dpng", "-r150")
else
    title('vu without residuals', 'FontSize', 14)
    print("vu_wo_residuals", "-dpng", "-r150")
end
clf

%% Plot shortage
plot(period, shortage, 'LineWidth', 1.5)
hold on
plot(period, shortage_simul, 'LineWidth', 1.5)

% Convert period to quarterly labels
old_xlbls = xticklabels;
new_xlbls = {};
crosswalk = containers.Map(["Jan", "Apr", "Jul", "Oct"], [1, 2, 3, 4]);
for step = 1:size(old_xlbls, 1)
    lbl = old_xlbls{step};
    if isempty(lbl)
        new_xlbls{step} = lbl;
    else
        year = lbl(end-4+1:end);
        quarter = crosswalk(lbl(1:3));
        new_xlbls{step} = year + " Q" + quarter;
    end
end

xticklabels(new_xlbls)

legend({'Actual','Removed (if applicable)'}, 'FontSize', 12, 'Location',...
    'northwest')
xlabel('Period', 'FontSize', 12)
ylabel('Percent', 'FontSize', 12)
grid on

% Add text denoting what shocks were introduced:
removed_text = "shocks removed: ";

for step = 1:size(shocks_removed,2)
    removed_text = removed_text + shocks_removed(step) + "  ";
end

annotation('textbox',[.9 .75 .1 .2], ...
    'String', removed_text,'EdgeColor','none');

% Save figure
cd(base_dir)
cd("..\..\figures\pngs\decompositions")

removed_folder = "";
if size(shocks_removed, 2) ~= 0
    for step = 1:size(shocks_removed, 2)
        if step ==1

            removed_folder = removed_folder + shocks_removed{step};
        else
            removed_folder = removed_folder + "_" + shocks_removed{step};
        end
    end
    cd(removed_folder);
end

if removed_folder == ""
    cd("no_shocks_removed")
end

if add_residuals
    title('shortage with residuals', 'FontSize', 14)
    print("shortage_w_residuals", "-dpng", "-r150")
else
    title('shortage without residuals', 'FontSize', 14)
    print("shortage_wo_residuals", "-dpng", "-r150")
end
clf
end
end