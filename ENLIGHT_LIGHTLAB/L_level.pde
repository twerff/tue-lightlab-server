///Maybe I should change the sender address to code the level to address in there...
// now only one level is in the luminaire and is changed

public class LVL
{
  private Luminaire parent;
  private int level;
  private String name;
  private boolean on = true;

  private int dimLevel      = 60000;
  private int ct            = 4000;
  private int timeOut       = 300;
  private int fadeTime      = 20;
  private int colorFadeTime = 10;

  public LVL(Luminaire p, int l)
  {
    level = l;
    parent = p;
  }
  
  public LVL(Luminaire p, int l, String n)
  {
    level = l;
    parent = p;
    name = n;
    
    if (l == 1) timeOut = 10000;
  }
  
  public int getFadeTime()
  {
    return fadeTime;
  }
  
  public int getColorFadeTime()
  {
    return colorFadeTime;
  }
 
  public String getName()
  {
    return name;
  }
  
  public void setName(String value)
  {
    name = value;
  }
  //set
  //get
  //save (put?)
  //update
  
  public void activate(boolean onoff)
  {
    on = onoff;
    int i = 0;
    if (on) i = getDimLevel();
    
    ENLIGHT.createMessage("DimLevelChanged", ADDRESS_PC, parent.getAddress(), i);
  }
  
  public int getLevel()
  {
    return level;
  }
  
  public void toggle()
  {
    on = !getOn();
    activate(on);
  }
  
  public int getLLE()
  {
    return 1;
  }
  
  public boolean getOn()
  {
    return on;
  }
  
  public int getTimeOut()
  {
    return timeOut;
  }
  
  public void setTimeOut(int value)
  {
    timeOut = value;
    traceln("not sent yet");
  }
  
  //////DIMLEVEL////////////////////////////////////////////////////////////  
  public void setDimLevel(int value)
  {
    saveDimLevel(value);
    ENLIGHT.createMessage("DimLevelChanged", ADDRESS_LVL+level, parent.getAddress(), getDimLevel());
  }
  
  public int getDimLevel()
  {
    return dimLevel;
  }
  
  public void saveDimLevel(int value)
  {
    int minDimLevel = parent.getMinDimLevel();
    int maxDimLevel = parent.getMaxDimLevel();
    
    if (value < minDimLevel || value >  maxDimLevel)
    {
      traceln("A DimLevel of "+ value + "on luminaire " + getName() + " on level " + level + " is not possible. Choose between " + minDimLevel + " and " +  maxDimLevel);
    }
    
    dimLevel = constrain(value, minDimLevel, maxDimLevel);
  }
  
  public void updateDimLevel(int value)
  {
    value += getDimLevel();
    setDimLevel(value);
  }
  
  //////CT////////////////////////////////////////////////////////////
  public void setCT(int value)
  {        
    saveCT(value);
    ENLIGHT.createMessage("timeUpdated", ADDRESS_PC, parent.getAddress(), getCT());
  }
  
  public int getCT()
  {
    return ct;
  }
  
  public void saveCT(int value)
  { 
    int minCT = parent.getMinCT();
    int maxCT = parent.getMaxCT();
    
    if (value < minCT || value > maxCT)
    {
      traceln("A CT of "+ value + " Kelvin on luminaire " + getName() + " is not possible. Choose between " + minCT + " and " + maxCT);
    }
    ct = constrain(value, minCT, maxCT);
  }
  
  public void updateCT(int value)
  {    
    int newCT = getCT() + value;
    setCT(newCT);
  }
  
  //////RGB/////////////////////////////////////////  
  public void setRGB(int r, int g, int b)
  {
    //c = color(r,g,b);
    //createMessage("sceneSelected", "01:02:03:04:05:06:07:00", ADDRESS_PC, r, g, b);
  }
  
  public void setRGB(float r, float g, float b)
  {
    setRGB(int(r), int(g), int(b));
  }
  
  //public color getColor()
  //{
    //return c;
  //}
}
