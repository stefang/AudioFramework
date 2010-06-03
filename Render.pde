void setupRender() {
  size(680,800); // Set to whatever you want this to be
  noStroke();
  smooth();
  // You can remove these two when you have your own renderers, used by the OctBands renderer
  PFont fontA = loadFont("myPixel.vlw"); 
  textFont(fontA, 8);
}

void render() {
  background(0);
  // You can remove these when you have your own renderers
  mySAMDisplay.render();
  myFFTDisplay.render();
  myOCTDisplay.render();
}
