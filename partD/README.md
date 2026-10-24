# Part D: Performance Analysis

This folder contains the performance analysis for the Adaptive QAM Transceiver project.

## Experiments
- Threshold sweep for switching thresholds T1 and T2.
- Fixed versus adaptive modulation throughput comparison.
- Comparison of ideal, delayed, noisy, and delayed-plus-noisy feedback.

## Best tested thresholds
- T1 = 17 dB
- T2 = 25 dB
- Useful throughput = 3521 bit/s
- Packet error rate (PER) = 8.66%, meeting the 10% target under ideal feedback.

With a 1-second feedback delay, PER increases to 22.78%.

The MATLAB analysis script uses recorded results from the Part B simulation. The channel simulation remains in the Part B files.
