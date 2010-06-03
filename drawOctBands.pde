class OCTDisplay {
  float displayWidth, displayHeight, xOffset, yOffset, barStep;

  OCTDisplay(float _dw, float _dh, float _xo, float _yo) {
    displayWidth = _dw;
    displayHeight = _dh;
    xOffset = _xo;
    yOffset = _yo;
    barStep = displayWidth/oct.nAverages;
  }
  
  void render() {
    strokeWeight(2);
    stroke(55);
    noFill();
    rect(xOffset-1, yOffset-1, displayWidth+1, displayHeight+1);
    noStroke();
    fill(255);
    for (int i=0; i<oct.nAverages; i++) {
      float x = xOffset + (float)(i) * barStep;
      float y = yOffset+displayHeight;
      rect(x, y, barStep-1, constrain(-oct.averages[i] * displayHeight, -displayHeight, 0));
      text(i, x, y+10);
      text(oct.averages[i], x, y+20);
    }  
  }
}
