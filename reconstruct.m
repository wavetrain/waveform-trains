function y = reconstruct(u,w)
% reconstruct signal from a wave train decomposition
m = (size(w,1)-1)/2;
number_of_channels = size(w,2);
T = size(u,1);
y = zeros(T,number_of_channels);
for k=find(sum(u))
    temp = conv2(u(:,k), w(:,:,k));
    y = y + temp(m+(1:T),:);
end
end

