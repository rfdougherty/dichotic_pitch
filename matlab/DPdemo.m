% This script demonstrates the dichotic pitch stimulus.
%
% See the function "dichoticPitch" for the algorithmic details
% of how I generate these stimuli.
%
% The first demo is a very simple DP stimulus- one note 
% time-shifted to lead one ear against background noise
% unshifted, so it appears the be in the middle.
%
% The second demo plays a sequence of dichotic pitches
% at decreasing signal-to-background ratios (sbr).
%
% The third demo is more complicated- it plays a melody
% composed of dichotic pitches at various time-shifts.
%
% copyright 1999
% Robert F. Dougherty (bobd@stanford.edu)
% http://www.stanford.edu/~bobd

% Common constants
sampSec = 11025;	% samples per second
fNyquist = sampSec/2;
fMax = 1200;	% lowpass filter cutoff

% Detect if we are running under Octave
octave = exist('OCTAVE_VERSION') ~= 0;

% 
% Simple Dichotic Pitch
%
sbr = 1;
peak = 500; 	% Hertz: center frequency of DP signal
width = peak/20;	% Hertz: width of rectangular DP signal filter
tsSig = -0.6; 	% milliseconds: time-shift of the signal
tsBack = 0.0; 	% milliseconds: time-shift of the background
noteDuration = 0.5;	% seconds

dp = dichoticPitch(sbr, peak, width, tsSig, tsBack, sampSec, noteDuration);

% lowpass filter 
dp = doBandpass(dp, 0, fMax/fNyquist);

% cosine window (10 ms)
dp = cosWindow(dp, round(sampSec/100));

% normalize 
dp = dp./max(max(abs(dp)));

if(~octave)
    % show power spectrum
    psd(dp(:,1), 256, sampSec);
    hold on; set(gca, 'ColorOrder', [0 .5 0]); set(gca, 'XLim', [0 fMax+100]);
    psd(dp(:,2), 256, sampSec);
    hold off;
end

% play and save
sound(dp, sampSec);
wavwrite(dp, sampSec, 'dp.wav');


%
% The effect of signal-to-background ratio
%
sbr = 10.^[log10(8):-.3:log(.5)];
disp(['The SBR levels: ' num2str(sbr,2)]);
peak = [300 600 900]; % play a harmonic complex
width = peak./20;
numNotes = length(sbr);
tsSig = 0.6;
tsBack = -0.6;
noteDuration = 0.3;

dp = [];
for ii=1:numNotes
   % build the sound vector
   % (the second call to dichoticPitch with the SBR set to 0 adds
   % a "blank" interval between the dichotic pitches.)
   dp = [dp; ...
    	dichoticPitch(sbr(ii), peak, width, tsSig, tsBack, sampSec, noteDuration); ...
    	dichoticPitch(0, peak, width, tsSig, tsBack, sampSec, noteDuration);];
end

% lowpass filter 
dp = doBandpass(dp, 0, fMax/fNyquist);

% cosine window (10 ms)
dp = cosWindow(dp, round(sampSec/100));

% normalize 
dp = dp./max(max(abs(dp)));

% play and save
sound(dp, sampSec);
wavwrite(dp, sampSec, 'dpSBR.wav');


%
% Dichotic Pitch melody
%
% here's the melody:
% (note 1 and then every odd-numbered note is a "blank" interval- no DP)
note(1).peak = 0;
note(1).tsSig = 0.6;
note(1).duration = 0.1;

note(2).peak = [300 600 900];
note(2).tsSig = 0.6;
note(2).duration = 0.3;

note(3) = note(1);

note(4).peak = [400 800];
note(4).tsSig = 0.6;
note(4).duration = 0.3;

note(5) = note(1); % another blank

note(6).peak = [300 600 900];
note(6).tsSig = 0.6;
note(6).duration = 0.3;

note(7) = note(1); % another blank

note(8).peak = [200 400 600 800];
note(8).tsSig = 0.6;
note(8).duration = 0.3;

note(9) = note(1); % another blank

numNotes = length(note);

% set parameters that are common to all notes
for ii=1:numNotes
   note(ii).sbr = 1;
   note(ii).width = note(ii).peak ./ 20;
   note(ii).tsBack = -0.6;
end

% build the sound vector
dp = [];
for ii=1:numNotes
   dp = [dp;dichoticPitch(note(ii).sbr, note(ii).peak, note(ii).width, ...
         note(ii).tsSig, note(ii).tsBack,	sampSec, note(ii).duration)];
end

% lowpass filter 
dp = doBandpass(dp, 0, fMax/fNyquist);

% cosine window (10 ms)
dp = cosWindow(dp, round(sampSec/100));

% normalize 
dp = dp./max(max(abs(dp)));

% play and save
sound(dp, sampSec);
wavwrite(dp, sampSec, 'dpMelody.wav')
