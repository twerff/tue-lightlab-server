import processing.serial.*;
Serial myPort;

void setupDMX(String portName)
{
  try
  {
    myPort = new Serial(this, portName, 115200);
  }
  catch(Exception e)
  {
  }
  
  traceln("DMX ready on " + portName);
}


public void setDMX(int channel, int v)
{
  int value = constrain(v,0,255);
  String message = ""+channel+"c"+value+"w";
  //traceln("DMX: " + message);
  myPort.write(message);
}