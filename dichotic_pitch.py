import numpy as np
import wave


def lowpass(x, f_max):
    """
    Simple lowpass filter.
    
    Parameters:
    -----------
    x : ndarray
        Input signal. If x is 2D, the filter is applied to each column.
    f_max : float
        Upper frequency bound (0 to 1, where 1 = Nyquist frequency)
    
    Returns:
    --------
    ndarray
        Filtered signal
    """
    if not isinstance(x, np.ndarray):
        x = np.array(x)
    
    # Get dimensions
    if x.ndim == 1:
        n = len(x)
        x = x.reshape(-1, 1)
    else:
        n, num = x.shape
    
    # Create the filter (assuming multi_bandpass is defined elsewhere)
    filter_response = multi_bandpass(n, 0, f_max)
    filter_matrix = np.tile(filter_response[:, np.newaxis], (1, x.shape[1]))
    
    # Apply FFT, filter, and inverse FFT
    ft = np.fft.fftshift(np.fft.fft(x, axis=0))
    filtered = filter_matrix * ft
    out = np.real(np.fft.ifft(np.fft.ifftshift(filtered), axis=0))
    
    # Return 1D array if input was 1D
    if out.shape[1] == 1:
        out = out.flatten()
    
    return out


def cos_window(x, num_atten):
    """
    Windows signal by a raised cosine.
    
    Parameters:
    -----------
    x : array_like
        Input signal. If 2D, each column is windowed separately.
    num_atten : int
        Number of values at the beginning and end of x to attenuate with the window.
        
    Returns:
    --------
    x : ndarray
        Windowed signal
    """
    if num_atten < 1:
        return x
    
    n, num = x.shape
    
    if n < num_atten:
        raise ValueError('Length of x must be greater than or equal to num_atten')
    
    # Create raised cosine window
    wind = 0.5 * np.cos(np.linspace(np.pi, 2*np.pi, num_atten)) + 0.5
    
    # Apply window to beginning and end of each column
    x[:num_atten] *= wind.reshape(-1, 1)
    x[-num_atten:] *= wind[::-1].reshape(-1, 1)
    
    return x.squeeze()

def multi_bandpass(n, low_freqs, high_freqs):
    """Create multiple bandpass filters"""
    # Create frequency array
    freqs = np.fft.rfftfreq(n)
    filt = np.zeros(n//2 + 1)
    
    # Convert input to arrays if they're not already
    low_freqs = np.atleast_1d(low_freqs)
    high_freqs = np.atleast_1d(high_freqs)
    
    # Create rectangular bandpass filter
    for low, high in zip(low_freqs, high_freqs):
        filt += np.where((abs(freqs) >= low) & (abs(freqs) <= high), 1, 0)
    
    return filt


def dichotic_pitch(sbr, peak, width, ts_sig, ts_back, samp_sec, duration):
    """
    Generate dichotic pitch stimulus
    
    Parameters:
    -----------
    sbr : float
        Signal-to-background ratio (<=1 is true dichotic pitch)
    peak : float or array-like
        Peak frequencies in Hz
    width : float or array-like
        Width of the frequency bands in Hz
    ts_sig : float
        Signal time shift in milliseconds
    ts_back : float
        Background time shift in milliseconds
    samp_sec : int, optional
        Sampling rate in Hz (default: 8192)
    duration : float, optional
        Duration in seconds (default: 0.5)
    
    Returns:
    --------
    tuple : (numpy.ndarray, int)
        Stereo audio signal and sampling rate
    """
    if sbr < 0:
        raise ValueError('SBR must be >= 0!')

    peak = np.atleast_1d(peak)
    width = np.atleast_1d(width)
    f_nyquist = samp_sec / 2

    # Calculate number of samples
    n = round(duration * samp_sec)
    n += n % 2  # ensure n is even

    # Create pseudo-noise in the frequency domain.
    # Amplitude is the square root of the number of samples.
    amp = np.sqrt(n)

    # Create pink noise in the frequency domain by applying 1/f filter
    freqs = np.fft.rfftfreq(n)[1:]  # Exclude DC component
    pink_filter = 1 / np.sqrt(freqs)  # 1/sqrt(f) for amplitude (1/f for power)
    
    # Generate random phases with pink noise amplitude spectrum
    sig = amp * np.exp(1j * np.concatenate([[0], np.random.rand(n//2) * 2 * np.pi - np.pi]))
    back = amp * np.exp(1j * np.concatenate([[0], np.random.rand(n//2) * 2 * np.pi - np.pi]))
    
    # Apply pink noise filter
    sig[1:] *= pink_filter
    back[1:] *= pink_filter

    # Create filters
    sig_filter = multi_bandpass(n, (peak-width / 2) / f_nyquist, (peak+width / 2) / f_nyquist)
    back_filter = sig_filter.copy() 

    # Scale filters
    sig_filter = sig_filter * sbr
    back_filter = back_filter * np.max([1 - sbr - 1, -1]) + 1

    # If sbr <1 then we need to renormalize the signal region by up to a factor of root 2 
    # to account for the decrease in amplitude caused by adding independant noise sources.  
    # For independant noise sources N1 and N2:
    #     a1*N1 + a2*N2 = N3
    # the average amplitude of N3 will be:
    #     a3 = (sqrt((a1^2 + a2^2) / (a1+a2)^2))
    # to renormalize, we mutiply by 1/a3
    if sbr < 1:
        renorm = 1 / np.sqrt(sbr**2 + (1-sbr)**2)
        renorm_filter = sig_filter.copy() * (renorm - 1) + 1
    else:
        renorm_filter = None

    # Transform to time domain
    sig = np.real(np.fft.irfft(sig_filter * sig, n))
    back = np.real(np.fft.irfft(back_filter * back, n))

    # Create stereo channels
    dp = np.zeros((n, 2))

    # Left channel is just sig + back
    dp[:, 0] = sig + back

    # Right channel is same but with time shifts
    sig = np.roll(sig, round(ts_sig/1000 * samp_sec))
    back = np.roll(back, round(ts_back/1000 * samp_sec))
    dp[:, 1] = sig + back

    # Apply renormalization if necessary
    if renorm_filter is not None:
        for ch in range(2): 
            dp[:, ch] = np.real(np.fft.irfft(np.fft.rfft(dp[:, ch]) * renorm_filter, n))

    # Normalize to prevent clipping
    dp = dp / np.max(np.abs(dp))

    return dp


def save_audio(signal, sample_rate, filename):
    """
    Save the audio signal to a WAV file
    
    Parameters:
    -----------
    signal : numpy.ndarray
        Stereo audio signal
    sample_rate : int
        Sampling rate in Hz
    filename : str
        Output filename (should end in .wav)
    """
    # Convert to 16-bit PCM
    signal = (signal * 32767).astype(np.int16)
    
    # Create WAV file
    with wave.open(filename, 'wb') as wav_file:
        wav_file.setnchannels(2)  # Stereo
        wav_file.setsampwidth(2)  # 2 bytes per sample
        wav_file.setframerate(sample_rate)
        wav_file.writeframes(signal.tobytes())


# Example usage
if __name__ == "__main__":
    # Example parameters
    sbr = 2.0  # signal-to-background ratio
    peak = 440  # frequency in Hz
    width = 50  # bandwidth in Hz
    ts_sig = 0.7  # signal time shift in ms
    ts_back = -0.7  # background time shift in ms
    
    # Generate dichotic pitch
    audio_signal, sample_rate = dichotic_pitch(
        sbr=sbr,
        peak=peak,
        width=width,
        ts_sig=ts_sig,
        ts_back=ts_back,
        samp_sec=44100,  # CD quality
        duration=1.0
    )
    
    # Save to file
    save_audio(audio_signal, sample_rate, "dichotic_pitch.wav") 