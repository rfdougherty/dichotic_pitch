function w = multiBandpass(n, fLow, fHigh)
% w = multiBandpass(n, fLow, [fHigh]) returns a 1*n window in frequency space.
% 
% fLow and fHigh are cut-off frequencies on the scale -1 to 1. 
% (send in fLow/fNyquist and fHigh/fNyquist for real frequencies)
% Passes the interval [fLow,fHigh).
% fLow and fHigh may be equal-length vectors specifying multiple passbands.
% (fHigh defaults to Inf.)
%

% 99.01.18 RFD: adapted from code by Dennis Pelli.
%
% copyright 1999
% Robert F. Dougherty (bobd@stanford.edu)
% http://www.stanford.edu/~bobd

if nargin<2 | nargin>3
	error('Usage: w = multiBandpass(n, fLow, [fHigh])')
end
if nargin<3
	fHigh = Inf;
end;
if n<2 | n~=floor(n)
	error('First arg ''n'' must be an integer greater than 1')
end
if min(fLow)<0 | min(fHigh)<0
	error('Frequencies can''t be negative')
end

numBands = length(fLow);
if length(fHigh) ~= numBands
   error('length(fHigh) must be the same as length(fLow)!');
end

if rem(n,2)
	t = -1+1/n:2/n:1-1/n;
else
	t = -1:2/n:1-2/n;
end
t = abs(t);
w = zeros(size(t));

for i=1:numBands
	d = find(t>=fLow(i) & t<fHigh(i));	% find in-band frequencies
	if ~isempty(d)
		w(d) = ones(size(d));	% set unit gain at those frequencies
   end
end
