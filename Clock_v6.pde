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
Vec2 minLoc;
boolean notOnScreen;
boolean dyingMinuteExists;
boolean dyingHourExists;
Vec2 explosionLocation = new Vec2((int)0, (int)0);
Vec2 force = new Vec2( 0.0f, 0.0f );
Vec2 pos = new Vec2( 0.0f, 0.0f );

void settings() {
  size(480,800,P2D);
  //fullScreen(P2D, 2);
}

void setup() {
  //size(640,360);
  //size(480,800,P2D);
  noStroke();
  //fullScreen();
  smooth();

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
      BoxHour bh = new BoxHour( (width/2)-35, 55, Integer.toString(newHours) );
      hourBoxList.add( bh );
      BoxMin bm = new BoxMin( (width/2)+55, 10, minString );
      minBoxList.add( bm );
    }
    //*****  SECONDS  *******
    // TODO: If the Minutes or Seconds aren't showing, drop new ones.
    if( newSeconds != oldSeconds ) {
      BoxSec bs = new BoxSec( width/2, 30, Integer.toString(newSeconds) );
      secBoxList.add( bs );
    }
    //*****  MINUTES  *******
    if( (oldSeconds == 59) && (newSeconds == 0) ) {
      // At the beginning of each minute period, apply an "explosive" force away from the existing Minute figure.
      // First, see if the Minutes and Hour boxes are on the screen.
      dyingMinuteExists = false;
      dyingHourExists = false;
      try {
      BoxMin dyingMinute = minBoxList.get(0);
      dyingMinuteExists = true;
      //print("Min exist ");
      }
      catch (Exception e) {
        dyingMinuteExists = false;
      }
      try {
      BoxHour dyingHour = hourBoxList.get(0);
      dyingHourExists = true;
      //println("Hour exist");
      }
      catch (Exception e) {
        dyingHourExists = false;
      }
      
      // If dyingMinuteExists, blow up the minutes.
      // If only the dyingHourExists, blow up the hours.
      // If neither exists, just blow up a few minutes near the bottom-center of the screen.
      if( dyingMinuteExists ) {
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
        
        // Now kill off all old minute boxes.
        for (int i = minBoxList.size()-1; i >= 0; i--) {
          BoxMin cs = minBoxList.get(i);
          cs.killIt();
          minBoxList.remove(i);
        }
        // If going to drop with an Hour figure, offset the Minutes a bit to leave room for Hours.
        if(newSeconds == 0) {
          BoxMin bm = new BoxMin( (width/2)+55, 10, minString );
          minBoxList.add( bm );
        }
        else {
          BoxMin bm = new BoxMin( width/2, 30, minString );
          minBoxList.add( bm );
        }
      }
      
      if( !dyingMinuteExists && dyingHourExists ) {
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
        BoxMin bm = new BoxMin( width/2, 30, minString );
        minBoxList.add( bm );
      }

      if( !dyingMinuteExists && !dyingHourExists ) {
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
        // Now drop new Minutes and Hours.
        BoxHour bh = new BoxHour( (width/2)-35, 55, Integer.toString(newHours) );
        hourBoxList.add( bh );
        BoxMin bm = new BoxMin( (width/2)+55, 10, minString );
        minBoxList.add( bm );
      }  // End of "what to do if there are no Minutes AND no Hours" on the screen.
    }  // End of the "start of a new minute" period.
    
    //*****  HOURS  *******
    if( (oldMinutes == 59) && (newMinutes == 0) ) {
      
      if( dyingHourExists ) {
        BoxHour dyingHour = hourBoxList.get(0);
        minLoc = dyingHour.body.getPosition();
        // Apply impulse away from the Minutes box. Force the Hour box, if it is close to the Minutes box.
        // Set explosive power based on the number of Second boxes.
        expPower = secBoxList.size() * 100;
        // Now do to all of the nearby Seconds boxes.
        for (int i = secBoxList.size()-1; i >= 0; i--) {
          Vec2 force = dyingHour.explode(secBoxList.get(i), expPower);   // Calc force on Hour box from nearby Minute box (if nearby).
          secBoxList.get(i).applyLinearImpulse(force);
        }
      }
      
      // Kill off all old hour boxes.
      for (int i = hourBoxList.size()-1; i >= 0; i--) {
        BoxHour cs = hourBoxList.get(i);
        cs.killIt();
        hourBoxList.remove(i);
      }
      BoxHour bh = new BoxHour( (width/2)-35, 55, Integer.toString(newHours) );
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
