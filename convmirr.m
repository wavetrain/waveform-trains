% convmirr(x,k) performs fast fft-based FIR convolution with boundary mirroring 
% to reduce boundary artifacts.  Both the signal x and the kernel k must be
% columnwise. x may contain multiple signals in its columns.
%
% Dimitri Yatsenko, 2010-09-07

function x=convmirr(x,k)
assert(size(k,2)==1, 'kernel must be a column')
l = size(x,1);
n = length(k);
assert(l>n, 'kernel must be shorter than signal')

% mirror boundaries in time
n = floor(n/2);
x = [x(n+2-(1:n),:); x; x(end-1-(1:n),:)];
x = fftfilt(k,x);  % apply filter
x = x(2*n+1:end,:);  % take valid values only