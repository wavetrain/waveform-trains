function train = read_one_train( fid, nchannels )
% see write_one_train() for record format

N = fread( fid, 1, 'uint16' );
train.idx = fread( fid, N, 'uint16');
L = fread( fid, 1, 'uint16' );
train.waveform = fread( fid, [L, nchannels], 'int16')';