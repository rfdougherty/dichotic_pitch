function dp = dichoticPitch(sbr, peak, width, tsSig, tsBack, sampSec, duration)
% dp = dichoticPitch(sbr, peak, width, tsSig, tsBack, [sampSec], [duration])
%	returns an n x 2 stereo sound (no low-pass filter & not normalized)
%
%	* sbr: signal-to-background ratio (<=1 is true dichotic pitch)
%	* peak and width are in Hertz (pass equal-length vectors to get
%		multiple simultaneous pitches)
%	* signal and background time shifts (tsSig and tsBack) are in
%	  milliseconds (.6 to .8 ms is about optimal)
%	* sampSec is the sample rate (i.e., samples per second)- defaults to 8192
%	* duration is in seconds- defaults to .5
%
% Note: This algorithm starts with 2 independant noise sources, applies
% filters and time shifts, and then sums the processed noises.  However,
% the same result can be achieved more efficiently by starting with just one
% noise and tweaking some of its phases in just the right way.  I think
% the algorithm presented here most clearly illustrates the basic idea, 
% but it would be nice to have the more eficient version.  If anyone 
% writes it, ket me know!
%
% copyright 1999
% Robert F. Dougherty (bobd@stanford.edu)
% http://www.stanford.edu/~bobd

% Notes:
% 99.11.05 RFD: fixed a bug in the renormalization section.
%               fftshift _does not_ work like fft when applied
%               to matrices.  fft does 1-d ffts on each column
%               (2d ffts require fft2).  However, fftshift, when
%               applied to a matrix, swaps quadrants (ie. assumes
%               a 2d fft).  Anyway, this introduced a bug that
%               added some noise to DPs requiring renorm- sbrs<1.


if nargin<5 | nargin>7
	error('usage: dp = dichoticPitch(sbr, peak, fwhm, tsSig, tsBack, [sampSec], [duration])')
end
if nargin<6
	sampSec = 8192;
end
if nargin<7
	duration = 0.5;
end

if sbr<0
   error('SBR must be >= 0!');
end

numPeaks = length(peak);
fNyquist = sampSec/2;

% Take n up to the next power of 2 (to speed DFT)
%n = 2^ceil(log2(duration*sampSec));
% n must at least be even:
n = round(duration*sampSec);
n = n+mod(n,2);

%
% Create pseudo-noise
% (all components have equal amplitude and random phases)
%
amp = sqrt(n);
phase = rand(n/2-1,1)*2*pi-pi;
% Remember:
%	z = amp * exp(i*phase)
%	amp = abs(z)
%	phase = angle(z);

% phase of negative freqs = -phase of positive freqs
sigPhase = [0; phase; 0; -flipud(phase)];

% the background is independant- so we need another set of random phases
phase = rand(n/2-1,1)*2*pi-pi;	
backPhase = [0; phase; 0; -flipud(phase)];

% Combine amplitude and phase into the imaginary representation
sig = amp .* exp(i*sigPhase);
back = amp .* exp(i*backPhase);
clear phase sigPhase backPhase amp;

%
% Create signal and background filters
%
% give 'em all the same rectangular bandpass filter (we'll 
% appropriately scale each one later)
sigFilter = multiBandpass(n, (peak-width./2)./fNyquist, (peak+width./2)./fNyquist)';
backFilter = sigFilter;
renormFilter = sigFilter;

% sigFilter gets scaled by the sbr
sigFilter = sigFilter .* sbr;

% backFilter is 1-sigFilter if sig <1, 0 otherwise
backFilter = backFilter .* max((1-sbr-1),-1) + 1; 

% We need to renormalize the signal region by up to a factor of root 2
% to account for the decrease in amplitude caused by adding independant
% noise sources.  (but only if the sbr is <1)
% for independant noise sources N1 and N2:
% a1*N1 + a2*N2 = N3
% the average amplitude of N3 will be:
% a3 = (sqrt((a1^2 + a2^2) / (a1+a2)^2))
% to renormalize, we mutiply by 1/a3
if sbr<1
   renorm = 1/sqrt(sbr.^2+(1-sbr).^2);
   renormFilter = renormFilter .* (renorm - 1) + 1;
else
   renormFilter = [];
end

%
% Take signal and background into time domain
%
sig = real(ifft(ifftshift(sigFilter .* fftshift(sig))));
back = real(ifft(ifftshift(backFilter .* fftshift(back))));
clear sigFilter backFilter;

%
% Create the two channels for dichotic pitch
%
dp = zeros(n,2);

% The first stereo channel is just the sum of sig and back
dp(:,1) = (sig+back);

% Apply time shifts- the other channel is the sum of the time-shifted versions
sig = shift(sig', round(tsSig/1000*sampSec))';	
back = shift(back', round(tsBack/1000*sampSec))';
dp(:,2) = sig+back;
clear sig back;

%
% Apply renormalization filter (if necessary)
%
if ~isempty(renormFilter)
   ft = fftshift(fft(dp(:,1)));
   dp(:,1) = real(ifft(ifftshift(ft .* renormFilter)));
   ft = fftshift(fft(dp(:,2)));
   dp(:,2) = real(ifft(ifftshift(ft .* renormFilter)));
end
