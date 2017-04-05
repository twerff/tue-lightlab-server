ArrayList<Luminaire> _luminaires;

ArrayList<Luminaire> _luminaires(int scope)
{
  ArrayList<Luminaire> lums = new ArrayList<Luminaire>();
  
  for (Luminaire l : _luminaires)
  {
    if (l.getScope() == scope) lums.add(l);
  }
  
  return lums;
}

void setupLuminaires()
{
  _luminaires = new ArrayList<Luminaire>();

  addMPB("00:15:8d:00:00:35:d3:9f", 2.25, 1.25);
  addMPB("00:15:8d:00:00:35:ce:97", 4.25, 1.25);
  addMPB("00:15:8d:00:00:35:d3:5c", 6.5, 1.25);
  addMPB("00:15:8d:00:00:35:d2:c8", 8.5, 1.25);
  
  addMPB("00:15:8d:00:00:35:d3:88", 2.25, 3.25);
  addMPB("00:15:8d:00:00:35:ce:73", 4.25, 3.25);
  addMPB("00:15:8d:00:00:35:d3:3a", 6.5, 3.25);
  addMPB("00:15:8d:00:00:35:d2:11", 8.5, 3.25);
  
  addMPB("00:15:8d:00:00:35:cf:72", 2.25, 5.25);
  addMPB("00:15:8d:00:00:35:d2:2c", 4.25, 5.25);
  addMPB("00:15:8d:00:00:35:d2:29", 6.5, 5.25);
  addMPB("00:15:8d:00:00:35:d2:cf", 8.5, 5.25);
  
  addMPB("00:15:8d:00:00:35:cf:3a", 2.25, 7.25);
  addMPB("00:15:8d:00:00:35:ce:7f", 4.25, 7.25);
  addMPB("00:15:8d:00:00:35:d2:42", 6.5, 7.25);
  addMPB("00:15:8d:00:00:35:d2:04", 8.5, 7.25);
  
  addMPB("00:15:8D:00:00:35:D2:00", 3.25, 2.25);
  addMPB("00:15:8D:00:00:35:D2:FB", 3.25, 6.25);
  addMPB("00:15:8D:00:00:35:D2:0E", 7.5, 6.25);
  addMPB("00:15:8D:00:00:35:D1:FD", 7.5, 2.25);
  
}


public Luminaire pb()
{
  return _luminaires.get(0);
}

void addMPB(String ad, float x, float y)
{
  Luminaire l = new mPB(ad,x,y);
  _luminaires.add(l);
}

/*
void addTaskFlex(String ad, float x, float y, int scope)
{
  Luminaire l = new Taskflex(ad,x,y);
  l.setScope(scope);
  _luminaires.add(l);
}

void addPB(String ad, float x, float y)
{
  addPB(ad, x, y, 0);
}

void addPB(String ad, float x, float y, boolean dwars)
{
  addPB(ad,x,y,0);
  if(dwars) thisLuminaire().setDwars();
}

void addPB(String ad, String name, float x, float y)
{
  addPB(ad,x,y,0);
  thisLuminaire().setName(name);
}

void addPB(String ad, float x, float y, int scope)
{
  Luminaire l = new PB(ad,x,y);
  _luminaires.add(l);
  thisLuminaire().setScope(scope);
  
  l.setName(getScopeName(scope) + " " + int(x) + "," + int(y));
}

*/

Luminaire thisLuminaire()
{
  return getLuminaire(getNumberOfLuminaires()-1);
}

public Luminaire getLuminaireByAddress(String value)
{
  //remove the :
  value = join(split(value, ':'),"");  
  value = value.toLowerCase();
  
  for (Luminaire l : _luminaires)
  {
    String address = join(split(l.getAddress(), ':'),"").toLowerCase();
    if (address.equals(value) ) return l;
  }
  traceln("luminaire " + value + " not found..");
  return null;
}

public Luminaire getLuminaireByShortAddress(String value)
{
  //add the 0x if not already in there.
  if ( !value.contains("0x") ) value = "0x"+value;
  value = value.toLowerCase();
  
  for (Luminaire l : _luminaires)
  {
    String address = l.getShortAddress().toLowerCase();
    if ( !address.contains("0x") ) address = "0x"+address;
    if (address.equals(value) ) return l;
  }
  traceln("luminaire " + value + " not found..");
  return null;
}

public Luminaire randomLuminaire()
{
  int random = int( random(_luminaires.size()-1) );
  traceln("random luminaire "+_luminaires.get(random).getShortAddress());
  
  return _luminaires.get(random);
}