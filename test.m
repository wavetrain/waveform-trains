% demonstration of the waveform train decomposition

disp 'reading EEG ...'
filename = 'data/KT_7.edf';
hdr = edfopen(filename);
signal = edfread(hdr,0,hdr.nsamples);
channelsToUse = [2:5 7:25];   % selected a subset of channels
fs = hdr.samples_per_second;
signal = signal(channelsToUse,:);

disp 'filtering...'
% notch filter
[b,a] = iirnotch(60/(fs/2),0.5/fs); % determie filter coefficients
signal = filtfilt(b,a,signal')'; % apply filter

% high-pass filter
cutoff = 2; % Hz
k = hamming(round(fs/cutoff)*2+1); % hamming window
k = k/sum(k); % normalize
signal = signal - convmirr(signal',k)'; % filter

disp 'plotting raw data...'
t = (0:size(signal,2)-1)/fs;
yticks = 1e4*(1:size(signal,1));
plot(t,bsxfun(@plus,signal',yticks))
set(gca,'YTick',yticks,'YTickLabel',arrayfun(@(i) strtrim(hdr.channelnames(i,:)),channelsToUse, 'uni', false))
xlabel 'time (s)'

% algorithm paramaters (all units are in samples)
startTime =270; % (s)
epoch = 2500;  % samples
epochStep = 2000;
waveform_width = 101;
ntrains = 3;


for i=round(startTime*fs):epochStep:size(signal,2)-epoch
    segment = signal(:,i+(1:epoch))'; % segment is the raw data
    [w, u] = choo3(segment, ntrains, waveform_width);
    show_trains(segment, u, w)
end