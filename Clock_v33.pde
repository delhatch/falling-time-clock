// Processing code for a unique clock.
// April 2021 by Del Hatch
// v28 has working i2c clock.
// v29 improves display after setting the clock

import shiffman.box2d.*;
import org.jbox2d.collision.shapes.*;
import org.jbox2d.common.*;
import org.jbox2d.dynamics.*;
import processing.io.*;

import gohai.simpletouch.*;
SimpleTouch touchscreen;

I2C i2c;  // This is the added RTC board. PCF8523

private static final int BACKGROUND = 15;
// Three screen modes.
private static final int CLOCK=1;
private static final int SETTING=2;
private static final int SETCOLOR=3;
// Button values.
private static final int HRM=3;
private static final int HRP=4;
private static final int MINM=5;
private static final int MINP=6;
private static final int DONE=7;
private static final int DOCOLOR=8;
private static final int DEFAULTBUTTON=9;

// A reference to our box2d world
Box2DProcessing box2d;

// A list we'll use to track fixed objects
ArrayList<Boundary> boundaries;
// A list for all of our rectangles
//ArrayList<CustomShape> polygons;
// A list of seconds boxes
ArrayList<BoxSec> secBoxList;
// A list of minutes boxes
ArrayList<BoxMin> minBoxList;
// A list of hours boxes
ArrayList<BoxHour> hourBoxList;

int timer = 0;
int oldSeconds = -1;
int oldMinutes = -1;
int newSeconds = 0;
String minString = new String("  ");
int newMinutes = 0;
int newHours = 0;
int expPower = 4000;
Vec2 minLoc;
boolean notOnScreen;
boolean dyingMinuteExists;
boolean dyingHourExists;
Vec2 explosionLocation = new Vec2((int)0, (int)0);
Vec2 force = new Vec2( 0.0f, 0.0f );
Vec2 pos = new Vec2( 0.0f, 0.0f );

color secDefaultColor = color(0xff, 0xff, 0xcc);
color minDefaultColor = color(0x00, 0x87, 0x76);
color hourDefaultColor = color(220,131,51);
color secColor = secDefaultColor;
color minColor = minDefaultColor;
color hourColor = hourDefaultColor;

//float secRedValue = red(secDefaultColor);

int valueX;
int valueY;
int state = CLOCK;
int sqSize = 150;   // Size of the buttons used to set the clock.
int settingGotOnce = 0;
int setHours = 1;
int setMinutes = 1;
Vec2 screenTouch = new Vec2(0,0);
int sent = 0;
int wB = 0;
boolean clearSc = false; // Clear screen after setting time.
boolean i2cExists = true;
boolean clearHoursMinutes = false;

void setup() {
  // For running on PC
  //size(480,800,P2D);
  //size(400,600);
  // For running on the Raspberry Pi
  fullScreen(P2D, SPAN);
  noCursor();
  
  // All
  noStroke();
  //fullScreen();
  smooth();
  
  // I2C setup --------
  i2c = new I2C(I2C.list()[0]);
  initRTC();
    
  // Touchscreen setup ----------
  //println("Available input devices:");
  String[] devs = SimpleTouch.list();
  //printArray(devs);

  for (int i=0; i < devs.length; i++) {
    try {
      touchscreen = new SimpleTouch(this, devs[i]);
      //println("Opened device: " + touchscreen.name());
    } catch (RuntimeException e) {
      // not all input devices are touch screens
      continue;
    }
  }
  if (touchscreen == null) {
    println("No input devices available");
    exit();
  }
  // End of Touchscreen setup ------------

  // Initialize box2d physics and create the world
  box2d = new Box2DProcessing(this);
  box2d.createWorld();
  // Set gravity pointing down.
  box2d.setGravity(0, -20);

  // Create ArrayLists  
  //polygons = new ArrayList<CustomShape>();
  boundaries = new ArrayList<Boundary>();
  secBoxList = new ArrayList<BoxSec>();
  minBoxList = new ArrayList<BoxMin>();
  hourBoxList = new ArrayList<BoxHour>();

  // Add a bunch of fixed boundaries
  boundaries.add(new Boundary(width/3,height-5,width/2-50,10,0));//Bottom left.1:bigger slides right 2:(-x)bigger x=up.
  boundaries.add(new Boundary(width/1.5,height-5,width/2-50,10,0));//Bottom right.
  boundaries.add(new Boundary(width-5,height-5,10,height/3,0));//right wall.
  boundaries.add(new Boundary(5,height-5,10,height/3,0));
}

void draw() {
  background(BACKGROUND);
  // We must always step through time!
  box2d.step();
    
  //*****  GET THE TIME  *******
  if( (state==CLOCK) || ( (state==SETTING) && (settingGotOnce==0) ) ) {
    if( i2cExists ) {
      newSeconds = i2cSeconds();
      newMinutes = i2cMinutes();
      newHours = i2cHours();
    }
    else {
      newSeconds = second();
      newMinutes = minute();
      newHours = hour();
    }
    // Convert from 24-hour time to 12-hour time.
    if( newHours > 12 ) { newHours -= 12; }
    // Add a leading zero character to single-digit minutes.
    minString = Integer.toString(newMinutes);
    if( minString.length() == 1 ) {
      minString = "0" + minString;
    }
  } // Done getting the time.
  
  screenTouch = getTouch(); // Is screen being touched?
  if( screenTouch.x != -1 ) {
    if( (state == CLOCK) && (screenTouch.y <= 200) ) {
      // User pressed near the top of the screen. Go into "time setting" mode.
      state = SETTING;
      setMinutes = newMinutes;
      setHours = newHours;
      settingGotOnce = 1;
      // Change touch location so no button is seen as pressed
      screenTouch.x = 240; screenTouch.y = 580;
    }
    if( state == SETTING ) {
      wB = whichButton( screenTouch );
      switch( wB )
      {
        case DONE: state = CLOCK;
                   settingGotOnce = 0;
                   // Send user-set time to the RTC
                   setTime();
                   clearHoursMinutes = true;
                   break;
        case MINM: setMinutes -= 1;
                   if( setMinutes < 0 ) {
                     setMinutes = 59;
                   }
                   clearSc = true;
                   break;
        case MINP: setMinutes += 1;
                   if( setMinutes > 59 ) {
                     setMinutes = 0;
                   }
                   clearSc = true;
                   break;
        case HRM : setHours -= 1;
                   if( setHours < 1 ) {
                     setHours = 12;
                   }
                   clearSc = true;
                   break;
        case HRP : setHours += 1;
                   if( setHours > 12) {
                     setHours = 1;
                   }
                   clearSc = true;
                   break;
        case DOCOLOR: state = SETCOLOR;
                   // Change touch location so no button is seen as pressed
                   screenTouch.x = 0; screenTouch.y = 0;
                   break;
        default : break;
      } // End of Switch statement
    } // End of "if state = SETTING
    if( state == SETCOLOR ) {
      wB = whichColorButton( screenTouch );
      switch( wB )
      {
        case DONE: state = SETTING;
                   break;
        case DEFAULTBUTTON:
                   secColor = secDefaultColor;
                   minColor = minDefaultColor;
                   hourColor = hourDefaultColor;
                   break;
        default : break;
      }
    }
  } // End of "the screen was touched"

  // Now act according to what state I'm in, CLOCK or SETTING
  if( state == SETTING ) {
    // Just Draw the time-setting buttons.
    drawSetClockScreen();
  } // End of state = SETTING
  else if( state == SETCOLOR ) {
    drawSetColorScreen();
  }
  else {
    // Normal CLOCK mode.
    // Display all the boundaries
    for (Boundary wall: boundaries) {
      wall.display();
    }
    if( millis() >= (500 + timer) ) {
      // First, determine if the Minutes and Hours are showing
      // Will frequently use this later.
      dyingMinuteExists = minsOnScreen();
      dyingHourExists = hoursOnScreen();
      //println(hourBoxList.size() + " " + minBoxList.size() + " " + secBoxList.size() );
      if( oldSeconds == -1 ) {
        //*****  UPON POWER-UP  *******
        BoxHour bh = new BoxHour( (width/2)-35, 55, Integer.toString(newHours), hourColor );
        hourBoxList.add( bh );
        BoxMin bm = new BoxMin( (width/2)+55, 10, minString, minColor );
        minBoxList.add( bm );
        // Now indicate that Hours and Minutes ARE onscreen.
        dyingMinuteExists = true;
        dyingHourExists = true; 
      }
      //*****  SECONDS  *******
      if( newSeconds != oldSeconds ) {
        BoxSec bs = new BoxSec( width/2, 30, Integer.toString(newSeconds), secColor );
        secBoxList.add( bs );
        // If just set the clock, blow up the screen,
        //    then add the new Minutes and Hours
        if( clearHoursMinutes ) {
          clearHoursMinutes = false;
          if( dyingMinuteExists ) {
            blowMinutes();
            // Now kill off all old minute boxes.
            for (int i = minBoxList.size()-1; i >= 0; i--) {
              BoxMin cs = minBoxList.get(i);
              cs.killIt();
              minBoxList.remove(i);
            }
            // Drop new Minutes
            BoxMin bm = new BoxMin( (width/2)+55, 10, minString, minColor );
            minBoxList.add( bm );
          }
          if( dyingHourExists ) {
            blowHours();
            // Kill off all old hour boxes.
            for (int i = hourBoxList.size()-1; i >= 0; i--) {
              BoxHour cs = hourBoxList.get(i);
              cs.killIt();
              hourBoxList.remove(i);
            }
            // Drop new Hours.
            BoxHour bh = new BoxHour( (width/2)-35, 55, Integer.toString(newHours), hourColor );
            hourBoxList.add( bh );
          }
          blowMiddle();
        }
        else {
          // Since didn't just set the clock, put Mins
          //   and Hours on screen, if missing.
          if( !dyingMinuteExists ) {
            BoxMin bm = new BoxMin( (width/2)+55, 10, minString, minColor );
            minBoxList.add( bm );
            dyingMinuteExists = true;
          }
          if( !dyingHourExists ) {
            BoxHour bh = new BoxHour( (width/2)-35, 55, Integer.toString(newHours), hourColor );
            hourBoxList.add( bh );
            dyingHourExists = true;
          }
        }
      }
      //*****  MINUTES  *******
    if( (oldSeconds == 59) && (newSeconds == 0) ) {
      // At the beginning of each minute period, apply an
      //   "explosive" force away from the existing Minute figure.
      // If dyingMinuteExists, blow up the minutes.
      // If only the dyingHourExists, blow up the hours.
      // If neither exists, just blow up a few minutes near
      //   the bottom-center of the screen.
      if( dyingMinuteExists ) {
        blowMinutes();
        // If the minutes number is high on the screen,
        //   give it a place to land.
        BoxMin dyingMinute = minBoxList.get(0);
        Vec2 pos = box2d.getBodyPixelCoord(dyingMinute.body);
        if( pos.y < 628 ) {
          blowMiddle();
        }
        // Now kill off all old minute boxes.
        for (int i = minBoxList.size()-1; i >= 0; i--) {
          BoxMin cs = minBoxList.get(i);
          cs.killIt();
          minBoxList.remove(i);
        }
        // If going to drop with an Hour figure, offset the Minutes a bit to leave room for Hours.
        if(newSeconds == 0) {
          BoxMin bm = new BoxMin( (width/2)+55, 10, minString, minColor );
          minBoxList.add( bm );
        }
        else {
          BoxMin bm = new BoxMin( width/2, 30, minString, minColor );
          minBoxList.add( bm );
        }
      }
      
      if( !dyingMinuteExists && dyingHourExists ) {
        blowHours();
        BoxMin bm = new BoxMin( width/2, 30, minString, minColor );
        minBoxList.add( bm );
      }

      if( !dyingMinuteExists && !dyingHourExists ) {
        blowMiddle();
        // Now drop new Minutes and Hours.
        BoxHour bh = new BoxHour( (width/2)-35, 55, Integer.toString(newHours), hourColor );
        hourBoxList.add( bh );
        BoxMin bm = new BoxMin( (width/2)+55, 10, minString, minColor );
        minBoxList.add( bm );
      }  // End of "what to do if there are no Minutes AND no Hours" on the screen.
    }  // End of the "start of a new minute" period.
    
    //*****  HOURS  *******
    if( (oldMinutes == 59) && (newMinutes == 0) ) {
      
      if( dyingHourExists ) {
        blowHours();
      }
      // Kill off all old hour boxes.
      for (int i = hourBoxList.size()-1; i >= 0; i--) {
        BoxHour cs = hourBoxList.get(i);
        cs.killIt();
        hourBoxList.remove(i);
      }
      BoxHour bh = new BoxHour( (width/2)-35, 55, Integer.toString(newHours), hourColor );
      hourBoxList.add( bh );
    }
    oldMinutes = newMinutes;
    oldSeconds = newSeconds;
    timer = millis();
  }
  
   // Display all the numbers
  for ( BoxSec cs: secBoxList ) {
    cs.display();
  }
  for ( BoxMin cs: minBoxList ) {
    cs.display();
  }
  for ( BoxHour cs: hourBoxList ) {
    cs.display();
  }

  // people that leave the screen, we delete them
  // (note they have to be deleted from both the box2d world and our list
  for (int i = secBoxList.size()-1; i >= 0; i--) {
    BoxSec cs = secBoxList.get(i);
    if (cs.done()) {
      secBoxList.remove(i);
    }
  }
  for (int i = minBoxList.size()-1; i >= 0; i--) {
    BoxMin cs = minBoxList.get(i);
    if (cs.done()) {
      minBoxList.remove(i);
    }
  }
  for (int i = hourBoxList.size()-1; i >= 0; i--) {
    BoxHour cs = hourBoxList.get(i);
    if (cs.done()) {
      hourBoxList.remove(i);
    }
  }
  } // End of "state = CLOCK mode."
}  // End of draw() method.

Vec2 explode( Vec2 expLoc, BoxText m, int expPower ) {
    int G = -expPower;
    force.x = 0.001;
    force.y = 0.001; // Default is "apply no force."
    // Make a copy of the box that is NOT moving. (The body that this method is being applied to.)
    //Vec2 pos = body.getWorldCenter();
    pos = expLoc;
    //println("Exploding body at " + expLoc );
    // Make a copy of the box that IS moving.
    //Vec2 moverPos = m.body.getWorldCenter();
    Vec2 moverPos = m.body.getPosition();
    //println("Moving body at " + moverPos );
    // Vector pointing from moving box to Minute box.
    Vec2 distanceForce = pos.sub(moverPos);
    float distance = distanceForce.length();
    //println("Dist to box is " + String.valueOf(distance) );
    if( distance < 15 ) {
      distanceForce.normalize();   // Set pointing vector (Hour box to Minute box) to unit length.
      float strength = (G * 1 * m.body.m_mass) / (distance * distance); // Calculate gravitional force magnitude
      distanceForce.mulLocal(strength);   // Create force vector --> magnitude * direction
      force = distanceForce;
    }
    //println("Force = " + force);
    return force;
  }
  
Vec2 getTouch() {
  Vec2 thisTouch = new Vec2(-1, -1);
  SimpleTouchEvt touches[] = touchscreen.touches();
  //for (SimpleTouchEvt touch : touches) {
    // the id value is used to track each touch
    // we use it to assign a unique color
    //fill((touch.id * 100) % 360, 100, 100);
    // x and y are values from 0.0 to 1.0
    //ellipse(width * touch.y, height * (1-touch.x), 100, 100);
  //}
  if( (touches.length != 0) && (sent == 0) ) {
    thisTouch.x = (int) (width * touches[0].y);
    thisTouch.y = (int) (height * (1-touches[0].x));
    //println(thisTouch.x + " " + thisTouch.y);
    sent = 1;
  }
  if( touches.length == 0) {
    sent = 0;
  }
  return thisTouch;
}

int whichButton( Vec2 but ) {
  if( but.y > 590 ) {
    return DONE;
  }
  if( (but.x>165) && (but.x<315) && (but.y<550)) {
    return DOCOLOR;
  }
  if( (but.x<165) && (but.y<300) ) {
    return HRM;
  }
  if( (but.x>315) && (but.y<300) ) {
    return HRP;
  }
  if( (but.x<165) && (but.y<550) ) {
    return MINM;
  }
  if( (but.x>315) && (but.y<550) ) {
    return MINP;
  }
  return 0;
}

void setTime() {
  if(!i2cExists) {
    return;
  }
  // Sends setMinutes and setHours to the RTC chip.
  int Mins;
  byte Mins_tens = 0;
  byte Mins_ones = 0;
  int Hours;
  byte Hours_tens = 0;
  byte Hours_ones = 0;
  
  Mins = setMinutes;
  //println(Mins);
  while( Mins >= 10 ) {
    //print("*");
    Mins_tens += 1;
    Mins -= 10;
  }
  //println(" ");
  //println("tens = " + Mins_tens );
  Mins_ones = (byte) Mins;
  Mins = Mins_tens << 4;
  Mins = Mins | Mins_ones;
  //println(Mins);
  
  Hours = setHours;
  if( Hours >= 10 ) {
    Hours_tens = 1;
    Hours_ones = (byte)(Hours - 10);
  }
  else {
    Hours_tens = 0;
    Hours_ones = (byte) Hours;
  }
  Hours = Hours_tens << 4;
  Hours = Hours | Hours_ones;
  
  i2c.beginTransmission(0x68); // Addr of PCF8523
  i2c.write(0x4);  // Addr = Reg 4 = Minutes
  i2c.write(Mins);
  i2c.write(Hours);
  i2c.endTransmission();
}
void initRTC() {
  if(!i2cExists) {
    return;
  }
  // Set RTC to 12H mode.
  // Battery switch-over enabled, standard mode.
  i2c.beginTransmission(0x68); // Addr of PCF8523
  i2c.write(0x0);  // Addr = Reg 0
  i2c.write(0x8);
  i2c.write(0);
  i2c.write(0);
  i2c.endTransmission();
}
int i2cSeconds() {
  int secs;
  int tens;
  
  i2c.beginTransmission(0x68);
  i2c.write(0x03);
  byte[] in = i2c.read(1);
  i2c.endTransmission();
  secs = in[0] & 0x0F;
  tens = (in[0] & 0x70)>>4;
  while(tens>0) {
    secs += 10;
    tens -= 1;
  }
  return secs;
}
int i2cMinutes() {
  int mins;
  int tens;
  
  i2c.beginTransmission(0x68);
  i2c.write(0x04);
  byte[] in = i2c.read(1);
  i2c.endTransmission();
  mins = in[0] & 0x0F;
  tens = (in[0] & 0x70)>>4;
  while(tens>0) {
    mins += 10;
    tens -= 1;
  }
  return mins;
}
int i2cHours() {
  int hours;
  
  i2c.beginTransmission(0x68);
  i2c.write(0x05);
  byte[] in = i2c.read(1);
  i2c.endTransmission();
  hours = in[0] & 0x0F;
  if( (in[0] & 0x10) != 0 ) {
    hours += 10;
  }
  return hours;
}
boolean minsOnScreen () {
  boolean retval = true;
  
  try {
      BoxMin dyingMinute = minBoxList.get(0);
      retval = true;
      Vec2 pos = box2d.getBodyPixelCoord(dyingMinute.body);
      println("Min at " + pos.y);
      }
      catch (Exception e) {
        retval = false;
      }
  return retval;
}
boolean hoursOnScreen () {
  boolean retval = true;
  
  try {
      BoxHour dyingHour = hourBoxList.get(0);
      retval = true;
      //print("Hour exist ");
      }
      catch (Exception e) {
        retval = false;
      }
  return retval;
}
void blowMinutes() {
  BoxMin dyingMinute = minBoxList.get(0);
  minLoc = dyingMinute.body.getPosition();
  // Apply impulse away from the Minutes box. Force the Hour box, if it is close to the Minutes box.
  // Set explosive power based on the number of Second boxes.
  expPower = secBoxList.size() * 100;
  // Apply explosion force to any nearby Hour box.
  for (int i = hourBoxList.size()-1; i >= 0; i--) {
    Vec2 force = dyingMinute.explode(hourBoxList.get(i), expPower);   // Calc force on Hour box from nearby Minute box (if nearby).
    hourBoxList.get(i).applyLinearImpulse(force);
  }
  // Now apply explosion force to all of the nearby Seconds boxes.
  for (int i = secBoxList.size()-1; i >= 0; i--) {
    Vec2 force = dyingMinute.explode(secBoxList.get(i), expPower);   // Calc force on Hour box from nearby Minute box (if nearby).
    secBoxList.get(i).applyLinearImpulse(force);
  }
  return;
}
void blowHours() {
  BoxHour dyingHour = hourBoxList.get(0);
  minLoc = dyingHour.body.getPosition();
  // Apply impulse away from the Minutes box. Force the Hour box, if it is close to the Minutes box.
  // Set explosive power based on the number of Second boxes.
  expPower = secBoxList.size() * 500;
  // Now do to all of the Seconds boxes.
  for (int i = secBoxList.size()-1; i >= 0; i--) {
    Vec2 force = dyingHour.explode(secBoxList.get(i), expPower);   // Calc force on Hour box from nearby Minute box (if nearby).
    secBoxList.get(i).applyLinearImpulse(force);
  }
  return;
}
void blowMiddle() {
  // There is no Minutes box to explode, AND no Hours box. So just explode from the middle-low part of screen.
  // First, set the x,y coordinate of middle-lower part of screen.
  //BoxText dyingHour = hourBoxList.get(0);   // The Minute box that is about to "explode."
  // Set explosive power based on number of Second boxes, and bigger than the Minutes explosion.
  expPower = secBoxList.size() * 150;
  explosionLocation.x = (int)(0);       // x = 0 = center of screen.
  explosionLocation.y = (int)(-38.4);   // y = -38.4 = very low on the screen.
  // Now process the explosion to all of the Seconds boxes.
  for (int i = secBoxList.size()-1; i >= 0; i--) {
    Vec2 force = explode(explosionLocation, secBoxList.get(i), expPower);   // Calc force on Hour box from nearby Minute box (if nearby).
    secBoxList.get(i).applyLinearImpulse(force);
  }
  return;
}
void drawSetClockScreen() {
  stroke(255);
  fill( BACKGROUND );
  square( ((sqSize/2)+10), 150, sqSize);  // Hours, -
  square( (480-((sqSize/2)+10)), 150, sqSize);  // Hours, +
  square( ((sqSize/2)+10), 450, sqSize);  // Minutes, -
  square( (480-((sqSize/2)+10)), 450, sqSize);  // Minutes, +
  rect( (480/2), 700, (480-10-10), 180 );  // DONE
  // Write the text on the screen
  // HOURS
  fill( 255 );
  textSize(50);
  text("Hours", 170, 50);
  textSize(90);
  fill( hourColor );
  if( setHours >= 10 ) {
    text(setHours, 180, 180); // Print the hours value between the buttons
  }
  else {
    text(setHours, 215, 180);
  }
  fill( 255 );
  text("-", 60, 175 );
  text("+", 361, 175 );
  // MINUTES
  textSize(50);
  //textAlign(CENTER, TOP);
  text("Minutes", 145, 350);
  textSize(90);
  fill( minColor );
  if( setMinutes >= 10 ) {
    text(setMinutes, 180, 480 ); // Print the hours value between the buttons
  }
  else {
    text(setMinutes, 215, 480 );
  }
  fill( 255 );
  text("-", 60, 474 );
  text("+", 361, 474 );
  // DONE
  text("DONE", 115, 735 );
  return;
}
void drawSetColorScreen() {
  int gap = 27;
  int barh = 30;
  int starty = 10;
  int barw = 300;
  int startx = 480-barw-10;
  int starty2 = 70+starty+2*gap+3*barh;
  int starty3 = 70+starty2+2*gap+3*barh;
  int ditw = 15;
  
  stroke(255);
  fill( BACKGROUND );
  // Bars
  rectMode(CORNERS);
  rect( startx, starty, startx+barw, starty+barh );
  rect( startx, starty+gap+barh, startx+barw, starty+gap+2*barh );
  rect( startx, starty+2*gap+2*barh, startx+barw, starty+2*gap+3*barh );
  rect( startx, starty2, startx+barw, starty2+barh );
  rect( startx, starty2+gap+barh, startx+barw, starty2+gap+2*barh );
  rect( startx, starty2+2*gap+2*barh, startx+barw, starty2+2*gap+3*barh );
  rect( startx, starty3, startx+barw, starty3+barh );
  rect( startx, starty3+gap+barh, startx+barw, starty3+gap+2*barh );
  rect( startx, starty3+2*gap+2*barh, startx+barw, starty3+2*gap+3*barh );
  float hourRed = red(hourColor);
  float hourGreen = green(hourColor);
  float hourBlue = blue(hourColor);
  float minRed = red(minColor);
  float minGreen = green(minColor);
  float minBlue = blue(minColor);
  float secRed = red(secColor);
  float secGreen = green(secColor);
  float secBlue = blue(secColor);
  // Draw dits. First do Hours
  float out = map(hourRed, 255, 0, startx, startx+barw-ditw);
  fill(#ff0000);
  rect( out, starty, out+ditw, starty+barh); 
  out = map(hourGreen, 255, 0, startx, startx+barw-ditw);
  fill(#00ff00);
  rect( out, starty+gap+barh, out+ditw, starty+gap+2*barh); 
  out = map(hourBlue, 255, 0, startx, startx+barw-ditw);
  fill(#0000ff);
  rect( out, starty+2*gap+2*barh, out+ditw, starty+2*gap+3*barh); 
  // Mins
  out = map(minRed, 255, 0, startx, startx+barw-ditw);
  fill(#ff0000);
  rect( out, starty2, out+ditw, starty2+barh); 
  out = map(minGreen, 255, 0, startx, startx+barw-ditw);
  fill(#00ff00);
  rect( out, starty2+gap+barh, out+ditw, starty2+gap+2*barh); 
  out = map(minBlue, 255, 0, startx, startx+barw-ditw);
  fill(#0000ff);
  rect( out, starty2+2*gap+2*barh, out+ditw, starty2+2*gap+3*barh); 
  // Secs
  out = map(secRed, 255, 0, startx, startx+barw-ditw);
  fill(#ff0000);
  rect( out, starty3, out+ditw, starty3+barh); 
  out = map(secGreen, 255, 0, startx, startx+barw-ditw);
  fill(#00ff00);
  rect( out, starty3+gap+barh, out+ditw, starty3+gap+2*barh); 
  out = map(secBlue, 255, 0, startx, startx+barw-ditw);
  fill(#0000ff);
  rect( out, starty3+2*gap+2*barh, out+ditw, starty3+2*gap+3*barh); 
  // Draw "DONE" and "Default" boxes
  rectMode(CENTER);
  fill(BACKGROUND);
  rect( 360, 720, (240-10-10), 140 );  // DONE
  rect( (480/4), 720, (240-10-10), 140 );  // DEFAULT
  textSize(50);
  fill( 255 );
  text("DONE", 290, 735 );
  text("Default", 30, 735 );
  // HOURS
  textSize(100);
  fill( hourColor );
  text("12", 10, 115);
  // Minutes
  textSize(80);
  fill( minColor );
  text("59", 25, 330); 
  // Seconds
  textSize(50);
  fill( secColor );
  text("59", 40, 528); 
  return;
}
int whichColorButton( Vec2 but ) {
  int gap = 27;
  int barh = 30;
  int starty = 10;
  int barw = 300;
  int startx = 480-barw-10;
  int starty2 = 70+starty+2*gap+3*barh;
  int starty3 = 70+starty2+2*gap+3*barh;
  int ditw = 15;
  float out;
  
  if( (but.y>590) && (but.x>240) ) {
    return DONE;
  }
  if( (but.y>590) && (but.x<240) ) {
    return DEFAULTBUTTON;
  }
  // If not "DONE" or "Default" use value to adjust color
  if( but.x<(startx-50) ) {
    return 0;
  }
  if( but.y<(starty+barh+(gap/2)) ) {
    // Adj hour red
    out=map(but.x,startx,(startx+barw-ditw),255,0);
    hourColor=color(out,green(hourColor),blue(hourColor));
    return 0;
  }
  if( but.y<(starty+2*barh+gap+(gap/2)) ) {
    // Adj hour green
    out=map(but.x,startx,(startx+barw-ditw),255,0);
    hourColor=color(red(hourColor),out,blue(hourColor));
    return 0;
  }
  if( but.y<(starty+3*barh+2*gap+(gap/2)) ) {
    // Adj hour blue
    out=map(but.x,startx,(startx+barw-ditw),255,0);
    hourColor=color(red(hourColor),green(hourColor),out);
    return 0;
  }
  // Minutes
  if( but.y<(starty2+barh+(gap/2)) ) {
    // Adj minutes red
    out=map(but.x,startx,(startx+barw-ditw),255,0);
    minColor=color(out,green(minColor),blue(minColor));
    return 0;
  }
  if( but.y<(starty2+2*barh+gap+(gap/2)) ) {
    // Adj minutes green
    out=map(but.x,startx,(startx+barw-ditw),255,0);
    minColor=color(red(minColor),out,blue(minColor));
    return 0;
  }
  if( but.y<(starty2+3*barh+2*gap+(gap/2)) ) {
    // Adj minutes blue
    out=map(but.x,startx,(startx+barw-ditw),255,0);
    minColor=color(red(minColor),green(minColor),out);
    return 0;
  }
  // Seconds
  if( but.y<(starty3+barh+(gap/2)) ) {
    // Adj secs red
    out=map(but.x,startx,(startx+barw-ditw),255,0);
    secColor=color(out,green(secColor),blue(secColor));
    return 0;
  }
  if( but.y<(starty3+2*barh+gap+(gap/2)) ) {
    // Adj secs green
    out=map(but.x,startx,(startx+barw-ditw),255,0);
    secColor=color(red(secColor),out,blue(secColor));
    return 0;
  }
  if( but.y<(starty3+3*barh+2*gap+(gap/2)) ) {
    // Adj secs blue
    out=map(but.x,startx,(startx+barw-ditw),255,0);
    secColor=color(red(secColor),green(secColor),out);
    return 0;
  }
  return 0;
}
//}
