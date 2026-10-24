
%% Part D: Performance Analysis
% Adaptive QAM Transceiver with Receiver-Reported Channel Quality
% Uses actual simulation results from partD_simulation_engine.m

clc;
close all;

disp('Part D: Performance Analysis');
disp('-----------------------------');

%% Run the simulation engine
results = partD_simulation_engine();

%% 1. Threshold sweep
fprintf('\n===== Threshold Sweep =====\n');
fprintf(' T1 (dB)  T2 (dB)  Throughput (bit/s)  PER (%%)\n');

disp(results.thresholdResults);

fprintf('\nBest tested thresholds:\n');
fprintf('T1 = %.1f dB, T2 = %.1f dB\n', ...
    results.bestThresholds(1), results.bestThresholds(2));

fprintf('Throughput = %.0f bit/s\n', ...
    results.bestThresholds(3));

fprintf('PER = %.2f%%\n', ...
    results.bestThresholds(4));

%% 2. Feedback comparison
fprintf('\n===== Feedback Comparison =====\n');

for k = 1:numel(results.feedbackNames)
    fprintf('%-18s Throughput = %8.0f bit/s, PER = %6.2f%%\n', ...
        results.feedbackNames{k}, ...
        results.feedbackResults(k,1), ...
        results.feedbackResults(k,2));
end

%% 3. Fixed versus adaptive modulation
fprintf('\n===== Fixed versus Adaptive Modulation =====\n');

for k = 1:numel(results.modeNames)
    fprintf('%-12s Throughput = %8.0f bit/s, PER = %6.2f%%\n', ...
        results.modeNames{k}, ...
        results.modeResults(k,1), ...
        results.modeResults(k,2));
end

fprintf('\nPart D analysis completed.\n');
fprintf('Figures and simulation results are saved in the partD folder.\n');
