void mousePressed()
{  
  Luminaire l = hitLuminaire(mouseX, mouseY);

  if (l != null)  select(l);
  else
  {
    for (Button b : _buttons)
    {
      if (mouseX > b.x && mouseX < b.x +b.w && mouseY > b.y && mouseY < b.y+b.h) 
      {
        b.mousePressed();
        return;
      }
    }
    selected = null;
    Button toggle = new Button("Toggle Lamps", textX, buttonY);
  }
}

void mouseReleased()
{
}

void mouseDragged()
{
}

void mouseMoved()
{
}

Luminaire hitLuminaire(float x, float y)
{
  for (Luminaire l : _luminaires)
  {
    if ( x > l.getX() && x < l.getX() + l.getWidth() )
    {
      if ( y > l.getY() && y < l.getY() + l.getHeight() )
      {
        traceln("selected " + l.getName());
        return l;
      }
    }
  }

  return null;
}

Luminaire selected;
int buttonY = 200;

void select(Luminaire l)
{
  _buttons.clear();
  Button toggle = new Button("toggle", textX, buttonY);
  selected = l;
}

void drawInfo()
{
  if (selected == null) 
  {
    //_buttons.clear();
    //return;
  }
  else
  {
    fill(0);
    Luminaire l = selected;
    tekst("Luminaire: \t ", l.getName());
  
    
    tekst("Address:   \t", l.getAddress() + " (64bit)");
    tekst("", l.getShortAddress() + " (32bit)");
    for (int i = 0; i< _luminaires.size(); i++) if (_luminaires.get(i) == l) tekst("lampID", ""+i);
    tekst("coordinates", l.getX()+","+l.getY());
    
    textY = 50;
  }
}

int textX = 550;
int textY = 50;

void tekst(String v1, String v2)
{
  textAlign(LEFT, TOP);
  text(v1, textX, textY);
  text(v2, textX+80, textY);
  textY+=12;
}

ArrayList<Button> _buttons = new ArrayList<Button>();

class Button
{
  int x, y;
  int w = 100;
  int h = 20;
  String function;
  long lastPressed;
  
  public Button(String event, int xc, int yc)
  {
    _buttons.add(this);
    x = xc;
    y = yc;
    function = event;
  }
  
  public void draw()
  {
    fill(100);
    rect(x,y,w,h);
    fill(0);
    textAlign(CENTER, CENTER);
    text(function, x+w/2,y+h/2);
  }
  
  public void mousePressed()
  {
    if (selected == null) 
    {
      for (Luminaire l : _luminaires) l.toggle();
      for (HueLamp l : _hueLamps) l.toggle();
      for (Cove l : _coves) l.toggle();
      return;
    }
    
    if (millis() > lastPressed+200)
    {
      lastPressed = millis();
    
      if (function.equals("toggle")) selected.toggle();
    }
  }
}