function show_trains(x0,u,w)
% illustrate the ongoing state of the algorithm
spacing = 6*std(x0(:));
number_of_trains = size(u,2);
colors = hsv(number_of_trains)*0.7+0.3;
for k=1:number_of_trains
    y = reconstruct(u(:,k), w(:,:,k));
    sig = sqrt(mean(mean(w(:,:,k).^2))+eps);
    y(abs(y)<sig) = nan;
    plot(bsxfun(@plus, y, spacing*(1:size(x0,2))), ...
        'color', colors(k,:), 'linewidth', 3)
    hold on
end
plot(bsxfun(@plus, x0, spacing*(1:size(x0,2))), 'k', 'linewidth',.5)
hold off
drawnow
end