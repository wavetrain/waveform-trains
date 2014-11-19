function train = extract_one_train( signal, widths, margin )
% extract one waveform train from polygraphic signal

specificity = 0.0;  %  between 0 and 1. High values make template matching less tolerant.  

train.waveform = get_initial_waveform( signal(:,floor(margin/2)+(1:size(signal,2)-margin)), widths(1) );
for width=widths
    [train.idx, Q] = detect_waveform( signal, train.waveform, margin, widths(1), specificity );
    train.waveform = update_waveform( signal, train.idx, Q, width );
    if isempty(train.waveform), break, end;
end
train.idx = detect_waveform( signal, train.waveform, margin, widths(1), 0 );  %match generously
train.idx = train.idx - floor(margin/2);  %reset relative to epoch start





function waveform = get_initial_waveform( signal, min_waveform_width )
% find the highest-amplitude impulse in the signal
[m,rows] = max(abs(signal));
[m,column] = max(m);
row = rows(column);
waveform = zeros(size(signal,1),1);
waveform(row) = signal(row,column); 





function [idx,Q] = detect_waveform( signal, waveform, margin, min_spacing, specificity )
% detect the instances of 'waveform' in 'signal'

% INPUTS:
% 'signal' - polygraphic signal
% 'waveform' - polygraphic waveform
% 'margin' - the number of margin samples to disregard 
% 'min_spacing' - the minimal spacing between instances
% 'specificity' - to be deprecated 

% OUTPUTS:
% 'idx' - detected instances
% 'Q' - match quality, between 0 and 1

if isempty(waveform)
    idx = []; Q = [];
else
    %exclude margins
    w = size(waveform,2);
    epoch_start = floor(margin/2);
    epoch_length = size(signal,2)-margin;
    signal = signal(:,epoch_start-floor((w-1)/2)+ (1:epoch_length+w-1)  );

    % compute Q quality for each point by correlation
    NORM = sum(sum(waveform.^2));
    Q = conv2( signal, rot90(waveform,2), 'valid' );
    Q = 2*Q / NORM - (1+specificity);

    % remove smaller overlapping competitors 
    w = max(min_spacing,get_waveform_width(waveform));
    idx = cull_peaks( Q, w );
    Q = Q(idx);

    %restore offset
    idx = idx+epoch_start;
    assert_( ~isempty(idx), 'No waveforms detected' );
end





function waveform = update_waveform( signal, idx, Q, width )
%update waveform based on matched observations

if isempty(idx)
    waveform = [];
else
    if length(idx)>1
        width = min(width,min(diff(idx)));
    end
    ix = -floor(width/2) + (0:width-1);  %waveform mapping to signal

    % average waveforms according to Q quality
    weight = max(0,min(Q,1));
    weight = weight'/sum(weight);  
    waveform = 0;
    for i=1:length(idx)
        waveform = waveform + weight(i)*signal(:,idx(i)+ix);
    end

    % in each channel, find contiguous fragments for which the average Q is positive
    N = waveform.*waveform;
    N = max(N, 0.01*max(max(N)));  %FUDGE factor!
    E = -N*length(idx);  
    for i=1:length(idx)
        E = E + 2*waveform.*signal(:,idx(i)+ix);
    end
    for j = 1:size(waveform,1)
        C = [0 cumsum(E(j,:))];
        [m,imin] = min(C);
        [m,imax] = max(C);
        waveform(j,1:min(imin-1,end))=0;
        waveform(j,imax:end) = 0;
    end
        
    %trim off zero columns
    z = any( waveform ~=0 );
    waveform = waveform(:, find(z,1,'first'):find(z,1,'last') );
    assert_( ~isempty(waveform), 'no recurrent waveform found' );
end




function idx = cull_peaks( signal, min_distance )
%find the indices of positive peaks in single-channel 'signal'
%The identified instances must be at least 'min_distance' apart
subset = find( signal > 0 & signal > max( [signal(2:end) 0], [0 signal(1:end-1)] ) );
if isempty(subset)
    idx = [];
else
    idx = subset(1);
    for i=subset(2:end)
        if i-idx(end) >= min_distance
            idx(end+1) = i;
        elseif signal(i) > signal(idx(end))
            idx(end) = i;
        end
    end
end





function w = get_waveform_width( waveform )
% the length of longest one-channel waveform in a multichannel waveform
w = 0;
waveform = waveform ~= 0;
for j=1:size(waveform,1)
    ix1 = find(waveform(j,:),1,'first');
    if ~isempty(ix1)
        w = max(w,find(waveform(j,:),1,'last')-ix1+1);
    end
end
