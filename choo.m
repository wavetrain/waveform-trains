function [w,u] = choo(x,K,d)
assert(mod(d,2)==1,'width must be odd')
[T,n] = size(x);  % T = # time samples, n = #channels
x0 = [zeros((d-1)/2,n); x; zeros((d-1)/2,n)];

% initialize random occurrence functions
%u = bsxfun(@times,rand(T,K), sum(abs(x),2));
%u = u/max(u(:));
u = zeros(T,K);
w = zeros(d,n,K);
q = 2;
for iter = 1:80
    
    for k=1:min(ceil(iter/3),K)   % introduce additional trains gradually
        err = x0 - reconstruct(u,w);    % residual
        L = sum(sum(err.^2));
        
        if all(all(w(:,:,k)==0))
            % initialize waveform with the largest peak in the error
            [~,ix] = max(sum(err((d-1)/2+(1:T),:).^2,2));
            w(:,:,k) = bsxfun(@times,flipud(err(ix+(1:d),:)),gausswin(d,6));
        else
            % update waveform
            dw = 0.7*bsxfun(@times,conv2(err,flipud(u(:,k).^q)/sum(u(:,k).^q),'valid'),gausswin(d));
            while sum(sum((err - reconstruct(u(:,k),dw)).^2))>L
                dw = 0.7*dw;
            end
            dw = 0.7*dw;  % be conservative
            w(:,:,k) = w(:,:,k) + dw;  
            err = err - reconstruct(u(:,k),dw);   % update error
            L = sum(sum(err.^2));
        end
        
        % update occurrence function
        du = conv2(err,fliplr(w(:,:,k))/sum(sum(w(:,:,k).^2)),'valid');
        if all(u(:,k)==0)
            % initialize sparsely
            du(setdiff(1:T,spaced_max(clamp(du),0.4*d,0.1)))=0;
        end            
        while sum(sum((err - reconstruct(clamp(u(:,k)+du)-u(:,k),w(:,:,k))).^2))>L
            du = 0.7*du;
        end        
        u(:,k) = clamp(u(:,k) + 0.7*du);  
    end
end
end


function L = loss(x0,u,w,lambda)
L = sum((x0 - reconstruct(u,w)).^2 + lambda*sum(u-u.^2,2));
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