function signal = edfread(hdr, start_sample, nsamples)
% simple EDF read
% The segment to read is specified in samples:
% 'start_sample' is zero-based index of the first sample
% 'nsamples' is the number of samples to read for each channel

% check index range
assert( start_sample >= 0 && start_sample + nsamples <= hdr.nsamples, 'index out of range' );

% open edf file
f = fopen(hdr.filename, 'r', 'ieee-le');
assert(f ~= -1, sprintf('%s not found',hdr.filename));

% generate zero-based frame numbers
first = floor(start_sample / hdr.samples_per_frame);
last  = floor((start_sample+nsamples-1) / hdr.samples_per_frame);

% read frames
fseek(f,hdr.header_size+2*first*hdr.samples_per_frame*hdr.nchannels,'bof');
signal = [];
for i=first:last
    frame = fread(f,[hdr.samples_per_frame,hdr.nchannels],'int16')';
    signal = [signal frame];  %#ok<AGROW>
end
fclose(f);

% select precise index range
signal = signal(:,start_sample-first*hdr.samples_per_frame+(1:nsamples));