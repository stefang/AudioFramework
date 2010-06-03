// My basic starting point for playback and analysis of audio files for realtime visuals with a boolean switch to allow a render of image sequences.
//
// Requires the Krister ESS library -> http://www.tree-axis.com/Ess/ and is working in Processing 1.1 (Build 110)
//
// Make sure you amend the audioFilename variable below and make sure the file is in the data directory (to copy a file you can just drag and drop
// it onto this window "File Added" will appear in the grey status bar below when it's copied and apple+k will show this sketches directory
//
// To switch from realtime playback to rendering an image sequence edit the 'render' boolean to true under the AudioSetup tab
// The image sequence will appear in a directory in the sketch folder call 'out'
//
// The three renderers (drawFFT, drawOctBands, drawSamples) are just examples of how to read the different data ESS and the OCT classes
// output. You can delete them when you have your own renderers set up, don't forget to remove the lines below, in setup() and in render() 
// in the Render tab or Processing will have a hissy fit.
//
// Have fun! http://stefangoodchild.com/

String audioFilename = "your_audio_filename_here.aif"; // *Should* support AIFF, WAVE, AU, MP3 files according to the lib docs, never tried anything but aiffs though!

boolean render = false; //  Set to true to go into offline (non realtime) rendering mode
int frameNumber = 0; // Inits the offline render count
int framesPerSecond = 25; // Framerate for the image sequence PAL framerate is 25, 30 for NTSC, 24 for film

// You can remove these three when you have your own renderers in place
FFTDisplay myFFTDisplay;
OCTDisplay myOCTDisplay;
SAMDisplay mySAMDisplay;

void setup() {
  setupRender();
  setupAudio();
  
  // You can remove these three lines when you have your own renderers
  float margin = 64;
  mySAMDisplay = new SAMDisplay(width - margin * 2f, height/3 - margin, margin, margin);
  myFFTDisplay = new FFTDisplay(width - margin * 2f, height/3 - margin, margin, height/3+margin/2);
  myOCTDisplay = new OCTDisplay(width - margin * 2f, height/3 - margin, margin, height/3*2);
}

void draw() {
  analyseAudio();
  render();
  if (render) {
    saveFrame("out/img_"+nf(frameCount,6)+".tif"); // also supports .jpg if preferred
    advance();
  }
}

void advance() {
  // Only used during render phase
  frameNumber ++ ;
}
