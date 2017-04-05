int consoleX = 600;

void drawGrid()
{
  fill(200,200,200);
  noStroke();
  rect(0,0,width,height);
  
  drawMap();
    
  for(int i = 0; i < getNumberOfLuminaires(); i++) getLuminaire(i).draw();
  for (HueLamp h:_hueLamps) h.draw();
  for (Cove c:_coves) c.draw();
  
  drawInfo();
  for (Button b: _buttons) b.draw();
}

void drawMap()
{
  //draw grid
  noFill();
  strokeWeight(1);
  stroke(210,210,210);
  
  for (int y = 1; y<9; y++)
  {
    for (int x = 1; x<11; x++)
    {
      float xx = x;
      float w = 1;
      if (x == 5 || x == 6) w = 0.5;
      if (x > 5) xx-=0.25;
      if (x > 6) xx-=0.5;
      
      recta(xx,y,w,1);
    }
  }
  
  stroke(100);
  strokeWeight(15);
  recta(1.5,0.5,8,8);
  
  text("Entrance", TILE*3,TILE*0.6);
}

boolean detailEnabled = true;
boolean simulationEnabled = false;


void recta(float x, float y, float w, float h)
{
  rect(TILE*x, TILE*y, TILE*w, TILE*h);
}

void linea(float x, float y, float w, float h)
{
  line(TILE*x, TILE*y, TILE*w, TILE*h);
}

public int getNumberOfLuminaires()
{
  return _luminaires.size();
}

public Luminaire getLuminaire(int i)
{
  return _luminaires.get(i);
}

public void drawRGBgrid(int x, int y, int w, int h)
{
  ///
  //  Draw a colorgrid on the screen if you like  
  colorMode(HSB,w,h,255);
  for(int i = x; i < x+w; i++){
    for(int j = y; j < y+h; j++){
      stroke(i,j,255);
      point(i,j);
    }
  }
  colorMode(RGB);
}