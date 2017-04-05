//ENLIGHT XML BUILDER
String data = "<AreaLightingSystem/>";
XML xml = parseXML(data);
String name = "XML for Lightlab";
String author = "Thomas van de Werff";
String version = "1.0";

XML Area, luminaire, rule, trigger, condition, action, actiontype;

RuleXML r;
LuminaireXML l;
LuminaireXML t;

Luminaire currentLuminaire;

void createXML(String filename)
{
  Area = new XML("AreaLightingSystem");
  Area.setString("xmlns:xsi", "http://www.w3.org/2001/XMLSchema-instance");
  Area.setString("xsi:noNamespaceSchemaLocation", "../../../03_Product_Area/Area_Configurator_Commissioning/Simulator/XML-Schema/Programming_data.xsd");

  //file properties
  XML prop = Area.addChild("FileProperties");
  prop.setString("Name", name);
  prop.setString("Author", author);
  prop.setString("Date", day()+" "+month()+" "+year());
  prop.setString("Version", version);

  for (int i = 0; i<getNumberOfLuminaires(); i++)
  {
    if (getLuminaire(i).getName().contains("TX"))
    {
      t = new LuminaireXML(getLuminaire(i));
    } else
    {
      l = new LuminaireXML(getLuminaire(i));

      //CONFIGS
      l.configureParameter("PresenceSensorDevice_PresenceReportingInterval", 1);
      l.configureParameter("PresenceSensorDevice_AbsenceTime", 1);
      l.configureParameter("PresenceSensorDevice_PresenceLevel", 3);

      l.configureParameter("LuminaireDevice_Max_RandomAnnounceDelay", randomAnnounceDelay);
    }
  }

  saveXML(Area, filename);
  traceln("XML saved as " + filename);
}

public class LuminaireXML extends XML
{
  Luminaire l;

  public LuminaireXML(Luminaire i)
  {
    l = i;
    currentLuminaire = i;

    luminaire = Area.addChild("Luminaire");
    luminaire.setString("Name", l.getName());
    luminaire.setString("Address", l.getAddress());
    luminaire.setInt("NumberOfLevels", l.getNrOfLevels());
    //?
    luminaire.setInt("NumberOfLLE", 1);
    luminaire.setInt("MaxNumberOfPresets", 1);
    luminaire.setInt("MaxNumberOfVariables", 1);

    setDefs();
    init();
    pcRules(l);
  }

  private void setDefs()
  {
    XML leveldefs = luminaire.addChild("LevelDefs");

    for (int i=0; i < l.getNrOfLevels(); i++)
    {
      LVL lvl = l.getLevel(0);

      XML def = leveldefs.addChild("DefColorCCT");
      def.setInt("Brightness", lvl.getDimLevel());
      def.setInt("CCT", lvl.getCT());
      def.setInt("LLEAddress", lvl.getLLE());
      def.setString("On", str(lvl.getOn()));
      def.setContent( str(lvl.getLevel()) );//str(i+1));
    }
  }

  public void init()
  {
    r = new RuleXML("Initialized");
    r.addTriggerEvent("Initialized", ADDRESS_INTERNAL, "Luminaire Internal");

    if (l.getName().equals("PB Exit")) r.addAction("LevelActivation", true, false, l.getLevels());

    else
    {
      r.addAction("LevelActivation", true, l.getLevel("lvl_work").getLevel());
      //r.addLevelToAction(str(l.getLevel("lvl_absence").getLevel()), true);
    }

    for (int i=0; i < l.getNrOfLevels(); i++)
    {
      LVL lvl = l.getLevel(i);

      r.addLuminaireSetting("SetFadeTime", i+1, lvl.getFadeTime());
      r.addLuminaireSetting("SetColorFadeTime", i+1, lvl.getColorFadeTime());
    }
  }

  public void configureParameter(String paramID, int content)
  {
    XML conf = luminaire.addChild("ConfigurationParameter");
    conf.setString("ParameterID", paramID);
    conf.setString("ILBDeviceIndex", "1");
    XML uint = conf.addChild("uint16");
    uint.setContent(str(content));
  }
}

void pcRules(Luminaire l)
{
  String address = ADDRESS_PC;

  //CT CHANGED
  r = new RuleXML("Color Changed CCT from PC");
  r.addTriggerEvent("ColorChangedCCT", address, "PC");
  r.addAction("SetColorTemperature", l.getLevels());

  r = new RuleXML("Color Changed CCT with fade time from PC");
  r.addTriggerEvent("Event02", address, "PC");
  r.addAction("SetColorTemperatureTime", l.getLevels());

  //DimLevel CHANGED
  r = new RuleXML("DimLevel changed from PC");
  r.addTriggerEvent("DimLevelChanged", address, "PC");
  r.addAction("SetDimmingLevel", l.getLevels());

  r = new RuleXML("Dimlevel changed with fade time from PC");
  r.addTriggerEvent("Event03", address, "PC");
  r.addAction("SetDimLevelTime", l.getLevels());

  //CT & DimLevel CHANGED
  r = new RuleXML("Color Changed CCT and DimLevel from PC");
  r.addTriggerEvent("Event01", address, "PC");
  r.addAction("SetCTandDimLevel", l.getLevels());

  //RGB CHANGED
  r = new RuleXML("Color Changed RGB from PC");
  r.addTriggerEvent("ColorChangedRGB", address, "PC");
  r.addAction("SetColorRGB", l.getLevels());
  
  r = new RuleXML("Color Changed RGB from PC");
  r.addTriggerEvent("Event04", address, "PC");
  r.addAction("SetColorRGBTime", l.getLevels());

  //ON/OFF CHANGED
  //on
  r = new RuleXML("On Received from PC");
  r.addTriggerEvent("OnOffChanged", address, "PC");
  r.addCondition(1, "EQ", 1);
  r.addAction("LevelActivation", true, l.getLevels());
  //off
  r = new RuleXML("Off Received from PC");
  r.addTriggerEvent("OnOffChanged", address, "PC");
  r.addCondition(1, "EQ", 0);
  r.addAction("LevelActivation", false, l.getLevels());
}



public void configureParameter(String paramID, int content)
{
  XML conf = luminaire.addChild("ConfigurationParameter");
  conf.setString("ParameterID", paramID);
  conf.setString("ILBDeviceIndex", "1");
  XML uint = conf.addChild("uint16");
  uint.setContent(str(content));
}

public class RuleXML extends XML
{
  Luminaire l;

  public RuleXML(String name)
  {
    rule = luminaire.addChild("Rule");
    rule.setString("Name", name);
  }

  //TRIGGEREVENT
  public void addTriggerEvent(String type, String address, String addressName)
  {
    trigger = rule.addChild("TriggerEvent");
    trigger.setString("Type", type);
    trigger.setString("Address", address);
    trigger.setString("AddressName", addressName);
  }

  //  public void addTriggerEvent(String type, int i, String address, String addressName)
  //  {
  //    addTriggerEvent(type, address, addressName);
  //    
  //    trigger.setString("UserEventName",str(i));
  //    trigger.setString("DontSubscribe","true");
  //  }

  //CONDITIONS
  public void addCondition(Luminaire l, String c, int...levels)
  {
    condition = rule.addChild("Condition");
    XML type = condition.addChild(c);

    for (int lvl=0; lvl < l.getNrOfLevels(); lvl++)
    {
      type.setContent(str(lvl+1));
    }
  }

  public void addCondition(int arg, String comperator, int value)
  {
    condition = rule.addChild("Condition");
    XML eventParCondition = condition.addChild("EventParCondition");
    eventParCondition.setString("Comparator", comperator);
    XML arg1 = eventParCondition.addChild("Argument");
    XML a = arg1.addChild("EventArgIndex");
    a.setContent(str(arg));
    XML arg2 = eventParCondition.addChild("Argument");
    XML b = arg2.addChild("Constant_u8");
    b.setContent(str(value));
  }

  //ACTION
  public void addAction(String actionType, int...levels)
  {
    action = rule.addChild("Action");

    //CT & DIM
    if (actionType.equals("SetCTandDimLevel"))
    {
      actiontype = action.addChild("LuminaireSetting");
      actiontype.setString("Command", "SetColorTemperature");

      for (int i = 0; i < levels.length; i++)
      {
        XML level = actiontype.addChild("Level");
        level.setContent(str(levels[i]));
      }

      XML argument = new XML("Argument");
      XML index = new XML("EventArgIndex");
      index.setContent(str(1));
      argument.addChild(index);
      actiontype.addChild(argument);

      actiontype = action.addChild("LuminaireSetting");
      actiontype.setString("Command", "SetDimmingLevel");

      for (int i = 0; i < levels.length; i++)
      {
        XML level = actiontype.addChild("Level");
        level.setContent(str(levels[i]));
      }

      argument = new XML("Argument");
      index = new XML("EventArgIndex");
      index.setContent(str(2));
      argument.addChild(index);
      actiontype.addChild(argument);
    }

    //RGB
    else if (actionType.equals("SetColorRGB"))
    {
      actiontype = action.addChild("LuminaireSetting");
      actiontype.setString("Command", actionType);

      for (int i = 0; i < levels.length; i++)
      {
        XML level = actiontype.addChild("Level");
        level.setContent(str(levels[i]));
      }

      int numArg = 3;

      for (int arg = 0; arg<numArg; arg++)
      {
        XML argument = new XML("Argument");
        XML index = new XML("EventArgIndex");

        index.setContent(str(arg+1));

        argument.addChild(index);
        actiontype.addChild(argument);
      }
    }
    
    else if (actionType.equals("SetColorRGBTime"))
    {
      actiontype = action.addChild("LuminaireSetting");
      actiontype.setString("Command", "SetColorRGB");

      for (int i = 0; i < levels.length; i++)
      {
        XML level = actiontype.addChild("Level");
        level.setContent(str(levels[i]));
      }

      int numArg = 3;

      for (int arg = 0; arg<numArg; arg++)
      {
        XML argument = new XML("Argument");
        XML index = new XML("EventArgIndex");

        index.setContent(str(arg+1));

        argument.addChild(index);
        actiontype.addChild(argument);
      }
      
      actiontype = action.addChild("LuminaireSetting");
      actiontype.setString("Command", "SetColorFadeTime");

      for (int i = 0; i < levels.length; i++)
      {
        XML level = actiontype.addChild("Level");
        level.setContent(str(levels[i]));
      }

      XML argument = new XML("Argument");
      XML index = new XML("EventArgIndex");

      index.setContent(str(4));

      argument.addChild(index);
      actiontype.addChild(argument);
    }
    
    else if (actionType.equals("SetColorTemperatureTime"))
    {
      actiontype = action.addChild("LuminaireSetting");
      actiontype.setString("Command", "SetColorTemperature");

      for (int i = 0; i < levels.length; i++)
      {
        XML level = actiontype.addChild("Level");
        level.setContent(str(levels[i]));
      }

      XML argument = new XML("Argument");
      XML index = new XML("EventArgIndex");

      index.setContent(str(1));

      argument.addChild(index);
      actiontype.addChild(argument);
      
      actiontype = action.addChild("LuminaireSetting");
      actiontype.setString("Command", "SetColorFadeTime");

      for (int i = 0; i < levels.length; i++)
      {
        XML level = actiontype.addChild("Level");
        level.setContent(str(levels[i]));
      }

      argument = new XML("Argument");
      index = new XML("EventArgIndex");

      index.setContent(str(2));

      argument.addChild(index);
      actiontype.addChild(argument);
    }
    
    else if (actionType.equals("SetDimLevelTime"))
    {
      actiontype = action.addChild("LuminaireSetting");
      actiontype.setString("Command", "SetDimmingLevel");

      for (int i = 0; i < levels.length; i++)
      {
        XML level = actiontype.addChild("Level");
        level.setContent(str(levels[i]));
      }

      XML argument = new XML("Argument");
      XML index = new XML("EventArgIndex");

      index.setContent(str(1));

      argument.addChild(index);
      actiontype.addChild(argument);
      
      actiontype = action.addChild("LuminaireSetting");
      actiontype.setString("Command", "SetFadeTime");

      for (int i = 0; i < levels.length; i++)
      {
        XML level = actiontype.addChild("Level");
        level.setContent(str(levels[i]));
      }

      argument = new XML("Argument");
      index = new XML("EventArgIndex");

      index.setContent(str(2));

      argument.addChild(index);
      actiontype.addChild(argument);
    }

    //CT && DIM
    else if (actionType.equals("SetColorTemperature") || actionType.equals("SetDimmingLevel"))
    {
      actiontype = action.addChild("LuminaireSetting");
      actiontype.setString("Command", actionType);

      for (int i = 0; i < levels.length; i++)
      {
        XML level = actiontype.addChild("Level");
        level.setContent(str(levels[i]));
      }

      XML argument = new XML("Argument");
      XML index = new XML("EventArgIndex");

      index.setContent(str(1));

      argument.addChild(index);
      actiontype.addChild(argument);
    } 


    //USEREVENT
    else if (actionType.equals("UserEvent"))
    {
      actiontype = action.addChild("GenerateEvent");
      actiontype.setString("Type", actionType);
      actiontype.setString("UserEventName", str(levels[0]));
      actiontype.setString("ForceBroadcast", "true");
    }
  }

  public void addLevelToAction(String lvl, boolean activate)
  {
    XML level = actiontype.addChild( "Level" );
    level.setString("Activation", str(activate));
    level.setContent( lvl );
  }

  public void addLuminaireSetting(String settingType, int lvl, int... args)
  {
    XML setting = action.addChild("LuminaireSetting");
    setting.setString("Command", settingType);

    XML level = setting.addChild("Level");
    level.setContent(str(lvl));

    for (int i = 0; i<args.length; i++)
    {
      XML argument = setting.addChild("Argument");
      XML index = argument.addChild("Constant_u8");

      index.setContent(str(args[i]));
    }
  }

  public void addAction(String actionType, int timeOut, boolean on, int...levels)
  {
    addAction(actionType, levels);

    if (actionType.equals("LevelActivation"))
    {
      actiontype = action.addChild("LevelActivation");

      for (int i = 0; i < levels.length; i++)
      {
        XML level = actiontype.addChild("Level");
        level.setString("Activation", str(on));
        level.setString("TimeOut", str(timeOut));
        level.setContent(str(levels[i]));
      }
    }
  }

  public void addAction(String actionType, boolean on, int...levels)
  {
    addAction(actionType, levels);

    if (actionType.equals("LevelActivation"))
    {
      actiontype = action.addChild("LevelActivation");

      for (int i = 0; i < levels.length; i++)
      {
        XML level = actiontype.addChild("Level");
        level.setString("Activation", str(on));
        level.setContent(str(levels[i]));
      }
    }
  }

  public void addAction(String actionType, boolean on, boolean timeOut, int...levels)
  {
    addAction(actionType, levels);

    if (actionType.equals("LevelActivation"))
    {
      actiontype = action.addChild("LevelActivation");

      for (int i = 0; i < levels.length; i++)
      {
        XML level = actiontype.addChild("Level");
        level.setString("Activation", str(on));
        if (timeOut) level.setString("TimeOut", str(currentLuminaire.getLevel(i).getTimeOut()));
        level.setContent(str(levels[i]));
      }
    }
  }
}