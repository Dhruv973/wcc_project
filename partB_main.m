function partB_main(part)
%PARTB_MAIN  Question 8, Part B: channel / propagation model.
%  Group 08 | ICT 3128 Wireless Communication and Computing | FISAC-1
%
%  partB_main          runs both Part B tasks (about 2 minutes)
%  partB_main('B1')    task B1: Part A waveform through AWGN and slow
%                      Rayleigh flat fading, model checked against theory
%                      (figures B1-B4)
%  partB_main('B2')    task B2: closed loop with ideal, delayed and noisy
%                      SNR feedback (figures B5-B7)
%
%  Needs Part A's gray_qam_map.m (folder ../src) and partB_channel.m.
%  No toolboxes. Figures are saved in partB/figures and the command-window
%  output in partB/results/partB_output.txt.

if nargin < 1, part = 'all'; end
here = fileparts(mfilename('fullpath'));
S = setup_folders(here);
P = get_params();

clc; close all;
logFile = fullfile(S.res, 'partB_output.txt');
if exist(logFile, 'file'), delete(logFile); end
diary(logFile);
if any(strcmpi(part, {'all', 'B1'})), task_B1(P, S); end
if any(strcmpi(part, {'all', 'B2'})), task_B2(P, S); end
diary off;
fprintf('\nFigures: partB/figures   Output: partB/results/partB_output.txt\n');
end


%% ======================================================================
function task_B1(P, S)
%TASK_B1  Part B task 1: pass the Part A waveform through AWGN and a
%  slow-varying flat-fading channel whose SNR changes over time, and check
%  the model against theory.
%    B1_fading_and_snr            fading gain and the time-varying Es/N0
%    B2_fading_validation         envelope PDF, autocorrelation, level crossings
%    B3_waveform_through_channel  a Part A frame through AWGN and through fading
%    B4_ber_validation            BER of the waveform chain vs exact theory

    [~, ~, req] = thresholds(P);
    col  = [0 0.447 0.741; 0.85 0.325 0.098; 0.466 0.674 0.188; 0.494 0.184 0.556];
    grey = [0.6 0.6 0.6];
    gbar = 10^(P.EsN0avg/10);

    %% 1. Channel parameters
    Tc = 0.423/P.fD;                       % coherence time (rule of thumb)
    fprintf('==== Part B1: channel model ====\n');
    fprintf('Rs = %d sym/s, Fs = %d samples/s, roll-off = %.2f\n', P.Rs, P.Fs, P.beta);
    fprintf('Occupied bandwidth B = Rs(1+beta) = %.0f Hz\n', P.B);
    fprintf('Max Doppler fD = %.2f Hz  ->  fD*Ts = %.1e (slow fading)\n', P.fD, P.fD/P.Rs);
    fprintf('Coherence time Tc = 0.423/fD = %.2f s\n', Tc);
    for m = 1:3
        fprintf('  %-7s frame: %3d symbols = %.3f s = %.3f Tc\n', ...
            P.names{m}, P.Nsym(m), P.Tframe(m), P.Tframe(m)/Tc);
    end
    fprintf('Flat fading holds if delay spread << 1/B = %.2f ms\n', 1e3/P.B);
    fprintf('Average Es/N0 = %d dB -> N0 = %.5f per complex sample (Es = 1)\n', ...
        P.EsN0avg, 1/gbar);
    fprintf('Es/N0 needed for PER <= %.0f%% (1200-bit payload, AWGN):\n', 100*P.PERtarget);
    fprintf('  QPSK %.2f dB, 16-QAM %.2f dB, 64-QAM %.2f dB\n', req);
    pOut = 1 - exp(-10^((req(1) - P.EsN0avg)/10));
    fprintf('P(Es/N0 < QPSK requirement) = 1 - exp(-%.2f/%.1f) = %.2f %%\n', ...
        10^(req(1)/10), gbar, 100*pOut);

    %% 2. Fig B1 - fading realisation and the time-varying SNR
    rng(21);
    F  = partB_channel('init', P.fD, P.Nsin);          % the Part B channel
    F4 = F;  F4.fD = 4*P.fD;  F4.wI = 4*F.wI;  F4.wQ = 4*F.wQ;   % 4x faster copy
    t  = (0:0.02:120).';
    h  = partB_channel('gain', F, t);
    h4 = partB_channel('gain', F4, t);
    snr_t = P.EsN0avg + 20*log10(abs(h));

    fh = figure('Name', 'B1 fading and SNR', 'Color', 'w', 'Position', [40 40 1000 680]);
    set(fh, 'DefaultAxesFontSize', 11);
    subplot(2, 1, 1);
    plot(t, 20*log10(abs(h4)), 'Color', grey, 'LineWidth', 0.8); hold on;
    plot(t, 20*log10(abs(h)), 'Color', col(1,:), 'LineWidth', 1.6);
    grid on; ylim([-35 10]); xlim([t(1) t(end)]);
    xlabel('Time (s)'); ylabel('Fading gain |h(t)|^2 (dB)');
    legend({sprintf('f_D = %.1f Hz (4x faster, for comparison)', 4*P.fD), ...
            sprintf('f_D = %.1f Hz (Part B channel)', P.fD)}, 'Location', 'southwest');
    title(sprintf('(a) Rayleigh flat fading, Jakes spectrum: T_c = 0.423/f_D = %.1f s >> frame (0.22-0.62 s)', Tc));

    subplot(2, 1, 2);
    plot(t, snr_t, 'Color', col(1,:), 'LineWidth', 1.6); hold on;
    plot([t(1) t(end)], [P.EsN0avg P.EsN0avg], 'k:', 'LineWidth', 1);
    for m = 1:3
        plot([t(1) t(end)], [req(m) req(m)], '--', 'Color', col(m+1,:), 'LineWidth', 1.4);
        text(t(end) - 1, req(m) + 2.2, sprintf(' %s needs %.1f dB ', P.names{m}, req(m)), ...
            'HorizontalAlignment', 'right', 'Color', col(m+1,:), 'FontWeight', 'bold', ...
            'BackgroundColor', 'w', 'Margin', 1);
    end
    text(1, P.EsN0avg + 2.2, sprintf(' average %d dB ', P.EsN0avg), 'BackgroundColor', 'w', 'Margin', 1);
    grid on; ylim([-5 35]); xlim([t(1) t(end)]);
    xlabel('Time (s)'); ylabel('Instantaneous E_s/N_0 (dB)');
    title(sprintf('(b) E_s/N_0(t) = %d dB + 20 log_{10}|h(t)|  (dashed: requirement of each mode for PER = 10%%)', P.EsN0avg));
    save_figure(fh, S, 'B1_fading_and_snr');

    %% 3. Fig B2 - validation of the fading generator
    % Statistics over 10 independent realisations of 2000 s each (20 000 s,
    % about 2000 Doppler periods), sampled every 0.04 s.
    nReal = 10;  Treal = 2000;  dt = 0.04;
    tl   = (0:dt:Treal).';
    w    = 0.05;  ctr = (w/2:w:3).';
    lags = (0:round(20/dt)).';
    lev  = (-30:2:6).';  rho = 10.^(lev/20);       % level relative to rms (= 1)
    cnt  = zeros(numel(ctr), 1);  acf = zeros(numel(lags), 1);
    ncr  = zeros(size(rho));  nbelow = zeros(size(rho));
    pw = 0;  below = 0;  nTot = 0;
    rng(22);
    for q = 1:nReal
        Fq = partB_channel('init', P.fD, P.Nsin);
        hq = partB_channel('gain', Fq, tl);
        a  = abs(hq);
        bin = floor(a/w) + 1;  bin = bin(bin <= numel(ctr));
        cnt = cnt + accumarray(bin, 1, [numel(ctr) 1]);
        Nf  = 2^nextpow2(2*numel(hq));
        rr  = ifft(abs(fft(hq, Nf)).^2);
        acf = acf + real(rr(1:numel(lags)))./(numel(hq) - lags)/nReal;
        for i = 1:numel(rho)
            ncr(i)    = ncr(i) + sum(a(1:end-1) < rho(i) & a(2:end) >= rho(i));
            nbelow(i) = nbelow(i) + sum(a < rho(i));
        end
        pw    = pw + sum(a.^2);
        below = below + sum(P.EsN0avg + 20*log10(a) < req(1));
        nTot  = nTot + numel(a);
    end
    Ttot   = nReal*Treal;
    pdfSim = cnt/(nTot*w);            pdfTh = 2*ctr.*exp(-ctr.^2);
    acfTh  = besselj(0, 2*pi*P.fD*lags*dt);
    lcr    = ncr/Ttot;                lcrTh = sqrt(2*pi)*P.fD*rho.*exp(-rho.^2);
    afd    = (nbelow/nTot)./max(lcr, eps);
    afdTh  = (exp(rho.^2) - 1)./(rho*P.fD*sqrt(2*pi));
    fprintf('\nFading generator check (%d realisations x %d s):\n', nReal, Treal);
    fprintf('  mean power E|h|^2 = %.3f (theory 1.000)\n', pw/nTot);
    i10 = find(lev == -10);  i0 = find(lev == 0);
    fprintf('  LCR at -10 dB: %.4f /s (theory %.4f); AFD: %.2f s (theory %.2f)\n', ...
        lcr(i10), lcrTh(i10), afd(i10), afdTh(i10));
    fprintf('  LCR at   0 dB: %.4f /s (theory %.4f) -> one fade every %.1f s\n', ...
        lcr(i0), lcrTh(i0), 1/lcrTh(i0));
    fprintf('  time below QPSK requirement: %.2f %% (theory %.2f %%)\n', 100*below/nTot, 100*pOut);

    fh = figure('Name', 'B2 fading validation', 'Color', 'w', 'Position', [40 40 1150 420]);
    set(fh, 'DefaultAxesFontSize', 11);
    subplot(1, 3, 1);
    bar(ctr, pdfSim, 1, 'FaceColor', [0.72 0.82 0.95], 'EdgeColor', [0.5 0.6 0.8]); hold on;
    plot(ctr, pdfTh, 'Color', col(2,:), 'LineWidth', 2);
    grid on; xlim([0 3]);
    xlabel('Envelope r = |h|'); ylabel('Probability density');
    legend({'simulated', 'Rayleigh 2r e^{-r^2}'}, 'Location', 'northeast');
    title('(a) Envelope PDF');

    subplot(1, 3, 2);
    plot(lags*dt, acf, 'Color', col(1,:), 'LineWidth', 2); hold on;
    plot(lags*dt, acfTh, '--', 'Color', col(2,:), 'LineWidth', 1.6);
    grid on; xlim([0 20]); ylim([-0.5 1.05]);
    xlabel('Time lag \tau (s)'); ylabel('Re\{R_h(\tau)\}');
    legend({'simulated', 'J_0(2\pi f_D \tau)'}, 'Location', 'northeast');
    title(sprintf('(b) Autocorrelation, f_D = %.1f Hz', P.fD));

    subplot(1, 3, 3);
    semilogy(lev, lcr, 'o', 'Color', col(1,:), 'LineWidth', 1.4, 'MarkerSize', 6); hold on;
    semilogy(lev, lcrTh, '-', 'Color', col(2,:), 'LineWidth', 1.6);
    grid on; xlim([-31 7]);
    xlabel('Threshold \rho relative to rms (dB)'); ylabel('Crossings per second');
    legend({'simulated', '\surd(2\pi) f_D \rho e^{-\rho^2}'}, 'Location', 'southeast');
    title('(c) Level-crossing rate');
    save_figure(fh, S, 'B2_fading_validation');

    %% 4. Fig B3 - one Part A frame through AWGN and through fading
    g = rrc_pulse(P.beta, P.span, P.sps);
    dB = 20*log10(abs(h));
    tf = t(find(t > 10 & dB <= -6, 1, 'first'));  % frame starts in a -6 dB fade
    rng(5);
    [s, ~, sym] = make_frame(2, P, g);      % 16-QAM frame (Part A format)
    [rA, cA] = partB_channel(s, 0,  P, [], P.EsN0avg);   % AWGN only
    [rF, cF] = partB_channel(s, tf, P, F,  P.EsN0avg);   % fading + AWGN
    yA = conv(rA, g, 'same');  yA = yA(1:P.sps:end);
    yF = conv(rF, g, 'same');  yF = yF(1:P.sps:end);
    cS = cF(1:P.sps:end);
    zF = yF./cS;
    pay = P.Nhdr+1:numel(sym);
    evm = @(z) 100*sqrt(mean(abs(z(pay) - sym(pay)).^2)/mean(abs(sym(pay)).^2));
    snrInst = 10*log10(gbar*mean(abs(cS).^2));
    fprintf('\nFig B3: 16-QAM frame starting at t = %.2f s\n', tf);
    fprintf('  mean |h|^2 over frame = %.2f dB, phase drift = %.1f deg\n', ...
        10*log10(mean(abs(cS).^2)), (angle(cS(end)/cS(1)))*180/pi);
    fprintf('  EVM AWGN only = %.1f %% (expected %.1f %%)\n', evm(yA), 100/sqrt(gbar));
    fprintf('  EVM after equaliser in fade = %.1f %% (expected %.1f %% at %.1f dB)\n', ...
        evm(zF), 100/sqrt(10^(snrInst/10)), snrInst);

    fh = figure('Name', 'B3 waveform through channel', 'Color', 'w', 'Position', [40 40 1100 760]);
    set(fh, 'DefaultAxesFontSize', 11);
    subplot(2, 3, [1 2 3]);
    n0 = 40*P.sps;  idx = n0 + (1:30*P.sps);  tt = (idx - 1)/P.Fs*1e3;
    plot(tt, abs(s(idx)), 'Color', col(1,:), 'LineWidth', 1.8); hold on;
    plot(tt, abs(cF(idx).*s(idx)), '--', 'Color', col(2,:), 'LineWidth', 1.8);
    plot(tt, abs(rF(idx)), 'Color', [0.3 0.3 0.3], 'LineWidth', 0.8);
    plot(tt, abs(cF(idx)), ':', 'Color', col(3,:), 'LineWidth', 2.2);
    grid on; xlim([tt(1) tt(end)]); ylim([0 0.95]);
    xlabel('Time within the frame (ms)'); ylabel('Envelope');
    legend({'transmitted |s(t)|', 'after fading |c(t)s(t)|', 'received |r(t)|', ...
            'fading gain |c(t)|'}, 'Location', 'north', 'Orientation', 'horizontal');
    title(sprintf('(a) Part A 16-QAM frame at t = %.1f s: fade |h|^2 = %.1f dB scales the signal, AWGN adds noise', ...
        tf, 10*log10(mean(abs(cS).^2))));

    Cst = constellations(P);
    ref = Cst{2}.points;
    lims = [-1.5 1.5];
    subplot(2, 3, 4);
    plot(real(yA(pay)), imag(yA(pay)), '.', 'Color', col(1,:), 'MarkerSize', 7); hold on;
    plot(real(ref), imag(ref), 'k+', 'MarkerSize', 9, 'LineWidth', 1.5);
    axis equal; grid on; xlim(lims); ylim(lims);
    xlabel('In-phase'); ylabel('Quadrature');
    title({sprintf('(b) AWGN only, %d dB', P.EsN0avg), sprintf('EVM %.1f%%', evm(yA))});
    subplot(2, 3, 5);
    plot(real(yF(pay)), imag(yF(pay)), '.', 'Color', col(2,:), 'MarkerSize', 7); hold on;
    plot(real(ref), imag(ref), 'k+', 'MarkerSize', 9, 'LineWidth', 1.5);
    axis equal; grid on; xlim(lims); ylim(lims);
    xlabel('In-phase'); ylabel('Quadrature');
    title({'(c) Fading + AWGN, before equaliser', sprintf('scaled by %.2f, rotated %.0f deg', mean(abs(cS)), angle(mean(cS))*180/pi)});
    subplot(2, 3, 6);
    plot(real(zF(pay)), imag(zF(pay)), '.', 'Color', col(3,:), 'MarkerSize', 7); hold on;
    plot(real(ref), imag(ref), 'k+', 'MarkerSize', 9, 'LineWidth', 1.5);
    axis equal; grid on; xlim(lims); ylim(lims);
    xlabel('In-phase'); ylabel('Quadrature');
    title({'(d) After dividing by c(t)', sprintf('EVM %.1f%%', evm(zF))});
    save_figure(fh, S, 'B3_waveform_through_channel');

    %% 5. Fig B4 - BER of the complete waveform chain vs exact theory
    fprintf('\nBER of the waveform chain (Part A Tx -> channel -> matched filter)\n');
    NsymBlk = 20000;
    rangeA  = {0:2:12, 0:2:18, 0:2:24};          % AWGN Es/N0 points (dB)
    rangeR  = 0:3:30;                            % Rayleigh average Es/N0 (dB)
    berA = cell(1, 3);  berR = zeros(3, numel(rangeR));
    rng(7);
    for m = 1:3
        berA{m} = zeros(size(rangeA{m}));
        for i = 1:numel(rangeA{m})
            e = 0;  nb = 0;
            while e < 300 && nb < 1.2e6
                [de, db] = ber_block(m, rangeA{m}(i), P, [], NsymBlk, 0);
                e = e + de;  nb = nb + db;
            end
            berA{m}(i) = e/nb;
        end
    end
    % Rayleigh: each 20 s block uses a new channel realisation with fD = 2 Hz,
    % so every point averages over 30 realisations / 1200 Doppler periods.
    % (With perfect channel knowledge the average BER of slow flat fading does
    % not depend on fD; a faster Doppler only shortens the simulation.)
    nBlkR = 30;
    for m = 1:3
        for i = 1:numel(rangeR)
            e = 0;  nb = 0;
            for bk = 1:nBlkR
                Ff = partB_channel('init', 2, P.Nsin);
                [de, db] = ber_block(m, rangeR(i), P, Ff, NsymBlk, 0);
                e = e + de;  nb = nb + db;
            end
            berR(m, i) = e/nb;
        end
    end

    fprintf('  %-7s | AWGN: Es/N0  sim BER    theory     | Rayleigh: avg Es/N0  sim BER    theory\n', 'mode');
    chkA = [10 16 22];  chkR = [15 24 30];
    for m = 1:3
        ia = find(rangeA{m} == chkA(m));  ir = find(rangeR == chkR(m));
        fprintf('  %-7s |       %2d dB  %.3e  %.3e  |           %2d dB    %.3e  %.3e\n', ...
            P.names{m}, chkA(m), berA{m}(ia), ber_theory(P.M(m), chkA(m), 'awgn'), ...
            chkR(m), berR(m, ir), ber_theory(P.M(m), chkR(m), 'rayleigh'));
    end
    for m = 1:3
        rA = berA{m}./ber_theory(P.M(m), rangeA{m}, 'awgn');
        rR = berR(m,:)./ber_theory(P.M(m), rangeR, 'rayleigh');
        fprintf('  %-7s sim/theory  AWGN: %s\n          Rayleigh: %s\n', P.names{m}, ...
            sprintf('%.2f ', rA), sprintf('%.2f ', rR));
    end
    fprintf('  Hand check: QPSK, 10 dB AWGN -> Q(sqrt(10)) = %.3e\n', 0.5*erfc(sqrt(10)/sqrt(2)));
    fprintf('              QPSK, 24 dB Rayleigh -> 0.5(1 - sqrt(g/(2+g))) = %.3e\n', ...
        0.5*(1 - sqrt(gbar/(2 + gbar))));

    fh = figure('Name', 'B4 BER validation', 'Color', 'w', 'Position', [40 40 1100 470]);
    set(fh, 'DefaultAxesFontSize', 11);
    mk = {'o', 's', '^'};
    subplot(1, 2, 1);
    hLeg = zeros(1, 6);
    for m = 1:3
        gg = 0:0.25:max(rangeA{m}) + 2;
        hLeg(2*m-1) = semilogy(gg, ber_theory(P.M(m), gg, 'awgn'), '-', 'Color', col(m,:), 'LineWidth', 1.5); hold on;
        hLeg(2*m)   = semilogy(rangeA{m}, max(berA{m}, 1e-7), mk{m}, 'Color', col(m,:), 'LineWidth', 1.5, 'MarkerSize', 7);
    end
    grid on; ylim([1e-5 0.5]); xlim([0 26]);
    xlabel('E_s/N_0 (dB)'); ylabel('Bit error rate');
    legend(hLeg, {'QPSK theory', 'QPSK simulated', '16-QAM theory', '16-QAM simulated', ...
                '64-QAM theory', '64-QAM simulated'}, 'Location', 'northeast');
    title('(a) AWGN channel');

    subplot(1, 2, 2);
    gg = 0:0.25:30;
    hLeg = zeros(1, 7);
    for m = 1:3
        hLeg(2*m-1) = semilogy(gg, ber_theory(P.M(m), gg, 'rayleigh'), '-', 'Color', col(m,:), 'LineWidth', 1.5); hold on;
        hLeg(2*m)   = semilogy(rangeR, max(berR(m,:), 1e-7), mk{m}, 'Color', col(m,:), 'LineWidth', 1.5, 'MarkerSize', 7);
    end
    hLeg(7) = semilogy(gg, ber_theory(4, gg, 'awgn'), ':', 'Color', grey, 'LineWidth', 1.5);
    grid on; ylim([1e-5 0.5]); xlim([0 30]);
    xlabel('Average E_s/N_0 (dB)'); ylabel('Average bit error rate');
    legend(hLeg, {'QPSK theory', 'QPSK simulated', '16-QAM theory', '16-QAM simulated', ...
                '64-QAM theory', '64-QAM simulated', 'QPSK in AWGN (reference)'}, 'Location', 'southwest');
    title('(b) Rayleigh flat fading (perfect CSI)');
    save_figure(fh, S, 'B4_ber_validation');

    %% 6. Save
    B1.req = req;  B1.Tc = Tc;  B1.pOut = pOut;
    B1.pdf = [ctr pdfSim pdfTh];  B1.acf = [lags*dt acf acfTh];
    B1.lcr = [lev lcr lcrTh afd afdTh];
    B1.rangeA = rangeA;  B1.berA = berA;  B1.rangeR = rangeR;  B1.berR = berR;
    save(fullfile(S.res, 'partB1_results.mat'), 'B1', 'P');
    fprintf('\nPart B1 finished. Results in partB/results/partB1_results.mat\n');
end


%% ======================================================================
function task_B2(P, S)
%TASK_B2  Part B task 2: run the closed loop over the Part B channel with
%  ideal feedback and with delayed and/or noisy SNR (CQI) feedback.
%    B5_feedback_traces    true SNR vs the SNR value the transmitter used
%    B6_mode_timeline      selected mode, best possible mode, lost frames
%    B7_feedback_summary   throughput, PER, switching rate, wrong decisions
%  Sweeping the feedback delay and the thresholds is left to Part D.

    [T1, T2, req] = thresholds(P);
    col  = [0.15 0.15 0.15; 0.85 0.325 0.098; 0 0.447 0.741; 0.494 0.184 0.556];
    grey = [0.65 0.65 0.65];
    Tsim    = 600;     % simulated time per run (s): 60 Doppler periods at 0.1 Hz
    seedCh  = 31;      % channel realisation shared by all cases
    seedRun = 100;     % payload / noise / CQI-error random numbers

    %% 1. Switching thresholds
    out = 1;                                         % print to the command window
    for o = out
        fprintf(o, '==== Part B2: closed loop with ideal / delayed / noisy feedback ====\n');
        fprintf(o, 'Channel: Rayleigh flat fading fD = %.2f Hz, average Es/N0 = %d dB, %d s per run\n', ...
            P.fD, P.EsN0avg, Tsim);
        fprintf(o, 'Es/N0 needed for PER <= %.0f%% (AWGN, 1200-bit payload): QPSK %.2f, 16-QAM %.2f, 64-QAM %.2f dB\n', ...
            100*P.PERtarget, req);
        fprintf(o, 'Part A rule: switch up at T+H, down at T-H, H = %.1f dB\n', P.H);
        fprintf(o, '  Part A illustrative thresholds: T1 = %.1f, T2 = %.1f dB (16-QAM kept down to %.1f dB)\n', ...
            P.T1_partA, P.T2_partA, P.T1_partA - P.H);
        fprintf(o, '  Calibrated for evaluation:      T1 = %.2f, T2 = %.2f dB (T = required SNR + H)\n\n', T1, T2);
    end
    sw  = struct('T1', T1, 'T2', T2, 'H', P.H, 'req', req, 'fixed', 0);
    swA = sw;  swA.T1 = P.T1_partA;  swA.T2 = P.T2_partA;

    %% 2. The four feedback cases on the same channel realisation
    mkfb = @(type, d, sg, q) struct('type', type, 'delay', d, 'sigma', sg, ...
                                    'quant', q, 'bitErr', 0);
    fbList = {mkfb('ideal', 0, 0, false), mkfb('report', 1, 0, true), ...
              mkfb('report', 0, 2, true), mkfb('report', 1, 2, true)};
    fbTxt  = {'Ideal', 'Delayed 1 s', 'Noisy 2 dB', 'Delayed + noisy'};
    fbTex  = {'Ideal feedback (true SNR, no delay)', ...
              'Delayed: CQI arrives 1 s after the frame', ...
              'Noisy: SNR estimate error \sigma = 2 dB', ...
              'Delayed 1 s + noisy \sigma = 2 dB'};
    rng(seedCh);
    F = partB_channel('init', P.fD, P.Nsin);
    R = cell(1, 4);
    fprintf('Running the four feedback cases...\n');
    for i = 1:4
        tic;
        R{i} = run_link(P, F, fbList{i}, sw, Tsim, seedRun);
        fprintf('  %-16s %4d frames  (%.0f s)\n', fbTxt{i}, R{i}.nFrames, toc);
    end
    RA = run_link(P, F, fbList{1}, swA, Tsim, seedRun);   % Part A thresholds

    % Part D: threshold sweep using ideal feedback
    T1_values = [17 19 21];
    T2_values = [23 25 27];

    sweep = zeros(9, 4);
    idxSweep = 0;

    fprintf('\n==== Part D: Threshold Sweep ====\n');
    fprintf(' T1 (dB)  T2 (dB)  Throughput (bit/s)  PER (%%)\n');

    for a = 1:numel(T1_values)
        for b = 1:numel(T2_values)
            if T2_values(b) <= T1_values(a)
                continue;
            end

            idxSweep = idxSweep + 1;
            swTest = sw;
            swTest.T1 = T1_values(a);
            swTest.T2 = T2_values(b);
            swTest.fixed = 0;

            RT = run_link(P, F, fbList{1}, swTest, Tsim, seedRun);

            sweep(idxSweep,:) = [swTest.T1, swTest.T2, ...
                RT.thr, 100*RT.PER];

            fprintf(' %7.1f  %7.1f  %18.0f  %7.2f\n', ...
                swTest.T1, swTest.T2, RT.thr, 100*RT.PER);
        end
    end

    valid = sweep(1:idxSweep,4) <= 10;

    if any(valid)
        validRows = sweep(1:idxSweep,:);
        validRows = validRows(valid,:);
        [~, bestIdx] = max(validRows(:,3));
        best = validRows(bestIdx,:);

        fprintf('\nBest tested thresholds meeting PER <= 10%%:\n');
        fprintf('T1 = %.1f dB, T2 = %.1f dB\n', best(1), best(2));
        fprintf('Throughput = %.0f bit/s, PER = %.2f%%\n', ...
            best(3), best(4));
    else
        fprintf('\nNo tested threshold pair met PER <= 10%%.\n');
    end


    % Part D: optimized thresholds under different feedback conditions
    swOpt = sw;
    swOpt.T1 = 17;
    swOpt.T2 = 25;
    swOpt.fixed = 0;

    fbTest = {
        mkfb('ideal', 0, 0, false), ...
        mkfb('report', 1, 0, true), ...
        mkfb('report', 0, 2, true), ...
        mkfb('report', 1, 2, true)
        };

    fbTestNames = {'Ideal', 'Delayed 1 s', ...
        'Noisy 2 dB', 'Delayed + noisy'};

    fprintf('\n==== Part D: Optimized Thresholds vs Feedback ====\n');
    fprintf('%-18s %14s %10s\n', ...
        'Feedback', 'Throughput', 'PER (%)');

    for q = 1:numel(fbTest)
        Ropt = run_link(P, F, fbTest{q}, swOpt, Tsim, seedRun);

        fprintf('%-18s %14.0f %10.2f\n', ...
            fbTestNames{q}, Ropt.thr, 100*Ropt.PER);
    end

    % Part D: plot threshold sweep results
    sweepData = sweep(1:idxSweep,:);

    figure('Name','Part D Threshold Sweep','Color','w');

    subplot(1,2,1);
    scatter(sweepData(:,1), sweepData(:,2), ...
        70, sweepData(:,3), 'filled');
    colorbar;
    xlabel('T1 threshold (dB)');
    ylabel('T2 threshold (dB)');
    title('Useful throughput (bit/s)');
    grid on;

    subplot(1,2,2);
    scatter(sweepData(:,1), sweepData(:,2), ...
        70, sweepData(:,4), 'filled');
    colorbar;
    hold on;
    validPoints = sweepData(:,4) <= 10;
    plot(sweepData(validPoints,1), ...
        sweepData(validPoints,2), 'ko', ...
        'MarkerSize', 11, 'LineWidth', 1.5);
    xlabel('T1 threshold (dB)');
    ylabel('T2 threshold (dB)');
    title('PER (%) - circles meet 10% target');
    grid on;

    saveas(gcf, fullfile(S.fig,'D_threshold_sweep.png'));
    saveas(gcf, fullfile(S.fig,'D_threshold_sweep.fig'));

    % Part D: compare fixed modulation with adaptive modulation
    RF = cell(1, 3);

    for m = 1:3
        swFixed = sw;
        swFixed.fixed = m;

        RF{m} = run_link(P, F, fbList{1}, ...
            swFixed, Tsim, seedRun);
    end

    fprintf('\n==== Part D: Fixed vs Adaptive ====\n');
    fprintf('%-12s %12s %10s\n', ...
        'Mode', 'Throughput', 'PER (%)');

    fprintf('%-12s %12.0f %10.2f\n', ...
        'Adaptive', R{1}.thr, 100*R{1}.PER);

    for m = 1:3
        fprintf('%-12s %12.0f %10.2f\n', ...
            P.names{m}, RF{m}.thr, 100*RF{m}.PER);
    end

    % Check of the delayed-feedback model against Jakes theory:
    % corr(|h(t)|^2, |h(t-tau)|^2) = J0(2*pi*fD*tau)^2
    L2 = R{2}.log;  v = ~isnan(L2.snrUsed);
    cc = corrcoef(10.^(L2.snrUsed(v)/10), 10.^(L2.snrStart(v)/10));
    rhoTh = mean(besselj(0, 2*pi*P.fD*L2.age(v)).^2);

    for o = out
        fprintf(o, '%-16s %9s %8s %7s %9s %7s %17s %7s %7s\n', 'Feedback', 'Thr b/s', 'vs ideal', ...
            'PER %', 'BER', 'Sw/min', 'time Q/16/64 %', 'Over %', 'Under %');
        for i = 1:4
            r = R{i};
            fprintf(o, '%-16s %9.0f %7.1f%% %7.1f %9.2e %7.1f %5.0f/%3.0f/%3.0f %10.1f %7.1f\n', ...
                fbTxt{i}, r.thr, 100*r.thr/R{1}.thr, 100*r.PER, r.BER, r.swPerMin, ...
                100*r.timeShare, 100*r.over, 100*r.under);
        end
        fprintf(o, '%-16s %9.0f %7.1f%% %7.1f %9.2e %7.1f %5.0f/%3.0f/%3.0f %10.1f %7.1f\n', ...
            'Ideal, Part A T', RA.thr, 100*RA.thr/R{1}.thr, 100*RA.PER, RA.BER, RA.swPerMin, ...
            100*RA.timeShare, 100*RA.over, 100*RA.under);
        fprintf(o, '\nDelayed CQI: mean age of the information = %.2f s\n', mean(L2.age(v)));
        fprintf(o, '  correlation(SNR used, actual SNR) = %.3f, Jakes theory J0^2 = %.3f\n\n', cc(1,2), rhoTh);
    end

    %% 3. Fig B5 - SNR used by the transmitter in each case
    L1 = R{1}.log;
    cand = find(L1.tStart > 40 & L1.tStart < Tsim - 40);
    [~, j] = min(L1.snrStart(cand));
    tc  = L1.tStart(cand(j));
    win = [tc - 30, tc + 30];                         % 60 s around the deepest fade
    tg  = (win(1):0.05:win(2)).';
    snrTrue = P.EsN0avg + 20*log10(abs(partB_channel('gain', F, tg)));

    fh = figure('Name', 'B5 feedback traces', 'Color', 'w', 'Position', [40 40 1000 900]);
    set(fh, 'DefaultAxesFontSize', 10);
    for i = 1:4
        Lg = R{i}.log;  k = Lg.tStart >= win(1) & Lg.tStart <= win(2);
        subplot(4, 1, i);
        h1 = plot(tg, snrTrue, 'Color', grey, 'LineWidth', 2.5); hold on;
        h2 = stairs(Lg.tStart(k), Lg.snrUsed(k), 'Color', col(i,:), 'LineWidth', 1.4);
        for T = [T1 T2]
            plot(win, [T - P.H, T - P.H], '--', 'Color', [0.2 0.6 0.2], 'LineWidth', 0.9);
            plot(win, [T + P.H, T + P.H], ':',  'Color', [0.8 0.2 0.2], 'LineWidth', 1.1);
        end
        grid on; xlim(win); ylim([0 34]);
        ylabel('E_s/N_0 (dB)');
        if i == 1
            legend([h1 h2], {'true SNR at the receiver', 'SNR value used by the transmitter'}, ...
                'Location', 'southwest');
        end
        if i == 4, xlabel('Time (s)'); end
        title(sprintf('%s  (switch up at dotted, down at dashed lines)', fbTex{i}));
    end
    save_figure(fh, S, 'B5_feedback_traces');

    %% 4. Fig B6 - mode timeline
    fh = figure('Name', 'B6 mode timeline', 'Color', 'w', 'Position', [40 40 1000 900]);
    set(fh, 'DefaultAxesFontSize', 10);
    for i = 1:4
        Lg = R{i}.log;  k = find(Lg.tStart >= win(1) & Lg.tStart <= win(2));
        best = 1 + (Lg.snrFrame >= req(2)) + (Lg.snrFrame >= req(3));
        te = Lg.tStart(k(end)) + Lg.Tf(k(end));
        subplot(4, 1, i);
        h1 = stairs([Lg.tStart(k); te], [best(k); best(k(end))], 'Color', grey, 'LineWidth', 4); hold on;
        h2 = stairs([Lg.tStart(k); te], [Lg.mode(k); Lg.mode(k(end))], 'Color', col(i,:), 'LineWidth', 1.6);
        bad = k(~Lg.ok(k));
        h3 = plot(Lg.tStart(bad) + Lg.Tf(bad)/2, Lg.mode(bad), 'x', 'Color', [0.85 0 0], ...
            'MarkerSize', 9, 'LineWidth', 2);
        grid on; xlim(win); ylim([0.5 3.5]);
        set(gca, 'YTick', 1:3, 'YTickLabel', P.names);
        if i == 1
            if isempty(bad), h3 = plot(NaN, NaN, 'x', 'Color', [0.85 0 0]); end
            legend([h1 h2 h3], {'best mode for the true SNR', 'mode selected', 'frame lost'}, ...
                'Location', 'southwest');
        end
        if i == 4, xlabel('Time (s)'); end
        title(sprintf('%s:  PER %.1f%%, %.1f switches/min (whole run)', fbTex{i}, ...
            100*R{i}.PER, R{i}.swPerMin));
    end
    save_figure(fh, S, 'B6_mode_timeline');

    %% 5. Fig B7 - summary of the four cases
    thr  = cellfun(@(r) r.thr, R)/1e3;
    per  = cellfun(@(r) r.PER, R)*100;
    swm  = cellfun(@(r) r.swPerMin, R);
    over = cellfun(@(r) r.over, R)*100;
    undr = cellfun(@(r) r.under, R)*100;
    lab  = {'Ideal', 'Delay', 'Noise', 'Both'};

    fh = figure('Name', 'B7 feedback summary', 'Color', 'w', 'Position', [40 40 1200 430]);
    set(fh, 'DefaultAxesFontSize', 10);
    subplot(1, 4, 1);
    draw_bars(thr(:), col, lab, '%.2f');
    ylim([0 1.15*max(thr)]);  grid on;  title('(a) Useful throughput (kbit/s)');
    subplot(1, 4, 2);
    draw_bars(per(:), col, lab, '%.1f');
    plot([0.4 4.6], 100*[P.PERtarget P.PERtarget], 'r--', 'LineWidth', 1.5);
    ylim([0 1.2*max(per)]);  grid on;  title('(b) PER (%), dashed = 10% target');
    subplot(1, 4, 3);
    draw_bars(swm(:), col, lab, '%.1f');
    ylim([0 1.2*max(swm)]);  grid on;  title('(c) Mode switches / min');
    subplot(1, 4, 4);
    draw_bars([over(:) undr(:)], [0.85 0.2 0.2; 0.55 0.7 0.9], lab, '%.0f');
    ylim([0 1.25*max(over + undr)]);  grid on;
    text(0.5, 1.2*max(over + undr), 'red: too aggressive', 'Color', [0.85 0.2 0.2], ...
        'FontWeight', 'bold', 'VerticalAlignment', 'top');
    text(0.5, 1.1*max(over + undr), 'blue: too conservative', 'Color', [0.3 0.45 0.7], ...
        'FontWeight', 'bold', 'VerticalAlignment', 'top');
    title('(d) Wrong mode (% of frames)');
    save_figure(fh, S, 'B7_feedback_summary');

    B2.R = R;  B2.RA = RA;  B2.req = req;  B2.T1 = T1;  B2.T2 = T2;
    save(fullfile(S.res, 'partB2_results.mat'), 'B2', 'P');
    fprintf('\nPart B2 finished. Results in partB/results/partB2_results.mat\n');
end


%% ======================================================================
%  Helper functions
%  ======================================================================

function S = setup_folders(here)
%SETUP_FOLDERS  Adds Part A's src folder to the path, creates output folders.
S.dir = here;
if ~exist('gray_qam_map', 'file')
    cands = {fullfile(here, '..', 'src'), fullfile(here, 'src')};
    for i = 1:numel(cands)
        if exist(fullfile(cands{i}, 'gray_qam_map.m'), 'file')
            addpath(cands{i});
            break;
        end
    end
end
if ~exist('gray_qam_map', 'file')
    error(['Part A file gray_qam_map.m not found. Keep the partB folder ' ...
           'next to the Part A "src" folder, or add src to the MATLAB path.']);
end
S.fig = fullfile(here, 'figures');
S.res = fullfile(here, 'results');
if ~exist(S.fig, 'dir'), mkdir(S.fig); end
if ~exist(S.res, 'dir'), mkdir(S.res); end
S.isOctave = exist('OCTAVE_VERSION', 'builtin') > 0;
end


function P = get_params()
%GET_PARAMS  Parameters for Question 8, Part B (channel / propagation model).
%
%   Transmitter values are copied unchanged from Part A
%   (src/step5_common_transmitter.m) so that Part B passes exactly the
%   Part A waveform through the channel. The channel and feedback values
%   are the Part B design choices explained in the report.
%
%   Group 08 - ICT 3128 Wireless Communication and Computing - FISAC-1

% ----- Part A transmitter (unchanged) ------------------------------------
P.sps    = 8;                    % samples per symbol
P.Rs     = 1000;                 % symbol rate (symbol/s)
P.Fs     = P.Rs*P.sps;           % common sample rate (sample/s)
P.beta   = 0.35;                 % RRC roll-off factor
P.span   = 10;                   % RRC span (symbols)
P.Npay   = 1200;                 % payload bits per frame
P.M      = [4 16 64];            % mode 1 = QPSK, 2 = 16-QAM, 3 = 64-QAM
P.k      = log2(P.M);            % bits per payload symbol
P.names  = {'QPSK', '16-QAM', '64-QAM'};
P.sync   = [1;1;0;1;0;0;1;1; 1;0;0;1;0;0;0;1];   % 16-bit sync word
P.Nhdr   = 17;                   % header = 34 bits = 17 QPSK symbols
P.Nsym   = P.Nhdr + P.Npay./P.k; % symbols per frame for each mode
P.Tframe = P.Nsym/P.Rs;          % frame duration (s) for each mode
P.B      = P.Rs*(1 + P.beta);    % occupied bandwidth (Hz)

% ----- Part B channel ----------------------------------------------------
P.fD      = 0.1;    % maximum Doppler shift (Hz) -> fD*Ts = 1e-4 (slow fading)
P.Nsin    = 32;     % sinusoids per quadrature in the fading generator
P.EsN0avg = 24;     % average Es/N0 of the time-varying link (dB)

% ----- Mode switching (Part A rule: up at T+H, down at T-H) -------------
P.T1_partA = 10;    % Part A illustrative QPSK/16-QAM threshold (dB)
P.T2_partA = 18;    % Part A illustrative 16-QAM/64-QAM threshold (dB)
P.H        = 1.5;   % hysteresis (dB), as in Part A
P.PERtarget = 0.10; % frame-error target used to calibrate the thresholds

% ----- CQI feedback word -------------------------------------------------
P.cqiBits = 5;      % CQI word length (bits)
P.cqiStep = 1;      % CQI resolution (dB)
P.cqiMin  = 0;      % CQI value of index 0 (dB) -> range 0..31 dB
end

function [T1, T2, req] = thresholds(P)
%THRESHOLDS  Switching thresholds calibrated for a frame-error target.
%
%   req(m) = Es/N0 (dB) at which mode m just meets P.PERtarget for a
%            P.Npay-bit payload in AWGN:  PER = 1 - (1 - BER)^Npay
%   Part A's rule switches UP at T + H and DOWN at T - H. Choosing
%   T = req + H makes the down-switch happen exactly at the SNR that still
%   meets the target, so a correctly informed transmitter never uses a
%   mode below its required SNR.

gdB = 0:0.01:40;
req = zeros(1, 3);
for m = 1:3
    ber = ber_theory(P.M(m), gdB, 'awgn');
    per = 1 - (1 - ber).^P.Npay;
    req(m) = gdB(find(per <= P.PERtarget, 1, 'first'));
end
T1 = req(2) + P.H;
T2 = req(3) + P.H;
end

function ber = ber_theory(M, EsN0dB, channel)
%BER_THEORY  Exact BER of Gray-coded QPSK / square M-QAM.
%
%   channel = 'awgn'     : Es/N0 = EsN0dB
%   channel = 'rayleigh' : average Es/N0 = EsN0dB, flat Rayleigh fading,
%                          perfect channel knowledge at the receiver
%
%   Exact AWGN expression of Cho & Yoon (IEEE Trans. Commun., 2002), a sum
%   of terms  w*erfc(b*sqrt(Es/N0)).  Averaging each term over Rayleigh
%   fading gives  w*(1 - sqrt(b^2*g/(1 + b^2*g))),  g = average Es/N0.
%   For QPSK this reduces to Q(sqrt(Es/N0)) and
%   0.5*(1 - sqrt(g/(2 + g))) respectively.

g   = 10.^(EsN0dB/10);
L   = sqrt(M);                      % levels per dimension
K   = log2(L);                      % bits per dimension
b0  = sqrt(3/(2*(M - 1)));
ber = zeros(size(g));
for k = 1:K
    for i = 0:((1 - 2^(-k))*L - 1)
        f  = floor(i*2^(k-1)/L);
        w  = (-1)^f * (2^(k-1) - floor(i*2^(k-1)/L + 1/2));
        bi = (2*i + 1)*b0;
        if strcmpi(channel, 'awgn')
            term = erfc(bi*sqrt(g));
        else
            term = 1 - sqrt(bi^2*g./(1 + bi^2*g));
        end
        ber = ber + w*term;
    end
end
ber = ber/(L*K);
end

function h = rrc_pulse(beta, span, sps)
%RRC_PULSE  Unit-energy root-raised-cosine filter taps (column vector).
%   Same design as the Part A transmitter (step5_common_transmitter.m),
%   wrapped as a function so the transmitter and the matched filter in
%   Part B use exactly the same pulse.

t = (-span*sps/2 : span*sps/2)/sps;
h = zeros(size(t));
for n = 1:length(t)
    x = t(n);
    if abs(x) < 1e-10
        h(n) = 1 + beta*(4/pi - 1);
    elseif abs(abs(x) - 1/(4*beta)) < 1e-10
        h(n) = (beta/sqrt(2))*((1 + 2/pi)*sin(pi/(4*beta)) + ...
                               (1 - 2/pi)*cos(pi/(4*beta)));
    else
        h(n) = (sin(pi*x*(1 - beta)) + 4*beta*x*cos(pi*x*(1 + beta))) / ...
               (pi*x*(1 - (4*beta*x)^2));
    end
end
h = h(:)/sqrt(sum(h.^2));
end

function [s, bits, sym] = make_frame(mode, P, g, payload)
%MAKE_FRAME  One transmit frame in the Part A format.
%
%   Frame = [16-bit sync | 2-bit mode ID | 16-bit length]  (QPSK header)
%         + 1200-bit payload mapped with Part A's gray_qam_map
%   followed by upsampling and RRC pulse shaping (Part A, 'same' alignment).
%
%   mode    : 1 = QPSK, 2 = 16-QAM, 3 = 64-QAM
%   g       : RRC taps from rrc_pulse
%   payload : optional payload bits (random if omitted)
%   s       : transmit waveform at P.Fs (column), Es = 1 per symbol
%   bits    : struct with the header and payload bits
%   sym     : transmitted symbols (header followed by payload)

M = P.M(mode);
if nargin < 4 || isempty(payload)
    payload = randi([0 1], P.Npay, 1);
end
payload = payload(:);

% Header (identical to Part A)
modeID     = mode - 1;
modeBits   = [bitget(modeID, 2); bitget(modeID, 1)];
lengthBits = zeros(16, 1);
for b = 1:16
    lengthBits(b) = bitget(P.Npay, 17 - b);
end
header = [P.sync; modeBits; lengthBits];          % 34 bits

pairs  = reshape(header, 2, []).';
hdrSym = ((1 - 2*pairs(:,1)) + 1j*(1 - 2*pairs(:,2)))/sqrt(2);

% Payload with the Part A Gray mapper
paySym = gray_qam_map(payload, M);

sym = [hdrSym; paySym(:)];
up  = zeros(numel(sym)*P.sps, 1);
up(1:P.sps:end) = sym;
s   = conv(up, g, 'same');

bits.header  = header;
bits.payload = payload;
end

function C = constellations(P)
%CONSTELLATIONS  Reference points and bit labels for each mode.
%   The points are produced by Part A's gray_qam_map, so the detector in
%   Part B always matches the Part A transmitter mapping.
%   C{m}.points : 1 x M complex points,  C{m}.bits : M x k bit labels

C = cell(1, 3);
for m = 1:3
    M = P.M(m);
    k = P.k(m);
    B = zeros(M, k);
    for v = 0:M-1
        B(v+1, :) = bitget(v, k:-1:1);        % MSB first
    end
    C{m}.bits   = B;
    C{m}.points = gray_qam_map(reshape(B.', [], 1), M).';
end
end

function [nErr, nBits] = ber_block(mode, EsN0dB, P, F, Nsym, t0)
%BER_BLOCK  Bit errors of one long payload block through the channel.
%
%   random bits -> Part A Gray mapper -> RRC pulse shaping -> partB_channel
%   (fading F, or AWGN if F = []) -> matched filter -> one-tap equaliser
%   with the true channel -> minimum-distance detection.
%   The first and last P.span symbols are not counted (filter edge).
%
%   t0 : start time (s) of the block on the fading time axis

g = rrc_pulse(P.beta, P.span, P.sps);
C = constellations(P);
k = P.k(mode);

b  = randi([0 1], Nsym*k, 1);
x  = gray_qam_map(b, P.M(mode));
up = zeros(Nsym*P.sps, 1);
up(1:P.sps:end) = x;
s  = conv(up, g, 'same');

[r, c] = partB_channel(s, t0, P, F, EsN0dB);
y = conv(r, g, 'same');
z = y(1:P.sps:end)./c(1:P.sps:end);

idx = (P.span + 1):(Nsym - P.span);
[~, d] = min(abs(bsxfun(@minus, z(idx), C{mode}.points)), [], 2);
bh = C{mode}.bits(d, :).';
bt = reshape(b, k, []);
bt = bt(:, idx);
nErr  = sum(bh(:) ~= bt(:));
nBits = numel(bt);
end

function R = run_link(P, F, fb, sw, Tsim, seed)
%RUN_LINK  Closed-loop adaptive QAM link over the Part B channel.
%
%   Part A frames are sent back to back for Tsim seconds over the slow
%   flat-fading + AWGN channel. Before every frame the transmitter selects
%   QPSK / 16-QAM / 64-QAM with Part A's threshold + hysteresis rule,
%   using whatever SNR information has reached it at that moment.
%
%   fb.type   : 'ideal'  -> transmitter knows the true SNR at frame start
%               'report' -> transmitter uses the latest CQI that has arrived
%   fb.delay  : feedback latency (s) from the end of the measured frame to
%               the arrival of its CQI at the transmitter
%   fb.sigma  : std of the receiver's SNR estimation error (dB)
%   fb.quant  : true -> 5-bit CQI with 1 dB steps
%   fb.bitErr : bit-error probability of the CQI on the feedback link
%   sw.T1, sw.T2, sw.H : thresholds and hysteresis (dB)
%   sw.req    : required SNR of each mode (dB), used to judge selections
%   sw.fixed  : 0 = adaptive; 1/2/3 = always transmit that mode
%   Tsim      : simulated time (s);  seed : random seed (payload, noise, CQI)
%
%   Output R: per-frame log (R.log) and summary metrics.

rng(seed);
g    = rrc_pulse(P.beta, P.span, P.sps);
C    = constellations(P);
gbar = 10^(P.EsN0avg/10);

maxF = ceil(Tsim/min(P.Tframe)) + 2;
L.tStart   = zeros(maxF, 1);  L.Tf     = zeros(maxF, 1);
L.mode     = zeros(maxF, 1);  L.snrUsed = nan(maxF, 1);
L.snrStart = zeros(maxF, 1);  L.snrFrame = zeros(maxF, 1);
L.errPay   = zeros(maxF, 1);  L.errHdr = zeros(maxF, 1);
L.ok       = false(maxF, 1);  L.age    = nan(maxF, 1);

repTime = inf(maxF, 1);  repVal = nan(maxF, 1);  repMid = nan(maxF, 1);
nRep = 0;  ptr = 0;

t = 0;  mode = 1;  n = 0;                  % start in QPSK (most robust)
while t < Tsim
    n = n + 1;
    snrStart = 10*log10(gbar*abs(partB_channel('gain', F, t))^2);

    % ---- SNR information available at the transmitter ----------------
    age = NaN;
    if sw.fixed > 0
        mode = sw.fixed;
        snrUsed = NaN;
    else
        if strcmpi(fb.type, 'ideal')
            snrUsed = snrStart;            % perfect, instantaneous CSI
            age = 0;
        else
            while ptr < nRep && repTime(ptr + 1) <= t
                ptr = ptr + 1;             % newest report that has arrived
            end
            if ptr > 0
                snrUsed = repVal(ptr);
                age = t - repMid(ptr);     % how old the information is (s)
            else
                snrUsed = NaN;             % nothing received yet
            end
        end
        mode = select_mode(snrUsed, mode, sw.T1, sw.T2, sw.H);
    end

    % ---- one frame through the channel ---------------------------------
    [s, bits] = make_frame(mode, P, g);
    [r, c]    = partB_channel(s, t, P, F, P.EsN0avg);
    out       = rx_measure(r, c, mode, P, g, bits, C);
    Tf        = numel(s)/P.Fs;

    % ---- receiver measures the frame SNR and returns a CQI -------------
    snrFrame = 10*log10(gbar*mean(abs(c(1:P.sps:end)).^2));
    nRep = nRep + 1;
    repTime(nRep) = t + Tf + fb.delay;
    repVal(nRep)  = cqi_report(snrFrame, fb, P);
    repMid(nRep)  = t + Tf/2;

    % ---- log -----------------------------------------------------------
    L.tStart(n) = t;        L.Tf(n) = Tf;          L.mode(n) = mode;
    L.snrUsed(n) = snrUsed; L.snrStart(n) = snrStart;
    L.snrFrame(n) = snrFrame;
    L.errPay(n) = out.errPay; L.errHdr(n) = out.errHdr; L.ok(n) = out.ok;
    L.age(n) = age;
    t = t + Tf;
end

fn = fieldnames(L);
for i = 1:numel(fn)
    L.(fn{i}) = L.(fn{i})(1:n);
end

% ---- summary metrics ---------------------------------------------------
Ttot = L.tStart(end) + L.Tf(end);
R.log       = L;
R.nFrames   = n;
R.Ttot      = Ttot;
R.thr       = sum(L.ok)*P.Npay/Ttot;           % useful throughput (bit/s)
R.thrNorm   = R.thr/P.Rs;                       % bit per symbol period
R.PER       = 1 - mean(L.ok);
R.BER       = sum(L.errPay)/(n*P.Npay);
R.switches  = sum(diff(L.mode) ~= 0);
R.swPerMin  = R.switches/(Ttot/60);
R.timeShare = zeros(1, 3);
for m = 1:3
    R.timeShare(m) = sum(L.Tf(L.mode == m))/Ttot;
end
% Mode the true frame SNR could support (highest mode meeting the target)
best    = 1 + (L.snrFrame >= sw.req(2)) + (L.snrFrame >= sw.req(3));
R.over  = mean(L.mode > best);                  % too aggressive
R.under = mean(L.mode < best);                  % too conservative
R.fb    = fb;
R.sw    = sw;
end

function mode = select_mode(snr, mode, T1, T2, H)
%SELECT_MODE  Part A threshold + hysteresis rule as a function.
%   Same logic as src/step7_snr_switching.m:
%     switch up   when snr >= T + H
%     switch down when snr <  T - H
%   snr  : SNR value available at the transmitter (dB); NaN = no report
%   mode : current mode (1 QPSK, 2 16-QAM, 3 64-QAM); returns the new mode

if isnan(snr)
    return;                               % no CQI yet: keep current mode
end
if mode == 1
    if snr >= T2 + H
        mode = 3;
    elseif snr >= T1 + H
        mode = 2;
    end
elseif mode == 2
    if snr >= T2 + H
        mode = 3;
    elseif snr < T1 - H
        mode = 1;
    end
else
    if snr < T1 - H
        mode = 1;
    elseif snr < T2 - H
        mode = 2;
    end
end
end

function cqi = cqi_report(snrdB, fb, P)
%CQI_REPORT  SNR value that the receiver feeds back to the transmitter.
%
%   1) estimation error : snr_hat = snr + e,  e ~ N(0, fb.sigma^2)  (dB)
%   2) quantisation     : 5-bit CQI, 1 dB steps, 0..31 dB  (if fb.quant)
%   3) feedback link    : each CQI bit flips with probability fb.bitErr
%   The feedback delay is applied by run_link (report arrival time).

x = snrdB + fb.sigma*randn(size(snrdB));
if ~fb.quant
    cqi = x;
    return;
end
nLev = 2^P.cqiBits;
q = round((x - P.cqiMin)/P.cqiStep);
q = min(max(q, 0), nLev - 1);
if fb.bitErr > 0
    for b = 1:P.cqiBits
        flip = rand(size(q)) < fb.bitErr;
        q(flip) = bitxor(q(flip), 2^(b - 1));
    end
end
cqi = P.cqiMin + q*P.cqiStep;
end

function out = rx_measure(r, c, mode, P, g, txBits, C)
%RX_MEASURE  Genie-aided measurement receiver used to test the channel.
%
%   Matched filter (Part A RRC) -> symbol sampling -> one-tap equaliser
%   using the TRUE channel gain -> minimum-distance decisions.
%
%   The receiver is given perfect channel knowledge and the true mode, so
%   every error it counts is caused by the channel (fading + noise) and
%   not by estimation inside the receiver. The practical receiver
%   (channel/SNR estimation, mode decoding, CRC) is built in Part C.

y  = conv(r, g, 'same');          % matched filter
ys = y(1:P.sps:end);              % one sample per symbol
cs = c(1:P.sps:end);              % true channel at the symbol instants
z  = ys./cs;                      % one-tap (zero-forcing) equaliser

% Header symbols (QPSK): Part A maps bit b to 1 - 2b, so b = 1 if negative
zh = z(1:P.Nhdr);
hb = [real(zh) < 0, imag(zh) < 0].';
hb = double(hb(:));

% Payload: nearest point of the Part A constellation
zp  = z(P.Nhdr+1:end);
[~, idx] = min(abs(bsxfun(@minus, zp, C{mode}.points)), [], 2);
pb  = C{mode}.bits(idx, :).';
pb  = pb(:);

out.errHdr = sum(hb ~= txBits.header);
out.errPay = sum(pb ~= txBits.payload);
out.ok     = (out.errHdr + out.errPay) == 0;  % frame passes (as a CRC would)
out.ys     = ys;                               % before equalisation
out.z      = z;                                % after equalisation
end

function save_figure(fh, S, name)
%SAVE_FIGURE  Save a figure as PNG (and as .fig when running in MATLAB).
set(fh, 'PaperPositionMode', 'auto');
print(fh, fullfile(S.fig, [name '.png']), '-dpng', '-r150');
if ~S.isOctave
    savefig(fh, fullfile(S.fig, [name '.fig']));
end
fprintf('  saved figures/%s.png\n', name);
end

function draw_bars(vals, colors, labels, fmt)
%DRAW_BARS  Bar chart drawn with fill() so it looks the same in MATLAB and Octave.
%   vals   : n x 1 values, or n x 2 for stacked bars (two segments)
%   colors : n x 3 colours (one per bar), or 2 x 3 for stacked segments
%   labels : cell array of x tick labels
%   fmt    : optional sprintf format for the value printed above each bar

hold on;
n = size(vals, 1);
w = 0.32;
for i = 1:n
    if size(vals, 2) == 1
        fill([i-w i+w i+w i-w], [0 0 vals(i) vals(i)], colors(i,:), 'EdgeColor', 'k');
        top = vals(i);
    else
        fill([i-w i+w i+w i-w], [0 0 vals(i,1) vals(i,1)], colors(1,:), 'EdgeColor', 'k');
        fill([i-w i+w i+w i-w], vals(i,1) + [0 0 vals(i,2) vals(i,2)], colors(2,:), 'EdgeColor', 'k');
        top = sum(vals(i,:));
    end
    if nargin > 3 && ~isempty(fmt)
        text(i, top, sprintf(fmt, top), 'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'bottom', 'FontWeight', 'bold');
    end
end
set(gca, 'XTick', 1:n, 'XTickLabel', labels);
xlim([0.4 n + 0.6]);
box on;
end
