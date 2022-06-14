function x = cosWindow(x, numAtten)
% x = cosWindow(x, numAtten) windows by a raised cosine.
% numAtten specifies the number of values at the beginning and end of
% x to attenuate with the window.
% If x is a matrix, the same window is applied to each column.
%

% copyright 1999
% Robert F. Dougherty (bobd@stanford.edu)
% http://www.stanford.edu/~bobd

if nargin~=2
	error('Usage: out = cosWindow(x, numAtten)')
end

if numAtten<1 return; end	% do nothing

[n, num] = size(x);

if n < numAtten	
	error('length of x must be > or = numAtten')
end

wind = [0.5*cos([pi:pi/(numAtten-1):2*pi])+.5]';

for ii=1:num
	x(1:numAtten, ii) = x(1:numAtten, ii).*wind;
	x(n-numAtten+1:n, ii) = x(n-numAtten+1:n, ii).*flipud(wind);
end
