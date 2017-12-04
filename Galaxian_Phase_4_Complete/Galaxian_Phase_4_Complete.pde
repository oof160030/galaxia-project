import sprites.utils.*;
import sprites.maths.*;
import sprites.*;
import org.gamecontrolplus.*;
import ddf.minim.*;

/*******************************************************************************************
DEFINITIONS AND SETUP:
Contains the essential initialization of sprites, certain global objects, and other variables
used throughout the entire program, as well as the actual setup() function that builds most
of the game objects.
Also contains miscellanous tools, such as timer objects.
*******************************************************************************************/
//instantiating the sprites
Sprite ship, monster, falling, rocket, explosionP, explosionXL, logo;
Sprite fallingA, fallingB, shotB, fallingC, fallingC2;
Sprite boss1, boss2, rocketLeft, rocketRight, hand1, hand2, bossHit;
Sprite skull, healthBar, boss3, rabbit, turtle;

//PImage backGround;

//instantiating StopWatch to get elapsed time 
StopWatch stopWatch = new StopWatch();

//Creates timers used in the program
int timer1 = 0; //Delay for monsters falling
boolean timer1On = true;

int timer2 = 0; //Used to time delay for monsterB attacks
boolean timer2On = false;

int timer3 = 0;
boolean timer3On = true;

int timer4 = 0;
boolean timer4On = true;

//instantiating a sprite array/grid for the monsters and explosions
Sprite [] grid;
Sprite [] explosion;
Sprite [] shotC;
Sprite [] fireball;
Sprite [] bounceBeam;
Sprite [] letters;
int right = 1;

//Creating variables monsters use
//fmRight & fmLeft determine the direction of the falling monster
double fmRight = 0;
double fmLeft = 0;
double fmSpeed = 0;
double fmA_Speed = 0;
double fmB_Phase = -1;
int fmC_Chance = 60;

//boss stuff
int bossPhase = 1, bossHealth = 100, hand1Health = 15, hand2Health = 15, attackPhase = 1;
boolean rocketControl = false;
int turtleHP = 10;

//Data used to manage game modes / game over screens
int gameMode = 0; // 0 = Main Menu (not yet programmed), 1 = Endless, 2 = Boss
boolean gameOver = false;
PFont myFont;

//instantiating the Control buttons
ControlIO controllIO;
ControlDevice keyboard;
ControlButton spaceBtn, leftArrow, rightArrow, downArrow, one, two, enter;

//instantiation for sound
Minim minimplay;
AudioSample popPlayer;
AudioSample esplosionPlayer;
AudioSample esplosion2Player;
AudioSample hitPlayer;
AudioSample hit2Player;
AudioSample BossplosionPlayer;

//Tracks the player's score
int score = 0;

//Initializes game objects and sounds before game starts
public void setup()
{
  myFont = createFont("Lucida Console", 32);
  textFont(myFont);
  textAlign(CENTER, CENTER);
  
  //sets size of the screen : X = 700, Y = 600
  size(700, 600);
  frameRate(60);

  //Creates the ship and it's rocket
  buildShip();
  buildRocket();
  
  //Creates sprites for explosions
  explosion = new Sprite[12];
  buildExplosion();

  // Creates an array of monsters (monster grid)
  grid = new Sprite[50];
  shotC = new Sprite[2];
  fireball = new Sprite[3];
  bounceBeam = new Sprite[2];
  letters = new Sprite[11];
  buildMonster();
  buildFalling();
  buildHazards();
  buildLogo();
  buildBoss();

  //Sets up the controls (Win Version)
  controllIO = ControlIO.getInstance(this);
  keyboard = controllIO.getDevice("Keyboard");
  spaceBtn = keyboard.getButton("Space");   
  leftArrow = keyboard.getButton("Left");   
  rightArrow = keyboard.getButton("Right");
  one = keyboard.getButton("1");
  two = keyboard.getButton("2");
  enter = keyboard.getButton("Enter");
  
  //Loads in sound object for firing gun
  minimplay = new Minim(this); 
  popPlayer = minimplay.loadSample("pop.wav", 1024);
  esplosionPlayer = minimplay.loadSample("esplosion.wav", 1024);
  esplosion2Player = minimplay.loadSample("esplosion2.wav", 1024);
  hitPlayer = minimplay.loadSample("hit.wav", 1024);
  hit2Player = minimplay.loadSample("hit2.wav", 1024);
  BossplosionPlayer = minimplay.loadSample("Bossplosion.wav", 1024);
  

  //Registers pre method used below
  registerMethod("pre", this);
}

/********************************************************************************************
PRE / MAIN
Repeatedly updates attributes of game objects based on input and logic checks. This function
controls the entire game - essential functions that monitor the status of the game are called
here.
*******************************************************************************************/
void pre()
{
  // Reads input and controls ship
  checkKeys();
  
  //Checks position of and moves monsters
  moveMonster();
  checkShots();
  
  //Updates timers
  updateTimers();
  
  checkExplode();
  
  //If rocket flies offscreen, rocket dies
  if (rocket.getY() < 0)
        stopRocket();
  //Checks if any monster has been hit by a rocket
      monsterHit();
      fallingHit();
  
  if (gameMode == 2)
  {
  //Selects a monster to fall based on timer
      if (timer1 >= 30)
      {
        timer1 = 0;
        timer1On = true;
        if (gameOver == false && checkDeadFM() && checkDead() != -1)
        {
          chooseFalling();
        }
      }
      //If basic monster falls off the screen
      if (!falling.isDead() && !falling.isOnScreem())
      {
        falling.setDead(true);
        timer1On = true;
      }
      changeFalling();
  }
  
  //Collision of falling monster with ship
  Collision();

  if(gameMode == 0)
  {
  drawMainMenu();
  }
  if(gameMode == 1)
  {  
    //Check if all the monsters are dead
    if (checkDead() == -1 && checkDeadFM())
     {
       resetMonsters(5);
     }
  
      //Selects a monster to fall based on timer
      if (timer1 >= 30)
      {
        timer1 = 0;
        if (gameOver == false && checkDeadFM())
        {
          timer1On = false;
          chooseFalling();
        }
      }

      //If basic monster falls off the screen
      if (!falling.isDead() && !falling.isOnScreem())
      {
        falling.setDead(true);
        timer1On = true;
      }
      
      
      //If all falling monsters are dead, activate timer regardless
      if (checkDeadFM())
      {
        timer1On = true;
      }
      
      //Controls each falling monster's movements
      changeFalling();
    }
    if(gameMode == 2)
    {
      bossMode();
    }
      
  
  //Updates the positions and attributes of sprites 
  S4P.updateSprites(stopWatch.getElapsedTime());
}

/*******************************************************************************************
FUNCTIONS FOR BUILDING OBJECTS:
Contains the build function for every object used in the game. Currently includes:
- ship (the player's ship used in the game)
- rocket (the main weapon the ship fires)
- monster / grid[index] (an array of weak monsters ]hat the player faces)
- falling (the basic falling enemy, it changes direction at random. Shares a sprite with fallingA)
- fallingA, fallingB, fallingC (advanced falling enemies with unique movement patterns)
- shotB (a projectile used by fallingA)
- explosionP / explosion[index] (explosion graphics, both the player specific one and the generic one)
*******************************************************************************************/


//Build Spaceship
void buildShip()
{
  // Creates the ship sprite on the screen (stationary)
  ship = new Sprite(this, "ship_anim.png", 3, 1, 50);
  ship.setXY(width/2, height - 30);
  ship.setVelXY(0.0f, 0);
  ship.setScale(0.25);
  ship.setFrame(0);
  ship.setDead(true);
  
  // Domain keeps the ship within the screen 
  ship.setDomain(0, height-ship.getHeight(), width, height, Sprite.HALT);
}

//Build Rocket
void buildRocket()
{
  rocket = new Sprite(this, "laser.png", 5);
  rocket.setDead(true);
  rocket.setScale(0.1);
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
      grid[index].setScale(0.25);
      grid[index].setDead(true);
      //grid[index].setDomain(100, height-grid[index].getHeight(), width - 100, height, Sprite.REBOUND);
      index++;
    }
  }
}

//Build Falling Monster
void buildFalling()
{
  falling = new Sprite(this, "monster2.png", 1, 1, 60);
  falling.setXY(0,0);
  falling.setScale(0.25);
  falling.setDead(true);
  falling.setDomain(0, 0, width, height+100, Sprite.REBOUND);
  
  fallingA = new Sprite(this, "monster_A_anim.png", 4, 1, 60);
  fallingA.setXY(0,0);
  fallingA.setScale(0.25);
  fallingA.setDead(true);
  fallingA.setDomain(0, 0, width, height+100, Sprite.REBOUND);
  
  fallingB = new Sprite(this, "monster_B_anim.png", 8, 2, 60);
  fallingB.setXY(0,0);
  fallingB.setScale(0.25);
  fallingB.setDead(true);
  fallingB.setDomain(0, 0, width, height+100, Sprite.REBOUND);
  
  fallingC = new Sprite(this, "monster_C_anim.png", 5, 1, 60);
  fallingC.setXY(0,0);
  fallingC.setScale(0.25);
  fallingC.setDead(true);
  fallingC.setDomain(0, 0, width, height+100, Sprite.REBOUND);
  
  fallingC2 = new Sprite(this, "monster_C2_anim.png", 5, 1, 60);
  fallingC2.setXY(0,0);
  fallingC2.setScale(0.25);
  fallingC2.setDead(true);
  fallingC2.setDomain(0, 0, width, height+100, Sprite.REBOUND);
}

void buildHazards()
{
  shotB = new Sprite(this, "bullet_B.png", 1, 1, 60);
  shotB.setXY(0,0);
  shotB.setScale(0.25);
  shotB.setDead(true);
  shotB.setDomain(0, 0, width, height+100, Sprite.REBOUND);
  
  for (int index = 0; index <=1; index++)
  {shotC[index] = new Sprite(this, "bullet_C.png", 1, 1, 60);
  shotC[index].setXY(0,0);
  shotC[index].setScale(0.25);
  shotC[index].setDead(true);
  shotC[index].setDomain(0, 0, width, height+100, Sprite.REBOUND);
  }
  
}

//Build Explosion
void buildExplosion()
{
  explosionP = new Sprite(this, "explosion2_anim.png", 9, 1, 75);
  explosionP.setDead(true);
  explosionP.setXY(0,0);
  explosionP.setScale(0.25);
  
  explosionXL = new Sprite(this, "explosion_anim.png", 7, 1, 75);
  explosionXL.setDead(true);
  explosionXL.setXY(0,0);
  explosionXL.setScale(0.5);
  
  for (int index = 0; index<=11; index++)
  {
    explosion[index] = new Sprite(this, "explosion_anim.png", 7, 1, 80);
    explosion[index].setDead(true);
    explosion[index].setXY(0,0);
    explosion[index].setScale(0.25);
  }
}

void buildLogo()
{
  logo = new Sprite(this, "Title.png", 1, 1, 50);
  logo.setXY(width/2, height - 500);
  logo.setScale(0.5);
  logo.setDead(false);
}

void buildBoss()
{
  boss1 = new Sprite(this, "boss_anim.png", 5, 2, 60);
  boss1.setXY(width/2, height - 500);
  boss1.setScale(.75);
  boss1.setDead(true);
  boss1.setDomain(0, 0, width, height+100, Sprite.REBOUND);
  
  boss2 = new Sprite(this, "boss2_anim.png", 6, 3, 60);
  boss2.setXY(width/2, height - 500);
  boss2.setScale(0.75);
  boss2.setDead(true);
  boss2.setDomain(0, 0, width, height+100, Sprite.REBOUND);
  
  boss3 = new Sprite(this, "boss_defeat_anim.png", 6, 3, 60);
  boss3.setXY(width/2, height - 500);
  boss3.setScale(.75);
  boss3.setDead(true);
  
  hand1 = new Sprite(this, "hand1_anim.png", 3, 3, 50);
  hand1.setXY(width/2, height - 500);
  hand1.setScale(0.75);
  hand1.setDead(true);
  
  hand2 = new Sprite(this, "hand2_anim.png", 3, 3, 50);
  hand2.setXY(width/2, height - 500);
  hand2.setScale(0.75);
  hand2.setDead(true);
  
  rocketLeft = new Sprite(this, "left_rocket.png", 2, 2, 55);
  rocketLeft.setXY(width/2, height - 500);
  rocketLeft.setScale(0.75);
  rocketLeft.setDead(true);
  
  rocketRight = new Sprite(this, "right_rocket.png", 2, 2, 55);
  rocketRight.setXY(width/2, height - 500);
  rocketRight.setScale(0.75);
  rocketRight.setDead(true);
  
  for (int i = 0; i<=2 ; i++)
  {
  fireball[i] = new Sprite(this, "fireball_anim.png", 2, 1, 49);
  fireball[i].setXY(width/2, height - 500);
  fireball[i].setScale(0.6);
  fireball[i].setDead(true);
  }
  
  for (int i = 0; i<=1 ; i++)
  {
  bounceBeam[i] = new Sprite(this, "bounce_beam.png", 2, 1, 49);
  bounceBeam[i].setXY(width/2, height - 500);
  bounceBeam[i].setScale(0.75);
  bounceBeam[i].setDead(true);
  }
  
  bossHit = new Sprite(this, "boss_hit.png", 3, 3, 70);
  bossHit.setXY(0,0);
  bossHit.setScale(0.75);
  bossHit.setDead(true);
  
  skull = new Sprite(this, "skull.png", 1, 1, 200);
  skull.setXY(width/2,10);
  skull.setScale(0.5);
  skull.setDead(true);
  
  healthBar = new Sprite(this, "bar.png", 1, 1, 199);
  healthBar.setXY(width/2,10);
  healthBar.setScale(0.5);
  healthBar.setDead(true);
  
  rabbit = new Sprite(this, "rabbit_anim.png", 3, 1, 199);
  rabbit.setXY(width/2,10);
  rabbit.setScale(0.5);
  rabbit.setDead(true);
  
  turtle = new Sprite(this, "turtle_anim.png", 2, 1, 199);
  turtle.setXY(width/2,10);
  turtle.setScale(0.5);
  turtle.setDead(true);
  
  for (int i = 0; i<=10 ; i++)
  {
  letters[i] = new Sprite(this, "letters.png", 4, 2, 49);
  letters[i].setXY(width/2, height - 500);
  letters[i].setScale(0.75);
  letters[i].setDead(true);
  }
  letters[0].setFrame(0);
  letters[1].setFrame(1);
  letters[2].setFrame(1);
  letters[3].setFrame(2);
  letters[4].setFrame(3);
  letters[5].setFrame(4);
  letters[6].setFrame(5);
  letters[7].setFrame(6);
  letters[8].setFrame(7);
  letters[9].setFrame(3);
  letters[10].setFrame(4);
}

/*******************************************************************************************
*******************************************************************************************
FUNCTIONS FOR MONSTERS:
Contains the code that controls all types of basic enemies - both the standard and falling
monster's code is here.
*******************************************************************************************
*******************************************************************************************/

/*******************************************************************************************
Normal Monsters:
Contains the functions that move the basic monsters, makes them turn at the edge of the
screen, resets monsters if they all die, and allows them to be killed by weapons.
*******************************************************************************************/

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
          makeExplode(grid[index].getX(),grid[index].getY());
          esplosion2Player.trigger();
          score += 10;
        }
        index++;
      }
    }
  }
}

//Checks if all normal monsters are dead
int checkDead()
{  
  int index = 0;
  for (int y=1; y<=5; y++)
    {
      for (int x=1; x<=10; x++){
        if (!grid[index].isDead())
        {
          return index;
        }
        index++;
      }
    }
   return -1;
}

//Reset monsters if all dead
void resetMonsters(int rows)
{
  int index = 0;
  for (int y=1; y<=rows; y++)
    {
      for (int x=1; x<=10; x++){
        grid[index].setDead(false);
        index++;
      }
    }
}

/*******************************************************************************************
Falling Monster:
Contains the functions that select which monsters should change to falling monsters, as well
as the code for the three types of falling monster: Sawblade, Warper, and Twin. Also contains
the basic falling enemy code used in Phase 4.
********************************************************************************************/
//Randomly selects a living monster
void chooseFalling()
{
  int chosen = -1;
  int index = 0;
  while (chosen == -1)
  {
    for (int y=1; y<=5; y++)
    {
      for (int x=1; x<=10; x++){
        if (chosen == -1 && !grid[index].isDead() && (random(70-y) < 1))
        {
          chosen = index;
          grid[index].setDead(true);
          setFalling2(chosen, x);
        }
        index++;
      }
    }
    if (index >= 50)
      index = 0;
  }
}

//Initiates special falling monsters
void setFalling2(int chosen, int col)
{
  double num = random(0.0,4.0);
  
  //bland monster stuff
  
  if (num <= 1.0 && num >= 0.0)
  {
  falling.setDead(false);
  falling.setXY(grid[chosen].getX(),grid[chosen].getY());
  falling.setFrameSequence(0, 3, 0.1);
  fmRight = random(0.78, 1.18);
  fmLeft = random(1.96, 2.36);
  
  if (col >= 6)
    falling.setSpeed(125,fmRight);
  else
    falling.setSpeed(125, fmLeft);
  }
  
  //Monster A - Sawblade
  else if (num <= 2.0 && num > 1.0)
  {
    fallingA.setDead(false);
    fallingA.setXY(grid[chosen].getX(),grid[chosen].getY());
    fallingA.setFrameSequence(0, 3, 0.1);
  }
  
  //Monster B - Warp
  else if (num <= 3.0 && num > 2.0)
  {
    fallingB.setDead(false);
    fallingB.setXY(grid[chosen].getX(),grid[chosen].getY());
    fallingB.setFrameSequence(0, 15, 0.1, 1);
    fmB_Phase = -1;
  }
  
  //Monster C - Mirror
  else if (num <= 4.0 && num > 3.0)
  {
    timer2 = 15;
    timer2On = true;
    
    fallingC.setDead(false);
    fallingC.setXY(grid[chosen].getX(),grid[chosen].getY());
    fallingC.setFrame(2);
    
    fallingC2.setDead(false);
    fallingC2.setXY(width - grid[chosen].getX(),grid[chosen].getY());
    fallingC2.setFrame(2);
    
    fmA_Speed = 0;
    if (col >= 6)
      fmRight = 1; //fmRight is used like a boolean for Monster C
    else
      fmRight = -1;
  }
  
}

//Changes falling monster speed
void changeFalling()
{
  // EXCLUSIVE TO BASIC MONSTER//
  double randomSpeed = random(125,200);
  if (!falling.isDead() && random(25) < 1)
  {
    //Change Speed & direction
    if (falling.getDirection() == fmRight)
      falling.setSpeed(randomSpeed, fmLeft);
    else
      falling.setSpeed(randomSpeed, fmRight);
  }
  
  //EXCLUSIVE TO MONSTER A
  if (!fallingA.isDead())
  {
    //Change acceleration relative to ship
    if (ship.getX() < fallingA.getX() && fmA_Speed > -10 && fallingA.getY() <= 480)
      fmA_Speed = fmA_Speed - 0.5;
    else if (ship.getX() >= fallingA.getX() && fmA_Speed < 10 && fallingA.getY() <= 480)
      fmA_Speed = fmA_Speed + 0.5;
    
    if (fallingA.getX() >= width)
      fallingA.setX(width);
    else if(fallingA.getX() <= 0)
      fallingA.setX(0);
    
    //Move ship downwards and sideways as needed
    fallingA.setX(fallingA.getX() + fmA_Speed);
    fallingA.setY(fallingA.getY()+1);
    
    //Kill if it falls offscreen
    if (fallingA.getY() > width)
      {fallingA.setDead(true);}
  }
  
  //EXCLUSIVE TO MONSTER B
  if (!fallingB.isDead())
  {
    //Phase 0 / -1 (waiting to warp)
    if (fmB_Phase <= 0 && (fallingB.getFrame() == 7 || fallingB.getFrame() == 8))
    {
      double fmB_X = 0;
      //Choose X position
      if (fallingB.getX() >= width/2)
        fmB_X = random(0.0, width/2);
      else
        fmB_X = random(width/2, width);
      
      if (fmB_Phase == -1)
        fallingB.setXY(fmB_X, 320);
      else
        fallingB.setXY(fmB_X, fallingB.getY() + 60);
      
      fmB_Phase = 1;
      timer2 = 0;
      timer2On = true;
    }
    //Phase 1 (waiting to fire)
    else if (fmB_Phase == 1 && timer2 >= 60)
    {
      fmB_Phase = 2;
      timer2 = 0;
      timer2On = false;
      shotB.setDead(false);
      shotB.setXY(fallingB.getX(),fallingB.getY());
      shotB.setSpeed(200, aimShot(fallingB.getX(),fallingB.getY()));
    }
    //Phase 2 (waiting to warp or fall)
    else if (fmB_Phase == 2 && shotB.isDead())
    {
      if (fallingB.getY() > 400)
      {fmB_Phase = 3;
      }
      else
      {fmB_Phase = 0;
      fallingB.setFrameSequence(0, 15, 0.1, 1);
      }
    }
    
    //Phase 3 (waiting to die)
    else if (fmB_Phase == 3)
    {
      if (fallingB.getY() > width)
      {fallingB.setDead(true);}
      else
      {fallingB.setY(fallingB.getY()+3);}
    }
    
  }
  
  // EXCLUSIVE TO MONSTER C
  if (!fallingC.isDead())
  {
    if (random(fmC_Chance) < 1 || fmC_Chance <= 0)
      {fmRight = fmRight*(-1);
       fmC_Chance = 160;}
    else
      {fmC_Chance -= 3;}
      
    if (fmRight == 1 && fmA_Speed < 5)
      {fmA_Speed = fmA_Speed + 0.25;}
    else if (fmRight == -1 && fmA_Speed > -5)
      {fmA_Speed = fmA_Speed - 0.25;}
    
    if (fallingC.getX() >= width || fallingC.getX() <= 0)
      fmA_Speed = -fmA_Speed;
    
    //Move ship downwards and sideways as needed
    fallingC.setX(fallingC.getX() + fmA_Speed);
    fallingC.setY(fallingC.getY()+1);
    
    fallingC2.setX(width - fallingC.getX());
    fallingC2.setY(fallingC.getY());
    
    //Changing sprite if needed
    if (fmA_Speed < -3)
    {
      fallingC.setFrame(0);
      fallingC2.setFrame(4);
    }
    else if (fmA_Speed >= -3 && fmA_Speed < -1)
    {
      fallingC.setFrame(1);
      fallingC2.setFrame(3);
    }
    else if (fmA_Speed >= -1 && fmA_Speed <= 1)
    {
      fallingC.setFrame(2);
      fallingC2.setFrame(2);
    }
    else if (fmA_Speed > 1 && fmA_Speed <= 3)
    {
      fallingC.setFrame(3);
      fallingC2.setFrame(1);
    }
    else
    {
      fallingC.setFrame(4);
      fallingC2.setFrame(0);
    }
    
    //Fire a projectile
    if (timer2 >= 60 && shotC[0].isDead())
    {timer2 = 0;
    shotC[0].setDead(false);
    shotC[0].setXY(fallingC.getX(),fallingC.getY());
    shotC[0].setSpeed(200, 1.57);
    
    shotC[1].setDead(false);
    shotC[1].setXY(fallingC2.getX(),fallingC2.getY());
    shotC[1].setSpeed(200, 1.57);
    }
    
    //Kill if it falls offscreen
    if (fallingC.getY() > width)
      {fallingC.setDead(true);
       fallingC2.setDead(true);}
  }
}

//Checks if all falling monsters are dead
boolean checkDeadFM()
{  
  if (!falling.isDead())
   return false;
  else if (!fallingA.isDead())
   return false;
  else if (!fallingB.isDead())
   return false;
  else if (!fallingC.isDead())
   return false;
  else if (!fallingC2.isDead())
   return false;
  else 
   return true;
}

//Checks If Falling Monster Hit By Rocket
void fallingHit()
{
  if (!rocket.isDead() && !falling.isDead() && falling.bb_collision(rocket))
  {
      falling.setDead(true);
      makeExplode(falling.getX(),falling.getY());
      esplosion2Player.trigger();
      rocket.setDead(true);
      timer1On = true;
      score += 20;
  }
  
  if (!rocket.isDead() && !fallingA.isDead() && fallingA.bb_collision(rocket))
  {
      fallingA.setDead(true);
      makeExplode(fallingA.getX(),fallingA.getY());
      esplosion2Player.trigger();
      rocket.setDead(true);
      timer1On = true;
      score += 20;
  }
  if (!rocket.isDead() && !fallingB.isDead() && fallingB.bb_collision(rocket))
  {
      fallingB.setDead(true);
      makeExplode(fallingB.getX(),fallingB.getY());
      esplosion2Player.trigger();
      rocket.setDead(true);
      timer1On = true;
      timer2On = false;
      score += 20;
  }
  if (!rocket.isDead() && !fallingC.isDead() && fallingC.bb_collision(rocket))
  {
      fallingC.setDead(true);
      fallingC2.setDead(true);
      makeExplode(fallingC.getX(),fallingC.getY());
      esplosion2Player.trigger();
      rocket.setDead(true);
      timer1On = true;
      timer2On = false;
      score += 20;
  }
  
  //Boss interactions
  
  if (!rocket.isDead() && !hand1.isDead() && hand1.bb_collision(rocket))
  {
      rocket.setDead(true);
      timer1On = true;
      bossHit.setDead(false);
      bossHit.setXY(hand1.getX(),hand1.getY());
      bossHit.setFrameSequence(0, 8, 0.03, 1);
      if(hand1Health>=1)
      {
        bossHealth --;
        hand1Health--;
        score += 5;
        hitPlayer.trigger();
      }
      if(hand1Health<=0)
      {
        explosionXL.setDead(false);
        explosionXL.setXY(hand1.getX(),hand1.getY());
        explosionXL.setFrameSequence(0, 8, 0.07, 1);
        hand1.setDead(true);
        score+=50;
        esplosionPlayer.trigger();
      }
      
  }
  
  if (!rocket.isDead() && !hand2.isDead() && hand2.bb_collision(rocket))
  {
      rocket.setDead(true);
      timer1On = true;
      bossHit.setDead(false);
      bossHit.setXY(hand2.getX(),hand2.getY());
      bossHit.setFrameSequence(0, 8, 0.03, 1);
      if(hand2Health>=1)
      {
        bossHealth --;
        hand2Health--;
        score += 5;
        hitPlayer.trigger();
      }
      if(hand2Health<=0)
      {
        explosionXL.setDead(false);
        explosionXL.setXY(hand2.getX(),hand2.getY());
        explosionXL.setFrameSequence(0, 8, 0.07, 1);
        hand2.setDead(true);
        score+=50;
        esplosionPlayer.trigger();
      }
  }
  
  if (!rocket.isDead() && !boss1.isDead() && boss1.bb_collision(rocket))
  {
      rocket.setDead(true);
      timer1On = true;
      if (bossPhase==2)
      {
        bossHit.setDead(false);
        bossHit.setXY(boss1.getX(),boss1.getY());
        bossHit.setFrameSequence(0, 8, 0.03, 1);
        bossHealth --;
        score += 5;
        hitPlayer.trigger();
      }
  }
  
  if (!rocket.isDead() && !boss2.isDead() && boss2.bb_collision(rocket))
  {
      rocket.setDead(true);
      timer1On = true;
      bossHit.setDead(false);
      bossHit.setXY(boss2.getX(),boss2.getY());
      bossHit.setFrameSequence(0, 8, 0.03, 1);
      bossHealth --;
      score += 5;
      hitPlayer.trigger();
  }
  
  if (!rocket.isDead() && !turtle.isDead() && turtle.bb_collision(rocket))
  {
      rocket.setDead(true);
      timer1On = true;
      turtleHP--;
      turtle.setFrameSequence(0,1,0.1,1);
      if (turtleHP<=0)
      {
        turtle.setDead(true);
        score += 15;
        hitPlayer.trigger();
      }
  }
}

// Checks for collision between the falling monster / projectiles and the ship
void Collision()
{
  if (!falling.isDead() && !ship.isDead() && falling.bb_collision(ship))
  {
    //explodeShip();
    falling.setDead(true);
    makeExplode(falling.getX(),falling.getY());
    ship.setDead(true);
    esplosionPlayer.trigger();
    
    //Player Explodes
    explosionP.setDead(false);
    explosionP.setXY(ship.getX(),ship.getY());
    explosionP.setFrameSequence(0, 8, 0.07, 1);
      
    gameOver = true;
    drawGameOver();
  }
  
  if (!fallingA.isDead() && !ship.isDead() && fallingA.bb_collision(ship))
  {
    //explodeShip();
    fallingA.setDead(true);
    makeExplode(fallingA.getX(),fallingA.getY());
    ship.setDead(true);
    esplosionPlayer.trigger();
    
    //Player Explodes
    explosionP.setDead(false);
    explosionP.setXY(ship.getX(),ship.getY());
    explosionP.setFrameSequence(0, 8, 0.07, 1);
      
    gameOver = true;
    drawGameOver();
  }
  
  if (!fallingB.isDead() && !ship.isDead() && fallingB.bb_collision(ship))
  {
    //explodeShip();
    fallingB.setDead(true);
    makeExplode(fallingB.getX(),fallingB.getY());
    ship.setDead(true);
    esplosionPlayer.trigger();
    
    //Player Explodes
    explosionP.setDead(false);
    explosionP.setXY(ship.getX(),ship.getY());
    explosionP.setFrameSequence(0, 8, 0.07, 1);
      
    gameOver = true;
    drawGameOver();
  }
  
  if (!fallingC.isDead() && !ship.isDead() && fallingC.bb_collision(ship))
  {
    //explodeShip();
    fallingC.setDead(true);
    fallingC2.setDead(true);
    makeExplode(fallingC.getX(),fallingC.getY());
    ship.setDead(true);
    esplosionPlayer.trigger();
    timer2On = false;
    
    //Player Explodes
    explosionP.setDead(false);
    explosionP.setXY(ship.getX(),ship.getY());
    explosionP.setFrameSequence(0, 8, 0.07, 1);
      
    gameOver = true;
    drawGameOver();
  }
  
  if (!fallingC2.isDead() && !ship.isDead() && fallingC2.bb_collision(ship))
  {
    //explodeShip();
    fallingC.setDead(true);
    fallingC2.setDead(true);
    makeExplode(fallingC.getX(),fallingC.getY());
    ship.setDead(true);
    esplosionPlayer.trigger();
    timer2On = false;
    
    //Player Explodes
    explosionP.setDead(false);
    explosionP.setXY(ship.getX(),ship.getY());
    explosionP.setFrameSequence(0, 8, 0.07, 1);
      
    gameOver = true;
    drawGameOver();
  }
  
  if (!shotB.isDead() && !ship.isDead() && shotB.bb_collision(ship))
  {
    //explodeShip();
    shotB.setDead(true);
    ship.setDead(true);
    esplosionPlayer.trigger();
    timer2On = false;
    
    //Player Explodes
    explosionP.setDead(false);
    explosionP.setXY(ship.getX(),ship.getY());
    explosionP.setFrameSequence(0, 8, 0.07, 1);
      
    gameOver = true;
    drawGameOver();
  }
  
  if (!shotC[0].isDead() && !ship.isDead() && (shotC[0].bb_collision(ship) || shotC[1].bb_collision(ship)) )
  {
    //explodeShip();
    shotC[0].setDead(true);
    shotC[1].setDead(true);
    ship.setDead(true);
    esplosionPlayer.trigger();
    
    //Player Explodes
    explosionP.setDead(false);
    explosionP.setXY(ship.getX(),ship.getY());
    explosionP.setFrameSequence(0, 8, 0.07, 1);
      
    gameOver = true;
    drawGameOver();
  }
  
  for(int i = 0; i<=2 ; i++)
  {
    if (!fireball[i].isDead() && !ship.isDead() && fireball[i].bb_collision(ship))
      {
        fireball[i].setDead(true);
        ship.setDead(true);
        
        
        //Player Explodes
        explosionP.setDead(false);
        explosionP.setXY(ship.getX(),ship.getY());
        explosionP.setFrameSequence(0, 8, 0.07, 1);
        hit2Player.trigger();
        gameOver = true;
        drawGameOver();
      }
   }
 
  if (!rocketRight.isDead() && !ship.isDead() && rocketRight.bb_collision(ship))
  {
    //explodeShip();
    rocketRight.setDead(true);
    makeExplode(rocketRight.getX(),rocketRight.getY());
    ship.setDead(true);
    hit2Player.trigger();
    
    //Player Explodes
    explosionP.setDead(false);
    explosionP.setXY(ship.getX(),ship.getY());
    explosionP.setFrameSequence(0, 8, 0.07, 1);
      
    gameOver = true;
    drawGameOver();
  }
 
 if (!rocketLeft.isDead() && !ship.isDead() && rocketLeft.bb_collision(ship))
  {
    //explodeShip();
    rocketLeft.setDead(true);
    makeExplode(rocketLeft.getX(),rocketLeft.getY());
    ship.setDead(true);
    hit2Player.trigger();
    
    //Player Explodes
    explosionP.setDead(false);
    explosionP.setXY(ship.getX(),ship.getY());
    explosionP.setFrameSequence(0, 8, 0.07, 1);
      
    gameOver = true;
    drawGameOver();
  }
  
  if (!rabbit.isDead() && !ship.isDead() && rabbit.bb_collision(ship))
  {
    //explodeShip();
    rabbit.setDead(true);
    makeExplode(rabbit.getX(),rabbit.getY());
    ship.setDead(true);
    hit2Player.trigger();
    
    //Player Explodes
    explosionP.setDead(false);
    explosionP.setXY(ship.getX(),ship.getY());
    explosionP.setFrameSequence(0, 8, 0.07, 1);
      
    gameOver = true;
    drawGameOver();
  }
  
  if (!turtle.isDead() && !ship.isDead() && turtle.bb_collision(ship))
  {
    //explodeShip();
    turtle.setDead(true);
    makeExplode(turtle.getX(),turtle.getY());
    ship.setDead(true);
    hit2Player.trigger();
    
    //Player Explodes
    explosionP.setDead(false);
    explosionP.setXY(ship.getX(),ship.getY());
    explosionP.setFrameSequence(0, 8, 0.07, 1);
      
    gameOver = true;
    drawGameOver();
  }
  
  for(int i = 0; i<=10 ; i++)
  {
    if (!letters[i].isDead() && !ship.isDead() && letters[i].bb_collision(ship))
      {
        letters[i].setDead(true);
        ship.setDead(true);
        
        
        //Player Explodes
        explosionP.setDead(false);
        explosionP.setXY(ship.getX(),ship.getY());
        explosionP.setFrameSequence(0, 8, 0.07, 1);
        hit2Player.trigger();
        gameOver = true;
        drawGameOver();
      }
   }
 //Undo if boss not complete
 if (gameMode == 2 && ship.isDead() && bossPhase != 0)
 {
   ship.setDead(false);
   gameOver = false;
   score-=50;
 }
}

/*******************************************************************************************
FUNCTIONS FOR BOSS:
********************************************************************************************/

void bossMode()
{
  phaseControl();
  bossTransition();
  attackControl();
  checkHitImage();
   
  if(bossPhase == 1)
 {
   if(attackPhase == 1 && timer3 >= 60)
   {
     timer3 = 0;
     timer3On = false;
     
     if (random(2.0) < 1.0)
     {
       launchFireball(boss1.getX(), boss1.getY(), 230, 1.04+(0*0.52));
       launchFireball(boss1.getX(), boss1.getY(), 230, 1.04+(1*0.52));
       launchFireball(boss1.getX(), boss1.getY(), 230, 1.04+(2*0.52));
     }
     else
     {
       launchFireball(boss1.getX(), boss1.getY(), 230, 1.04+(0*1.04));
       launchFireball(boss1.getX(), boss1.getY(), 230, 1.04+(1*1.04));
     }
     
    }
    
   else if(attackPhase == 2 && timer3 >= 60)
   {
     timer3 = 0;
     timer3On = false;
     
     if (!hand1.isDead() && !hand2.isDead())
     {
       if (random(2.0) < 1.0)
         launchRocket(hand2.getX(), hand2.getY(), 180, true);
       else
         launchRocket(hand1.getX(), hand1.getY(), 180, false);
     }
     else
     {
       if (!hand2.isDead())
         launchRocket(hand2.getX(), hand2.getY(), 180, true);
       else
         launchRocket(hand1.getX(), hand1.getY(), 180, false);
     }
     rocketControl = false;
    }
  } 
  
  if(bossPhase == 2)
 {
   if(attackPhase == 1 && timer3 >= 60)
   {
     timer3 = 0;
     timer3On = false;
     timer4 = 0;
     timer4On = true;
     
     if (random(2.0) < 1.0)
       boss1.setFrame(9);
     else
       boss1.setFrame(8);
    }
    
   else if(attackPhase == 1 && timer4 >= 60)
   {
     timer4 = 0;
     timer4On = false;
     
     if (boss1.getFrame()==9)
     {  
       boss1.setFrame(0);
       launchRocket(boss1.getX(), boss1.getY(), 360, false);
     }
     else
     {
       boss1.setFrame(0);
       launchRocket(boss1.getX(), boss1.getY(), 360, true);
     }
     rocketControl = false;
    }
    
   else if(attackPhase == 2 && timer3 >= 60)
   {
     timer3 = 0;
     timer3On = false;
     launchFireball(boss1.getX(), boss1.getY(), 290, aimShot(boss1.getX(), boss1.getY()));
     launchFireball(boss1.getX(), boss1.getY(), 265, aimShot(boss1.getX(), boss1.getY()));
     launchFireball(boss1.getX(), boss1.getY(), 240, aimShot(boss1.getX(), boss1.getY()));
    }
    else if(attackPhase == 3 && timer3 >= 60)
   {
     timer3 = 0;
     timer3On = false;
     for (int i = 0; i<=1; i++)
     {
       bounceBeam[i].setDead(false);
       bounceBeam[i].setXY(boss1.getX(), boss1.getY());
     }
     bounceBeam[0].setSpeed(400, 0.52);
     bounceBeam[0].setFrame(1);
     bounceBeam[1].setSpeed(400, 2.62);
     bounceBeam[1].setFrame(0);
    }
  } 
  
  if(bossPhase == 3)
   {
     if(attackPhase == 1)
     {
       timer3On = false;
       timer3 = 0;
       if (checkDead()==-1)
         resetMonsters(2);
       //timer4On=true;
       //imer4 = 0;
      }
      
     else if(attackPhase == 2 && rabbit.isDead())
     {
       timer3 = 0;
       timer3On = false;
       rabbit.setXY(boss2.getX(), boss2.getY());
       rabbit.setDead(false);
       rabbit.setSpeed(250, 1.57);
      }
      
      else if(attackPhase == 3 && turtle.isDead())
     {
       timer3 = 0;
       timer3On = false;
       turtle.setXY(boss2.getX(), boss2.getY());
       turtle.setDead(false);
       turtle.setSpeed(100, 1.57);
       turtleHP = 10;
       turtle.setFrame(0);
      }
    } 
}

void bossTransition()
{
    
  if (bossPhase == 1 && hand1.isDead() && hand2.isDead())
  {
    boss1.setFrameSequence(0,7,0.1,1);
    boss1.setSpeed(120, 0);
    bossPhase=2;
    timer3=0;
    timer3On=true;
    attackPhase=1;
  }
  else if (bossPhase == 2 && bossHealth <= 45)
  {
    boss1.setDead(true);
    boss2.setXY(boss1.getX(), boss1.getY());
    boss2.setDead(false);
    boss2.setFrameSequence(0,17,0.07,1);
    bossPhase=3;
    timer3=0;
    timer3On=true;
    score+=75;
    attackPhase=1;
    boss2.setSpeed(120, 0);
  }
  else if (bossPhase == 3 && bossHealth <= 0)
  {
    bossPhase=4;
    boss2.setDead(true);
    boss3.setXY(boss2.getX(), boss2.getY());
    boss3.setDead(false);
    boss3.setFrameSequence(0,17,0.07,1);
    BossplosionPlayer.trigger();
    score+=100;
    
  }
    
  if (bossPhase == 4 && boss3.getFrame()==17)
  {
    gameOver = true;
    drawGameOver();
    boss3.setDead(true);
  }
}

void phaseControl()
{
  //Update HP Bar
  skull.setX((width/2)+80-(1.6*bossHealth));
  
  if (bossPhase == 1 && attackPhase == 1 && fireball[0].isDead() && fireball[1].isDead() && fireball[2].isDead())
  {
    attackPhase = 2;
    timer3On = true;
  }
  
  else if (bossPhase == 1 && attackPhase == 2 && rocketLeft.isDead() && rocketRight.isDead())
  {
    attackPhase = 1;
    timer3On = true;
    hand1.setFrameSequence(0, 5, 0.1);
    hand2.setFrameSequence(0, 5, 0.1);
  }
  
  else if (bossPhase == 2 && attackPhase == 1 && rocketLeft.isDead() && rocketRight.isDead() && boss1.getFrame()==0)
  {
    attackPhase = 2;
    timer3On = true;
  }
  
  else if (bossPhase == 2 && attackPhase == 2 && fireball[0].isDead() && fireball[1].isDead() && fireball[2].isDead())
  {
    attackPhase = 3;
    timer3On = true;
  }
  
  else if (bossPhase == 2 && attackPhase == 3 && bounceBeam[0].isDead() && bounceBeam[1].isDead())
  {
    attackPhase = 1;
    timer3On = true;
  }
  
  else if (bossPhase == 3 && attackPhase == 1)
  {
    attackPhase = 2;
    timer4=0;
    timer4On=false;
    timer3On = true;
  }
  
  else if (bossPhase == 3 && attackPhase == 2 && rabbit.isDead() && fireball[0].isDead() && fireball[1].isDead() && fireball[2].isDead())
  {
    attackPhase = 3;
    timer3On = true;
  }
  
  else if (bossPhase == 3 && attackPhase == 3 && turtle.isDead() && fireball[0].isDead() && fireball[1].isDead() && fireball[2].isDead())
  {
    attackPhase = 1;
    timer3On = true;
  }
}

void attackControl()
{
  //Drop Rocket
  if (!rocketLeft.isDead() && rocketLeft.getY() >= ship.getY() && rocketControl == false)
  {
    rocketLeft.setSpeed(400, 3.14);
    rocketLeft.setFrameSequence(0,3,0.1);
    rocketControl = true;
  }
  
  if (!rocketRight.isDead() && rocketRight.getY() >= ship.getY() && rocketControl == false)
  {
    rocketRight.setSpeed(400, 0.0);
    rocketRight.setFrameSequence(0,3,0.1);
    rocketControl = true;
  }
  
  //Bounce Beam
  for(int i = 0; i<=1; i++)
  {
   if (bounceBeam[i].getX()>width)
   {
    bounceBeam[i].setX(width);
    bounceBeam[i].setSpeed(400, 2.62);
    bounceBeam[i].setFrame(0);
   }
   if (bounceBeam[i].getX()<0)
   {
    bounceBeam[i].setX(0);
    bounceBeam[i].setSpeed(400, 0.52);
    bounceBeam[i].setFrame(1);
   }
  }
  
  //Rabbot Rocket
  if (!rabbit.isDead() && rabbit.getX() >= width - 20)
  {
    rabbit.setDead(true);
    launchFireball(rabbit.getX(), rabbit.getY(), 30, 1.57);
  } 
  
  //Turtle Rocket
  if (!turtle.isDead() && turtle.getX() >= width)
  {
    turtle.setDead(true);
    launchFireball(turtle.getX(), turtle.getY(), 200, 0);
    launchFireball(turtle.getX(), turtle.getY(), 200, 3.14);
  } 
  
  
}

void launchFireball(double x, double y, double speed, double direction)
{
  boolean launched = false;
  for(int i = 0; i<=2; i++)
  {
   if (!launched && fireball[i].isDead())
   {
    fireball[i].setDead(false);
    fireball[i].setXY(x, y);
    fireball[i].setSpeed(speed, direction);
    fireball[i].setFrameSequence(0 , 1, 0.1);
    launched = true;
   }
  }
}

void launchRocket(double x, double y, double speed, boolean isLeft)
{
  if(isLeft)
  {
    rocketLeft.setDead(false);
    rocketLeft.setXY(x, y);
    rocketLeft.setSpeed(speed, 1.57);
    rocketLeft.setFrame(0);
    
    hand2.setFrame(6);
    hand1.setFrame(7);
  }
  if(!isLeft)
  {
    rocketRight.setDead(false);
    rocketRight.setXY(x, y);
    rocketRight.setSpeed(speed, 1.57);
    rocketRight.setFrame(0);
    
    hand1.setFrame(6);
    hand2.setFrame(7);
  }
}

void checkHitImage()
{
  if (bossHit.getFrame() == 8)
    bossHit.setFrame(0);
}

/*******************************************************************************************
FUNCTIONS FOR PLAYER:
Functions that read player input, control which projectiles the user can fire, and destroys
user projectiles when they fly off screen.
********************************************************************************************/
//Reads input for ship
void checkKeys()
{
  if (focused) {
    if(gameMode == 0 && one.pressed())
      {
          gameMode = 1;
          gameOver = false;
          ship.setDead(false);
          logo.setDead(true);
      }
      if(gameMode == 0 && two.pressed())
      {
          gameMode = 2;
          gameOver = false;
          ship.setDead(false);
          logo.setDead(true);
          
          boss1.setDead(false);
          boss1.setFrame(1);
          boss1.setXY(width/2, 130);
          
          hand1.setDead(false);
          hand1.setFrame(1);
          hand1.setXY(width/2 - 160, 130);
          hand1.setFrameSequence(0, 5, 0.1);
          
          hand2.setDead(false);
          hand2.setFrame(1);
          hand2.setXY(width/2 + 160, 130);
          hand2.setFrameSequence(0, 5, 0.1);
          
          skull.setDead(false);
          healthBar.setDead(false);
          
          bossHealth = 100;
          hand1Health = 15;
          hand2Health = 15;
          bossPhase = 1;
          timer3On = true;
          timer3 = 0;
          attackPhase = 1;
      }
    if((gameMode == 1 || gameMode == 2) && gameOver == true && enter.pressed())
     {
        reset();
     }
    if(!ship.isDead())
    {
    ship.setFrame(0);  
    if (leftArrow.pressed()) {
        ship.setX(ship.getX()-5);
        ship.setFrame(1);
      }
      if (rightArrow.pressed()) {
        ship.setX(ship.getX()+5);
        ship.setFrame(2);
      }
      if (spaceBtn.pressed()) {
        if (rocket.isDead() && !ship.isDead()){
          popPlayer.trigger();
          fireRocket();
        }
     }
    }
  }
}

//Fire Rocket
void fireRocket()
{
  rocket.setXY(ship.getX(), ship.getY());
  rocket.setDead(false);
  rocket.setVelY(-1000);
}

//Stops and kills Rocket when called
void stopRocket()
{
  rocket.setVelY(0);
  rocket.setDead(true);
}

/********************************************************************************************
PROJECTILES AND SPECIAL EFFECTS:
Stores functions that control and create explosions, as well as enemy projectiles, ensuring
they are destroyed when no longer needed.
********************************************************************************************/
//Creating explosions
void makeExplode(double x, double y)
{
  boolean exploded = false;
  for (int index = 0; index<=11; index++)
  {
    if (!exploded && explosion[index].isDead())
    {
      explosion[index].setDead(false);
      explosion[index].setXY(x,y);
      explosion[index].setFrameSequence(0, 6, 0.07, 1);
      exploded = true;
    }
  }
}

void checkExplode()
{
  if (!explosionP.isDead() && explosionP.getFrame() == 8)
  {
    explosionP.setDead(true);
    explosionP.setFrame(0);
  }
  
  if (!explosionXL.isDead() && explosionXL.getFrame() == 6)
  {
    explosionXL.setDead(true);
    explosionXL.setFrame(0);
  }
  
  for (int index = 0; index<=4; index++)
  {
    if (!explosion[index].isDead() && explosion[index].getFrame() == 6)
    {
      explosion[index].setDead(true);
      explosion[index].setFrame(0);
    }
  }
}

void checkShots()
{
  if (!shotB.isDead() && shotB.getY() > height)
  {shotB.setDead(true);}
  
  if (!shotC[0].isDead() && shotC[0].getY() > height)
  {shotC[0].setDead(true); shotC[1].setDead(true);}
  
  if (!shotC[1].isDead() && shotC[0].isDead())
  {shotC[1].setDead(true);}
  
  if (gameMode == 0)
  {
    for (int i = 0; i<=2; i++)
    fireball[i].setDead(true);
    shotC[1].setDead(true);
    shotC[0].setDead(true); 
    shotB.setDead(true);
  }
  
  for (int i = 0; i<=2; i++)
  {if (!fireball[i].isDead() && !fireball[i].isOnScreem())
    fireball[i].setDead(true);
  }
  
  if (!rocketLeft.isDead() && !rocketLeft.isOnScreem())
    rocketLeft.setDead(true);
  if (!rocketRight.isDead() && !rocketRight.isOnScreem())
    rocketRight.setDead(true);
    
  if (!bounceBeam[0].isDead() && !bounceBeam[0].isOnScreem())
    bounceBeam[0].setDead(true);
  if (!bounceBeam[1].isDead() && !bounceBeam[1].isOnScreem())
    bounceBeam[1].setDead(true);
    
  if (!rabbit.isDead() && !rabbit.isOnScreem())
    rabbit.setDead(true);
    
  if (!turtle.isDead() && !turtle.isOnScreem())
    turtle.setDead(true);
}

/********************************************************************************************
GENERAL USE FUNCTIONS:
Stores Functions with no specific purpose, such as timers and simple calculations
********************************************************************************************/
//Updates all running timers
void updateTimers()
{
  if (timer1On == true)
   timer1++;
  
  if (timer2On == true)
   timer2++;
   
   if (timer3On == true)
   timer3++;
   
   if (timer4On == true)
   timer4++;
}

//calculates the direction needed to strike the ship in radians
double aimShot(double x, double y)
{
  //Calculate delta x and delta y
  double dX, dY, dD;
  float dF;
  dX = (ship.getX() - x);
  dY = (ship.getY() - y);
  
  //Find the correct location in radians
  dD = dY/dX;
  dF = (float) dD;
  dF = atan(dF);
  
  if (dF >= 0)
    return (double) dF;
  else
  {
    dD = (double) dF;
    return (3.14+dD);
  }
}


/*******************************************************************************************
DRAWING FUNCTIONS:
Stores data used to draw text and sprites.
********************************************************************************************/
//Draws sprites based on current values
void draw() 
{
  //backGround = loadImage("starBackground.jpg");
  //background(backGround);
  background(0);
  S4P.drawSprites();
  drawscore();
  drawGameOver();
  drawMainMenu();
}

//Draws Game Over Screen
void drawGameOver()
{
  if(gameOver == true && gameMode == 1)
  {
    textSize(64);
    textAlign(CENTER, CENTER);
    text("Game Over", width/2, height/2);
    textSize(20);
    text("Press Enter to return to main menu", width/2, height - 150);
  }
  if(gameOver == true && gameMode == 2)
  {
    textSize(60);
    textAlign(CENTER, CENTER);
    text("Congratulations, You Won!", width/2, height/2);
    textSize(20);
    text("Presss Enter to return to main menu", width/2, height - 150);
  }
}

//Draws Score (both during game and game over)
void drawscore()
{
  if (ship.isDead() && (gameMode == 1 || gameMode == 2))
  {
    textAlign(CENTER, CENTER);
    text("Score: " + score, width/2, height - 200);
  }
  else if(!ship.isDead() && (gameMode == 1 || gameMode == 2))
  {
    textAlign(LEFT, CENTER);
    textSize(20);
    text("Score: " + score, 10, 10);
  }
}

//main menu stuff
void drawMainMenu()
{
  if(gameMode == 0)
  {
    textAlign(CENTER);
    textSize(40);
    text("Endless - 1       Boss - 2", width/2, height - 250);
  }
}
 
void reset()
{
  gameMode = 0;
  ship.setDead(true);
  ship.setXY(width/2, height - 30);
  logo.setDead(false);
  boss1.setDead(true);
  hand1.setDead(true);
  hand2.setDead(true);
  for (int index=0; index<=49; index++)
    grid[index].setDead(true);
  score = 0;
  falling.setDead(true);
  fallingA.setDead(true);
  fallingB.setDead(true);
  fallingC.setDead(true);
  fallingC2.setDead(true);
}