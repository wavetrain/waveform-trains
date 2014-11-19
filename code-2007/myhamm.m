function y = myhamm( n )
% our own hamming kernel so we don't need the signal processing toolbox
x = -(n-1)/2:(n-1)/2';
y = 1.08+cos(2*pi*x/(n-1));
