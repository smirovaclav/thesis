%% Description
% This script runs various combinations of removing various shocks and adding
% or leaving out residuals. The main model is defined in the file
% dynamic_simul.m
%
% This script is used to derive the contribution each shock contributes to
% overall inflation.
%
% If running into an error where "PNG library failed", please pause syncing 
% for all cloud-based storage systems (e.g. Dropbox, OneDrive) and try
% again.
%
% Set update_graphs to false if you don't wish to produce all the graphs
% (takes some time to produce).
%
% Please contact James Lee (Brookings Institution) or Athiana Tettaravou
% (Peterson Institute) for further questions.

clear all
close all 
clc

%% Import data
data = readtable("eq_simulations_data.xlsx");

%% Initialize structure to store results
results = struct;

%% Delete old all data file
% We do this to make sure no old data is somehow left in from previous
% runs. Since we are saving sheet by sheet, it's not always the case that
% old data gets deleted
if exist("all_data_decompositions.xlsx", 'file')
    delete("all_data_decompositions.xlsx")
end

%% Run simulations for each option (14 combinations total)
for option = 1:14
    %% Options for simulation.
    update_graphs = false;
    
    % Option 1: Baseline bez reziduí
    if option == 1
        add_residuals = false;
        remove_grpe = false;
        remove_grpf = false;
        remove_vu = false;
        remove_shortage = false;
        remove_covid = false;
    
    % Option 2: Pouze Energie (+ Tarif) bez reziduí
    elseif option == 2
        add_residuals = false;
        remove_grpe = true;
        remove_grpf = false;
        remove_vu = false;
        remove_shortage = false;
        remove_covid = false;
    
    % Option 3: Pouze Potraviny bez reziduí
    elseif option == 3
        add_residuals = false;
        remove_grpe = false;
        remove_grpf = true;
        remove_vu = false;
        remove_shortage = false;
        remove_covid = false;
    
    % Option 4: Pouze Nezaměstnanost bez reziduí
    elseif option == 4
        add_residuals = false;
        remove_grpe = false;
        remove_grpf = false;
        remove_vu = true;
        remove_shortage = false;
        remove_covid = false;
    
    % Option 5: Pouze Úzká hrdla bez reziduí
    elseif option == 5
        add_residuals = false;
        remove_grpe = false;
        remove_grpf = false;
        remove_vu = false;
        remove_shortage = true;
        remove_covid = false;

    % Option 6: Pouze Lockdown bez reziduí
    elseif option == 6
        add_residuals = false;
        remove_grpe = false;
        remove_grpf = false;
        remove_vu = false;
        remove_shortage = false;
        remove_covid = true;
    
    % Option 7: Všechny šoky dohromady bez reziduí
    elseif option == 7
        add_residuals = false;
        remove_grpe = true;
        remove_grpf = true;
        remove_vu = true;
        remove_shortage = true;
        remove_covid = true;
    
    % Option 8: Baseline s rezidui (Simulace = Realita)
    elseif option == 8
        add_residuals = true;
        remove_grpe = false;
        remove_grpf = false;
        remove_vu = false;
        remove_shortage = false;
        remove_covid = false;
    
    % Option 9: Energie s rezidui
    elseif option == 9
        add_residuals = true;
        remove_grpe = true;
        remove_grpf = false;
        remove_vu = false;
        remove_shortage = false;
        remove_covid = false;
    
    % Option 10: Potraviny s rezidui
    elseif option == 10
        add_residuals = true;
        remove_grpe = false;
        remove_grpf = true;
        remove_vu = false;
        remove_shortage = false;
        remove_covid = false;
    
    % Option 11: Nezaměstnanost s rezidui
    elseif option == 11
        add_residuals = true;
        remove_grpe = false;
        remove_grpf = false;
        remove_vu = true;
        remove_shortage = false;
        remove_covid = false;
    
    % Option 12: Úzká hrdla s rezidui
    elseif option == 12
        add_residuals = true;
        remove_grpe = false;
        remove_grpf = false;
        remove_vu = false;
        remove_shortage = true;
        remove_covid = false;

    % Option 13: Lockdown s rezidui
    elseif option == 13
        add_residuals = true;
        remove_grpe = false;
        remove_grpf = false;
        remove_vu = false;
        remove_shortage = false;
        remove_covid = true;

    % Option 14: Všechny šoky dohromady s rezidui
    elseif option == 14
        add_residuals = true;
        remove_grpe = true;
        remove_grpf = true;
        remove_vu = true;
        remove_shortage = true;
        remove_covid = true;
    end    
    %% Format residual and shock strings
    % Initializes string to show what shocks have been added and whether
    % residuals were added. Used to store results in an organized manner.

    if add_residuals
        residuals_added_text = "w_residuals";
    else
        residuals_added_text = "wo_residuals";
    end

    shocks_removed_text = "";
    is_first = true;
    if remove_grpe
        if ~is_first
            shocks_removed_text = shocks_removed_text + "_";
        end
        shocks_removed_text  = shocks_removed_text + "grpe";
        is_first = false;
    end
    
    if remove_grpf
        if ~is_first
            shocks_removed_text = shocks_removed_text + "_";
        end
        shocks_removed_text  = shocks_removed_text + "grpf";
        is_first = false;
    end
    
    if remove_vu
        if ~is_first
            shocks_removed_text = shocks_removed_text + "_";
        end
        shocks_removed_text  = shocks_removed_text + "vu";
        is_first = false;
    end
    
    if remove_shortage
        if ~is_first
            shocks_removed_text = shocks_removed_text + "_";
        end
        shocks_removed_text  = shocks_removed_text + "shortage";
        is_first = false;
    end
    
    if remove_covid
        if ~is_first
            shocks_removed_text = shocks_removed_text + "_";
        end
        shocks_removed_text  = shocks_removed_text + "lockdown";
        is_first = false;
    end

    if shocks_removed_text == ""
        shocks_removed_text = "no_shocks_removed";
    end

    %% Run simulation and store data
    results.(residuals_added_text).(shocks_removed_text) =...
    dynamic_simul(data, add_residuals, remove_grpe,...
    remove_grpf, remove_vu, remove_shortage, remove_covid, update_graphs);
    
    sheet_data = struct2table(...
        results.(residuals_added_text).(shocks_removed_text));
    sheet_name = residuals_added_text + "_" + shocks_removed_text;
    if strlength(sheet_name) > 31
        sheet_name = extractBefore(sheet_name, 31); % Excel tabs support max length of 31
    end
    writetable(sheet_data, "all_data_decompositions.xlsx", "Sheet",...
    sheet_name, 'WriteVariableNames', true)
end
