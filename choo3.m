function [w, u] = choo3(x, number_of_trains, waveform_width)
% decompose signal x into waveform trains characterized by waveforms w and
% their occurrences u

assert(mod(waveform_width, 2) == 1, 'waveform_width must be odd')

% algorithm controls
selectivity = 0.2;   % between 0 and 1, most likely between 0 and 0.5
% selectivity = 0.2; % between 0 and 1, most likely between 0 and 0.5

% rename for brevity
d = waveform_width;
K = number_of_trains;

[T, number_of_channels] = size(x);  % T = # time samples
m = (d-1)/2;  % margin for convolution

u = zeros(T,K);    % occurrences
w = zeros(d,number_of_channels,K);  % waveforms
initial_kernel = gausswin(d,9);

err = x;
niters = 6*number_of_trains + sqrt(36*number_of_trains);  % rule of thumb
for iter = 1:niters
    fprintf('Iteration %3d: residual %1.6e\n', iter, sqrt(mean(err(:).^2)))
    show_trains(x,u,w); % Uncomment to show wavetrains at each step. Comment for speed.
    
    for iTrain = 1:min(ceil(iter/4), K) % every four iteration a new train is added
        if sum(u(:,iTrain)) == 0
            % initialize waveform with the largest peak in the error
            err([1:m end-m+1:end],:) = 0; % zero out error too close to the boundaries
            [~,ix] = max(abs(err(:))); % max peak of error
            [i,j] = ind2sub(size(err),ix);
            w(:,j,iTrain) = bsxfun(@times,err(i+(-m:m),j), initial_kernel);
        else
            % update waveform to better fit data for current occurrences
            w(:,:,iTrain) = w(:,:,iTrain) + ...
                conv2(err,flipud(u(m+1:end-m,iTrain))/sum(u(m+1:end-m,iTrain)),'valid');
        end
        
        % threshold waveform for detection and centering
        wt = w(:,:,iTrain); % create template waveform from error peak
        wt(abs(wt)<2*sqrt(mean(wt(:).^2)))=0; % removes anything below two sigma of amlitude
        
        % re-detect occurrences
        u(:, iTrain) = 0; % erases old occurrences so it can find them again
        err = x - reconstruct(u,w); % new error signal disregarding current train
        c = conv2(err, rot90(wt,2)/sum(sum(wt.^2)), 'valid');  % normalized correlation (flipped for correlation (conv2 will flip otherwise))
        idx = spaced_max(c, width(wt), (selectivity+1)/2); %finds the indices of the peaks
        u(idx+m, iTrain) = 1;
        err = x - reconstruct(u,w);
    end
end
%keyboard

end


function d = width(w)
% the effective width of the waveform w, calculated from the standard
% deviation of waveform distribution around its center of mass
w = bsxfun(@rdivide, abs(w), sum(abs(w))+eps);  % normalize columns
t = (1:size(w,1))';   % time
t =  bsxfun(@minus, t, sum(bsxfun(@times, t, w)));  % coordinate relative to center of mass
d = max(sqrt(sum(t.^2 .* w)));   % max standard deviation
d = 2.5*d;   % multiples of standard deviation (rule of thumb, approximates width) (waveforms should not overlap)
end