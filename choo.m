function [w,u] = choo(x,K,d)
assert(mod(d,2)==1,'width must be odd')
[T,n] = size(x);  % T = # time samples, n = #channels
x0 = [zeros((d-1)/2,n); x; zeros((d-1)/2,n)];

u = zeros(T,K);    % occurrence function
w = zeros(d,n,K);  % waveform
q = 2;
for iter = 1:80
    fprintf .
    lambda = 0; %max(0,iter-20)/60;
    
    for k=1:min(ceil(iter/3),K)   % introduce additional trains gradually
        err = x0 - reconstruct(u,w);    % residual
        
        % update waveform
        L = loss(err);
        if all(all(w(:,:,k)==0)) 
            % initialize waveform with the largest peak in the error
            [~,ix] = max(sum(conv2(err((d-1)/2+(1:T),:).^2,hamming(ceil(d/8)*2+1)),2));
            w(:,:,k) = bsxfun(@times,flipud(err(ix+(1:d),:)),gausswin(d,6));
            u(:,k) = 0;
        else
            dw = 0.7*bsxfun(@times,conv2(err,flipud(u(:,k).^q)/sum(u(:,k).^q),'valid'),gausswin(d));
            while loss(err-reconstruct(u(:,k),dw))>L
                dw = 0.7*dw;
            end
            dw = 0.7*dw;  % be conservative
            w(:,:,k) = w(:,:,k) + dw;
            err = err - reconstruct(u(:,k),dw);   % update error
        end
        
        % update occurrence function
        L = loss(err,u,w,lambda);
        du = conv2(err,fliplr(w(:,:,k))/sq(w(:,:,k)),'valid') + lambda*(u(:,k)-0.3);
        if all(u(:,k)==0)
            % initialize sparsely
            du(setdiff(1:T,spaced_max(clamp(du),0.4*d,0.1)))=0;
        end
        while loss(err - reconstruct(clamp(u(:,k)+du)-u(:,k),w(:,:,k)),u,w,lambda)>L
            du = 0.5*du;
        end
        u(:,k) = clamp(u(:,k) + 0.7*du);
        
    end
end
fprintf \n

% plot resulting waveforms
subplot 211
plot(bsxfun(@plus,reshape(cat(1,w,nan(size(w))),[],K)/max(abs(w(:))),1:K))

subplot 212
plot(bsxfun(@plus,u,1:K))
end


function L = loss(err,u,w,lambda)
L = sq(err);
if nargin==3 && lambda > 0
    for k=1:size(u,2)
        L = L - lambda*sq(w(:,:,k))*sq(u(:,k)-0.3);
    end
end
end

function s = sq(x)
s = x(:)'*x(:);
end

function x = clamp(x)
x = max(0,min(1,x));
end

function y = reconstruct(u,w)
y = 0;
for k=1:size(u,2)
    y = y + conv2(u(:,k),w(:,:,k));
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