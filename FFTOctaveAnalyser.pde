// FFTOctaveAnalyzer.pde
// Dave Bollinger Mar 2007
// http://www.davebollinger.com
// a "helper" for the collection of octave-based bands of fft averages

// this is intentionally not compiled into a library so that:
//   1) is doesn't have to import ESS or Sonia, potentially breaking if they're revised
//   2) doesn't have to be ESS- or Sonia-specific (it was designed for ESS, but could work with Sonia)
// so to use:   just add the .pde to your sketch


public class FFTOctaveAnalyzer {
  public FFT fft;  // a reference to the FFT instance
  public float samplingRate; // sampling rate in Hz (needed to calculate frequency spans)
  public int nSpectrum; // number of spectrum bins in the fft
  public int nAverages; // number of averaging bins here
  public int nAveragesPerOctave; // number of averages per octave as requested by user
  public float spectrumFrequencySpan; // the "width" of an fft spectrum bin in Hz
  public float firstOctaveFrequency; // the "top" of the first averaging bin here in Hz
  public float averageFrequencyIncrement; // the root-of-two multiplier between averaging bin frequencies
  public float [] averages; // the actual averages
  public float [] peaks; // peaks of the averages, aka "maxAverages" in other implementations
  public int [] peakHoldTimes; // how long to hold THIS peak meter?  decay if == 0
  public int peakHoldTime; // how long do we hold peaks? (in fft frames)
  public float peakDecayRate; // how quickly the peaks decay:  0f=instantly .. 1f=not at all
  public int [] spe2avg; // the mapping between spectrum[] indices and averages[] indices
  // the fft's log equalizer() is no longer of any use (it would be nonsense to log scale
  // the spectrum values into log-sized average bins) so here's a quick-and-dirty linear
  // equalizer instead:
  public float linearEQSlope; // the rate of linear eq
  public float linearEQIntercept; // the base linear scaling used at the first averaging bin
  // the formula is:  spectrum[i] * (linearEQIntercept + i * linearEQSlope)
  // so.. note that clever use of it can also provide a "gain" control of sorts
  // (fe: set intercept to 2f and slope to 0f to double gain)
  public FFTOctaveAnalyzer(FFT fft, float samplingRate, int nAveragesPerOctave) {
    this.fft = fft;
    this.samplingRate = samplingRate;
    this.nSpectrum = fft.spectrum.length;
    this.spectrumFrequencySpan = (samplingRate / 2f) / (float)(nSpectrum);
    this.nAverages = fft.averages.length;
    // fe:  2f for octave bands, sqrt(2) for half-octave bands, cuberoot(2) for third-octave bands, etc
    if (nAveragesPerOctave==0) // um, wtf?
      nAveragesPerOctave = 1;
    this.nAveragesPerOctave = nAveragesPerOctave;
    this.averageFrequencyIncrement = pow(2f, 1f/(float)(nAveragesPerOctave));
    // this isn't currently configurable (used once here then no effect), but here's some reasoning:
    // 43 is a good value if you want to approximate "computer" octaves: 44100/2/2/2/2/2/2/2/2/2/2
    // 55 is a good value if you'd rather approximate A-440 octaves: 440/2/2/2
    // 65 is a good value if you'd rather approximate "middle-C" octaves:  ~262/2/2
    // you could easily double it if you felt the lowest band was just rumble noise (as it probably is)
    // but don't go much smaller unless you have a huge fft window size (see below for more why)
    // keep in mind, if you change it, that the number of actual bands may change +/-1, and
    // for some values, the last averaging band may not be very useful (may extend above nyquist)
    this.firstOctaveFrequency = 55f;
    // for each spectrum[] bin, calculate the mapping into the appropriate average[] bin.
    // this gives us roughly log-sized averaging bins, subject to how "fine" the spectrum bins are.
    // with more spectrum bins, you can better map into the averaging bins (especially at low
    // frequencies) or use more averaging bins per octave.  with an fft window size of 2048,
    // sampling rate of 44100, and first octave around 55, that's about enough to do half-octave
    // analysis.  if you don't have enough spectrum bins to map adequately into averaging bins
    // at the requested number per octave then you'll end up with "empty" averaging bins, where
    // there is no spectrum available to map into it.  (so... if you have "nonreactive" averages,
    // either increase fft buffer size, or decrease number of averages per octave, etc)
    spe2avg = new int[nSpectrum];
    int avgidx = 0;
    float averageFreq = firstOctaveFrequency; // the "top" of the first averaging bin
    // we're looking for the "top" of the first spectrum bin, and i'm just sort of
    // guessing that this is where it is (or possibly spectrumFrequencySpan/2?)
    // ... either way it's probably close enough for these purposes
    float spectrumFreq = spectrumFrequencySpan;
    for (int speidx=0; speidx < nSpectrum; speidx++) {
      while (spectrumFreq > averageFreq) {
        avgidx++;
        averageFreq *= averageFrequencyIncrement;
      }
      spe2avg[speidx] = avgidx;
      spectrumFreq += spectrumFrequencySpan;
    }
    this.nAverages = avgidx;
    this.averages = new float[nAverages];
    this.peaks = new float[nAverages];
    this.peakHoldTimes = new int[nAverages];
    this.peakHoldTime = 0; // arbitrary
    this.peakDecayRate = 0.9f; // arbitrary
    this.linearEQIntercept = 1f; // unity -- no eq by default
    this.linearEQSlope = 0f; // unity -- no eq by default
  }
  /**
  * call calculate() after fft.getSpectrum() (for example in audioInputData())
  */
  public void calculate() {
    int last_avgidx = 0; // tracks when we've crossed into a new averaging bin, so store current average
    float sum = 0f; // running total of spectrum data
    int count = 0; // count of spectrums accumulated (for averaging)
    for (int speidx=0; speidx < nSpectrum; speidx++) {
      count++;
      sum += fft.spectrum[speidx] * (linearEQIntercept + (float)(speidx) * linearEQSlope);
      int avgidx = spe2avg[speidx];
      if (avgidx != last_avgidx) {
        averages[last_avgidx] = sum / (float)(count);
        count = 0;
        sum = 0f;
      }
      last_avgidx = avgidx;
    }
    // the last average was probably not calculated...
    if ((count > 0) && (last_avgidx < nAverages))
      averages[last_avgidx] = sum / (float)(count);
    // update the peaks separately
    for (int i=0; i < nAverages; i++) {
      if (averages[i] >= peaks[i]) {
        // save new peak level, also reset the hold timer
        peaks[i] = averages[i];
        peakHoldTimes[i] = peakHoldTime;
      } else {
        // current average does not exceed peak, so hold or decay the peak
        if (peakHoldTimes[i] > 0) {
          peakHoldTimes[i]--;
        } else {
          peaks[i] *= peakDecayRate;
        }
      }
    }
  }
}

