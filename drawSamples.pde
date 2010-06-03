class SAMDisplay {
  // based on http://www.tree-axis.com/Ess/_examples/analysis/
  float displayWidth, displayHeight, xOffset, yOffset, step, left, right;

  SAMDisplay(float _dw, float _dh, float _xo, float _yo) {
    displayWidth = _dw;
    displayHeight = _dh;
    xOffset = _xo;
    yOffset = _yo;
    step = displayWidth / 255;
  }
  
  void render() {
    strokeWeight(2);
    stroke(55);
    noFill();
    rect(xOffset-1, yOffset-1, displayWidth+1, displayHeight+1);
    stroke(255);
      // interpolate between 0 and writeSamplesSize over writeUpdateTime
    if (!render) {
      // Doesn't work in render mode so no point showing it
      int interp=(int)max(0,(((millis()-chn.bufferStartTime)/(float)bufferDuration)*bufferSize));
      for (int i=0;i<255;i++) {
        left=yOffset;
        right=yOffset;
        if (i+interp+1<chn.buffer2.length) {
          left-=chn.buffer2[i+interp]*(displayHeight/2)-(displayHeight/2);
          right-=chn.buffer2[i+1+interp]*(displayHeight/2)-(displayHeight/2);
        }
        line((i*step)+xOffset,left,((i+1)*step)+xOffset,right);
      }
    } else {
      text("Doesn't work in render mode, not sure why!", xOffset*2, yOffset+displayHeight/2);
    }
  }
  
}
