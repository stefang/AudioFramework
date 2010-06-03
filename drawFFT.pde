class FFTDisplay {
  float displayWidth, displayHeight, xOffset, yOffset, xspan;

  FFTDisplay(float _dw, float _dh, float _xo, float _yo) {
    displayWidth = _dw;
    displayHeight = _dh;
    xOffset = _xo;
    yOffset = _yo;
    xspan = displayWidth / fft.spectrum.length;
  }
  
  void render() {
    strokeWeight(2);
    stroke(55);
    noFill();
    rect(xOffset-1, yOffset-1, displayWidth+1, displayHeight+1);
    stroke(255);
    for (int i=1; i<fft.spectrum.length; i++) {
      float temp=max(0,displayHeight-fft.spectrum[i]*displayHeight);
      float prev=max(0,displayHeight-fft.spectrum[i-1]*displayHeight);
      line(((i-1)*xspan)+xOffset,prev+yOffset,(i*xspan)+xOffset,temp+yOffset);
    }
  }
  
}
