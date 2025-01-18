clear all; close all;

A = readtable("./Speed_StereoVO_OBDII_Reference_Toronto_T19_1.csv"); % Trajectory T19.1
C = readtable("./Speed_StereoVO_OBDII_Reference_Kingston_K19_1.csv"); % Trajectory K19.1
D = readtable("./Speed_StereoVO_OBDII_Reference_Toronto_T19_2.csv"); % Trajectory T19.1

OBDII = readtable('./OBDII_Toronto_13_10_19_Trj1_15Hz_ZED.csv');
OBDII_second = OBDII.gps_sec;

time = [0; diff(OBDII.gps_sec)];
time = cumsum(time);

std_OBD_PWSS = []; var_OBD_PWSS = []; mean_OBD_PWSS = [];
std2_OBD_PWSS = []; var2_OBD_PWSS = []; mean2_OBD_PWSS = [];
std3_OBD_PWSS = []; var3_OBD_PWSS = []; mean3_OBD_PWSS = [];

delta = 2;
offset = 4;

for k = 0:delta:56 % Speed spectrum to analyze
    start_speed = offset + k;
    end_speed = offset + delta + k;
    idx = A.RefSpeed_reindexed >= start_speed & A.RefSpeed_reindexed <= end_speed;

    if sum(idx) == 0
        fprintf('No speed measurements were acquired in that range!\n');
        fprintf('Stopping @ %.2f kmph \n', k - delta);
        break;
    end
    
    fprintf('Interval: %d - %d \n', start_speed, end_speed);
    str_ = sprintf('%d-%d', start_speed, end_speed);
    
    if k == 0
        string_intervals = {str_};
    else
        string_intervals(end+1) = {str_};
    end

    mean_OBD_PWSS = [mean_OBD_PWSS, mean(A.OBDSpeed_err_reindexed(idx))];
    std_OBD_PWSS = [std_OBD_PWSS, std(A.OBDSpeed_err_reindexed(idx))];
    var_OBD_PWSS = [var_OBD_PWSS, var(A.OBDSpeed_err_reindexed(idx))];

    idx2 = C.ref_vf_sorted >= start_speed & C.ref_vf_sorted <= end_speed;
    mean2_OBD_PWSS = [mean2_OBD_PWSS, mean(C.obd_speed_sorted(idx2))];
    std2_OBD_PWSS = [std2_OBD_PWSS, std(C.obd_speed_sorted(idx2))];
    var2_OBD_PWSS = [var2_OBD_PWSS, var(C.obd_speed_sorted(idx2))];

    idx3 = D.ref_vf_sorted >= start_speed & D.ref_vf_sorted <= end_speed;
    mean3_OBD_PWSS = [mean3_OBD_PWSS, mean(D.obd_speed_sorted(idx3))]; 
    std3_OBD_PWSS = [std3_OBD_PWSS, std(D.obd_speed_sorted(idx3))];
    var3_OBD_PWSS = [var3_OBD_PWSS, var(D.obd_speed_sorted(idx3))];
end

figure;
plot(1:length(mean_OBD_PWSS)-1, var_OBD_PWSS(2:end), 'gs');
hold on;
plot(1:length(mean3_OBD_PWSS)-1, var3_OBD_PWSS(2:end), 'bs');
plot(1:length(mean2_OBD_PWSS)-1, var2_OBD_PWSS(2:end), 'rs');

mean_var_3_trajs = (var_OBD_PWSS(2:end) + var3_OBD_PWSS(2:end) + var2_OBD_PWSS(2:end)) ./ 3;
plot(1:length(mean2_OBD_PWSS)-1, mean_var_3_trajs, 'ks');

ylabel('\sigma^2_{PWSS} (km/h)^2');
xlabel('Speed intervals (km/h)');
set(gca, 'XTickMode', 'manual', 'XTick', 1:length(mean_OBD_PWSS)-1, ...
         'XTickLabelMode', 'manual', 'XTickLabel', string_intervals);

grid on;

x = 1:length(mean2_OBD_PWSS)-1;
y = mean_var_3_trajs;
f = fit(x', y', 'exp2');

prediction_interval = predint(f, x, 0.95, 'observation', 'on');
plot(x, f(x), 'r--', 'LineWidth', 2);
plot(x, prediction_interval, 'm--', 'LineWidth', 2);

h = legend('Trajectory T19.1', 'Trajectory T19.2', 'Trajectory K19.1', '$\bar{\sigma}_{\mathrm{ PWSS}}^2$ : Mean of variances', '$f(v_{\mathrm{ PWSS}})$ : Fitted curve');
set(h, 'Interpreter', 'latex', 'fontsize', 10);
asd = gcf;
set(gca, 'FontName', 'Times', 'FontSize', 10);
set(asd, 'DefaultTextInterpreter', 'latex');
set(asd, 'DefaultAxesTickLabelInterpreter', 'latex');
set(gca, 'TickLabelInterpreter', 'latex');
