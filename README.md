# Dichotic Pitch Generator

Matlab/Octave code to generate dichotic pitch stimuli. 

To quickly hear some demos, grab your headphones and checkout the demos directory. See below for a brief introduction to the phenomenon.

## Background

Our two eyes get slightly different views of the world and these two different vantage points allow the brain to compute the distance of objects based on retinal disparity- the difference in image location in one retina relative to the other. This ability is called stereopsis.

Like our eyes, our two ears receive slightly different versions of the soundscape and our brain can exploit this interaural difference to localize and segregate sound sources. Sounds originating on the left reach the left ear first and are louder in the left ear than the right. In addition, as the sound source continues to produce sound waves, each crest of these waves will arrive at the left ear before the right ear. If these sound waves include frequencies whose wavelength is greater than the distance between the ears (i.e. below about 1400 Hz), then the brain can utilize the interaural time difference between crests.

This ongoing interaural time difference (ITD) can be exploited to create dichotic pitch. This is possible because the brain uses the ongoing ITD to segregate sounds produced by different sources as well as to help localize sounds in 3-dimensional space. (See my page on spatial hearing for more about interaural cues to sound source localization.)

Dichotic pitch is a perception of pitch that is extracted by the brain from two noise sequences, neither of which alone contain any cues to pitch. This perceived pitch may be localized to a different spatial location than the background noise, which is heard along with the pitch.

### Traditional dichotic pitch algorithm

Creating a dichotic pitch stimulus begins with two identical copies of white noise. If played through headphones, the brain will detect that the fine time structure of the noise in each ear is the same and will fuse the two noises into one perceived sound source. To the listener, this will sound like a "ball of noise" in the middle of the head. If the phases of a narrow band of frequencies, say 490 to 510 Hertz, are inverted in the noise signal going to one ear, that interaural phase-inverted frequency band will perceptually segregate from the ball of noise, and a faint but distinct pitch will be heard along with the noise ([Bilsen, 1976](https://pubmed.ncbi.nlm.nih.gov/1249333/); [Cramer & Huggins, 1958](https://asa.scitation.org/doi/10.1121/1.1909628)). For this example, the pitch will sound something like the pitch heard when a 500 Hz tone is played, since it is a narrow band of noise centered on 500 Hz that is segregated from the background noise. A slight variant on this technique, which produces similar pitch sensations, involves an interaural phase-inversion of all the frequency components in the noise except those in a narrow frequency band. Another variant involves "sparse noise" composed of only a dozen or so frequency components, one of which is phase inverted ([Kubovy, Cutting & McGuire, 1974](https://pubmed.ncbi.nlm.nih.gov/4413641/)).

### Filter-based dichotic pitch algorithm

In 1998, my colleagues and I created an alternative technique involving complementary filters and time shifts to produce a more effective and useful dichotic pitch stimulus ([Dougherty et. al., 1998](https://pubmed.ncbi.nlm.nih.gov/9804305/)). For a pure tone, a given phase shift is equivalent to a particular time shift. But, for a sound containing a range of frequencies, a constant phase shift will produce a slightly different time shift for each frequency component. A constant interaural phase shift smears the frequency band in time, which has the effect of smearing the spatial localization of the sound source. The stimuli produced by our algorithm are more similar to real localized sound sources than phase-shift based dichotic pitch stimuli because frequency components of real localized complex sounds have constant time shifts rather than constant phase shifts.

The time-shift dichotic pitch stimulus generation algorithm allows adjustment of the dichotic pitch signal strength through the signal-to-background ratio (SBR) parameter. The SBR can be adjusted from 0 (no signal present) to 1 (full dichotic pitch signal) by changing the height of the signal filter, with a corresponding change in the depth of the complementary background filter. In fact, the SBR can be set greater than 1 to produce cues to pitch that are monaurally detectable (i.e. peaks in the amplitude spectra). The adjustable SBR of this stimulus is very useful for assessing individual listener's sensitivities to dichotic pitch. The monaurally audible SBR levels are necessary because some listeners may be completely insensitive to true dichotic pitch (just as some lack stereopsis). With the time-shift stimulus, however, such listeners may still have a measurable pitch detection threshold; their threshold SBR will simply be above the true dichotic pitch cut-off of one.

