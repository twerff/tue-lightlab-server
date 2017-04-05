//variables for updating
int drawInterval = 25;
long lastDraw = 0;

void settings()
{
  size(800,600);
  smooth();
}

void setup()
{
  setupEnlight("COM4");
  setupDMX("COM8");
  setupHue("192.168.1.137");
  
  setupLuminaires();
  setupCoves(5);
  createXML(getClass().getSimpleName() + ".xml");
  setupOSC();

  traceln("Setup completed");
  mousePressed();
  
  
}

void draw()
{
  if (enlightEnabled) ENLIGHT.draw();
  if (timeToDraw())   drawGrid();
}

long lastSend;
int sendInterval = 2000;
boolean on = false;

boolean timeToDraw()
{
  if (millis()-lastDraw > drawInterval)
  {
    lastDraw = millis();
    return true;
  }
  return false;
}

void exit()
{
  if (enlightEnabled) enlighPort.stop();
}