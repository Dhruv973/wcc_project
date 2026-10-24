%% Part D: Performance Analysis
% Adaptive QAM Transceiver with Receiver-Reported Channel Quality
% Author: Dhruv
% This script is separate from partB_main.m

clc;
clear;
close all;

disp('Part D: Performance Analysis');
disp('-----------------------------');

% Target packet error rate
targetPER = 10;  % percent

% Threshold combinations tested (dB)
T1_values = [17 19 21];
T2_values = [23 25 27];

% Results from the threshold sweep
% Columns: T1, T2, Throughput (bit/s), PER (%)
results = [
    17 23 3630 14.90
    17 25 3521  8.66
    17 27 3360  7.03
    19 23 3549 14.00
    19 25 3509  5.70
    19 27 3339  3.97
    21 23 3365 13.33
    21 25 3303  5.00
    21 27 3124  3.52
    ];

% Select the highest-throughput combination meeting the PER target
valid = results(:,4) <= targetPER;
validResults = results(valid,:);

[bestThroughput, idx] = max(validResults(:,3));
best = validResults(idx,:);

fprintf('\nThreshold sweep results:\n');
fprintf(' T1 (dB)  T2 (dB)  Throughput (bit/s)  PER (%%)\n');

disp(results);

fprintf('\nBest tested thresholds meeting PER <= %.1f%%:\n', targetPER);
fprintf('T1 = %.1f dB, T2 = %.1f dB\n', best(1), best(2));
fprintf('Useful throughput = %.0f bit/s\n', bestThroughput);
fprintf('PER = %.2f%%\n', best(4));

% Plot throughput versus threshold combination
figure('Name','Part D Threshold Sweep');
scatter(results(:,1), results(:,2), 100, results(:,3), 'filled');
colorbar;
xlabel('T1 threshold (dB)');
ylabel('T2 threshold (dB)');
title('Useful Throughput for Threshold Combinations');
grid on;

% Save figure in the current folder
savefig('D_threshold_sweep.fig');
saveas(gcf, 'D_threshold_sweep.png');


%% Fixed versus adaptive modulation comparison
% Columns: Mode, Useful throughput (bit/s), PER (%)
modeResults = {
    'Adaptive', 3378, 4.25;
    'QPSK',     1835, 5.65;
    '16-QAM',   3136, 17.17;
    '64-QAM',   2584, 53.27
    };

fprintf('\nFixed versus Adaptive Modulation:\n');
fprintf('%-12s %18s %10s\n', ...
    'Mode', 'Throughput (bit/s)', 'PER (%)');

for k = 1:size(modeResults,1)
    fprintf('%-12s %18.0f %10.2f\n', ...
        modeResults{k,1}, modeResults{k,2}, modeResults{k,3});
end

% Plot throughput comparison
figure('Name','Part D Fixed vs Adaptive');
throughputValues = cell2mat(modeResults(:,2));

bar(throughputValues);
set(gca, 'XTick', 1:4, ...
    'XTickLabel', modeResults(:,1));
ylabel('Useful throughput (bit/s)');
title('Fixed versus Adaptive QAM');
grid on;

savefig('D_fixed_vs_adaptive.fig');
saveas(gcf, 'D_fixed_vs_adaptive.png');


%% Feedback delay and SNR estimation noise comparison
% Results recorded from the earlier Part B simulation.
% Columns: Throughput (bit/s), PER (%)

feedbackNames = {
    'Ideal';
    'Delayed 1 s';
    'Noisy 2 dB';
    'Delayed + noisy'
    };

feedbackResults = [
    3521  8.66
    2942 22.78
    3530  9.02
    2926 24.55
    ];

fprintf('\nFeedback condition comparison:\n');
fprintf('%-18s %18s %10s\n', ...
    'Feedback', 'Throughput (bit/s)', 'PER (%)');

for k = 1:numel(feedbackNames)
    fprintf('%-18s %18.0f %10.2f\n', ...
        feedbackNames{k}, feedbackResults(k,1), ...
        feedbackResults(k,2));
end

figure('Name','Part D Feedback Comparison');

subplot(1,2,1);
bar(feedbackResults(:,1));
set(gca,'XTick',1:4,'XTickLabel',feedbackNames);
ylabel('Useful throughput (bit/s)');
title('Throughput vs Feedback');
grid on;

subplot(1,2,2);
bar(feedbackResults(:,2));
hold on;
yline(targetPER,'r--','10% PER target');
hold off;
set(gca,'XTick',1:4,'XTickLabel',feedbackNames);
ylabel('Packet error rate (%)');
title('PER vs Feedback');
grid on;

savefig('D_feedback_comparison.fig');
saveas(gcf,'D_feedback_comparison.png');
