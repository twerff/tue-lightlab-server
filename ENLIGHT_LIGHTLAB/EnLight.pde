import processing.serial.*;

Serial enlighPort;
Enlight ENLIGHT;
boolean enlightEnabled = false;
int randomAnnounceDelay = 240;

void setupEnlight(String port)
{ 
  enlightEnabled = true;
  
  ENLIGHT = new Enlight();
  
  try
  {
    enlighPort = new Serial(this, port, 115200);
    traceln("Enlight ready on " + port);
  }
  catch(Exception e)
  {
    traceln("Can't connect to Enlight on port " + port);
    traceln("These ports are available: " + Serial.list());
    enlightEnabled = false;
  }
}


class Enlight
{
  //types of events sent by the dongle
  String eventTypes[] = {};
  String events[] = {};

  boolean discovering = true;  //state indicates whether the system is discovering luminaires
  
  long lastSend = 0;
  int sendInterval = 60;
  boolean readyToSend = true;  //change to waitingForConfirmation and inverse
  int confirmationTimeOut = 500;
  
  int announceInterval = 1000;  //increases over time
  long lastAnnounce;
  int nrOfAnnounces;
  
  EnlightMessage lastSentMessage;
  
  ArrayList<Luminaire> _unfoundLuminaires = new ArrayList<Luminaire>();
  ArrayList<EnlightMessage> outbox = new ArrayList<EnlightMessage>();
  
  ArrayList<Luminaire> _unfoundLuminaires(int scope)
  {
    ArrayList<Luminaire> lums = new ArrayList<Luminaire>();
    
    for (Luminaire l : _unfoundLuminaires)
    {
      if (l.getScope() == scope) lums.add(l);
    }
    return lums;
  }
  
  public Enlight()
  {
    addEvents();
  }
  
  void TX()
  {
    tx = true;
  }
  
  void RX()
  {
    rx = true;
  }
  
  boolean tx, rx = false;
  
  void drawRXTX()
  {
    //int fillColor = g.fillColor;
    noStroke();
    if (rx) fill(255);
    else fill(0);
    rect(600,440,10,10);
    fill(0);
    text("RX",612,450);
    
    if (tx) fill(255);
    else fill(0);
    rect(600,452,10,10);
    fill(0);
    text("TX",612,462);
    
    //fill(fillColor);
    
    rx = tx = false;
  }
  
  void draw()
  {
    drawRXTX();
    
    //check if all lamps are still announced
    //if (!discovering)
    if (millis() - lastAnnounce > announceInterval)
    {
      if (discoverLuminiares()) lastAnnounce = millis();
    }
    
    //if the last message is not confirmed
    if (!readyToSend)
    {
      //if the message timed out
      if(millis() - lastSentMessage.getSendTime() > confirmationTimeOut )
      {
        println(lastSentMessage.getEvent() + "failed after " + (millis() - lastSentMessage.getSendTime()) + "ms");
               
        lastSentMessage.fail++;
        lastSentMessage.priority++;

        if (lastSentMessage.fail < 10) addMessageToOutbox(lastSentMessage);
        else traceln("message timed out: " + lastSentMessage.getEvent() + " from " + lastSentMessage.getFrom() +  " to " + lastSentMessage.getRecipient() + " " + lastSentMessage.fail + " times.");
        readyToSend = true;
      }
    }
    else if (POWERON)
    {
      if (outbox.size() > 0)
      {
        if (millis()-lastSend > sendInterval)
        {
          lastSend = millis();
          
          //traceln("messages in outbox: " + outbox.size());
          
          //only send announces when discovering
          //if (discovering)
          //{
          //  for (int i = 0; i<outbox.size(); i++)
          //  {
          //    if (outbox.get(i).event.equals("requestToAnnounce"))
          //    {
          //      sendMessage(outbox.get(i));
          //      return;
          //    }
          //  }
          //}
          //else
          //{
            //traceln("sending " + outbox.get(0).event);
            sendMessage(outbox.get(0));
          //}
        }
      }
    }    
  }
  
  
  //WERKT NIET LEKKER....
  private boolean discoverLuminiares()
  {
    ArrayList<Luminaire> temp = new ArrayList<Luminaire>();
    
    for (Luminaire l : _luminaires)
    {
      //if a lamp is not announced and had been announced less then 5 minutes ago
      if (!l.getAnnounced()) temp.add(l);// && l.getLastAnnounce() < 5*60000 ) temp.add(l);
    }
    
    if (temp.size() == 0) 
    {
      return false;
    }
    
    else if (temp.size() > _luminaires.size()/2 && lastAnnounce > 0)
    {
      traceln("ERROR: Are the lights turned off??");
      POWERON = false;
      return true;
    }
    else if (temp.size() > 0)
    {
      requestToAnnounce(temp);
      return true;
    }
    
    return false;
  }
  
  private void sendMessage(EnlightMessage m)
  {
    try
    {
      m.sendTime = millis();
      enlighPort.write( m.getBody() );
      TX();
      outbox.remove(m);
      lastSentMessage = m;
      if (m.confirmationRequired()) readyToSend = false;
      //traceln(m.getEvent() + " is sent to " + m.getRecipient());
    }
    catch (Exception e)
    {
      traceln("ENLIGHT sending error");
    }
  }
  
  void AddEvent(String code, String name)
  {
    eventTypes = append(eventTypes, name);
    events = append(events, code);
  }
  
  void addEvents()
  {
    AddEvent("0001", "Initialized");
    AddEvent("0003", "LuminaireReset");
    AddEvent("0004", "LuminaireToBeReseted");
    AddEvent("0005", "ClearZigbeeContext");
    AddEvent("000E", "CommissionLuminaire");                //uint8: LLE", bool: OnOff", uint16: dim level", uint16 Xcolor", uint16 Ycolor
    AddEvent("0020", "IamAlive");
    AddEvent("0101", "TimerExpired");
    AddEvent("0102", "FailureDetected");
    AddEvent("0103", "CounterUpdated");          //uint8: Counter_id", uint8 Counter_value
    AddEvent("0104", "TimeUpdated");             //uint32: #seconds after 1-1-2000
    AddEvent("0201", "AlarmActivated");
    AddEvent("0202", "AlarmReset");
    AddEvent("0301", "StatusUpdated");           //uint8
    AddEvent("0302", "PowerUsageUpdated");       //uint32 [milliwatts]
    AddEvent("1001", "LightlevelUpdated");      //uint16 [???] actual light level
    AddEvent("1101", "TemperatureUpdated");     //uint16 [Kelvin] actual temperature
    AddEvent("1101", "HumidityUpdated");        //uint16 [??] actual humidity level
    AddEvent("1201", "PresenceDetected");
    AddEvent("1203", "PresenceReported");       //uint8 1 ==> presence", 0 ==> absence
    AddEvent("1202", "AbsenceDetected");
    AddEvent("1301", "PersonCountChanged");     //uint8: personcount", uint8: pervious person count", uint16 person ID", uint8 zone id
    AddEvent("1302", "PersonEntered");          //uint8: personcount", uint16 person ID", uint8 zone id
    AddEvent("1303", "PersonLeft");             //uint8: personcount", uint16 person ID", uint8 zone id
    AddEvent("1304", "PersonSit");              //uint8: personcount", uint16 person ID", uint8 zone id
    AddEvent("1305", "PersonStand");            //uint8: personcount", uint16 person ID", uint8 zone id
    AddEvent("1401", "MovementDetected");       //uint16 [dm] x-position", uint16 [dm] y-position", int16 person ID", uint8 zone id
    AddEvent("1502", "ActivityDetected");       //enum8: activity", int16: personID", uint8: zone id
    AddEvent("1601", "PersonIdentified");       //int16: person id
    AddEvent("2001", "SceneSelected");          //uint16: scene id
    
    AddEvent("2101", "OnOffChanged");           //bool: on=true", off=false
    AddEvent("2102", "DimLevelChanged");        //uint8: dimlevel
    AddEvent("2103", "SwitchToggled");
    AddEvent("2104", "ColorChangedXY");         //uint16: XColor", uint16 YColor
    AddEvent("2105", "ColorChangedSV");        //uint8: hue", uint8 saturation
    AddEvent("2106", "ColorChangedCCT");        //uint16: [Kelvin] CCT
    AddEvent("2107", "ColorChangedRGB");        //uint8: red", uint8: green", uint8 blu
    
    
    AddEvent("2200", "Event00");  //dimlevel chanched on scope: uint16: dimlevel, uint8 scope
    AddEvent("2201", "Event01");  //ct & dimlevel changed
    
    AddEvent("2202", "Event02");  //setCT + colorFadeTime
    AddEvent("2203", "Event03");  //setDimLevel + fadeTime
    AddEvent("2204", "Event04");  //setRGB + colorFadeTime
    AddEvent("2205", "Event05");
    AddEvent("2206", "Event06");
    AddEvent("2207", "Event07");
    AddEvent("2208", "Event08");
    AddEvent("2209", "Event09");
    
    AddEvent("220A", "Event10");
    AddEvent("220B", "Event11");
    AddEvent("220C", "Event12");
    AddEvent("220D", "Event13");
    AddEvent("220E", "Event14");
    AddEvent("220F", "Event15");
    AddEvent("2210", "Event16");
    AddEvent("2211", "Event17");
    AddEvent("2212", "Event18");
    AddEvent("2213", "Event19");
    AddEvent("7FF0", "DebugOutput");
    
  }
  
  boolean checkIfNewMessage(EnlightMessage newMessage)
  {
    //if the outbox is empty, return true;
    if (outbox.size() == 0) return true;
    
    else
    {
      for (int i = 0; i<outbox.size(); i++)
      {
        EnlightMessage oldMessage = outbox.get(i);
        
        //if it is the same luminaire
        if ( oldMessage.getRecipient().equals( newMessage.getRecipient() ) && oldMessage.getFrom().equals( newMessage.getFrom() ) )
        {
          //replace message with same event to the same level of the same luminaire with the new one..
          if (oldMessage.getEvent().equals(newMessage.getEvent()) )
          {
            newMessage.setPriority(-1);      //set the lowest priority
            outbox.set(i, newMessage);       //add it to the outbox
            return false;
          }
          
          EnlightMessage m = new EnlightMessage();
          m.setFrom(ADDRESS_PC);
          m.setRecipient(newMessage.getRecipient());
          m.setEvent("Event01");
            
          //if it is ct, have a look if the same lamp has a message for dimlevel (and the other way around)
          if (newMessage.getEvent().equals("ColorChangedCCT") && oldMessage.getEvent().equals("DimLevelChanged"))
          {
            
            m.setArgs( concat(newMessage.getArgs(), oldMessage.getArgs()) );
            m.setBody();
            outbox.set(i, m);       //add it to the outbox
            return false;
          }
          else if (newMessage.getEvent().equals("DimLevelChanged") && oldMessage.getEvent().equals("ColorChangedCCT"))
          {
            m.setArgs( concat(oldMessage.getArgs(), newMessage.getArgs()) );
            m.setBody();
            outbox.set(i, m);       //add it to the outbox
            return false;
          }
        }
        
      }
    }
    return true;
  }

  void addMessageToOutbox(EnlightMessage message)
  {
    if (checkIfNewMessage(message)) outbox.add(message);
    //try
    //{
      Collections.sort(outbox);      //sort the outbox by priority;
    //}
    //catch (Exception e)
    //{
    //}
  }
  
  
  ////REQUEST TO ANNOUNCE MESSAGE////////////////////////////////////////////////// 
  void requestToAnnounce(ArrayList<Luminaire> luminaires)
  {
    for (int i = 0; i<luminaires.size(); i++) requestToAnnounce( luminaires.get(i) );
  }
  
  void requestToAnnounce(Luminaire l)
  {    
    //check if it is already being requested
    Boolean listed = false;
    for (Luminaire u : _unfoundLuminaires)
    {
      if (u == l) 
      {
        listed = true;
      }
    }
    
    if (!listed) _unfoundLuminaires.add(l);
    
    //traceln("ENLIGHT: discovering " + l.getAddress());
    discovering = true;
    String address = join(split(l.getAddress(), ':'),"");  //remove : from the address
    String m = "zdo nwk {" + address + "}\r\n";
    
    EnlightMessage message = new EnlightMessage(m);
    
    message.setConfirmation(false);
    message.setRecipient(l.getAddress());
    message.setFrom("server");
    message.setEvent("requestToAnnounce");
    message.setPriority(999);                  //set the highest priority
    
    addMessageToOutbox(message);
  }
  
  ////CREATE THE MESSAGE//////////////////////////////////////////////////
  //maybe change function to createMessage();
  
  //broadcast without any arguments
  void createMessage(String event, String sender)
  {
    createMessage(event, sender, "broadcast", null);
  }
  
  //unicast without any arguments
  void createMessage(String event, String sender, String receiver)
  {
    createMessage(event, sender, receiver, null);
  }
  
  //broadcast with arguments
  void createMessage(String event, String sender, int... args)
  {
    createMessage(event, sender, "broadcast", args);
  }
  
  //unicast with arguments
  void createMessage(String event, String sender, String receiver, int... args)
  {
    //if (!getLuminaireByAddress(receiver).getAnnounced()) traceln("l not announced " + receiver);
    EnlightMessage m = new EnlightMessage();
    m.setFrom(sender);
    m.setRecipient(receiver);
    m.setEvent(event);
    m.setArgs(args);
    m.setBody();
    //set message priority///
    addMessageToOutbox(m);
    
    //traceln("message created: " + m.getEvent() + " is sent to " + m.getRecipient());
  }
}

//is het wel presence detected? is het niet announce?
String[][] commands = { {"81", "presenceDetected" }, { "80", "?" } };

void serialEvent(Serial p)
{
  ENLIGHT.RX();
  POWERON = true;
  
  try {
    // get message till line break (ASCII > 13)
    String message = p.readStringUntil(13);
    
    if (message != null)
    {
      //traceln(message);
      
      int _NARPos = message.indexOf("NAR(");
      int _64BitPos = message.indexOf("(>)");
      int _incomingMSGPos = message.indexOf("MSG(");
      int _confirmationMSGPos = message.indexOf("buffer: ");      
      int _DANPos = message.indexOf("DAN(");
      int _FAILPos = message.indexOf("FAIL");
      
      // NAR message (New Announce Request) 
      if( _NARPos > -1 && _64BitPos > -1 )
      {
        String _16Bit = message.substring(_NARPos+4, _NARPos+8).toLowerCase();
        String _64Bit = message.substring(_64BitPos+3, _64BitPos+19).toLowerCase();
        
        for(int i = 0; i<_luminaires.size(); i++)
        {
          Luminaire l = getLuminaire(i);
          if (join(split(l.getAddress().toLowerCase(), ':'),"").equals(_64Bit))
          {
            l.setShortAddress(_16Bit);
            l.setAnnounced(true);
            ENLIGHT._unfoundLuminaires.remove( l );
          }
        }
        
        //traceln("ENLIGHT: announce from " + _64Bit);
        //log("Enlight", _64Bit, "server", "announce");
      }
      
     
      //DAN(BD8A) 00158D000035D361    looks like a message when lamp is turned on
      else if( _DANPos > -1 )
      {
        String _16Bit = message.substring(_DANPos+4, _DANPos+8).toLowerCase();
        String _64Bit = message.substring(_64BitPos+3, _64BitPos+29).toLowerCase();
                
        Luminaire l = getLuminaireByShortAddress(_16Bit);
        
        traceln(l.getName() + " turned on");
        
        //ENLIGHT.requestToAnnounce(l);
        
        for (Luminaire ll : _luminaires(STUDIO))
        {
          if (ll.getName().equals("PB Exit") && (ll.getDimLevel() != 35000 || ll.getCT() != 4000)) 
          {
            println("setting " + ll.getName() + " back to default");
            ll.setDimLevel(35000);
            ll.setCT(4000);
          }
        }
        //l.update();
        
        //update the exit luminaires...?        
        //log ("Enlight", l.getAddress(), "Server", "power on");
      }
      
      //announce return
      else if(message.indexOf("Service discovery done.") > -1)
      {         
        if (ENLIGHT._unfoundLuminaires.size() == 0)
        {
          ENLIGHT.discovering = false;
          traceln("ENLIGHT: discovery done");
          //log("Enlight", "","","discovery done");
        }
      }
      
      else if ( _incomingMSGPos > -1 )
      {
        String command = message.substring(_incomingMSGPos+15, _incomingMSGPos+17).toLowerCase();
        String address = message.substring(_incomingMSGPos+4, _incomingMSGPos+8).toLowerCase();
        
        traceln(command + " heb ik zojuist binnen gekregen van " + address);
        
        String commandName = "?";
        
        for (int i = 0; i < commands.length; i++)
        {
          if (commands[i][0].equals(command) )
          {
            commandName = commands[i][1];
          }
        }
        
        Luminaire l = getLuminaireByShortAddress(address);
        
        //if presence detected, set presence
//if (command.equals("81")) l.setPresence(true);
        
        //log("Enlight", l.getAddress(), "server", command);
        //traceln(commandName + " from " + l.getAddress());
      }  
      
      else if(_confirmationMSGPos > -1)
      {
        String lastAddress = ENLIGHT.lastSentMessage.getBody().substring(21,21+15).toUpperCase();
        
        String[] allChars = new String[lastAddress.length()/2];
        
        for (int i = 0; i < lastAddress.length()/2; i++) allChars[i] = lastAddress.charAt(i*2) +""+ lastAddress.charAt(i*2+1);
   
        lastAddress = join(allChars, " "); 
        
        if(message.indexOf(lastAddress) > -1) ENLIGHT.readyToSend = true;
      }
      
      else if (message.contains("T00000000:TX (CLI) Ucast") || message.contains("Msg: clus 0xFC30, cmd 0x80, len 27")) //part of the confirm message
      {
        message = message.replace("\n", " ");
        message = message.replace("\r", " ");
        message = message.replace("\b", " ");
        //traceln(message);
      }
      
      else if (_FAILPos > -1)
      {
        traceln(message);
        String _16Bit = "0x" + message.substring(_FAILPos+5, _FAILPos+9).toLowerCase();
        if (!_16Bit.equals("0xfffd"))
        {
          traceln("FAIL " + _16Bit + ": " + message + " request to announce..");
          //it should send the same message again...
          //ENLIGHT.requestToAnnounce(getLuminaireByShortAddress(_16Bit));
        }
        
      }
      
      //if nothing of the above
      else 
      {
        //log("Enlight", "ERROR", "server", message);
        message = message.replace("\n", " ");
        message = message.replace("\r", " ");
        message = message.replace("\b", " ");
        //traceln("Enlight received: " + message);
      }
    }
  }
  
  catch (Exception e)
  {
  }
}