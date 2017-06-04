%Checks the spectrum hole detector testbench results
%Compares expected holes, hole rankings, and PSD to actual results for SHD
clear; close all; clc;
Nf = 128;
Ns = 512;
num_ffts = Ns/Nf;
n = 0:Ns-1;
filt_bw = 0.7;
sf = 1.45;
Noutput = floor(filt_bw*Nf);
k_clip_start = floor(Nf*filt_bw/2.0)+1+1;
k_clip_end = Nf - floor(Nf*filt_bw/2.0) - 1+1;

infile = 'samples_314mhz.csv';
outfile = 'shd_tb_dout.txt';

indata = csvread(infile);
tdata = complex(indata(1:Ns,1), indata(1:Ns,2));

%Calculate expected results
psdexp0 = calc_psd(tdata, Nf, 0);
psdexp(1:44) = psdexp0(21:64);
psdexp(45:89) = psdexp0(65:109);
psdexp(45) = (psdexp(44)+psdexp(46))/2;
thresh = min(psdexp)*sf;
holes = psdexp < thresh;
holerank = thresh ./ psdexp;
holerank(holes == 0) = 1;

%Plot expected results
figure; plot(n, real(tdata)); hold on; plot(n, imag(tdata), 'r');
title('Input time signal');
xlabel('n'); xlim([0 Ns-1]);
ylim([-2200 2200]);
figure; plot(10*log10(psdexp/2^4/2^8));
threshdb = 10*log10(thresh/2^4/2^8);
hold on; plot([1 Noutput], [threshdb threshdb], 'g');
title('Expected PSD (dB)');
ylim([20 60]);
figure; plot(holes);
title('Expected holes');
figure; plot(holerank);
title('Expected hole rankings');
ylim([1 sf]);

%Parse outfile file
outdata = csvread(outfile);
outholes = outdata(:,1);
outrank = outdata(:,2);
outpsd = outdata(:,3);
%Plot results
figure; plot(10*log10(outpsd));
title('Output PSD (dB)');
ylim([20 60]);
figure; plot(outholes);
title('Output holes');
outrank(outholes == 0) = 0;
figure; plot(outrank);
title('Output hole rankings');
ylim([0 (sf-1)*2^7]);