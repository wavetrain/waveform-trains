function [waveforms, occurrences] = choo3(x, number_of_trains, waveform_width)
assert(mod(waveform_width, 2) == 1, 'waveform_width must be odd')

% algorithm controls
update = 0.5;  % between 0 and 1
selectivity = 0.5;   % between 0 and 1

% rename for brevity
d = waveform_width;
K = number_of_trains;

[T, number_of_channels] = size(x);  % T = # time samples
m = (d-1)/2;  % margin for convolution

u = zeros(T,K);    % occurrences
w = zeros(d,number_of_channels,K);  % waveforms

for iter = 1:10*number_of_trains + sqrt(100*number_of_trains)
    err = x - reconstruct(u,w);
    fprintf('Iteration %3d: residual %1.6e\number_of_channels', iter, std(err(:)))
    show(x,u,w)
    
    for iTrain = 1:min(ceil(iter/5), K)
        if sum(u(:,iTrain)) == 0
            % initialize waveform with the largest peak in the error
            [~,ix] = max(abs(err(:)));
            [i,j] = ind2sub(size(err),ix);
            w(:,j,iTrain) = bsxfun(@times,err(i+(-m:m),j), initial_kernel);
        else
            % update waveform
            dw = flipud(conv2(err,flipud(u(:,iTrain))/sum(u(:,iTrain)),'valid'));
            w(:,:,iTrain) = w(:,:,iTrain) + update*dw;
        end
        
        % threshold waveform for detection and centering
        wt = w(:,:,iTrain);
        sigma = sqrt(mean(wt.^2));
        wt = wt.*(abs(wt)>2*sigma);
        normalized_columns = bsxfun(@rdivide, abs(wt), sum(abs(wt)));
        waveform_width = 2*max(sqrt(sum(bsxfun(@times, ((-m:m).^2)', normalized_columns))));
        waveform_mag = sum(sum(wt.^2));
        
        % update occurrences
        u(:, iTrain) = 0;
        err = x - reconstruct(u,w);
        du = conv2(err, rot90(wt,2)/waveform_mag, 'valid');
        idx = spaced_max(2*du-1, waveform_width, selectivity);
        u(idx+m, iTrain) = 1;
        err = x0 - reconstruct(u,w);
    end
end
fprintf \number_of_channels

% rename output arguments
waveforms = w;
occurrences = u;


    function y = reconstruct(u,w)
        % reconstruct signal from a wave train decomposition
        y = zeros(T,number_of_channels);
        for k=find(sum(u))
            temp = conv2(u(:,k), w(:,:,k));
            y = y + temp(m+(1:T),:);
        end
    end

    function show(x0,u,w)
        spacing = 3*std(x0(:));
        colors = hsv(number_of_trains)*0.7+0.3;
        for k=1:number_of_trains
            y = reconstruct(u(:,k), w(:,:,k));
            y(abs(y)<sqrt(mean(w(:,:,k).^2))) = nan;
            plot(bsxfun(@plus, y, spacing*(1:size(x0,2))), 'color', colors(k,:),'linewidth',3)
            hold on
        end
        plot(bsxfun(@plus, x0, spacing*(1:size(x0,2))),'k','linewidth',.5)
        hold off
        drawnow
    end

end



function idx = spaced_max(x, min_interval, thresh)
peaks = local_max(x);
if nargin>2
    peaks = peaks(x(peaks)>thresh);
end
if isempty(peaks)
    idx = [];
else
    idx=peaks(1);
    for i=peaks(2:end)'
        if i-idx(end)>=min_interval
            idx(end+1)=i;          %#ok<AGROW>
        elseif x(i)>x(idx(end))
            idx(end)=i;
        end
    end
end
end