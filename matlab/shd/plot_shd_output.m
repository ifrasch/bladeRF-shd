%Plots output samples from spectrum hole detector
clear; close all; clc;
samp_per_band = 89;
num_bands = 35;	%125
fstart = 1588;	%300 MHz 2008
lpf_bw = 28;	%28 MHz

%Number of PSD samples
ns = samp_per_band*num_bands;
%Create frequency vector for x axis
fend = fstart+num_bands*lpf_bw;
bw_per_bin = lpf_bw/samp_per_band;
f = fstart+bw_per_bin/2:bw_per_bin:fend-bw_per_bin/2;

%Open input FIFO file
infile = fopen('shd_out.fifo');
if infile < 0
	error('Couldn''t open input file');
end

shddata = zeros(ns, 1, 'uint32');

%Initialize PSD plot
psd = zeros(ns, 1);
figure;
subplot(2, 1, 1);
psdplot = plot(f, psd);
ax_psd = gca;
xlim([fstart fend]);
ylim([5 60]);
title('(a) Received Power Spectral Density');
xlabel('Frequency [MHz]');
ylabel('PSD [dB]');

%Initialize hole detection plot

holes = zeros(ns, 1, 'logical');
subplot(2, 1, 2);
shdplot = plot(f, uint8(holes));
%shdplot = stairs(f, uint8(holes));
%shdplot = bar(f, uint8(holes), 1, 'g', 'EdgeColor', 'none');
ax_det = gca;
xlim([fstart fend]);
ylim([0 1.2]);
set(gca,'ytick',[0 1]);
title('(b) Identified Spectrum Holes (1=hole, 0=no hole)');
xlabel('Frequency (MHz)');
ylabel('Hole Detected');

rankings = zeros(ns, 1, 'uint8');
figure;
rankplot = plot(f, rankings);
ax_rank = gca;
xlim([fstart fend]);
ylim([0 60]);
title('(c) Rankings of Identified Spectrum Holes (higher = better)');
xlabel('Frequency [MHz]');
ylabel('Hole Ranking');

i = 0;
dt = 0;
while true
	%Read in data
	shddata = uint32(fread(infile, ns, 'uint32'));
	if length(shddata) ~= ns
		break;
	end
	if i ~= 0
		dt = dt + toc;
	end
	tic;
	psd = bitshift(shddata, -8);
	holes = (bitand(shddata, hex2dec('00000080')) ~= 0);
	rankings = bitand(shddata, hex2dec('0000007F'));
	rankings(holes == 0) = 0;
	%Update PSD plot
	set(psdplot, 'YData', 10*log10(psd));
	%Update hole detection plot
	set(shdplot, 'YData', uint8(holes));
	%Update hole rankings
	set(rankplot, 'YData', rankings);
	drawnow;
	i = i+1;
end

latency = dt/(i-1)

hold(ax_psd, 'on');
hold(ax_det, 'on');
hold(ax_rank, 'on');
for i=1:num_bands-1
	plot(ax_psd, [fstart+lpf_bw*i fstart+lpf_bw*i], [-10 80], 'g--');
	plot(ax_det, [fstart+lpf_bw*i fstart+lpf_bw*i], [-10 80], 'g--');
	plot(ax_rank, [fstart+lpf_bw*i fstart+lpf_bw*i], [-10 80], 'g--');
end
