function [waveforms, occurrences] = choo2(x, number_of_trains, waveform_width)
assert(mod(waveform_width, 2) == 1, 'width must be odd')

% algorithm settings
new_points = 10;
remove_fraction = 0.1;
rng(3)

[T,n] = size(x);  % T = # time samples, n = #channels
half = (waveform_width-1)/2;
x0 = [zeros(half, n); x; zeros(half, n)];  % zero-padded for convolutions

u = zeros(T,number_of_trains);    % occurrence function
w = zeros(waveform_width,n,number_of_trains);  % waveform

% a occurrences randomly at high-energy points
e2 = mean(x.^2, 2);
v = mean(e2);
occurrences = spaced_max(e2,waveform_width/4,v);
u(sub2ind([T,number_of_trains], occurrences, randi(number_of_trains,size(occurrences)))) = 1;

du = zeros(T,number_of_trains);
for iter = 1:100
    err = x0 - reconstruct(u,w);
    fprintf('Iteration %3d: residual %1.6e\n', iter, sum(err(:).^2))
    
    % update waveforms
    for iTrain=1:number_of_trains
        g = gausswin(waveform_width, 1.5);
        dw = bsxfun(@times, g, conv2(err,flipud(u(:,iTrain))/sum(u(:,iTrain)),'valid'));
        w(:,:,iTrain) = w(:,:,iTrain) + 0.1*dw;
    end
    
    show(x0,u,w)
    
    % compute correlations
    err = x0 - reconstruct(u,w);
    for iTrain=1:number_of_trains
        du(:,iTrain) = conv2(err,fliplr(w(:,:,iTrain))/sq(w(:,:,iTrain)),'valid');
    end
    
    % remove some occurrences 
    u = u.*((rand(size(u)) < exp(du) | rand(size(u))>0.1) & rand(size(u))<0.98);
    
    % add occurrences randomly at highest correlations
    c = max(du,0);
    c = cumsum(c(:).^3);
    c = 0.99*c/c(end)+0.01*linspace(0,1,length(c))';
    u(interp1(c, 1:length(c), rand(1, new_points), 'nearest','extrap')) = 1;
end
fprintf \n

% rename output arguments
waveforms = w;
occurrences = u;

end


function show(x0,u,w)
spacing = 3*std(x0(:));
number_of_trains = size(u,2);
colors = hsv(number_of_trains)*0.7+0.3;
for iTrain=1:number_of_trains
    y = reconstruct(u(:,iTrain),w(:,:,iTrain));
    y(~y) = nan;
    plot(bsxfun(@plus, y, spacing*(1:size(x0,2))), 'color', colors(iTrain,:),'linewidth',3)
    hold on
end
plot(bsxfun(@plus, x0, spacing*(1:size(x0,2))),'k','linewidth',.5)
hold off
drawnow
end


function s = sq(x)
s = x(:)'*x(:);
end

function y = reconstruct(u,w)
y = 0;
for iTrain=1:size(u,2)
    y = y + conv2(u(:,iTrain),w(:,:,iTrain));
end
end

function idx = spaced_max(x, min_interval, thresh)
peaks = local_max( x );
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