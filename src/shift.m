function x = shift(x, d)
% x = shift(x, d) shifts the row vector x by d units (with wrap around)
%

% copyright 1999
% Robert F. Dougherty (bobd@stanford.edu)
% http://www.stanford.edu/~bobd

if nargin~=2
	error('Usage: x = shift(x, d)')
end

[m,n] = size(x);
if m>1	
	error('x must be a row vector')
end
if n<d	
	error('length of x must be > or = d')
end

if d==0 return; end

temp = zeros(1,d);
if d < 0
	d = abs(d);
	temp = x(1:d);
	x(1:n-d) = x(d+1:n);
	x(n-d+1:n) = temp;
else
	temp = x(n-d+1:n);
	x(d+1:n) = x(1:n-d);
	x(1:d) = temp;
end

