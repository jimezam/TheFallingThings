//////////////////////////////////////////////////////////////////////////////

Universe universe;

//////////////////////////////////////////////////////////////////////////////

void setup() 
{
  size(640, 480);
  frameRate(30);
  noStroke();
  smooth();

  reset();  
}

void reset()
{
  float ratio = 3F/4;
  
  universe = new Universe(ratio);
  
  redraw();
}

void draw() 
{
  background(0);
  
  universe.paint();
  
  universe.passTime();
}

void keyPressed() 
{
  if (key == CODED) 
  {
    switch(keyCode)
    {
      case LEFT:
        universe.movePaddle(LEFT);
      break;
      
      case RIGHT:
        universe.movePaddle(RIGHT);
      break;
    }
  }
  else
  {
    switch(key)
    {
      case 'r':
        reset();
      break;
      
      case 'p':
        universe.toggleActive();
      break;
      
      case 'q':
        exit();
      break;
    }
  }
}

void mouseMoved() 
{
  universe.movePaddleTo(mouseX);
}

//////////////////////////////////////////////////////////////////////////////

class Universe extends Thing
{
  private float ratio;

  private Sky sky;
  private Ground ground;

  private Paddle paddle;

  private ArrayList<FallingThing> fallingThings;

  private int maxFallingThingsCount;
  private float maxFallingThingsSpeed;
  
  private boolean active;

  public Universe(float ratio)
  {
    super(new PVector(0, 0), 
          new PVector(width, height));
          
    this.ratio = ratio;

    this.sky = new Sky(ratio);
    this.ground = new Ground(1 - ratio);

    int paddleIniWidth  = 110;
    int paddleIniHeight = 30;
    int paddleIniDepth  = 50;

    this.paddle = new Paddle(new PVector((width - paddleIniWidth)/2, 
                                         height - paddleIniHeight - 10), 
                             new PVector(paddleIniWidth, 
                                         paddleIniHeight, 
                                         paddleIniDepth));
                                    
    this.fallingThings = new ArrayList();
    
    this.maxFallingThingsCount = 4;
    this.maxFallingThingsSpeed = 2.3;
    
    this.active = true;
  }

  public void paint()
  {
    sky.paint();
    
    ground.paint();
    
    for(FallingThing fthing : this.fallingThings)
    {
      fthing.paint();
      fthing.fall();
    }
    
    paddle.paint();
  }
  
  public void movePaddle(int direction)
  {
    if(!this.isActive())
      return;
    
    int step = 10;
    
    float x = paddle.getLocation().x;
    float y = paddle.getLocation().y;
    float z = paddle.getLocation().z;
    
    switch(direction)
    {
      case LEFT:
        x = x - step;
      break;

      case RIGHT:
        x = x + step;
      break;

      default:
        println("movePaddle, unknown direction: " + direction);
      break;
    }
    
    PVector dimension = paddle.getDimension();
    
    x = constrain(x, 0, width - dimension.x);
    
    paddle.setLocation(new PVector(x, y, z));
  }
  
  public void movePaddleTo(int nx)
  {
    if(!this.isActive())
      return;
    
    PVector dimension = paddle.getDimension();
    
    float x = nx - (dimension.x/2F);
    float y = paddle.getLocation().y;
    float z = paddle.getLocation().z;
    
    x = constrain(x, 0, width - dimension.x);
    
    paddle.setLocation(new PVector(x, y, z));
  }
  
  public void passTime()
  {
    if(this.fallingThings.size() <= this.maxFallingThingsCount)
    {
      this.fallingThings.add(this.createFallingThing());
    }
    
    for(int i=0; i<this.fallingThings.size(); i++)
    {
      FallingThing fthing = this.fallingThings.get(i);
      
      boolean explode = false;      
      
      if(fthing.hasCollision(this.paddle))
      {
        explode = true;
        
        println(hour() + ":" + minute() + ":" + second() + "." + millis() + " Got it!");        
      }
      
      if(!fthing.hasCollision(this))
      {
        explode = true;
        
        println(hour() + ":" + minute() + ":" + second() + "." + millis() + " Miss it!");        
      }
      
      if(explode)
      {
        this.fallingThings.remove(i);
        
        i--;
      }
    }
  }
  
  private FallingThing createFallingThing()
  {
    FallingThing thing;

    int ftWidth  = 60;
    int ftHeight = 60;    
    float x      = random(0, width - ftWidth);
    float speed  = random(0.5, this.maxFallingThingsSpeed);
    
    thing = new FallingThing(new PVector(x, 0), 
                             new PVector(ftWidth, ftHeight), 
                             new PVector(0, speed), 
                             new PVector(1, 1));    
    
    return thing;
  }
  
  public void toggleActive()
  {
    this.active = !this.active;
    
    if(this.active)
    {
      loop();
      
      println("Getting unpaused :-)");
    }
    else
    {
      noLoop();
      
      println("Getting paused :-(");
    }      
}
  
  public boolean isActive()
  {
    return this.active;
  }
}

//////////////////////////////////////////////////////////////////////////////

class Sky extends Thing
{
  public Sky(float pHeight)
  {
    super(new PVector(0, 0), 
          new PVector(width, pHeight * height));
  }

  public void paint()
  {
    noStroke();
    fill(186, 224, 251);
    rect(location.x, location.y, dimension.x, dimension.y);
  }
}

//////////////////////////////////////////////////////////////////////////////

class Ground extends Thing
{
  public Ground(float pHeight)
  {
    super(new PVector(0, (1 - pHeight) * height), 
          new PVector(width, pHeight * height));
  }

  public void paint()
  {  
    fill(196, 236, 166);
    rect(location.x, location.y, dimension.x, dimension.y);

    stroke(161, 224, 87);
    strokeWeight(3);
    line(location.x, location.y, location.x + dimension.x, location.y);
  }
}

//////////////////////////////////////////////////////////////////////////////

class Thing
{
  protected PVector location;
  protected PVector dimension;

  public Thing(PVector location, PVector dimension)
  {
    this.location = location;
    this.dimension = dimension;
  }

  public PVector getLocation()
  {
    return this.location;
  }
  
  public void setLocation(PVector newLocation)
  {
    this.location = newLocation;
  }
  
  public PVector getDimension()
  {
    return this.dimension;
  }
  
  public boolean hasCollision(Thing thing)
  {
    if ((this.location.x + this.dimension.x >= thing.getLocation().x) &&
        (this.location.x <= thing.getLocation().x + thing.getDimension().x) &&
        (this.location.y + this.dimension.y >= thing.getLocation().y) &&
        (this.location.y <= thing.getLocation().y + thing.getDimension().y))    
     {
       return true;
     }  
     
     return false;
  }

  public void paint()
  {
    ellipse(this.location.x + this.dimension.x/2, 
    this.location.y + this.dimension.y/2, 
    this.dimension.x, 
    this.dimension.y);
  }
}

//////////////////////////////////////////////////////////////////////////////

public class FallingThing extends Thing
{
  protected PVector speed;
  protected PVector direction;

  public FallingThing(PVector location, PVector dimension, PVector speed, PVector direction)
  {
    super(location, dimension);

    this.speed = speed;
    this.direction = direction;
  }  

  public PVector getSpeed()
  {
    return this.speed;
  }

  public PVector getDirection()
  {
    return this.direction;
  }

  public void fall()
  {
    this.location.x = this.location.x + (this.speed.x * this.direction.x);
    this.location.y = this.location.y + (this.speed.y * this.direction.y);
  }

  public void paint()
  {
    fill(250, 150, 150);
    stroke(240, 15, 15);
    strokeWeight(2);

/*
    ellipse(this.location.x + this.dimension.x/2, 
    this.location.y + this.dimension.y/2, 
    this.dimension.x, 
    this.dimension.y);
*/

    rect(this.location.x, 
         this.location.y, 
         this.dimension.x, 
         this.dimension.y);
  }
}

//////////////////////////////////////////////////////////////////////////////

class Paddle extends Thing
{
  public Paddle(PVector location, PVector dimension)
  {
    super(location, dimension);
  }
  
  public void paint()
  {
    fill(251, 201, 81);
    stroke(234, 143, 45);
    strokeWeight(5);
    rect(location.x, location.y, dimension.x, dimension.y);
  }
}

//////////////////////////////////////////////////////////////////////////////

// scores, pause(msg), got/miss(msg)
// change view
// wiimote (2)
// opencv
// kinect

