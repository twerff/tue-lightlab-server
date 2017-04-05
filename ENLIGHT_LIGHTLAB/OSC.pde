import oscP5.*;
import netP5.*;

OscP5 oscP5;
boolean OSCenabled = false;
int connectInterval = 4000;

final static int OSCPORT = 11000;

void setupOSC()
{
  oscP5 = new OscP5(this, OSCPORT);
  oscP5.properties().setRemoteAddress("127.0.0.1", OSCPORT );
  OSCenabled = true;
}

void oscEvent(OscMessage message)
{
  if (message.checkAddrPattern("/Enlight/connect"))
  {
    traceln("client connected");
  } else
  {
    int lampID = message.get(0).intValue() + 0;
    int numValues = message.get(1).intValue();
    
    //COVE
    if (lampID > 199)
    {
      lampID = int( lampID-200 );
      
      Cove l = getCove(lampID);

      if (message.checkAddrPattern("/Enlight/setOn"))
      {
        if (message.get(2).intValue() == 0) l.turnOff();
        else l.turnOn();
      }
      else if (message.checkAddrPattern("/Enlight/setDimLevel"))
      {
        int value = int( map(message.get(2).intValue(),0,65535,0,255) );
        l.setBrightness(value);
      }
      else if (message.checkAddrPattern("/Enlight/setCT"))
      {
         int value = message.get(2).intValue();
         color c = CTtoHEX(value);

         if (numValues > 1) l.setFadetimeInMS(message.get(3).intValue());
         l.setRGB(red(c),green(c),blue(c));
      }
      else if (message.checkAddrPattern("/Enlight/setRGB"))
      {
        int r = message.get(2).intValue();
        int g = message.get(3).intValue();
        int b = message.get(4).intValue();
        
        if (numValues > 3) l.setFadetimeInMS(message.get(5).intValue());
        l.setRGB(r, g, b);
      }
       
    }
    //HUE
    else if (lampID > 99) 
    {
      HueLamp l = _hueLamps.get(lampID-100);
      
      if (message.checkAddrPattern("/Enlight/setOn"))
      {
        if (message.get(2).intValue() == 0) l.turnOff();
        else l.turnOn();
      }
      else if (message.checkAddrPattern("/Enlight/setDimLevel"))
      {
        int value = int( map(message.get(2).intValue(),0,65535,0,255) );
        if (numValues > 1) l.setFadetimeInMS(message.get(3).intValue());
        l.setBrightness(value);
      }
      else if (message.checkAddrPattern("/Enlight/setBrightness"))
      {
         int value = message.get(2).intValue();
         if (numValues > 1) l.setFadetimeInMS(message.get(3).intValue());
         l.setBrightness(value);
      }
      else if (message.checkAddrPattern("/Enlight/setCT"))
      {
         int value = message.get(2).intValue();
         value = constrain(value,2000,6500);
         int ct = (int) map(value,2000,6500,500,154);
         
         if (numValues > 1) l.setFadetimeInMS(message.get(3).intValue());
         l.setCT(ct);
      }
      else if (message.checkAddrPattern("/Enlight/setRGB"))
      {
        int r = message.get(2).intValue();
        int g = message.get(3).intValue();
        int b = message.get(4).intValue();
        
        if (numValues > 3) l.setFadetimeInMS(message.get(5).intValue());
        l.setRGB(r, g, b);
        
      }
    }
    else
    {
      Luminaire l = _luminaires.get(lampID);

      if (message.checkAddrPattern("/Enlight/setOn"))
      {
        boolean onState = true;
        if (message.get(2).intValue() == 0) onState = false;
        l.setOn(onState);

        if (onState) traceln("turn on lamp " + lampID);
        else traceln("turn off lamp " + lampID);
      } 
      else if (message.checkAddrPattern("/Enlight/setCT"))
      {
        if (numValues == 1) l.setCT(message.get(2).intValue());
        else l.setCT(message.get(2).intValue(), message.get(3).intValue()/100);

        traceln("set "+ lampID + " to ct " + message.get(2).intValue());
      } else if (message.checkAddrPattern("/Enlight/setDimLevel"))
      {
        if (numValues == 1) l.setDimLevel(message.get(2).intValue());
        else l.setDimLevel(message.get(2).intValue(), message.get(3).intValue()/100);

        traceln("set "+ lampID + " to dimLevel " + message.get(2).intValue());
      } else if (message.checkAddrPattern("/Enlight/setRGB"))
      {
        if (numValues > 2)
        {
          int r = message.get(2).intValue();
          int g = message.get(3).intValue();
          int b = message.get(4).intValue();

          if (numValues == 3) l.setRGB(r, g, b);
          else l.setRGB(r, g, b, message.get(5).intValue());
        }
      } else traceln("unknown OSC message: " + message);
    }
  }
}