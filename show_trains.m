function show_trains(x, u, w)
% plot original signal x and superpose waveform trains u, w
spacing = 6*std(x(:));
number_of_trains = size(u,2);
colors = hsv(number_of_trains)*0.7+0.3;
ticks = 1:size(x,2);
for k=1:number_of_trains
    y = reconstruct(u(:,k), w(:,:,k));
    sig = sqrt(mean(mean(w(:,:,k).^2))+eps);
    y(abs(y)<sig) = nan;
    plot(bsxfun(@plus, y/spacing, ticks), ...
        'color', colors(k,:), 'linewidth', 3)
    hold on
end
plot(bsxfun(@plus, x/spacing, ticks), 'k', 'linewidth',.5)
set(gca, 'YTick', ticks)
hold off
grid on
drawnow
end