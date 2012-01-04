//////////////////////////////////////////////////////////////////////////////

/**
 * Sketch universe container
 */

Universe universe;

PImage[] graphics;

//////////////////////////////////////////////////////////////////////////////

void setup() 
{
  size(640, 480);
  frameRate(30);
  noStroke();
  smooth();
  
  graphics = new PImage[] {
    loadImage("img/baby_smiling.png"),  
    loadImage("img/baby_sad.png")  
  };
  
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
  background(244);

  if(universe.isActive())
  {  
    universe.paint();
  
    universe.passTime();
  }
  else
  {  
    int l = 260;
    PImage pauseImg = loadImage("img/player_pause.png");
    image(pauseImg, (width - l)/2, (height - l)/2 - 50, l, l);

    fill(0);
    textAlign(CENTER, CENTER);
    textSize(33);
    text("Paused!", 20, (height - l)/2 + l - 50, width - 40, 100);
  }
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
      
      case UP:
        universe.setMaxFallingThingsSpeed(universe.getMaxFallingThingsSpeed() + 0.1);
      break;

      case DOWN:
        universe.setMaxFallingThingsSpeed(universe.getMaxFallingThingsSpeed() - 0.1);
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
      
      case '+':
        universe.setMaxFallingThingsCount(universe.getMaxFallingThingsCount() + 1);
      break;
      
      case '-':
        universe.setMaxFallingThingsCount(universe.getMaxFallingThingsCount() - 1);
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
  
  private int scoreGood;
  private int scoreBad;

  private int fallingThingWidth;
  private int fallingThingHeight;    
  private int fallingThingDepth;    
  
  private int showSign;
  private int showSignTime;

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
    
    this.maxFallingThingsCount = 5;
    this.maxFallingThingsSpeed = 2.5;
    
    this.active = true;
    
    this.scoreGood = 0;
    this.scoreBad  = 0;

    this.fallingThingWidth  = 50;
    this.fallingThingHeight = 50;    
    this.fallingThingDepth  = 50;

    this.showSign = -1;
    this.showSignTime = 0;    
  }

  public void paint()
  {
    sky.paint();
    
    ground.paint();
    
    // Show the success/failure sign
    
    if(this.showSign >= 0 && this.showSignTime > 0)
    {
      tint(255, 170);
      
      image(graphics[this.showSign], (width - 300)/2, 80, 300, 220);
      
      noTint();
      
      if(millis() >= this.showSignTime)
        hideSign();
    }
    
    for(FallingThing fthing : this.fallingThings)
    {
      fthing.paint();
      fthing.fall();
    }
    
    paddle.paint();
    
    String message = "Falling Things catched: " + this.scoreGood +
                     "; missed: " + this.scoreBad +
                     "; amount: " + this.maxFallingThingsCount +
                     "; speed limit: " + nf(this.maxFallingThingsSpeed, 1, 1);
    
    fill(0);
    textSize(18);
    textAlign(CENTER, CENTER);
    text(message, width/2, 20);
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
    if(this.fallingThings.size() < this.maxFallingThingsCount)
    {
      this.fallingThings.add(this.createFallingThing());
    }

    handleCollisions();
  }
  
  private void handleCollisions()
  {
    for(int i=0; i<this.fallingThings.size(); i++)
    {
      FallingThing fthing = this.fallingThings.get(i);
      
      // Checking for collisions between the things (pushing each other)
      
      for(int j=0; j<this.fallingThings.size(); j++)
      {
        // Avoid checking with itself        
        
        if(i == j)
          continue;
          
        // Get the second thing to compare  
          
        FallingThing fthing2 = this.fallingThings.get(j);
        
        if(fthing.hasCollision(fthing2))
        {
          if(fthing.isAbove(fthing2))
          {
            float diff = (fthing.location.y + fthing.dimension.y) - fthing2.getLocation().y;
            
            PVector newLocation = fthing2.getLocation();
            
            newLocation.y += diff + 6; 
            
            fthing2.setLocation(newLocation);
          }
        }
      }      
      
      boolean explode = false;      
      
      // Checking collision with the paddle (you got it)
      
      if(fthing.hasCollision(this.paddle))
      {
        explode = true;
        
        this.scoreGood ++;
        
        showSign(0, 1.5);
        
        println(hour() + ":" + minute() + ":" + second() + "." + millis() + " Got it!");        
      }
      
      // Checking things leaving the universe (you missed it)
      
      if(!fthing.hasCollision(this))
      {
        explode = true;
        
        this.scoreBad ++;
        
        showSign(1, 1.5);
        
        println(hour() + ":" + minute() + ":" + second() + "." + millis() + " Miss it!");        
      }
      
      // Exploding the thing
      
      if(explode)
      {
        this.fallingThings.remove(i);
        
        i--;
      }      
    }
  }
  
  public void showSign(int signIndex, float seconds)
  {
    this.showSign = signIndex;
    
    this.showSignTime = int(millis() + seconds * 1000);
  }
  
  public void hideSign()
  {
    this.showSign = -1;
    
    this.showSignTime = 0;
  }
  
  private FallingThing createFallingThing()
  {
    FallingThing thing;

    float x      = random(0, width - this.fallingThingWidth);
    float speed  = random(0.5, this.maxFallingThingsSpeed);
    
    thing = new FallingThing(new PVector(x, 0), 
                             new PVector(this.fallingThingWidth, this.fallingThingHeight, this.fallingThingDepth), 
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
      
      draw();
      
      println("Getting paused :-(");
    }      
}
  
  public boolean isActive()
  {
    return this.active;
  }
  
  public float getMaxFallingThingsSpeed()
  {
      return this.maxFallingThingsSpeed;
  }
  
  public boolean setMaxFallingThingsSpeed(float value)
  {
    if(value < 0)
      return false;
      
    this.maxFallingThingsSpeed = value;
      
    return true;
  }
  
  public int getMaxFallingThingsCount()
  {
      return this.maxFallingThingsCount;
  }
  
  public boolean setMaxFallingThingsCount(int value)
  {
    if(value < 0)
      return false;
      
    this.maxFallingThingsCount = value;
      
    return true;
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
  
  public boolean isAbove(Thing other)
  {
    if(this.location.y < other.getLocation().y)
      return true;
    
    return false;  
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

// change variables keyboard
// sound
// change view
// wiimote (2)
// opencv
// kinect

