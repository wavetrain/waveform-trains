function make_metrics( train_filename, metrics_filename, roles, epoch, samples_per_second )
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


% open train file
train_file = fopen  ( train_filename  , 'r', 'ieee-le' );
assert( train_file ~= -1,  ['Could not open ' train_filename] );
nchannels = fread( train_file, 1, 'uint8' );

% open metrics file
metrics_file = fopen  ( metrics_filename, 'w');
assert( metrics_file ~= -1,  ['Could not open ' metrics_filename] );

% write heading
fprintf(metrics_file,'Time, index\n');

% calculate one set of metrics for each epoch and save
seconds_per_epoch = epoch / samples_per_second;

while ~end_of_file(train_file)   
    
    density = [];  energy = [];  rhythmicity = []; accept = [];
    epoch_start = fread( train_file, 1, 'uint32' );
    while fread( train_file, 1, 'uint8' )
        train = read_one_train( train_file, nchannels );
         [density(end+1), energy(end+1), rhythmicity(end+1), accept(end+1) ] ...
            = compute_train_metrics( train, seconds_per_epoch, roles );
    end
    simplicity = fread( train_file, 1, 'uint16' );
    simplicity = simplicity/65535;
    
    %%% combine train metrics
    % average rhythmicity and density according to energy distribution
    % Only accepted channels are factored in. 
    energy = energy/sum(energy);
    energy = energy.*accept; 
    rhythmicity = sum( rhythmicity.*energy );
    density     = sum( density    .*energy );
    simplicity  = simplicity*sum(energy);

    % compute the composite metric
    composite = (simplicity*(rhythmicity/5+0.01))^0.5;
       
    %save metrics for the epoch
    fprintf(metrics_file,'%d,%d\n', round(epoch_start+epoch/2), round(composite*1024));
end

fclose(metrics_file);
fclose(train_file);





function [density, energy, rhythmicity, accept] = compute_train_metrics( train, seconds_per_epoch, roles )
% compute seizure metrics for an epoch
  
% compute epoch/train rhythmicity 
rhythmicity = get_rhythmicity( train.idx ) / seconds_per_epoch;

% compute epoch/train density 
density = sum( length( train.idx ) ) / seconds_per_epoch;

% compute train's L1 norm
energy = sum( abs( train.waveform ), 2 ); 

% Decide wether to interpret this waveform train as signal or noise
% The train is accepted if the majority of energy is on signal channels
accept = roles'*energy > 0;

energy = sum(energy)*length(train.idx);






function r = get_rhythmicity( idx )
% Compute the rhythmicity metric for an ordered set of points
% A point is considered 'rhythmic' if the distances to its two adjacent
% neighbors differ by less than the 'allowed_relative_difference'. 
% The rhythmicity of an epoch is the fraction of ponts that are 'rhythmic'.

allowed_relative_difference = 0.15;  %this value was obtained heuristically
if length(idx) < 3
    r = 0;
else
    left   = idx(1:end-2);
    center = idx(2:end-1);
    right  = idx(3:end  );
    r = sum( abs(left+right-2*center) < 0.5*allowed_relative_difference*(right-left) ); 
end
