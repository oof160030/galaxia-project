import sprites.utils.*;
import sprites.maths.*;
import sprites.*;
import org.gamecontrolplus.*;
import ddf.minim.*;

Sprite ship;
StopWatch stopWatch = new StopWatch();

ControlIO controllIO;
ControlDevice keyboard;
ControlButton spaceBtn, leftArrow, rightArrow, downArrow;

Minim minimplay;
AudioSample popPlayer;

public void setup()
{
  size(700, 500);
  frameRate(50);

  ship = new Sprite(this, "ship.png", 1, 1, 50);
  ship.setXY(width/2, height - 30);
  ship.setVelXY(0.0f, 0);
  ship.setScale(.75);
  ship.setDomain(0, height-ship.getHeight(), width, height, Sprite.HALT);
  
  controllIO = ControlIO.getInstance(this);
  keyboard = controllIO.getDevice("Apple Internal Keyboard / Trackpad");
  spaceBtn = keyboard.getButton(" ");   
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
        ship.setX(ship.getX()-10);
      }
      if (rightArrow.pressed()) {
        ship.setX(ship.getX()+10);
      }
      if (spaceBtn.pressed()) {
        popPlayer.trigger();
      }
  }

  S4P.updateSprites(stopWatch.getElapsedTime());
}

void draw() {
  background(0);
  S4P.drawSprites();
}