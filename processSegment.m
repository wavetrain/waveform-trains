function trains = processSegment(signal, ntrains, widths, margin)
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


% extract trains
trains = [];
for k=1:ntrains
    train = extract_one_train(signal, widths, margin);
    if isempty(train.waveform) || isempty(train.idx)        
        break;
    end

    trains = [trains train]; %#ok<AGROW>
    
    % subtract train from signal
    w = size(train.waveform,2);
    ix = floor(margin/2)-floor(w/2)+(0:w-1);
    for i=train.idx
        signal(:,i+ix) = signal(:,i+ix)-train.waveform;
    end
end