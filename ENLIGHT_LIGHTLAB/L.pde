public class Luminaire extends Item
{
  public long lastUpdate;
  public long randomUpdate;
  
  private String address = "";
  private String shortAddress = "";
  private boolean dwars = false;
  private int scope = STUDIO;
  private String localAddress = "";
  
  private int dimLevel      = 35000;
  private int maxDimLevel   = 65535;
  private int minDimLevel   = 0;
  private boolean on = true;
  
  private boolean ctEnabled = true;
  private int ct            = 4000;
  private int minCT         = 1500;
  private int maxCT         = 10000;
  
  public boolean presenceDetected = false;
  public long presenceDetectedTime = 9999999;
  public int presenceTimeOut = 2000 * 60;
  
  public boolean globalPresenceDetected = false;
  public long globalPresenceDetectedTime = 99999;
  public int globalPresenceTimeOut = 3000 * 60;
  
  private boolean announced = false;
  private long announceTime = 0;
  private long annouceTimeOut = randomAnnounceDelay * 2000;
  
  private float previewSize = 0.5;
  private color c = color(CTtoHEX(ct));
  private int b = (int) map(dimLevel,minDimLevel, maxDimLevel,0,255);
  
  ArrayList<LVL> _levels = new ArrayList<LVL>();
  
  public Luminaire()
  {
    //lowest level first (the last created level overrules all)
    //addLevel("lvl_absence", getCT(), 35000);
    addLevel("lvl_work", getCT(), 35000);
  }
  
  public void addLevel(String name, int c, int dim)
  {
    LVL l = new LVL(this, _levels.size()+1, name);
    l.saveCT(c);
    l.saveDimLevel(dim);
    _levels.add(l);
  }

  public void setMinCT(int value)
  {
    minCT = value;
  }
  
  public int getNrOfLevels()
  {
    return _levels.size();
  }
  
  public int[] getLevels()
  {
    int[] lvl = {};
    
    for (int i = 0; i<getNrOfLevels(); i++)
    {
      lvl = append(lvl, i+1);
    }
    
    return lvl;
  }
  
  public LVL getLevel(int i)
  {
    if (i!=0) i--;
    return _levels.get(i);
  }
  
  public LVL getLevel(String i)
  {
    for (LVL l : _levels)
    {
      if (i.toUpperCase().equals( l.getName().toUpperCase() ) ) return l;
    }
    
    traceln("cant find level, returning the first");
    return _levels.get(0);
  }
  
  public void activateLevel(int level)
  {
    getLevel(level).activate(true);
  }
  
  public void deactivateLevel(int level)
  {
    getLevel(level).activate(false);
  }
  
  public void draw()
  {
  }
  
  public float getPreviewSize()
  {
    return previewSize;
  }
  
  public void setLocalAddress(String s)
  {
    localAddress = s;
  }
  
  public String getLocalAddress()
  {
    return localAddress;
  }
  
  public void setPreviewSize(float s)
  {
    previewSize = s;
  }
  
  public void updateTimers()
  {
    if (presenceDetected       && millis() - presenceDetectedTime > presenceTimeOut)             setPresence(false);
    //if (globalPresenceDetected && millis() - globalPresenceDetectedTime > globalPresenceTimeOut) setGlobalPresence(false);
    if (announced              && millis() - announceTime > annouceTimeOut*5)                      
    {
      println(getAddress() + " timed out");
      setAnnounced(false);
    }
  }
  
  public void setScope(int s)
  {
    scope = s;
  }
  
  public int getScope()
  {
    return scope;
  }
  
  boolean isCollidingCircleRectangle(
    float circleX,
    float circleY,
    float radius,
    float rectangleX,
    float rectangleY,
    float rectangleWidth,
    float rectangleHeight)
  {
    float circleDistanceX = abs(circleX - rectangleX - rectangleWidth/2);
    float circleDistanceY = abs(circleY - rectangleY - rectangleHeight/2);
 
    if (circleDistanceX > (rectangleWidth/2 + radius)) { return false; }
    if (circleDistanceY > (rectangleHeight/2 + radius)) { return false; }
 
    if (circleDistanceX <= (rectangleWidth/2)) { return true; }
    if (circleDistanceY <= (rectangleHeight/2)) { return true; }
 
    float cornerDistance_sq = pow(circleDistanceX - rectangleWidth/2, 2) + pow(circleDistanceY - rectangleHeight/2, 2);
 
    return (cornerDistance_sq <= pow(radius,2));
  }

  
  public void setNeighbours(int radius)
  {
    //draw a circle, everyone in the cirkel is a neighbour.
    fill(255,255,255,20);
    float circleX = this.getX() + this.getWidth()/2;
    float circleY = this.getY() + this.getHeight()/2;
    
    ellipse(circleX, circleY, radius*2, radius*2);
    
    for (Luminaire l : _luminaires(this.getScope()))
    {
      if (l != this)
      {
        float rectangleWidth = l.getWidth();
        float rectangleHeight = l.getHeight();
        float rectangleX = l.getX() + rectangleWidth/2;
        float rectangleY = l.getY() + rectangleHeight/2;
        
        if (isCollidingCircleRectangle(circleX, circleY, radius, rectangleX, rectangleY, rectangleWidth, rectangleHeight)) neighbours.add(l);
      }
    }
    //
//    for(int i = 0; i < getNumberOfLuminaires(); i++)
//    {
//      if (getLuminaire(i) != this && getLuminaire(i).getScope() == this.getScope())
//      {
//        float rectangleWidth = getLuminaire(i).getWidth();
//        float rectangleHeight = getLuminaire(i).getHeight();
//        float rectangleX = getLuminaire(i).getX() + rectangleWidth/2;
//        float rectangleY = getLuminaire(i).getY() + rectangleHeight/2;
//        
//        if (isCollidingCircleRectangle(circleX, circleY, radius, rectangleX, rectangleY, rectangleWidth, rectangleHeight)) neighbours.add(getLuminaire(i));
//      }
//    }
  }
  
  public Luminaire getNeighbour(int i)
  {
    return neighbours.get(i);
  }
  
  
  public void setGlobalPresence(boolean value)
  {
    globalPresenceDetected = value;
    if (value) globalPresenceDetectedTime = millis();
  }
  
  
  
  public void setDwars()
  {
    dwars = true;
    
    float w = getWidth() / TILE;
    float h = getHeight() / TILE;
    
    this.setHeight(w);
    this.setWidth(h);
  }
  
  public int getDwars()
  {
    if(dwars) return 1;
    return 0;
  }
  
  public long getLastAnnounce()
  {
    return announceTime;
  }
  
  public void setAnnounced(boolean a)
  {
    announced = a;
    if (a) announceTime = millis();
  }
  
  public boolean getAnnounced()
  {
    return announced;
  }
  
  public int getNrOfNeighbours()
  {
    return neighbours.size();
  }
  
  public void setPresence(boolean p)
  {
    if (presenceDetected != p)
    {
      presenceDetected = p;
    }
    
    if (presenceDetected) 
    {
      presenceDetectedTime = millis();
      //ENLIGHT.createMessage("presenceDetected", ADDRESS_LVL+"1", getAddress());
      //ENLIGHT.createMessage("presenceDetected", ADDRESS_LVL+"2", getAddress());
      
      setGlobalPresence(true);
    
      for(int i = 0; i < getNrOfNeighbours(); i++)
      {
        neighbours.get(i).setGlobalPresence(true);
      }
      
    }
  }
  
  public boolean getPresence()
  {
    return presenceDetected;
  }
  
  //////ADDRESSS//////////////////////////
  public void setAddress(String ad)
  {
    address = ad;
  }
  
  public String getAddress()
  {
    return address;
  }
  
  public void setShortAddress(String ad)
  {
    if ( !ad.contains("0x") ) shortAddress = "0x";
    shortAddress += ad;
  }
  
  public String getShortAddress()
  {
    //if (shortAddress.equals("") ) return "0xFFFD";
    return shortAddress;
  }
  
  
  //////////////
  public void update()
  {
    traceln("applying settings on lamp " + getAddress() + "only in log, not really");
    
    for (LVL l : _levels)
    {
      //update dimlevel & brightness
      //l.sendDimLevel(getDimLevel());
      //l.sendCT(getCT());
    }
    
    int c = getCT();
    
    saveCT(0);
    setCT(c);
  }
  ////////////
  
  //////DIMLEVEL////////////////////////////////////////////////////////////
  public float getBrightness()
  {
    float b = map(dimLevel, minDimLevel, maxDimLevel, 0, 1);
    b = constrain(b, 0, 1);
    return b;
  }
  
  public void setBrightness(float value)
  {
    value = constrain(value, 0, 1);
    int v = int( map(value, 0, 1, minDimLevel, maxDimLevel) );
    setDimLevel(v);
  }
  
  public boolean saveDimLevel(int value)
  {
    if (value == getDimLevel()) return true;
    
    if (value < getMinDimLevel() && getDimLevel() < getMinDimLevel() || value > getMaxDimLevel() && getDimLevel() > getMaxDimLevel())
    {
      traceln("A dimLevel of "+ value + " on luminaire " + getName() + " is not possible. Choose between " + getMinDimLevel() + " and " + getMaxDimLevel());
      dimLevel = value;
      return false;
    }
    
    dimLevel = value;
    return true;
  }
  
  public void updateDimLevel(int value)
  {
    value += getDimLevel();
    setDimLevel(value);
  }
  
  public void setDimLevel(int value)
  {
    if( saveDimLevel(value) ) //returns false if the the value is not new, or if the value is higher then max if it is already higher then max (or min)
    {      
      value = constrain(value, getMinDimLevel(), getMaxDimLevel());
      ENLIGHT.createMessage("DimLevelChanged", ADDRESS_PC, getAddress(), value);
    }
  }
    
  public int getDimLevel()
  {
    return dimLevel;
  }
  
  public int getMaxDimLevel()
  {
    return maxDimLevel;
  }
  
  public int getMinDimLevel()
  {
    return minDimLevel;
  }
  
  //////CT////////////////////////////////////////////////////////////
  public void disableCT()
  {
    ctEnabled = false;
  }

  public void saveCT(int value)
  { 
    if (value < getMinCT() || value > getMaxCT())  traceln("A CT of "+ value + " Kelvin on luminaire " + getName() + " is not possible. Choose between " + getMinCT() + " and " + getMaxCT());
    ct = value;
    //ct = constrain(value, minCT, maxCT);
  }
  
  public void updateCT(int value)
  {
    if(!ctEnabled) traceln("CT not possible for " + getName());
    
    int newCT = getCT() + value;
    setCT(newCT);
  }
  
  public int getCT()
  {
    if(!ctEnabled) return 0;
    return ct;
  }
  
  public void setCT(int value)
  {
    //if (getCT() != value) 
    //{
      saveCT(value);
      value = constrain(value, getMinCT(), getMaxCT());
      ENLIGHT.createMessage("ColorChangedCCT", ADDRESS_PC, getAddress(), value);
    //}
  }
  
  public int getMaxCT()
  {
    return maxCT;
  }
  
  public int getMinCT()
  {
    return minCT;
  }
  
//////RGB/////////////////////////////////////////  
  
  public void setRGB(int r, int g, int b)
  {
    ENLIGHT.createMessage("ColorChangedRGB", ADDRESS_PC, getAddress(), r,g,b);
  }
  
  public void setRGB(float r, float g, float b)
  {
    setRGB(int(r), int(g), int(b));
  }
  
  
  
  //////////////FADETIMES
  public void setCT(int value, int time)
  {
    ENLIGHT.createMessage("Event02", ADDRESS_PC, getAddress(), value, time);
  }
  
  public void setDimLevel(int value, int time)
  {
    ENLIGHT.createMessage("Event03", ADDRESS_PC, getAddress(), value, time);
  }
  
  public void setRGB(int r, int g, int b, int time)
  {
    ENLIGHT.createMessage("Event04", ADDRESS_PC, getAddress(), r,g,b, time);
  }
  
  
  public color getColor()
  {
    return c;
  }
  
  void toggle()
  {
    traceln("toggle");
    if (getOn()) setOn(false);
    else setOn(true);
  }
  
  public boolean getOn()
  {
    return on;
  }
  
  public void setOn(Boolean value)
  {
    on = value;
    int condition = value?1:0;
    ENLIGHT.createMessage("OnOffChanged", ADDRESS_PC, getAddress(), condition);
  }
}