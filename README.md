
# WCC Project — Q8 Adaptive QAM Transceiver with Receiver-Reported Channel Quality

**Group 08**  
ICT 3128 Wireless Communication and Computing · FISAC-1

## Project Overview

This project implements a closed-loop wireless communication link that switches among QPSK, 16-QAM, and 64-QAM according to receiver-estimated channel quality while maintaining a target error rate.

The project covers transmitter design, channel and propagation modelling, receiver implementation, and performance analysis.

## Project Structure

| Part | Description | Folder |
| --- | --- | --- |
| A | Transmitter design and implementation | [`src/`](src) |
| B | Channel / propagation model | [`partB/`](partB) |
| C | Receiver design and implementation | [`partC/`](partC) |
| D | Analysis, validation and engineering decision | [`partD/`](partD) |

## Part A — Transmitter Design and Implementation

Part A implements the transmitter-side components for an adaptive modulation system.

### Implemented Features
- QPSK, 16-QAM, and 64-QAM symbol mapping
- Framed data with modulation-mode signalling
- Root-raised-cosine (RRC) pulse shaping
- Common-rate transmit waveform for all modulation modes
- Constellation and spectrum plots
- Configurable SNR switching thresholds and hysteresis

### Files
- `step5_common_transmitter.m` — Main transmitter, frame generation, pulse shaping, and plots.
- `gray_qam_map.m` — Gray-coded QPSK, 16-QAM, and 64-QAM mapper.
- `step7_snr_switching.m` — Demonstration of configurable SNR thresholds and hysteresis.

### How to Run
1. Open MATLAB.
2. Add the `src` folder to the MATLAB path.
3. Run `step5_common_transmitter.m`.
4. Run `step7_snr_switching.m` to demonstrate the SNR switching logic.

## Part B — Channel / Propagation Model

Part B passes the Part A waveform through an AWGN and slow-varying Rayleigh flat-fading channel whose SNR changes over time.

It evaluates channel behaviour and compares ideal feedback with delayed and noisy SNR feedback.

Details and results: [`partB/README.md`](partB/README.md).

## Part C — Receiver Design and Implementation

Part C addresses receiver-side operations, including:
- Estimating channel quality and selecting the expected modulation mode
- Demodulating the received signal
- Checking CRC
- Returning simulated channel-quality information to the transmitter
- Recording instantaneous modulation mode, BER/PER, and useful throughput

See the [`partC/`](partC) directory for the implementation.

## Part D — Analysis, Validation and Engineering Decision

Part D evaluates fixed and adaptive modulation performance under the same average SNR profile and investigates threshold selection, feedback effects, and mode-switching behaviour.

### Analysis Performed

**1. Threshold sweep**
- Evaluates nine combinations of switching thresholds.
- Compares useful throughput and packet error rate (PER).
- Selects the best tested threshold combination meeting the specified PER target.

**2. Feedback comparison**
- Ideal feedback
- Feedback delayed by 1 second
- Noisy feedback with 2 dB estimation error
- Delayed and noisy feedback combined

Throughput and PER are compared across these feedback conditions.

**3. Mode-switching rate analysis**

Compares the number of modulation-mode switches per minute under different feedback conditions to investigate modulation switching behaviour.

**4. Fixed versus adaptive modulation**

Compares QPSK, 16-QAM, and 64-QAM operating in fixed modes with adaptive QAM.

### Current Simulation Result

For the current simulation run, the selected thresholds are:

- **T1 = 17 dB**
- **T2 = 25 dB**
- **Useful throughput = approximately 3521 bit/s**
- **PER = approximately 8.66%**
- **Target PER = 10%**

These thresholds provide the highest throughput among the nine tested combinations that meet the 10% PER target. The result is specific to the tested threshold values and simulation settings.

### Part D Files

- [`partD_performance_analysis.m`](partD/partD_performance_analysis.m) — Main analysis script.
- [`partD_simulation_engine.m`](partD/partD_simulation_engine.m) — Simulation engine and performance calculations.
- [`partD/figures/`](partD/figures) — Generated plots in PNG format and editable MATLAB FIG format.
- [`partD/results/`](partD/results) — Saved simulation results.

### How to Run Part D

1. Open the project in MATLAB.
2. Ensure the `src` folder and Part B channel function are accessible on the MATLAB path.
3. Set the current folder to `partD/`.
4. Run:

```matlab
partD_performance_analysis
```

The script runs the performance analysis and generates the figures and saved results.

## Required Project Evidence

The project specification calls for the following evidence:

- MATLAB code
- Closed-loop link/transceiver results
- Transmitter and receiver constellation or spectrum plots
- Mode-timeline plot
- BER/PER and throughput curves
- Switching-threshold justification

The corresponding evidence should be included in the relevant project folders as each part is completed.

## Technologies

- MATLAB
- QPSK, 16-QAM, and 64-QAM
- AWGN and Rayleigh flat-fading channel models
- Receiver-reported channel-quality feedback
- Adaptive modulation and threshold hysteresis
- BER, PER, useful throughput, and mode-switching-rate analysis
