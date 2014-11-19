function make_metrics_C( train_filename, metrics_filename, roles, epoch, samples_per_second )
% make_metrics( train_filename, metrics_filename, roles, epoch, samples_per_second )
% Read waveform trains from 'train_filename', compute waveform metrics, and
% saves them in metrics_filename as a comma-delimited ASCII file 'metrics_filename'
%
% 'train_filename' is the filename containining waveform trains created by
% make_trains()
%
% 'metrics_filename' is the filename in which to store the resulting
% metrics
%
% 'roles' contains 1s for channels containing signal and -1 for channels
% containing noise or artifacts such as EKG, pulse oximetry, or
% accelerometer 
%
% 'epoch' is the is the length of the epoch in samples. 
%
% 'samples_per_second' - sampling rate necessary for metrics involving time
%

disp('Called placeholder for C implemenation of make_metrics');
disp('Calling the MATLAB implementation for now.');

% calling the Matlab implementaion for now
make_metrics( train_filename, metrics_filename, roles, epoch, samples_per_second );
