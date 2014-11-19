function make_trains( signal_filename, train_filename, epoch, step, ntrains, widths )

hdr = edfopen(signal_filename);
train_file = fopen( train_filename, 'w', 'ieee-le' );
assert( train_file ~= -1,  ['Could not open ' train_filename] );
channels = find(hdr.roles ~= 'D');
fwrite( train_file, length(channels), 'uint8' );

margin = max(widths)-1;
for t = floor(margin/2):step:hdr.nsamples-epoch-ceil(margin/2)-1   %t is zero-based
    disp(sprintf('Epoch start: %d\n', t ) );
    signal = edfread(hdr, t-floor(margin/2), epoch+margin );
    fwrite( train_file, t, 'uint32' );
    
    % remove display-only channels
    signal = signal( channels, : );  
    
    process_epoch( train_file, signal, epoch, ntrains, widths, margin );
end
fclose(train_file);




function process_epoch( train_file, signal, epoch, ntrains, widths, margin )
% process_epoch( train_file, signal, ntrains, widths, margin )
% Extracts trains of waveforms from signal.
%
% INPUTS:
%
% 'signal' is the original polygraphic signal 
%
% 'ntrains' is the number of trains to extract
%
% 'widths' is the array maximum waveform witdths to try at each iteration.  
% 'widths' determines how many WTP iterations to perform. 
% 'widths' defines the tradeoff between speed and % detection accuracy. 
% widths(1) is  the shortest allowed waveform.
% widths(end) is the longest allowed waveform.  
% widths(2:end-1) define waveform widths for each iteration of pursuit.
% 
% 'margin' is the number of samples added to the signal to enable valid
% correlations and must be no smaller than the widths(end)-1 
% waveform time indices are allowed in the range
% floor((margin+1)/2):floor(L-(margin-1)/2), where L = size(signal,2)
% 
% OUTPUTS:
% 'trains' is an array of structures containing fields 'waveform' and 'idx'
% trains{k}.waveform is the polygraphic waveform
% trains{k}.idx is the list of time indices at which the waveform is found


% high-pass filtration (unnecessary for Ripple data)
k = myhamm(101); k = k/sum(k);
signal = signal - conv2(signal,k,'same');

% extract trains
snip = floor(margin/2)+(1:epoch);
initial_energy = mean(abs(signal(:,snip)),2);

for k=1:ntrains
    train = extract_one_train( signal, widths, margin );
    if isempty(train.waveform) || isempty(train.idx)        
        break;
    end

    %record the train
    fwrite( train_file, 1, 'uint8' );  %indicate that a train will follow
    write_one_train( train_file, train );
    
    % subtract train from signal
    w = size(train.waveform,2);
    ix = floor(margin/2)-floor(w/2)+(0:w-1);
    for i=train.idx
        signal(:,i+ix) = signal(:,i+ix)-train.waveform;
    end
end

fwrite( train_file, 0, 'uint8' ); %indicate no more trains
        
% compute and save simplicity
simplicity = 1-mean(abs(signal(:,snip)),2)./initial_energy;
q = 8;  %sensitivity to focal activity
simplicity = mean(simplicity.^q).^(1/q);
fwrite( train_file, simplicity*65535, 'uint16');
        





function write_one_train( train_file, train )
% writes 'train' into 'train_file' 

fwrite( train_file, length( train.idx ), 'uint16' );
fwrite( train_file, train.idx, 'uint16' );
fwrite( train_file, size( train.waveform, 2 ), 'uint16' );
fwrite( train_file, train.waveform', 'int16' );
