
# Part D: Performance Analysis

## Overview
Part D evaluates the performance of the adaptive QAM transceiver using the Part B channel model. It compares switching thresholds, receiver-reported channel quality feedback, and fixed versus adaptive modulation.

## Objectives
- Compare fixed-modulation and adaptive-modulation throughput under the same average SNR profile.
- Analyze the effects of threshold placement and feedback delay on packet error rate (PER) and mode switching.
- Select switching thresholds that maximize useful throughput while meeting a specified PER target.
- Compare mode-switching rates under different feedback conditions.

## Simulation Configuration
- Modulation schemes: QPSK, 16-QAM, and 64-QAM
- Average SNR: 24 dB
- Channel: Rayleigh flat fading with AWGN
- Feedback cases: ideal, delayed by 1 second, noisy with 2 dB estimation error, and delayed plus noisy
- Simulation duration: 600 seconds per run
- Target packet error rate (PER): 10%

## Results and Figures

### 1. Threshold Sweep
**Figure:** `D_threshold_sweep.png`

Nine combinations of switching thresholds were evaluated:
- T1 = 17, 19, and 21 dB
- T2 = 23, 25, and 27 dB

The selected thresholds are **T1 = 17 dB and T2 = 25 dB**, achieving approximately 3521 bit/s throughput with a PER of 8.66%. This is the highest-throughput tested combination that meets the 10% PER target.

### 2. Feedback Comparison
**Figure:** `D_feedback_comparison.png`

The simulation compares throughput and PER under ideal, delayed, noisy, and delayed-plus-noisy feedback. Delayed feedback reduces throughput and increases PER because the transmitter may use outdated channel information when selecting a modulation mode.

### 3. Mode-Switching Rate Comparison
**Figure:** `D_mode_switching_rates.png`

The mode-switching rates from the simulation are:

| Feedback case | Switches per minute |
|---|---:|
| Ideal | 17.30 |
| Delayed 1 s | 17.20 |
| Noisy 2 dB | 32.88 |
| Delayed + noisy | 29.80 |

The noisy feedback cases show more frequent mode switching in this simulation, indicating that SNR estimation errors can lead to less stable modulation decisions.

### 4. Fixed versus Adaptive Modulation
**Figure:** `D_fixed_vs_adaptive.png`

The simulation compares useful throughput and PER for adaptive QAM, fixed QPSK, fixed 16-QAM, and fixed 64-QAM. Adaptive QAM achieves approximately 3521 bit/s throughput with a PER of 8.66%. Fixed QPSK has lower throughput, while fixed 16-QAM and 64-QAM exceed the 10% PER target in this run.

## Conclusion
The simulation demonstrates the trade-off between throughput and reliability in adaptive modulation. The selected thresholds, T1 = 17 dB and T2 = 25 dB, meet the 10% PER target and provide the highest throughput among the tested threshold combinations. Feedback delay degrades throughput and reliability, while noisy feedback increases mode-switching activity.

## Files
- `partD_performance_analysis.m` — Part D analysis driver
- `partD_simulation_engine.m` — simulation engine and performance calculations
- `D_threshold_sweep.png` — threshold sweep results
- `D_feedback_comparison.png` — feedback comparison
- `D_mode_switching_rates.png` — mode-switching rate comparison
- `D_fixed_vs_adaptive.png` — fixed versus adaptive modulation
- Corresponding `.fig` files, if available
- `partD_results.mat` — saved simulation results

## How to Run
1. Open MATLAB and set the current folder to the **Part D folder**.
2. Ensure the project `src` folder contains `gray_qam_map.m`.
3. Ensure the Part B folder contains `partB_channel.m`.
4. Run:

```matlab
partD_performance_analysis
```

The simulation generates the figures and saves the results in the Part D `results` and `figures` folders.
