function [waveforms, occurrences] = choo3(x, number_of_trains, waveform_width)
assert(mod(waveform_width, 2) == 1, 'waveform_width must be odd')

% algorithm controls 
update = 0.5;  % between 0 and 1
selectivity = 0.5;   % between 0 and 1

% rename for brevity
d = waveform_width; 
K = number_of_trains; 

[T,n] = size(x);  % T = # time samples, n = #channels
m = (d-1)/2;  % margin for convolution

u = zeros(T,K);    % occurrences
w = zeros(d,n,K);  % waveforms

for iter = 1:10*number_of_trains + sqrt(100*number_of_trains)
    err = x - reconstruct(u,w);
    fprintf('Iteration %3d: residual %1.6e\n', iter, std(err(:)))
    show(x,u,w)

    for iTrain = 1:min(ceil(iter/5), K)    
        if sum(u(:,iTrain)) == 0
            % initialize waveform with the largest peak in the error
            [~,ix] = max(abs(err(:)));
            [i,j] = ind2sub(size(err),ix);
            w(:,j,iTrain) = bsxfun(@times,flipud(err(i+(-m:m),j)), initial_kernel);
        else
            % update waveform 
            dw = conv2(err,flipud(u(:,iTrain))/sum(u(:,iTrain)),'valid');
            dw = bsxfun(@times, refining_kernel, dw);
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
        du = conv2(err, fliplr(wt)/waveform_mag, 'valid');
        idx = spaced_max(2*du-1, waveform_width, selectivity);
        u(idx+m, iTrain) = 1;
        err = x0 - reconstruct(u,w);
    end
end
fprintf \n

% rename output arguments
waveforms = w;
occurrences = u;

end


function show(x0,u,w)
spacing = 3*std(x0(:));
K = size(u,2);
colors = hsv(K)*0.7+0.3;
for iTrain=1:K
    y = reconstruct(u(:,iTrain),w(:,:,iTrain));
    sigma = sqrt(mean(w(:,:,iTrain).^2));
    y(abs(y)<sigma) = nan;
    plot(bsxfun(@plus, y, spacing*(1:size(x0,2))), 'color', colors(iTrain,:),'linewidth',3)
    hold on
end
plot(bsxfun(@plus, x0, spacing*(1:size(x0,2))),'k','linewidth',.5)
hold off
drawnow
end


function y = reconstruct(u,w)
y = 0;
for iTrain=find(sum(u))
    y = y + conv2(u(:,iTrain),w(:,:,iTrain));
end
y = y((size(w,1)-1)/2+(1:size(u,1)),:);
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