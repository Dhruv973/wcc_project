
# WCC Project — Q8 Adaptive QAM Transceiver (Group 08)

ICT 3128 Wireless Communication and Computing · FISAC-1

| Part | Folder | Done by |
| --- | --- | --- |
| A — Transmitter design and implementation | [`src/`](src) | Person 1 · [original repository](https://github.com/saanvi-afk/wcc_project) |
| B — Channel / propagation model | [`partB/`](partB) | Person 2 |
| C — Receiver implementation | [`partC/`](partC) | Person 3 |
| D — Analysis, validation and engineering decision | [`partD/`](partD) | Person 4 |

## Part B — Channel / Propagation Model

Part B passes the Part A waveform through AWGN and a slow Rayleigh flat-fading channel, checks the channel against theory, and compares ideal with delayed and noisy SNR feedback.

Details and results: [`partB/README.md`](partB/README.md).

## Part C — Receiver Implementation

Part C contains the receiver-related implementation and CRC functionality.

Details and results: [`partC/`](partC).

## Part D — Analysis, Validation and Engineering Decision

Part D evaluates the performance of the adaptive QAM transceiver using the channel model and feedback mechanisms.

The analysis includes:

- **Threshold sweep:** Compares throughput and packet error rate (PER) across nine switching-threshold combinations.
- **Feedback comparison:** Evaluates ideal, delayed, noisy, and delayed-plus-noisy channel-quality feedback.
- **Mode-switching rate analysis:** Compares modulation-mode switching rates under different feedback conditions.
- **Fixed versus adaptive modulation:** Compares QPSK, 16-QAM, 64-QAM, and adaptive QAM.
- **Threshold selection:** Selects the tested threshold combination that provides the highest useful throughput while meeting the specified PER target.

For the current simulation run, the selected thresholds are **T1 = 17 dB** and **T2 = 25 dB**, achieving approximately **3521 bit/s throughput** with **8.66% PER**, meeting the 10% PER target.

Details, figures, and results: [`partD/README.md`](partD/README.md).

### Part D Files

- [`partD_performance_analysis.m`](partD/partD_performance_analysis.m) — main analysis script.
- [`partD_simulation_engine.m`](partD/partD_simulation_engine.m) — simulation engine and performance calculations.
- [`partD/figures/`](partD/figures) — generated PNG plots and editable MATLAB FIG files.
- [`partD/results/`](partD/results) — saved simulation results.

## Part A — Transmitter Design and Implementation

*Part A description by Person 1, unchanged.*

### Overview

This project implements the transmitter-side components for an adaptive modulation system.

### Implemented Features

- QPSK, 16-QAM, and 64-QAM symbol mapping
- Frame creation with header and payload
- Root-raised-cosine (RRC) pulse shaping
- Common transmit sample rate across modulation modes
- Constellation and spectrum plots
- Configurable SNR switching thresholds and hysteresis

### Files

- `step5_common_transmitter.m` — Main transmitter, frame generation, pulse shaping, and plots.
- `gray_qam_map.m` — Gray-coded QPSK, 16-QAM, and 64-QAM mapper.
- `step7_snr_switching.m` — Demonstration of configurable SNR thresholds and hysteresis.

### Requirements

- MATLAB
- Communications Toolbox may be required if the scripts use toolbox-specific functions.

### How to Run Part A

1. Open MATLAB.
2. Add the `src` folder to the MATLAB path.
3. Run `step5_common_transmitter.m` to generate the transmitter waveforms and plots.
4. Run `step7_snr_switching.m` to demonstrate the SNR switching logic.

### Scope and Limitations

This is the transmitter-side Part A implementation. Receiver design, channel simulation, BER evaluation, and full closed-loop adaptation are outside the Part A scope. The SNR thresholds in Part A are illustrative and have not been calibrated against measured BER performance.

## Technologies

- MATLAB
- Digital modulation: QPSK, 16-QAM, and 64-QAM
- AWGN and Rayleigh flat-fading channel simulation
- Adaptive modulation and SNR feedback
- Performance metrics: throughput, BER, PER, and mode-switching rate
