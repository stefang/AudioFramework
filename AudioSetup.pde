import krister.Ess.*;

AudioChannel chn;
FFT fft;
FFTOctaveAnalyzer oct;

int bufferSize;
int bufferDuration;
float level;

void setupAudio() {
   Ess.start(this);
   if (render) {
     chn = new AudioChannel(dataPath(audioFilename)); // render
   } else {
     chn = new AudioChannel(audioFilename); // playback
   }
  bufferSize=chn.buffer.length;
  bufferDuration=chn.ms(bufferSize);
  if (!render) chn.play(Ess.FOREVER); // playback
  fft=new FFT(512); // 512 bins is 256 freqency bands
  fft.limits();
  fft.damp(0.15f);
  fft.equalizer(false); // ESS has a built in corrector for the bass skew in FFT but I use the one in Dave's oct instead.
  oct = new FFTOctaveAnalyzer(fft, chn.sampleRate, 1);
  oct.peakHoldTime = 20; // hold longer
  oct.peakDecayRate = .15f; // decay slower
  oct.linearEQIntercept = 0.9f; // unity -- no eq by default
  oct.linearEQSlope = 0.03f; // unity -- no eq by default
}

void analyseAudio() {
   if (render) {
     fft.getSpectrum(chn.samples, (int)(frameNumber * chn.sampleRate / framesPerSecond)); // render
   } else {
     fft.getSpectrum(chn); // playback
   }
   oct.calculate();
   setLevel();
}

void setLevel() {
   // Can't get FFT level during render so have to fake it.
  if (render) {
    float avgLevel = 0;
    for (int i=0; i<oct.nAverages; i++) {
      avgLevel += oct.averages[i];
    }  
    level = avgLevel / oct.nAverages;
  } else {
    level = fft.getLevel(chn);
  }
}

public void stop() {
  Ess.stop();
  super.stop();
}

