class mPB extends Luminaire
{ 
  public mPB(String ad, float x, float y)
  {
    this.setAddress(ad);
    String[] n = split(ad,":");
    
    this.setName(n[n.length-2] + ":" + n[n.length-1]);
    
    this.setWidth (0.5);
    this.setHeight(0.5);
    this.setMinCT(2700);
    
    this.setPosition(new PVector(x,y));
    
    this.setPreviewSize(this.getWidth());
  }
  
  public void draw()
  {
    strokeWeight(3);
    stroke(255);
    if (!this.getSelected()) noStroke();
    updateTimers();
    
    //draw the border
    if(!getPresence()) fill(0);
    if(!getAnnounced()) fill(255,0,0);  //if not announce yet..
    rect( getX(), getY(), getWidth(), getHeight() );
    
    //fill the luminaire
    noStroke();
    int b = int( map(getDimLevel(), getMinDimLevel(), getMaxDimLevel(), 0, 255) );
    fill( getColor(), b);
    
    if(getPresence()) rect( getX(), getY(), getWidth(), getHeight() );
    //preview color
    else
    {
      fill(CTtoHEX(getCT()));
      rect(getX() ,getY(), getPreviewSize(), getPreviewSize() );
    }
    
    //draw the name + info
    if(detailEnabled)
    { 
      fill(0);
      text(getAddress().substring(18, 23), getX(), getY()-12);
      text(getShortAddress(), getX(), getY()-2);
      
      if (!presenceDetected && globalPresenceDetected) text("B",getX(),getY()+15);
    }
  }

}