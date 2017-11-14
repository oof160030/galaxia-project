import sprites.utils.*;
import sprites.maths.*;
import sprites.*;
import org.gamecontrolplus.*;
import ddf.minim.*;

//instantiating the sprites
Sprite ship, monster, monster1, rocket;

//instantiating StopWatch to get elapsed time 
StopWatch stopWatch = new StopWatch();

//instantiating a sprite array/grid for the monsters
Sprite [] grid;

int right = 1;

//instantiating the Control buttons
ControlIO controllIO;
ControlDevice keyboard;
ControlButton spaceBtn, leftArrow, rightArrow, downArrow;

//instantiation for sound
Minim minimplay;
AudioSample popPlayer;

//Initializes game objects and sounds before game starts
public void setup()
{
  //sets size of the screen : X = 700, Y = 600
  size(700, 600);
  frameRate(60);

  //Creates the ship and it's rocket
  buildShip();
  buildRocket();

  // Creates an array of monsters (monster grid)
  grid = new Sprite[50];
  buildMonster();

  //Sets up the controls (Mac Version)
  controllIO = ControlIO.getInstance(this);
  keyboard = controllIO.getDevice("Apple Internal Keyboard / Trackpad");
  spaceBtn = keyboard.getButton(" ");   
  leftArrow = keyboard.getButton("Left");   
  rightArrow = keyboard.getButton("Right");
  
  //Loads in sound object for firing gun
  minimplay = new Minim(this); 
  popPlayer = minimplay.loadSample("pop.wav", 1024);

  //Registers pre method used below
  registerMethod("pre", this);
}

//Repeatedly updates attributes of game objects based on input and logic checks
void pre()
{
  // Reads input and controls ship
  checkKeys();
  
  //Checks position of and moves monsters
  moveMonster();
  
  //Check if all the monsters are dead
  checkDead();
  
  
  //If rocket flies offscreen, rocket dies
  if (rocket.getY() < 0)
    stopRocket();
  
  //Checks if any monster has been hit by a rocket
  monsterHit();
  
  //Updates the positions and attributes of sprites 
  S4P.updateSprites(stopWatch.getElapsedTime());
}

//FUNCTIONS FOR BUILDING OBJECTS-------------------------------

//Build Spaceship
void buildShip()
{
  // Creates the ship sprite on the screen (stationary)
  ship = new Sprite(this, "ship.png", 1, 1, 50);
  ship.setXY(width/2, height - 30);
  ship.setVelXY(0.0f, 0);
  ship.setScale(.75);
  
  // Domain keeps the ship within the screen 
  ship.setDomain(0, height-ship.getHeight(), width, height, Sprite.HALT);
}

//Build Rocket
void buildRocket()
{
  rocket = new Sprite(this, "rocket.png", 5);
  rocket.setDead(true);
  rocket.setScale(0.5);
  rocket.setXY(0,0);
}

//Build Monster funciton
void buildMonster()
{
  int index = 0;
  for (int y=1; y<=5; y++)
  {
    for (int x=1; x<=10; x++){
      grid[index] = new Sprite(this, "monster.png", 1, 1, 40);
      grid[index].setXY(width - (75+(x*50)), height - (300+(y*50)));
      grid[index].setScale(0.2);
      //grid[index].setDomain(100, height-grid[index].getHeight(), width - 100, height, Sprite.REBOUND);
      index++;
    }
  }
}

//FUNCTIONS FOR MONSTERS----------------------------------

//Checks position of monsters, moves them all accordinlgy 
void moveMonster()
{
  // Checks the postion of monsters on grid, sets direction they should travel
  for (int i = 0; i<=49; i++){
    if(grid[i].getX() > width-100 && right == 1){
      right = 0;
    }
    else if(grid[i].getX() < 100 && right == 0){
      right = 1;
    }
  }
  // Moves the monsters left or right depending on the direction set above.
  for (int i = 0; i<=49; i++){
    if(right == 0){
      grid[i].setX(grid[i].getX()-1);
    }
    if(right == 1){
      grid[i].setX(grid[i].getX()+1);
    }
  }
}

//Checks If Monster Hit By Rocket
void monsterHit()
{
  if (!rocket.isDead())
  {
    int index = 0;
    for (int y=1; y<=5; y++)
    {
      for (int x=1; x<=10; x++){
        if (!grid[index].isDead() && grid[index].bb_collision(rocket))
        {
          grid[index].setDead(true);
          rocket.setDead(true);
        }
        index++;
      }
    }
  }
}

//Checks if all monsters are dead
void checkDead()
{
  boolean alive = false;  
  int index = 0;
  for (int y=1; y<=5; y++)
    {
      for (int x=1; x<=10; x++){
        if (!grid[index].isDead())
        {
          alive = true;
        }
        index++;
      }
    }
  if (alive == false)
  {
    resetMonsters();
  }
}

//Reset monsters if all dead
void resetMonsters()
{
  int index = 0;
  for (int y=1; y<=5; y++)
    {
      for (int x=1; x<=10; x++){
        grid[index].setDead(false);
        index++;
      }
    }
}

//FUNCTIONS FOR PLAYER--------------------------------
//Reads input for ship
void checkKeys()
{
  if (focused) {
      if (leftArrow.pressed()) {
        ship.setX(ship.getX()-5);
      }
      if (rightArrow.pressed()) {
        ship.setX(ship.getX()+5);
      }
      if (spaceBtn.pressed()) {
        if (rocket.isDead()){
          popPlayer.trigger();
          fireRocket();
        }
     }
  }
}

//Fire Rocket
void fireRocket()
{
  rocket.setXY(ship.getX(), ship.getY());
  rocket.setDead(false);
  rocket.setVelY(-500);
}

//Stops and kills Rocket when called
void stopRocket()
{
  rocket.setVelY(0);
  rocket.setDead(true);
}

//GENERAL USE FUNCTIONS----------------------------------------
//Draws sprites based on current values
void draw() 
{
  background(0);
  S4P.drawSprites();
}
  
