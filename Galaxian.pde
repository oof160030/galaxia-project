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

public void setup()
{
  //sets size of the screen : X = 700, Y = 600
  size(700, 600);
  frameRate(60);

  // Creates the ship sprite on the screen (stationary)
  ship = new Sprite(this, "ship.png", 1, 1, 50);
  ship.setXY(width/2, height - 30);
  ship.setVelXY(0.0f, 0);
  ship.setScale(.75);
  
  // Domain keeps the ship within the screen 
  ship.setDomain(0, height-ship.getHeight(), width, height, Sprite.HALT);

  grid = new Sprite[50];
  
  // Creates an array of monsters (monster grid)
  buildMonster();
  buildRocket();
  controllIO = ControlIO.getInstance(this);
  keyboard = controllIO.getDevice("Keyboard");
  spaceBtn = keyboard.getButton("Space");   
  leftArrow = keyboard.getButton("Left");   
  rightArrow = keyboard.getButton("Right");
  
  //"pop" sound made when called
  minimplay = new Minim(this); 
  popPlayer = minimplay.loadSample("pop.wav", 1024);

  registerMethod("pre", this);
}

// Function defining how the ship will move
void pre()
{
    if (focused) {
      if (leftArrow.pressed()) {
        ship.setX(ship.getX()-5);
      }
      if (rightArrow.pressed()) {
        ship.setX(ship.getX()+5);
      }
      if (spaceBtn.pressed()) {
        popPlayer.trigger();
        if (rocket.isDead()){
          fireRocket();
        }
      }
  }
  // Checks the postion of the grid
  for (int i = 0; i<=49; i++){
    if(grid[i].getX() > width-100 && right == 1){
      right = 0;
    }
    else if(grid[i].getX() < 100 && right == 0){
      right = 1;
    }
  }
  // Moves the grid in the reverse direction if the grid reaches 2/3rds of the screen
  for (int i = 0; i<=49; i++){
    if(right == 0){
      grid[i].setX(grid[i].getX()-1);
    }
    if(right == 1){
      grid[i].setX(grid[i].getX()+1);
    }
  }
  //Check if monsters are dead
  checkDead();
  
  
  //If bullet flies offscreen
  if (rocket.getY() < 0)
  {
    stopRocket();
  }
  
  monsterHit();
  
  S4P.updateSprites(stopWatch.getElapsedTime());
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

//Check Monster Collision
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

//Check if all dead
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

//Reset Monsters
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


//Build Rocket
void buildRocket()
{
  rocket = new Sprite(this, "rocket.png", 5);
  rocket.setDead(true);
  rocket.setScale(0.5);
  rocket.setXY(0,0);
}

//Fire Rocket
void fireRocket()
{
  rocket.setXY(ship.getX(), ship.getY());
  rocket.setDead(false);
  rocket.setVelY(-500);
}

//Stop Rocket
void stopRocket()
{
  rocket.setVelY(0);
  rocket.setDead(true);
}

void draw() 
{
  background(0);
  S4P.drawSprites();
}
  
