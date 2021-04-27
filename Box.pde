// This class creates an invisible box for the physics engine to use.
// The box holds the text that is the number that is displayed.
// The invisible box is sized so that it is very close to the size of the numbers.
// In this way, it appears that the numbers are physical objects in the box2d world.

class BoxText
{
  float x;
  float y;
  float w;
  float h;
  String text;
  int size;
  color mycolor;
  Vec2 center = new Vec2();
  Vec2 upper_l = new Vec2();
  Vec2 upper_r = new Vec2();
  Vec2 lower_r = new Vec2();
  Vec2 lower_l = new Vec2();
  float temp_x;
  float temp_y;
  int G;
  float distance;
  float strength;
  float a;
  
  Vec2[] vertices = new Vec2[4];
  // Define a polygon (this is what we use for the box)
  PolygonShape sd = new PolygonShape();
  
  // We need to keep track of a Body and a width and height
  Body body;
  BodyDef bd = new BodyDef();
  
  Vec2 force = new Vec2(0.001,0.001); // Default is "apply no force."
  Vec2 pos;
  
  FixtureDef secFd = new FixtureDef();
  FixtureDef minFd = new FixtureDef();
  FixtureDef hourFd = new FixtureDef();
  
  // Constructor
  BoxText(float x_, float y_, String text_, int size_, color mycolor_)
  {
    x = x_;
    y = y_;
    w = size_;
    h = size_;
    text = text_;
    size = size_;
    mycolor = mycolor_;
    if( this.text.length() == 1 ) {
      w = size / 2;
    }
    else {
      w = size * 1.1;
    }

    center.x = x;
    center.y = y;
    
    temp_x = w/2.1;
    temp_y = h/2.8;
    upper_l.x = -temp_x; upper_l.y = temp_y;
    upper_r.x = temp_x; upper_r.y = temp_y;
    lower_r.x = temp_x; lower_r.y = -temp_y;
    lower_l.x = -temp_x; lower_l.y = -temp_y;
    vertices[0] = box2d.vectorPixelsToWorld(upper_l);
    vertices[1] = box2d.vectorPixelsToWorld(upper_r);
    vertices[2] = box2d.vectorPixelsToWorld(lower_r);
    vertices[3] = box2d.vectorPixelsToWorld(lower_l);

    sd.set(vertices, vertices.length);
    
    // Define a fixture
    //FixtureDef fd = new FixtureDef();
    secFd.shape = sd;
    minFd.shape = sd;
    hourFd.shape = sd;
    // Parameters that affect the physics
    secFd.density = 1;
    secFd.friction = 0.5;
    secFd.restitution = 0.2;
    //-----------------------
    minFd.density = 15;
    minFd.friction = 0.5;
    minFd.restitution = 0.15;
    //-----------------------
    hourFd.density = 25;
    hourFd.friction = 0.5;
    hourFd.restitution = 0.15;

    // Define the body and make it from the shape
    //BodyDef bd = new BodyDef();
    bd.type = BodyType.DYNAMIC;
    bd.position.set(box2d.coordPixelsToWorld(center));
    // Create the body
    body = box2d.createBody(bd);
    // Attach the fixture
    if( this.size < 60 ) {
      body.createFixture(secFd);
    }
    else if ( this.size < 110 ) {
      body.createFixture(minFd);
    }
    else {
      body.createFixture(hourFd);
    }

    // Give it some initial random velocity
    body.setLinearVelocity(new Vec2(random(-5, 5), random(2, 5)));
    if( this.size < 60 ) {
      body.setAngularVelocity(random(-5, 5));
    }
    else if ( this.size < 110 ) {
      body.setAngularVelocity(random(-1, 1));
    }
    else {
      body.setAngularVelocity(random(-1, 1));
    }
    
    if( this.size < 60 ) {
      body.setGravityScale(1);
    }
    else if ( this.size < 110 ) {
      body.setGravityScale(1);
    }
    else {
      body.setGravityScale(1);
    }  
  }
  
  Vec2 explode( BoxText m, int expPower ) {
    G = -expPower;
    force.x = 0.001;
    force.y = 0.001; // Default is "apply no force."
    // Make a copy of the box that is NOT moving. (The body that this method is being applied to.)
    //Vec2 pos = body.getWorldCenter();
    pos = body.getPosition();
    //println("Exploding body at " + pos );
    // Make a copy of the box that IS moving.
    //Vec2 moverPos = m.body.getWorldCenter();
    Vec2 moverPos = m.body.getPosition();
    //println("Moving body at " + moverPos );
    // Vector pointing from moving box to Minute box.
    Vec2 distanceForce = pos.sub(moverPos);
    distance = distanceForce.length();
    //println("Dist to box is " + String.valueOf(distance) );
    if( distance < 15 ) {
      distanceForce.normalize();   // Set pointing vector (Hour box to Minute box) to unit length.
      strength = (G * 1 * m.body.m_mass) / (distance * distance); // Calculate gravitional force magnitude
      distanceForce.mulLocal(strength);   // Create force vector --> magnitude * direction
      force = distanceForce;
    }
    //println("Force = " + force);
    return force;
  }
  
  void applyLinearImpulse( Vec2 v ) {
    body.applyLinearImpulse(v, body.getWorldCenter(), true );
  }
  
  // Is the particle ready for deletion?
  boolean done()
  {
    // Let's find the screen position of the particle
    //let pos = scaleToPixels(this.body.GetPosition());
    Vec2 pos = box2d.getBodyPixelCoord(body);
    // Is it off the bottom of the screen?
    //if (pos.y > height + this.w * this.h) {
    //  this.killBody();
    //  return true;
    //}
    //if ( (pos.y > height) || (pos.x<0) || (pos.x>width) ) {
    if( (pos.y > (height-10) ) || (pos.y < -10) || (pos.x<10) || (pos.x>(width-10) ) ) {
      killIt();
      return true;
    }
    return false;
  }
  
  void killIt() {
    //body.destroyFixture(body.getFixtureList() );
    box2d.destroyBody(this.body);
    //box2d.world.destroyBody(this.body);
  }

  void calColor()
  {
    
  }

  void display()
  {
    // Get the body's position
    //pos = scaleToPixels(this.body.GetPosition());
    Vec2 pos = box2d.getBodyPixelCoord(body);
    // Get its angle of rotation
    //float a = this.body.GetAngleRadians();
    a = body.getAngle();
    
    Fixture f = body.getFixtureList();
    PolygonShape ps = (PolygonShape) f.getShape();

    // Draw it!
    //pushMatrix();
    //translate(pos.x, pos.y);
    //rotate(a);
    //fill(this.mycolor);
    //textSize(this.size);
    //text(this.text,0,0,this.w,this.h);
    //popMatrix();
    rectMode(CENTER);
    pushMatrix();
    translate(pos.x, pos.y);
    rotate(-a);
    textSize(this.size);
    //fill(255,255,255);
    if( this.size < 55 ) {
      fill(#ffffcc);
    }
    else {
      fill(this.mycolor);
    }
    // Place text inside of boxes
    if( this.size <55 ) {
      // Seconds
      if( this.text.length() == 1 ) {
        text(this.text,-17,18);  // 1st: smaller = left shift. 2nd: smaller = more up
      }
      else {
        text(this.text,-33,18);  // 1st: smaller = left shift. 2nd: smaller = more up
      }
    }
    else if ( this.size < 105 ) {
      // Minutes
      if( this.text.length() == 1 ) {
        text(this.text,-35,36);
      }
      else {
        text(this.text,-65,36);
      }
    }
    else {
      // Hours
      if( this.text.length() == 1 ) {
        text(this.text,-50,55);
      }
      else {
        text(this.text,-105,55);
      }
    }
    
    fill(175);
    noStroke();
    //stroke(255);
    noFill();
    beginShape();
    //println(vertices.length);
    // For every vertex, convert to pixel vector
    for (int i = 0; i < ps.getVertexCount(); i++) {
      Vec2 v = box2d.vectorWorldToPixels(ps.getVertex(i));
      vertex(v.x, v.y);
    }
    endShape(CLOSE);
    popMatrix();
  }
}
//==========================================================================
class BoxSec extends BoxText
{
  float x;
  float y;
  float w;
  float h;
  String text;
  int size;
  color mycolor;
  
  // Constructor
  BoxSec(float x_, float y_, String text_)
  {
    super( x_, y_, text_, 50, color(0,255,0) );
    
    x = x_;
    y = y_;
    text = text_;
    size = 50;
    mycolor = color(0,255,0);
    
    //if( text.length() == 1 ) {
    //  this.w = size / 2;
    //  println("L=1 ");
    //}
    //else {
    //  this.w = size;
    //  println("L!=1 ");
    //}
  }

  void calColor()
  {
    //var diff=new Date()-this.createTime;
    //var newValue=-0.00425*diff+255;
    int newValue = 125; 
    if(newValue<0) {
      newValue=0;
    }
    if(newValue>255) {
      newValue=255;  
    }

    this.mycolor=color(0,newValue,0);
  }

  
}
//============================================================================
class BoxMin extends BoxText
{
  float x;
  float y;
  float w;
  float h;
  String text;
  int size;
  color mycolor;
  
  // Constructor
  BoxMin(float x_, float y_, String text_)
  {
    super(x_,y_,text_,100,color(#007766));
    this.size=100;
  }

  void calColor()
  {
    //var diff=new Date()-this.createTime;
    //var newValue=-0.00105*diff+255;
    int newValue = 128;
    if(newValue<0) {
      newValue=0;
    }
    if(newValue>255) {
      newValue=255;  
    }

    this.mycolor=color(newValue,0,0);
  }
}
//=======================================================================
class BoxHour extends BoxText
{
  float x;
  float y;
  float w;
  float h;
  String text;
  int size;
  color mycolor;
  
  // Constructor
  BoxHour(float x_, float y_, String text_)
  {
    super( x_, y_, text_, 150, color(220,131,51));
    this.size = 150;
  }

  
}
