/*****************************************************************************
 *
 * The Falling Things (concept)
 * ----------------------------
 *
 * Developed by Jorge Iván Meza Martínez (http://jorgeivanmeza.com/) under the
 * license Attribution-NonCommercial-ShareAlike 3.0 Unported (CC BY-NC-SA 3.0)
 * (http://creativecommons.org/licenses/by-nc-sa/3.0/) using thr Processing
 * programming language (http://processing.org/)
 *
 * Collect the falling things until they fall out the universe!
 *
 * Keys:
 *
 *  - (left/right) move the paddle
 *  - (up/down)    change the speed limit of the falling things
 *  - +/-          change the amount of falling things
 *  - p            pause the sketch
 *  - q            quit the sketch
 *
 * @autor    Jorge Iván Meza Martínez
 * @website  http://jorgeivanmeza.com/
 * @email    jimezam@gmail.com
 * @version  0.1
 * @date     20120106
 ****************************************************************************/

//////////////////////////////////////////////////////////////////////////////

/**
 * Sketch universe container
 */

Universe universe;

/**
 * Images to display as signs
 */

PImage[] graphics;

//////////////////////////////////////////////////////////////////////////////

void setup() 
{
  size(640, 480);
  frameRate(30);
  noStroke();
  smooth();
  
  // Load the images to display as signs
  
  graphics = new PImage[] {
    loadImage("img/baby_smiling.png"),    // A falling thing was catched  
    loadImage("img/baby_sad.png")         // A falling thing was missed
  };
  
  // Set the default enviroment values
  
  reset();  
}

void reset()
{
  // Proportion between the height of sky/ground in the universe
  
  float ratio = 3F/4;
  
  // Create the universe
  
  universe = new Universe(ratio);
  
  // Draw it for first time
  
  redraw();
}

void draw() 
{
  background(244);

  // If the sketch is not paused

  if(universe.isActive())
  {  
    // Draw the current state of the universe
    
    universe.paint();
  
    // Let the things happen to update the state of the universe
  
    universe.passTime();
  }
  else    // If the sketch is paused
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
      case LEFT:                    // Move the paddle to the left
        universe.movePaddle(LEFT);
      break;
      
      case RIGHT:                   // Move the paddle to the right 
        universe.movePaddle(RIGHT);
      break;
      
      case UP:                      // Increase the falling things speed limit
        universe.setMaxFallingThingsSpeed(universe.getMaxFallingThingsSpeed() + 0.1);
      break;

      case DOWN:                    // Decrease the falling things speed limit
        universe.setMaxFallingThingsSpeed(universe.getMaxFallingThingsSpeed() - 0.1);
      break;
    }
  }
  else
  {
    switch(key)
    {
      case 'r':                      // Reset the sketch
        reset();
      break;
      
      case 'p':                      // Pause the sketch
        universe.toggleActive();
      break;
      
      case 'q':                      // Quit the sketch
        println("Goodbye!");
        exit();
      break;
      
      case '+':                      // Increase the amount of things falling
        universe.setMaxFallingThingsCount(universe.getMaxFallingThingsCount() + 1);
      break;
      
      case '-':                      // Decrease the amount of falling things
        universe.setMaxFallingThingsCount(universe.getMaxFallingThingsCount() - 1);
      break;
    }
  }
}

void mouseMoved() 
{
  // Move the paddle to the selected -horizontal- position
  
  universe.movePaddleTo(mouseX);
}

//////////////////////////////////////////////////////////////////////////////

/**
 * Contain and control the whole world of the sketch
 */

class Universe extends Thing
{
  /**
   * Ratio between the sky and ground heights
   */

  private float ratio;

  /**
   * Sky part of the universe
   */

  private Sky sky;

  /**
   * Ground part of the universe
   */

  private Ground ground;

  /**
   * User controlled element to catch the falling things
   */

  private Paddle paddle;

  /**
   * Falling things from the sky
   */

  private ArrayList<FallingThing> fallingThings;

  /**
   * Maximun number of falling things in one moment of time
   */

  private int maxFallingThingsCount;

  /**
   * Maximun speed for the falling things
   */

  private float maxFallingThingsSpeed;
  
  /**
   * Determine if universe is active (playing) or not (paused)
   */

  private boolean active;
  
  /**
   * Amount of falling things catched
   */

  private int scoreGood;

  /**
   * Amount of falling things missed
   */

  private int scoreBad;

  /**
   * Width of the falling things graphical representation
   */

  private int fallingThingWidth;

  /**
   * Height of the falling things graphical representation
   */

  private int fallingThingHeight;    

  /**
   * Depth of the falling things graphical representation
   */

  private int fallingThingDepth;    
  
  /**
   * Index of the sign to show. -1 means none
   */

  private int showSign;

  /**
   * Amount of time to show the current sign
   */

  private int showSignTime;

  /**
   * Universe constructor
   *
   * @param  ratio between sky and ground heights
   */

  public Universe(float ratio)
  {
    super(new PVector(0, 0), 
          new PVector(width, height));
          
    this.ratio = ratio;

    // Create the sky and the ground

    this.sky = new Sky(ratio);
    this.ground = new Ground(1 - ratio);

    // Set default dimension for the paddle

    int paddleIniWidth  = 110;
    int paddleIniHeight = 30;
    int paddleIniDepth  = 50;

    // Create the paddle for the user

    this.paddle = new Paddle(new PVector((width - paddleIniWidth)/2, 
                                         height - paddleIniHeight - 10), 
                             new PVector(paddleIniWidth, 
                                         paddleIniHeight, 
                                         paddleIniDepth));
                                 
    // Create the falling things storage                                 
                                    
    this.fallingThings = new ArrayList();
    
    // Set default falling things values
    
    this.maxFallingThingsCount = 5;
    this.maxFallingThingsSpeed = 2.5;
    
    // The sketch is active
    
    this.active = true;
    
    // Set empty the scores
    
    this.scoreGood = 0;
    this.scoreBad  = 0;

    // Set default falling things dimensions
    
    this.fallingThingWidth  = 50;
    this.fallingThingHeight = 50;    
    this.fallingThingDepth  = 50;

    // Do not show any sign for beginning

    this.showSign = -1;
    this.showSignTime = 0;    
  }

  /**
   * Draw the graphical inerface of the universe
   */

  public void paint()
  {
    // Draw the sky and the ground
    
    sky.paint();
    
    ground.paint();
    
    // Show the success/failure sign if it is required
    
    if(this.showSign >= 0 && this.showSignTime > 0)
    {
      // Set transparency level
      
      tint(255, 170);
      
      // Display the image
      
      image(graphics[this.showSign], (width - 300)/2, 80, 300, 220);
      
      noTint();
      
      // Check if it has been shown enough and remove it
      
      if(millis() >= this.showSignTime)
        hideSign();
    }
    
    // Draw the falling things and make them fall
    
    for(FallingThing fthing : this.fallingThings)
    {
      fthing.paint();
      fthing.fall();
    }
    
    // Draw the user's paddle
    
    paddle.paint();
    
    // Draw the score string line
    
    String message = "The Falling Things catched: " + this.scoreGood +
                     "; missed: " + this.scoreBad +
                     "; amount: " + this.maxFallingThingsCount +
                     "; speed limit: " + nf(this.maxFallingThingsSpeed, 1, 1);
    
    fill(0);
    textSize(18);
    textAlign(CENTER, CENTER);
    text(message, width/2, 20);
  }
  
  /**
   * Move the paddle one step in the selected direction
   *
   * @param  direction of the movement {LEFT, RIGHT}
   */

  public void movePaddle(int direction)
  {
    // Check if the sketch is active
    
    if(!this.isActive())
      return;
    
    // Set the size of the step
    
    int step = 10;
    
    // Calculate the new location of the paddle after the movement
    
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
    
    // Set the new location to the paddle
    
    paddle.setLocation(new PVector(x, y, z));
  }
  
  /**
   * Move the paddle to specific location on the universe
   *
   * @param  specific horizontal location
   */

  public void movePaddleTo(int nx)
  {
    // Check if the sketch is active
    
    if(!this.isActive())
      return;

    // Calculate the new location of the paddle using the specified
    // location as its center
    
    PVector dimension = paddle.getDimension();
    
    float x = nx - (dimension.x/2F);
    float y = paddle.getLocation().y;
    float z = paddle.getLocation().z;
    
    x = constrain(x, 0, width - dimension.x);

    // Set the new location to the paddle
    
    paddle.setLocation(new PVector(x, y, z));
  }
  
  /**
   * Make the things happen in the universe for an unit of time ellapsed
   */

  public void passTime()
  {
    // Check if there are enough falling things on the universe or
    // create a new one
    
    if(this.fallingThings.size() < this.maxFallingThingsCount)
    {
      this.fallingThings.add(this.createFallingThing());
    }

    // Check for collisions with the falling thigs

    handleCollisions();
  }
  
  /**
   * Handle the collisions between the falling thins and the paddle
   */

  private void handleCollisions()
  {
    // Check collisions between falling things, in case of have them
    // the falling things will push each others
    
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
        
        // Check for collisions between selected falling things
        
        if(fthing.hasCollision(fthing2))
        {
          // If one is above the other, push it
          
          if(fthing.isAbove(fthing2))
          {
            // Calculate the distance to push
            
            float diff = (fthing.location.y + fthing.dimension.y) - fthing2.getLocation().y;
            
            PVector newLocation = fthing2.getLocation();
            
            // Set the new location for the falling thing pushed
            
            newLocation.y += diff + 6; 
            
            fthing2.setLocation(newLocation);
          }
        }
      }      
      
      boolean explode = false;      
      
      // Checking collision with the paddle (you got it)
      
      if(fthing.hasCollision(this.paddle))
      {
        // Mark the falling thing to be removed
        
        explode = true;
        
        // Update the score
        
        this.scoreGood ++;
        
        // Display the success sign
        
        showSign(0, 1.5);
      }
      
      // Checking things leaving the universe (you missed it)
      
      if(!fthing.hasCollision(this))
      {
        // Mark the falling thing to be removed
        
        explode = true;
        
        // Update the score
        
        this.scoreBad ++;
        
        // Display the failure sign
        
        showSign(1, 1.5);
      }
      
      // Exploding the current thing
      
      if(explode)
      {
        this.fallingThings.remove(i);
        
        i--;
      }      
    }
  }
  
  /**
   * Display the specified sign for an specific amount of time
   *
   * @param  index of the desired sign
   * @param  amount of time (seconds) to display the sign on screen
   */

  public void showSign(int signIndex, float seconds)
  {
    this.showSign = signIndex;
    
    this.showSignTime = int(millis() + seconds * 1000);
  }
  
  /**
   * Disable the current sign and avoid displaying it 
   */

  public void hideSign()
  {
    this.showSign = -1;
    
    this.showSignTime = 0;
  }
  
  /**
   * Create a new falling thing in a random place with random speed
   *
   * @return  a new falling thing with random location and speed
   */

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
  
  /**
   * Pause/resume the universe (sketch)
   */

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
  
  /**
   * Check if the universe is active or not
   *
   * @return  true if the universe is active, false otherwise
   */

  public boolean isActive()
  {
    return this.active;
  }
  
  /**
   * Get the maximun falling things speed
   *
   * @param  maximun falling things speed
   */

  public float getMaxFallingThingsSpeed()
  {
      return this.maxFallingThingsSpeed;
  }
  
  /**
   * Set the maximun falling things speed
   *
   * @param   new falling things speed
   * @pre     new speed > 0
   * @return  true if the speed was succesfuly changed, false otherwise
   */

  public boolean setMaxFallingThingsSpeed(float value)
  {
    if(value < 0)
      return false;
      
    this.maxFallingThingsSpeed = value;
      
    return true;
  }
  
  /**
   * Get the maximun amount of falling thins in one time unit
   *
   * @return  maximun amount of falling things
   */

  public int getMaxFallingThingsCount()
  {
      return this.maxFallingThingsCount;
  }
  
  /**
   * Set the maximun amount of falling things in one time unit
   *
   * @param   new amount of falling things
   * @pre     new amount > 0
   * @return  true if the amount was succesfuly changed, false otherwise
   */

  public boolean setMaxFallingThingsCount(int value)
  {
    if(value < 0)
      return false;
      
    this.maxFallingThingsCount = value;
      
    return true;
  }
}

//////////////////////////////////////////////////////////////////////////////

/**
 * Sky part of the universe
 */

class Sky extends Thing
{
  /**
   * Construct the sky with given height
   */

  public Sky(float pHeight)
  {
    super(new PVector(0, 0), 
          new PVector(width, pHeight * height));
  }

  /**
   * Draw the content of the sky
   */

  public void paint()
  {
    noStroke();
    fill(186, 224, 251);
    rect(location.x, location.y, dimension.x, dimension.y);
  }
}

//////////////////////////////////////////////////////////////////////////////

/**
 * Ground part of the universe
 */

class Ground extends Thing
{
  /**
   * Construct the ground with given height
   */
  
  public Ground(float pHeight)
  {
    super(new PVector(0, (1 - pHeight) * height), 
          new PVector(width, pHeight * height));
  }

  /**
   * Draw the content of the ground
   */

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

/**
 * Generic entity with location and dimension
 */

abstract class Thing
{
  /**
   * Location (x,y,z) of the thing
   */

  protected PVector location;

  /**
   * Dimension along (x,y,z) of the thing
   */

  protected PVector dimension;

  /**
   * Construct the thing with given location and dimension
   *
   * @param  specified location
   * @param  specified dimension
   */

  public Thing(PVector location, PVector dimension)
  {
    this.location = location;
    this.dimension = dimension;
  }

  /**
   * Get the location of the thing
   *
   * @return  location of the thing
   */

  public PVector getLocation()
  {
    return this.location;
  }
  
  /**
   * Set the location of the thing
   *
   * @param  new location of the thing
   */

  public void setLocation(PVector newLocation)
  {
    this.location = newLocation;
  }
  
  /**
   * Get the dimension of the thing
   *
   * @return   dimension of the thing
   */

  public PVector getDimension()
  {
    return this.dimension;
  }
  
  /**
   * Check if thing thing has a collision with another thing
   *
   * @param   the second thing to check collision with
   * @return  true if two things collide or false otherwise
   */

  public boolean hasCollision(Thing thing)
  {
    if ((this.location.x + this.dimension.x >= thing.getLocation().x)       &&
        (this.location.x <= thing.getLocation().x + thing.getDimension().x) &&
        (this.location.y + this.dimension.y >= thing.getLocation().y)       &&
        (this.location.y <= thing.getLocation().y + thing.getDimension().y))    
     {
       return true;
     }  
     
     return false;
  }

  /**
   * Draw the current thing in a generic way (should be overriden)
   */

  public void paint()
  {
    ellipse(this.location.x + this.dimension.x/2, 
    this.location.y + this.dimension.y/2, 
    this.dimension.x, 
    this.dimension.y);
  }
}

//////////////////////////////////////////////////////////////////////////////

/**
 * Special kind of thing that can fall down
 */

public class FallingThing extends Thing
{
  /**
   * Falling speed
   */

  protected PVector speed;

  /**
   * Direction of the movement
   */

  protected PVector direction;

  /**
   * Construct the falling thing with given location, dimension, speed and direction
   */

  public FallingThing(PVector location, PVector dimension, PVector speed, PVector direction)
  {
    super(location, dimension);

    this.speed = speed;
    this.direction = direction;
  }  

  /**
   * Get the current speed of the falling thing
   *
   * @return  falling speed
   */

  public PVector getSpeed()
  {
    return this.speed;
  }

  /**
   * Get the direction of the movement of the falling thing
   *
   * @return  direction of the movement
   */

  public PVector getDirection()
  {
    return this.direction;
  }

  /**
   * Move (make it fall) the falling thing according its current location and speed
   */

  public void fall()
  {
    this.location.x = this.location.x + (this.speed.x * this.direction.x);
    this.location.y = this.location.y + (this.speed.y * this.direction.y);
  }

  /**
   * Draw the falling thing in its current location
   */

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
  
  /**
   * Test if this falling thing is above another or not
   *
   * @param   Another thing to check with
   * @return  true if this falling thing is above the other, false otherwise
   */

  public boolean isAbove(Thing other)
  {
    if(this.location.y < other.getLocation().y)
      return true;
    
    return false;  
  }
}

//////////////////////////////////////////////////////////////////////////////

/*
 * Paddle controlled by the user
 */

class Paddle extends Thing
{
  /**
   * Construct the paddle with the given location and dimension
   */

  public Paddle(PVector location, PVector dimension)
  {
    super(location, dimension);
  }
  
  /**
   * Draw the paddle in its current location 
   */

  public void paint()
  {
    fill(251, 201, 81);
    stroke(234, 143, 45);
    strokeWeight(5);
    rect(location.x, location.y, dimension.x, dimension.y);
  }
}

//////////////////////////////////////////////////////////////////////////////

// sound
// change view
// wiimote (2)
// opencv
// kinect
