function out = doBandpass(x, fMin, fMax)
% doBandpass(signal, fMin, fMax)  simple bandpass filter
% 
% fMin and fMax are 0 to 1, where 1 = fNyquist (i.e. pass in Hz/fNyquist)
% If x is a matrix, the same filter is applied to each column.
% pass band = [fLow,fHigh)
%
% See multiBandpass.m, which actually generates the frequency-domain filter 
% used here.

% copyright 1999
% Robert F. Dougherty (bobd@stanford.edu)
% http://www.stanford.edu/~bobd

if nargin~=3
	error('Usage: out = doBandpass(x, fMin, fMax)')
end

[n, num] = size(x);

% create the filter
filter = repmat(multiBandpass(n, 0, fMax)', 1, num);

ft = fftshift(fft(x));
out = real(ifft(ifftshift(filter.*ft)));

