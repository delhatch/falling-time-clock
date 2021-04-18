// Processing code for a unique clock.
// April 2021 by Del Hatch

import shiffman.box2d.*;
import org.jbox2d.collision.shapes.*;
import org.jbox2d.common.*;
import org.jbox2d.dynamics.*;

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
int newMinutes = 0;
int newHours = 0;
int expPower = 4000;

void setup() {
  //size(640,360);
  size(640,640);
  //fullScreen();
  smooth();

  // Initialize box2d physics and create the world
  box2d = new Box2DProcessing(this);
  box2d.createWorld();
  // We are setting a custom gravity
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
  background(15);

  // We must always step through time!
  box2d.step();

  // Display all the boundaries
  for (Boundary wall: boundaries) {
    wall.display();
  }
  
  if( millis() >= (500 + timer) ) {
    //println(hourBoxList.size() + " " + minBoxList.size() + " " + secBoxList.size() );
    //*****  GET THE TIME  *******
    newSeconds = second();
    newMinutes = minute();
    newHours = hour();
    // Convert from 24-hour time to 12-hour time.
    if( newHours > 12 ) { newHours -= 12; }
    // Add a leading zero character to single-digit minutes.
    String minString = Integer.toString(newMinutes);
    if( minString.length() == 1 ) {
      minString = "0" + minString;
    }
    if( oldSeconds == -1 ) {
      //*****  UPON POWER-UP  *******
      BoxHour bh = new BoxHour( width/2, 30, Integer.toString(newHours) );
      hourBoxList.add( bh );
      BoxMin bm = new BoxMin( width/2, 30, minString );
      minBoxList.add( bm );
    }
    //*****  SECONDS  *******
    if( newSeconds != oldSeconds ) {
      BoxSec bs = new BoxSec( width/2, 30, Integer.toString(newSeconds) );
      secBoxList.add( bs );
    }
    //*****  MINUTES  *******
    if( (oldSeconds == 59) && (newSeconds == 0) ) {
      // When new minute comes along, apply an "explosive" force away from the existing minute figure.
      // Apply impulse to the Hour box, if it is close to the Minutes box.
      BoxMin dyingMinute = minBoxList.get(0);   // The Minute box that is about to "explode."
      // Set explosive power based on number of Second boxes.
      expPower = secBoxList.size() * 150;
      for (int i = hourBoxList.size()-1; i >= 0; i--) {
        Vec2 force = dyingMinute.explode(hourBoxList.get(i), expPower);   // Calc force on Hour box from nearby Minute box (if nearby).
        hourBoxList.get(i).applyLinearImpulse(force);
      }
      // Now do to all of the Seconds boxes.
      for (int i = secBoxList.size()-1; i >= 0; i--) {
        Vec2 force = dyingMinute.explode(secBoxList.get(i), expPower);   // Calc force on Hour box from nearby Minute box (if nearby).
        secBoxList.get(i).applyLinearImpulse(force);
      }
      // Now kill off all old minute boxes.
      for (int i = minBoxList.size()-1; i >= 0; i--) {
        BoxMin cs = minBoxList.get(i);
        cs.killIt();
        minBoxList.remove(i);
      }
      BoxMin bm = new BoxMin( width/2, 30, minString );
      minBoxList.add( bm );
    }
    //*****  HOURS  *******
    if( (oldMinutes == 59) && (newMinutes == 0) ) {
      // Kill off all old hour boxes.
      for (int i = hourBoxList.size()-1; i >= 0; i--) {
        BoxHour cs = hourBoxList.get(i);
        cs.killIt();
        hourBoxList.remove(i);
      }
      BoxHour bh = new BoxHour( width/2, 30, Integer.toString(newHours) );
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
}
