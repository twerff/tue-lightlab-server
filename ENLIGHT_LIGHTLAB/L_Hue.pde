import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.client.methods.HttpPut;
import org.apache.http.impl.client.DefaultHttpClient;
import java.io.*;
import java.awt.*;
import java.lang.Object.*;
import java.util.Date;

final static String HUE_KEY = "yZDKj7UIc4-u4fcH-3fwBeEYGuCtq-5Hmz7EN9LS";
             String HUE_IP  = "192.168.1.137";
final static int NUM_HUE_LAMPS = 3;

ArrayList<HueLamp> _hueLamps = new ArrayList<HueLamp>();
HueHub hub;

void setupHue(String ip)
{
  HUE_IP = ip;
  
  hub = new HueHub();

  for (int i = 0; i < NUM_HUE_LAMPS; i++)
  {
    _hueLamps.add( new HueLamp(i+1, hub));
    //add the positions
  }

  _hueLamps.get(0).setPosition(1, 1);
  _hueLamps.get(1).setPosition(1, 2);
  _hueLamps.get(2).setPosition(1, 3);
  
  traceln("HUE ready at " + HUE_IP);
}

class HueHub 
{
  private static final String KEY = HUE_KEY; // "secret" key/hash
  private String IP = HUE_IP; // ip address of the hub
  private static final boolean ONLINE = true; // for debugging purposes, set to true to allow communication

  private DefaultHttpClient httpClient; // http client to send/receive data

  // constructor, init http
  public HueHub() 
  {
    httpClient = new DefaultHttpClient();
  }

  // apply the state for the passed hue light based on the values
  public void applyState(HueLamp light) 
  { 
    ByteArrayOutputStream baos = new ByteArrayOutputStream();
    try {
      // format url for specific light
      StringBuilder url = new StringBuilder("http://");
      url.append(IP);
      url.append("/api/");
      url.append(KEY);
      url.append("/lights/");
      url.append(light.getID());
      url.append("/state");

      String data = light.getLightData();
      StringEntity se = new StringEntity(data, "ISO-8859-1");     
      se.setContentType("application/json");
      HttpPut httpPut = new HttpPut(url.toString());            
      httpPut.addHeader("Accept", "application/json");                  // tell everyone we are talking JSON
      httpPut.addHeader("Content-Type", "application/json");

      //debugging
      //println(url);
      //println(light.getID() + "->" + data);

      //with post requests you can use setParameters, however this is
      //the only way the put request works with the JSON parameters
      httpPut.setEntity(se);
      //println( "executing request: " + httpPut.getRequestLine() );
      //println("");

      // sending data to url is only executed when ONLINE = true
      if (ONLINE) { 
        HttpResponse response = httpClient.execute(httpPut);
        HttpEntity entity = response.getEntity();

        if (entity != null) 
        {
          // only check for failures, eg [{"success":
          entity.writeTo(baos);
          if (!baos.toString().startsWith("[{\"success\":")) println("error updating"); 
          //println(baos.toString());
        }
        // needs to be done to ensure next put can be executed and connection is released
        if (entity != null) entity.consumeContent();
      }
    } 
    catch( Exception e ) { 
      e.printStackTrace();
    }
  }

  // close connections and cleanupp
  public void disconnect() {
    // when HttpClient instance is no longer needed, 
    // shut down the connection manager to ensure
    // deallocation of all system resources
    httpClient.getConnectionManager().shutdown();
  }
}

// Hue class; one instance represents a lamp which is addressed using number
class HueLamp extends Item
{
  private int id; // lamp number/ID as known by the hub, e.g. 1,2,3
  // light variables
  private int hue = 30000; // hue value for the lamp
  private int saturation = 255; // saturation value
  private int brightness = 255; // brightness
  private int dimLevel;
  private int ct = 300; // range 153 - 500

  int maxCT = 6500;
  int minCT = 200;
  int maxMirek = 500;
  int minMirek = 153;
  static final int ON   = 0;
  static final int BRI  = 1;
  static final int XY   = 2;
  static final int CT   = 3;
  static final int TRANS= 4;

  private boolean[] updates = { 
    false, false, false, false, false
  }; // on, bri, xy, ct, transition

  private boolean lightOn = false; // is the lamp on or off, true if on?
  private byte transitiontime = 8; // transition time, how fast  state change is executed -> 1 corresponds to 0.1s

  // hub variables
  private HueHub hub; // hub to register at
  // graphic settings
  private byte radius = 10; // size of the ellipse drawn on screen
  //private int x; // x position on screen
  //private int y; // y position on screen
  // control variables
  private float damping = 0.9; // control how fast dim() impacts brightness and lights turn off
  private float flashDuration = 0.2; // in approx. seconds
  
  private String mode = "";

  // constructor, requires light ID and hub
  public HueLamp(int lightID, HueHub aHub) 
  {
    id = lightID;
    hub = aHub;
    getLightData();

    this.setWidth (1);
    this.setHeight(1);
  }

  public void draw() 
  {

    float w = getWidth();
    float h = getHeight();
    float x = getX();
    float y = getY();

    strokeWeight(3);
    stroke(255);
    if (!this.getSelected()) noStroke();
    
    //fill the luminaire
    int b = int( getBrightness() );
    
    colorMode(HSB);
    fill( hue, saturation, brightness);
    colorMode(RGB);
    
    beginShape();
    vertex(x+0.2*w, y+0.1*h);
    bezierVertex(x+0.0*w, y+0.20*h, x+0.3*w, y+0.50*h, x+0.30*w, y+0.80*h);
    bezierVertex(x+0.3*w, y+0.85*h, x+0.5*w, y+0.85*h, x+0.50*w, y+0.80*h);
    bezierVertex(x+0.5*w, y+0.50*h, x+0.8*w, y+0.20*h, x+0.60*w, y+0.10*h);
    bezierVertex(x+0.5*w, y+0.05*h, x+0.3*w, y+0.05*h, x+0.20*w, y+0.10*h);
    endShape();
  }

  // set the hue value; if outside bounds set to min/max allowed
  public void setCT(int ctValue) 
  {
    if (ctValue > maxCT || ctValue < minCT) println("ct value of " + ctValue + " is not possible on Hue");
    ct = ctValue;

    int ctM = constrain(int( map(ct, minCT, maxCT, maxMirek, minMirek)), minMirek, maxMirek);
    updates[CT] = true;
    this.update();
  }

  public int getCT()
  {
    getLightData();
    return ct;
  }

  public void setDimLevel(int dim)
  {
    dimLevel = dim;
    int bri = int( map(dimLevel, 0, 65535, 0, 255) );
    setBrightness(bri);
  }

  public int getDimLevel()
  {
    getLightData();
    return dimLevel;
  }

  // set the brightness value, max 255
  public void setBrightness(int bri) 
  {
    brightness = bri;
    dimLevel = int(map(bri, 0, 255, 0, 65535));
    // Because the hue works with minimum brightness at 0; we have to turn it off manually at brightness 0
    //println("this.lightOn = " + this.lightOn );

    if (brightness == 0)
    {
      this.lightOn = false;
      updates[ON] = true;
      this.update();
    } else if (!this.lightOn) // if bri > 0 and we are not on; turn it on as well!
    {
      this.lightOn = true;
      updates[ON] = true;

      brightness = int(bri);
      updates[BRI] = true;
      this.update();
    } else
    {
      brightness = int(bri);
      updates[BRI] = true;
      this.update();
    }
  }

  void setRGB( int r, int g, int b) 
  {
    colorMode(RGB, 255);
    color rgbCol = color(r, g, b);
    colorMode(HSB, 255);
    int h = int(hue       (rgbCol));
    h = int( map(h, 0, 255, 0, 65532));
    int s = int(saturation(rgbCol));
    int br= int(brightness(rgbCol));
    setHSB(h, s, br);
  }

  // set the hue value; if outside bounds set to min/max allowed
  public void setHue(int hueValue) 
  {
    hue = int(hueValue);
    hue = constrain(hueValue, 0, 65532);
    updates[XY] = true;
    this.update();
  }

  // set the saturation value, max 255
  public void setSaturation(byte sat) 
  {
    saturation = int(sat);
    saturation = constrain(sat, 0, 255);
    updates[XY] = true;
    this.update();
  }

  // set the HSB
  public void setHSB(int hueValue, int sat, int bri) 
  {
    hue = constrain(hueValue, 0, 65532);
    saturation = sat;
    updates[XY] = true;
    setBrightness(bri); // also calls the udpate;
  }

  //  public void setCTParameters(int ctValue, byte bri) 
  //  {
  //    ct = constrain(ctValue, 153, 500);
  //    updates[CT] = true;
  //    this.setBrightness(bri); // also calls teh udpate;
  ////    brightness = int(bri);
  ////    updates[BRI] = true;
  ////    this.update();
  //  }

  // set the transition time in seconds; (1 = 0.1sec (not sure if there is a max)
  public void setFadetime(byte transTime) 
  {
    transitiontime = transTime;
    updates[TRANS] = true;
    this.update();
  }
  
  public void setFadetimeInMS(int transTime) 
  {
    setFadetime((byte) int(transTime/100));
  }
  

  // returns true if the light is on (based on last state change, not a query of the light) 
  public boolean isOn() 
  {
    return this.lightOn;
  }

  /*
   have the changes to the settings applied to the lamp & visualize; this
   calls the hub which handles the actual updates of the lights
   */
  public void update() 
  {
    hub.applyState(this);
  }

  // convenience method to turn the light off
  public void turnOff() 
  {
    this.lightOn = false;
    updates[ON] = true;
    this.update();
  }
  
  public void toggle()
  {
    this.lightOn = !this.lightOn;
    updates[ON] = true;
    this.update();
  }

  // convenience method to turn the light on
  public void turnOn() 
  {
    this.lightOn = true;
    updates[ON] = true;
    this.update(); // apply new state
  }

  // convenience method to turn the light on with some passed settings
  public void turnOn(int hue, int brightness) 
  {
    this.lightOn = true;
    this.hue = hue;
    this.brightness = brightness;
    updates[ON] = true;
    updates[XY] = true;
    updates[BRI] = true;
    this.update(); // apply new state
  }

  public String getLightData()
  {
    StringBuilder data = new StringBuilder("{");

    // vars used for comma placement
    int totalUpdates = 0;
    int updated = 0;

    // Check the total udpates to make
    for (int i = 0; i < updates.length; i++)
    {
      if (updates[i])
      {
        totalUpdates ++;
      }
    }

    for (int i = 0; i < updates.length; i++)
    {
      if (updates[i])
      {
        if ( i == ON )
        {
          data.append( getOnData() );
        }
        if ( i == BRI )
        {
          data.append( getBriData() );
        }
        if ( i == XY )
        {
          data.append( getXYData() );
        }
        if ( i == CT )
        {
          data.append( getCTData() );
        }
        if ( i == TRANS )
        {
          data.append( getTransData() );
        }
        updates[i] = false; // unflag the update    
        updated ++;
        if ( updated < totalUpdates )
        {
          data.append(",");
        }
      }
    }
    data.append("}");
    return data.toString();
  }

  public String getXYData() 
  {
    colorMode(HSB, 255);
    color hsbCol = color( constrain(map(hue, 0, 65532, 0, 255), 0, 255), saturation, brightness);
    colorMode(RGB, 255);

    float redVar   = map(red(hsbCol), 0, 255, 0, 1);
    float greenVar = map(green(hsbCol), 0, 255, 0, 1);
    float blueVar  = map(blue(hsbCol), 0, 255, 0, 1);

    float xVar = (0.412453 * redVar)  + (0.35758 * greenVar)  + (0.180423 * blueVar);
    float yVar = (0.212671 * redVar)  + (0.715160 * greenVar) + (0.072169 * blueVar);
    float zVar = (0.019334 * redVar)  + (0.119193 * greenVar) + (0.950227 * blueVar);

    float xColor = 0;
    float yColor = 0;

    if (xVar!=0 || yVar!=0 || zVar!=0)
    {
      xColor = xVar / (xVar + yVar + zVar);
      yColor = yVar / (xVar + yVar + zVar);
    }

    StringBuilder data = new StringBuilder("");

    data.append("\"xy\":[");
    data.append(xColor);
    data.append(", ");
    data.append(yColor);
    data.append("]");

    return data.toString();
  }

  public String getBriData() 
  {
    StringBuilder data = new StringBuilder("");
    data.append("\"bri\":");
    data.append(brightness);
    return data.toString();
  }

  public String getCTData() 
  {
    StringBuilder data = new StringBuilder("");
    data.append("\"ct\":");
    data.append(ct);
    return data.toString();
  }

  public String getOnData()
  {
    StringBuilder data = new StringBuilder("");
    data.append("\"on\":"); 
    data.append(lightOn);
    return data.toString();
  }

  public String getTransData() 
  {
    StringBuilder data = new StringBuilder("");
    data.append("\"transitiontime\":");
    data.append(transitiontime);
    return data.toString();
  }

  // get current values
  public int getBrightness() {
    return brightness;
  }

  public int getSaturation() {
    return saturation;
  }

  public int getHue() {
    return hue;
  }

  public int getID() {
    return id;
  }

  //  // set position on screen
  //  public void setPosition(int x, int y) 
  //  {
  //    this.x = x;
  //    this.y = y;
  //  }
}