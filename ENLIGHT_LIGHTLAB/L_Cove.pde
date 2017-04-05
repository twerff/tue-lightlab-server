ArrayList<Cove>_coves = new ArrayList<Cove>();

void setupCoves(int nrOfCoves)
{
  for (int i = 0; i<nrOfCoves; i++)
  {
    Cove c = new Cove(i*3);
    _coves.add(c);
  }
}

public Cove getCove(int id)
{
  return _coves.get(id);
}

class Cove extends Luminaire
{
  int startChannel;
  int start_rgb[] = {0,0,0};
  int target_rgb[] = {0,0,0};
  int rgb[] = {0,0,0};
  int brightness = 255;
  int fadeTime = 400;
  long startFadeTime;
  boolean on = true;
  
  public Cove(int channel)
  {
    startChannel = channel;
  }
  
  void draw()
  {
    if (!on)
    {
      for(int i = 0; i<3; i++) setDMX(startChannel+1+i,0); 
    }
    else if (millis() - startFadeTime < fadeTime)
    {
      int timeIntoFade = int( millis() - startFadeTime );
      
      for(int i = 0; i<3; i++)
      {
        rgb[i] = start_rgb[i] + (timeIntoFade * (target_rgb[i] - start_rgb[i])/fadeTime );
        setDMX(startChannel+1+i,rgb[i]);  
      }
    }
  }
  
  public void setBrightness(int value)
  {
    brightness = value;
    startFadeTime = millis();
  }
  
  public void setRGB(int r, int g, int b)
  {
    for(int i = 0; i<3; i++) start_rgb[i] = rgb[i];
    target_rgb[0] = int( r );
    target_rgb[1] = int( g );
    target_rgb[2] = int( b );
    
    startFadeTime = millis();
  }
  
  public void turnOn()
  {
    on = true;
  }
  
  public void turnOff()
  {
    on = false;
  }
  
  public void setFadetimeInMS(int t)
  {
    fadeTime = t;
  }
}