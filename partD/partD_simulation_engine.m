
function results = partD_simulation_engine()
% Part D simulation engine using the Part B link model.

here = fileparts(mfilename('fullpath'));
partBdir = fullfile(here, '..', 'partB');
if exist(partBdir, 'dir')
    addpath(partBdir);
end

S = setup_folders(here);
P = get_params();

targetPER = 0.10;
T1_values = [17 19 21];
T2_values = [23 25 27];
Tsim = 600;
seedCh = 31;
seedRun = 100;

rng(seedCh);
F = partB_channel('init', P.fD, P.Nsin);
[~, ~, req] = thresholds(P);

mkfb = @(type,d,sg,q) struct('type',type,'delay',d, ...
    'sigma',sg,'quant',q,'bitErr',0);

fbList = {
    mkfb('ideal',0,0,false), ...
    mkfb('report',1,0,true), ...
    mkfb('report',0,2,true), ...
    mkfb('report',1,2,true)
};

feedbackNames = {'Ideal'; 'Delayed 1 s'; ...
    'Noisy 2 dB'; 'Delayed + noisy'};

fprintf('Part D: running actual simulations\n');

%% Threshold sweep
thresholdResults = zeros(9,4);
row = 0;

for i = 1:numel(T1_values)
    for j = 1:numel(T2_values)
        row = row + 1;

        sw = struct('T1',T1_values(i), ...
            'T2',T2_values(j),'H',P.H, ...
            'req',req,'fixed',0);

        R = run_link(P,F,fbList{1},sw,Tsim,seedRun);

        thresholdResults(row,:) = [T1_values(i), ...
            T2_values(j),R.thr,100*R.PER];

        fprintf('T1=%g T2=%g: %.0f bit/s, PER %.2f%%\n', ...
            T1_values(i),T2_values(j),R.thr,100*R.PER);
    end
end

valid = thresholdResults(:,4) <= 100*targetPER;

if any(valid)
    validResults = thresholdResults(valid,:);
    [~,idx] = max(validResults(:,3));
    best = validResults(idx,:);
else
    [~,idx] = min(thresholdResults(:,4));
    best = thresholdResults(idx,:);
    warning('No tested thresholds meet the PER target.');
end

fprintf('Best tested T1=%.1f, T2=%.1f dB\n',best(1),best(2));

fig = figure('Name','Part D Threshold Sweep','Color','w');
subplot(1,2,1);
scatter(thresholdResults(:,1),thresholdResults(:,2), ...
    100,thresholdResults(:,3),'filled');
colorbar;
xlabel('T1 (dB)'); ylabel('T2 (dB)');
title('Throughput (bit/s)'); grid on;

subplot(1,2,2);
scatter(thresholdResults(:,1),thresholdResults(:,2), ...
    100,thresholdResults(:,4),'filled');
colorbar;
xlabel('T1 (dB)'); ylabel('T2 (dB)');
title('PER (%)'); grid on;
save_figure(fig,S,'D_threshold_sweep');

%% Feedback comparison
swBest = struct('T1',best(1),'T2',best(2), ...
    'H',P.H,'req',req,'fixed',0);

feedbackResults = zeros(4,2);
switchingResults = zeros(4,2); % [number of switches, switches per minute]

for i = 1:4
    R = run_link(P,F,fbList{i},swBest,Tsim,seedRun);
    feedbackResults(i,:) = [R.thr,100*R.PER];
    switchingResults(i,:) = [R.switches,R.swPerMin];
end

fprintf('\nMode switching rate comparison:\n');
fprintf('%-20s %12s %20s\n','Feedback case','Switches','Switches per minute');
for i = 1:4
    fprintf('%-20s %12.0f %20.3f\n',feedbackNames{i}, ...
        switchingResults(i,1),switchingResults(i,2));
end

fig = figure('Name','Part D Feedback Comparison','Color','w');
subplot(1,2,1);
bar(feedbackResults(:,1));
set(gca,'XTick',1:4,'XTickLabel',feedbackNames);
ylabel('Throughput (bit/s)');
title('Throughput vs feedback'); grid on;

subplot(1,2,2);
bar(feedbackResults(:,2)); hold on;
plot([0.5 4.5],[10 10],'r--');
set(gca,'XTick',1:4,'XTickLabel',feedbackNames);
ylabel('PER (%)'); title('PER vs feedback'); grid on;
save_figure(fig,S,'D_feedback_comparison');

fig = figure('Name','Part D Mode Switching Rates','Color','w');
bar(switchingResults(:,2));
set(gca,'XTick',1:4,'XTickLabel',feedbackNames);
ylabel('Mode switches per minute');
title('Mode switching rate by feedback case'); grid on;
save_figure(fig,S,'D_mode_switching_rates');

%% Fixed versus adaptive modulation
modeNames = {'Adaptive';'QPSK';'16-QAM';'64-QAM'};
modeResults = zeros(4,2);
modeResults(1,:) = feedbackResults(1,:);

for mode = 1:3
    swFixed = swBest;
    swFixed.fixed = mode;

    R = run_link(P,F,fbList{1},swFixed,Tsim,seedRun);
    modeResults(mode+1,:) = [R.thr,100*R.PER];
end

fig = figure('Name','Part D Fixed vs Adaptive','Color','w');
subplot(1,2,1);
bar(modeResults(:,1));
set(gca,'XTick',1:4,'XTickLabel',modeNames);
ylabel('Throughput (bit/s)'); title('Throughput'); grid on;

subplot(1,2,2);
bar(modeResults(:,2)); hold on;
plot([0.5 4.5],[10 10],'r--');
set(gca,'XTick',1:4,'XTickLabel',modeNames);
ylabel('PER (%)'); title('PER'); grid on;
save_figure(fig,S,'D_fixed_vs_adaptive');

results.thresholdResults = thresholdResults;
results.bestThresholds = best;
results.feedbackNames = feedbackNames;
results.feedbackResults = feedbackResults;
results.switchingResults = switchingResults;
results.modeNames = modeNames;
results.modeResults = modeResults;
results.targetPER = 10;
results.Tsim = Tsim;
results.P = P;

save(fullfile(S.res,'partD_results.mat'),'results');
fprintf('Part D results saved in %s\n',S.res);
end

function S = setup_folders(here)
S.dir = here;

srcdir = fullfile(here,'..','src');
if exist(fullfile(srcdir,'gray_qam_map.m'),'file')
    addpath(srcdir);
end

if ~exist('gray_qam_map','file')
    error('Cannot find src/gray_qam_map.m');
end

S.fig = fullfile(here,'figures');
S.res = fullfile(here,'results');

if ~exist(S.fig,'dir'), mkdir(S.fig); end
if ~exist(S.res,'dir'), mkdir(S.res); end

S.isOctave = exist('OCTAVE_VERSION','builtin') > 0;
end

function P = get_params()
P.sps = 8;
P.Rs = 1000;
P.Fs = P.Rs*P.sps;
P.beta = 0.35;
P.span = 10;
P.Npay = 1200;
P.M = [4 16 64];
P.k = log2(P.M);
P.names = {'QPSK','16-QAM','64-QAM'};
P.sync = [1;1;0;1;0;0;1;1;1;0;0;1;0;0;0;1];
P.Nhdr = 17;
P.Nsym = P.Nhdr + P.Npay./P.k;
P.Tframe = P.Nsym/P.Rs;
P.B = P.Rs*(1+P.beta);

P.fD = 0.1;
P.Nsin = 32;
P.EsN0avg = 24;

P.T1_partA = 10;
P.T2_partA = 18;
P.H = 1.5;
P.PERtarget = 0.10;

P.cqiBits = 5;
P.cqiStep = 1;
P.cqiMin = 0;
end

function [T1,T2,req] = thresholds(P)
gdB = 0:0.01:40;
req = zeros(1,3);

for m = 1:3
    ber = ber_theory(P.M(m),gdB,'awgn');
    per = 1-(1-ber).^P.Npay;
    req(m) = gdB(find(per <= P.PERtarget,1,'first'));
end

T1 = req(2)+P.H;
T2 = req(3)+P.H;
end

function ber = ber_theory(M,EsN0dB,channel)
g = 10.^(EsN0dB/10);
L = sqrt(M);
K = log2(L);
b0 = sqrt(3/(2*(M-1)));
ber = zeros(size(g));

for k = 1:K
    for i = 0:((1-2^(-k))*L-1)
        f = floor(i*2^(k-1)/L);
        w = (-1)^f*(2^(k-1)-floor(i*2^(k-1)/L+1/2));
        bi = (2*i+1)*b0;

        if strcmpi(channel,'awgn')
            term = erfc(bi*sqrt(g));
        else
            term = 1-sqrt(bi^2*g./(1+bi^2*g));
        end

        ber = ber+w*term;
    end
end

ber = ber/(L*K);
end

function h = rrc_pulse(beta,span,sps)
t = (-span*sps/2:span*sps/2)/sps;
h = zeros(size(t));

for n = 1:length(t)
    x = t(n);

    if abs(x)<1e-10
        h(n) = 1+beta*(4/pi-1);
    elseif abs(abs(x)-1/(4*beta))<1e-10
        h(n) = (beta/sqrt(2))* ...
            ((1+2/pi)*sin(pi/(4*beta))+ ...
             (1-2/pi)*cos(pi/(4*beta)));
    else
        h(n) = (sin(pi*x*(1-beta))+ ...
            4*beta*x*cos(pi*x*(1+beta)))/ ...
            (pi*x*(1-(4*beta*x)^2));
    end
end

h = h(:)/sqrt(sum(h.^2));
end

function [s,bits,sym] = make_frame(mode,P,g,payload)
M = P.M(mode);

if nargin<4 || isempty(payload)
    payload = randi([0 1],P.Npay,1);
end
payload = payload(:);

modeID = mode-1;
modeBits = [bitget(modeID,2);bitget(modeID,1)];
lengthBits = zeros(16,1);

for b = 1:16
    lengthBits(b) = bitget(P.Npay,17-b);
end

header = [P.sync;modeBits;lengthBits];
pairs = reshape(header,2,[]).';
hdrSym = ((1-2*pairs(:,1))+1j*(1-2*pairs(:,2)))/sqrt(2);

paySym = gray_qam_map(payload,M);
sym = [hdrSym;paySym(:)];

up = zeros(numel(sym)*P.sps,1);
up(1:P.sps:end) = sym;
s = conv(up,g,'same');

bits.header = header;
bits.payload = payload;
end

function C = constellations(P)
C = cell(1,3);

for m = 1:3
    M = P.M(m);
    k = P.k(m);
    B = zeros(M,k);

    for v = 0:M-1
        B(v+1,:) = bitget(v,k:-1:1);
    end

    C{m}.bits = B;
    C{m}.points = gray_qam_map(reshape(B.',[],1),M).';
end
end

function R = run_link(P,F,fb,sw,Tsim,seed)
rng(seed);
g = rrc_pulse(P.beta,P.span,P.sps);
C = constellations(P);
gbar = 10^(P.EsN0avg/10);

maxF = ceil(Tsim/min(P.Tframe))+2;
L.tStart = zeros(maxF,1);
L.Tf = zeros(maxF,1);
L.mode = zeros(maxF,1);
L.snrUsed = nan(maxF,1);
L.snrStart = zeros(maxF,1);
L.snrFrame = zeros(maxF,1);
L.errPay = zeros(maxF,1);
L.errHdr = zeros(maxF,1);
L.ok = false(maxF,1);
L.age = nan(maxF,1);

repTime = inf(maxF,1);
repVal = nan(maxF,1);
repMid = nan(maxF,1);
nRep = 0;
ptr = 0;

t = 0;
mode = 1;
n = 0;

while t<Tsim
    n = n+1;
    snrStart = 10*log10(gbar*abs(partB_channel('gain',F,t))^2);
    age = NaN;

    if sw.fixed>0
        mode = sw.fixed;
        snrUsed = NaN;
    else
        if strcmpi(fb.type,'ideal')
            snrUsed = snrStart;
            age = 0;
        else
            while ptr<nRep && repTime(ptr+1)<=t
                ptr = ptr+1;
            end

            if ptr>0
                snrUsed = repVal(ptr);
                age = t-repMid(ptr);
            else
                snrUsed = NaN;
            end
        end

        mode = select_mode(snrUsed,mode,sw.T1,sw.T2,sw.H);
    end

    [s,bits] = make_frame(mode,P,g);
    [r,c] = partB_channel(s,t,P,F,P.EsN0avg);
    out = rx_measure(r,c,mode,P,g,bits,C);
    Tf = numel(s)/P.Fs;

    snrFrame = 10*log10(gbar*mean(abs(c(1:P.sps:end)).^2));
    nRep = nRep+1;
    repTime(nRep) = t+Tf+fb.delay;
    repVal(nRep) = cqi_report(snrFrame,fb,P);
    repMid(nRep) = t+Tf/2;

    L.tStart(n) = t;
    L.Tf(n) = Tf;
    L.mode(n) = mode;
    L.snrUsed(n) = snrUsed;
    L.snrStart(n) = snrStart;
    L.snrFrame(n) = snrFrame;
    L.errPay(n) = out.errPay;
    L.errHdr(n) = out.errHdr;
    L.ok(n) = out.ok;
    L.age(n) = age;

    t = t+Tf;
end

fn = fieldnames(L);
for i = 1:numel(fn)
    L.(fn{i}) = L.(fn{i})(1:n);
end

Ttot = L.tStart(end)+L.Tf(end);
R.log = L;
R.nFrames = n;
R.Ttot = Ttot;
R.thr = sum(L.ok)*P.Npay/Ttot;
R.thrNorm = R.thr/P.Rs;
R.PER = 1-mean(L.ok);
R.BER = sum(L.errPay)/(n*P.Npay);
R.switches = sum(diff(L.mode)~=0);
R.swPerMin = R.switches/(Ttot/60);
R.timeShare = zeros(1,3);

for m = 1:3
    R.timeShare(m) = sum(L.Tf(L.mode==m))/Ttot;
end

bestMode = 1+(L.snrFrame>=sw.req(2))+(L.snrFrame>=sw.req(3));
R.over = mean(L.mode>bestMode);
R.under = mean(L.mode<bestMode);
R.fb = fb;
R.sw = sw;
end

function mode = select_mode(snr, mode, T1, T2, H)
%SELECT_MODE Part A threshold + hysteresis rule as a function.
% Same logic as src/step7_snr_switching.m:
%   switch up   when snr >= T + H
%   switch down when snr <  T - H
% snr: SNR value available at transmitter (dB); NaN = no report
% mode: current mode (1 QPSK, 2 16-QAM, 3 64-QAM)

if isnan(snr)
    return;
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
%CQI_REPORT SNR value that the receiver feeds back to the transmitter.
%
% 1) Estimation error: snr_hat = snr + e, e ~ N(0, fb.sigma^2) (dB)
% 2) Quantisation: CQI bits and step size defined by P
% 3) Feedback link: each CQI bit flips with probability fb.bitErr
% The feedback delay is applied by run_link.

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

function out = rx_measure(r,c,mode,P,g,txBits,C)
y = conv(r,g,'same');
ys = y(1:P.sps:end);
cs = c(1:P.sps:end);
z = ys./cs;

zh = z(1:P.Nhdr);
hb = [real(zh)<0,imag(zh)<0].';
hb = double(hb(:));

zp = z(P.Nhdr+1:end);
[~,idx] = min(abs(bsxfun(@minus,zp,C{mode}.points)),[],2);
pb = C{mode}.bits(idx,:).';
pb = pb(:);

out.errHdr = sum(hb~=txBits.header);
out.errPay = sum(pb~=txBits.payload);
out.ok = (out.errHdr+out.errPay)==0;
end

function save_figure(fh,S,name)
set(fh,'PaperPositionMode','auto');
print(fh,fullfile(S.fig,[name '.png']),'-dpng','-r150');

if ~S.isOctave
    savefig(fh,fullfile(S.fig,[name '.fig']));
end

fprintf('Saved %s.png\n',name);
end
