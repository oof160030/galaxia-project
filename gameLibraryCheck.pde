import sprites.utils.*;
import sprites.maths.*;
import sprites.*;
import org.gamecontrolplus.*;
import ddf.minim.*;

Sprite ship, monster, monster1;
StopWatch stopWatch = new StopWatch();
Sprite [] grid;
boolean right = true;

ControlIO controllIO;
ControlDevice keyboard;
ControlButton spaceBtn, leftArrow, rightArrow, downArrow;

Minim minimplay;
AudioSample popPlayer;

public void setup()
{
  size(700, 600);
  frameRate(60);

  ship = new Sprite(this, "ship.png", 1, 1, 50);
  ship.setXY(width/2, height - 30);
  ship.setVelXY(0.0f, 0);
  ship.setScale(.045);
  ship.setDomain(0, height-ship.getHeight(), width, height, Sprite.HALT);

  grid = new Sprite[50];
  
  int index = 0;
  for (int y=1; y<=5; y++){
    for (int x=1; x<=10; x++){
      grid[index] = new Sprite(this, "monster.png", 1, 1, 40);
      grid[index].setXY(width - (75+(x*50)), height - (300+(y*50)));
      grid[index].setScale(0.2);
      grid[index].setDomain(100, height-grid[index].getHeight(), width - 100, height, Sprite.REBOUND);
      index++;
    }
  }
  controllIO = ControlIO.getInstance(this);
  keyboard = controllIO.getDevice("Keyboard");
  spaceBtn = keyboard.getButton("Space");   
  leftArrow = keyboard.getButton("Left");   
  rightArrow = keyboard.getButton("Right");
  
  minimplay = new Minim(this); 
  popPlayer = minimplay.loadSample("pop.wav", 1024);

  registerMethod("pre", this);
}

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
      }
  }
  
  for (int i = 0; i<=49; i++){
    if(grid[i].getX() > width-150){
      right = false;
    }
    else if(grid[i].getX() < 150){
      right = true;
    }
  }
  
  for (int i = 0; i<=49; i++){
    if(right){
      grid[i].setSpeed(100.0);
    }
    else if(!right){
      grid[i].setSpeed(-100.0);
    }
  }
  S4P.updateSprites(stopWatch.getElapsedTime());
}

void draw() {
  background(0);
  S4P.drawSprites();
}
