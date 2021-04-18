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
  
  // We need to keep track of a Body and a width and height
  Body body;
  
  // Constructor
  BoxText(float x_, float y_, String text_, int size_, color mycolor_)
  {
    //super( x_, y_, size_, size_);
    
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
    
    // Define a body
    Vec2 center = new Vec2(x,y);
    // Define a polygon (this is what we use for a rectangle)
    PolygonShape sd = new PolygonShape();

    Vec2[] vertices = new Vec2[4];
    vertices[0] = box2d.vectorPixelsToWorld(new Vec2( -(this.w/2.1), (h/2.8) ));
    vertices[1] = box2d.vectorPixelsToWorld(new Vec2( (this.w/2.1), (h/2.8) ));
    vertices[2] = box2d.vectorPixelsToWorld(new Vec2( (this.w/2.1), -(h/2.8) ));
    vertices[3] = box2d.vectorPixelsToWorld(new Vec2( -(this.w/2.1), -(h/2.8) ));

    sd.set(vertices, vertices.length);

    // Define the body and make it from the shape
    BodyDef bd = new BodyDef();
    bd.type = BodyType.DYNAMIC;
    bd.position.set(box2d.coordPixelsToWorld(center));
    // Create the body
    body = box2d.createBody(bd);
    // Attach the fixture
    body.createFixture(sd, 1.0);

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
      body.setGravityScale(20);
    }
    else {
      body.setGravityScale(20);
    }
    
    //this.createTime = new Date();    
  }
  
  Vec2 explode( BoxText m, int expPower ) {
    //int G = -2300;
    int G = -expPower;
    Vec2 force = new Vec2(0.001,0.001); // Default is "apply no force."
    // Make a copy of the box that is NOT moving. (The body that this method is being applied to.)
    Vec2 pos = body.getWorldCenter();
    // Make a copy of the box that IS moving.
    Vec2 moverPos = m.body.getWorldCenter();
    // Vector pointing from moving box to Minute box.
    Vec2 distanceForce = pos.sub(moverPos);
    Vec2 df = pos.sub(moverPos);
    //if( ((df.x<0) && (df.y>0)) || ( (df.x>0) && (df.y<0) ) ) {
      //println(distanceForce);
    //}
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
  
  void applyLinearImpulse( Vec2 v ) {
    body.applyLinearImpulse(v, body.getWorldCenter(), true );
  }
  
    // This function removes the particle from the box2d world
  void killBody()
  {
    box2d.destroyBody(this.body);
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
    if ( (pos.y > height) || (pos.x<0) || (pos.x>width) ) {
      killBody();
      return true;
    }
    return false;
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
    float a = body.getAngle();
    
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

  boolean done()
  {
    
    // Let's find the screen position of the particle
    //pos = scaleToPixels(this.body.GetPosition());
    Vec2 pos = box2d.getBodyPixelCoord(body);
    // Is it off the bottom of the screen?
    //if (pos.y > height + this.w * this.h) {
    //  this.killBody();
    //  return true;
    //}
    if (pos.y > height) {
      killBody();
      return true;
    }

    //var diff=new Date()-this.createTime;
    //if(diff > 60*1000) {
    //  this.killBody();
    //  return true;
    //}

    return false;
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

  boolean done()
  {
    
    // Let's find the screen position of the particle
    //pos = scaleToPixels(this.body.GetPosition());
    Vec2 pos = box2d.getBodyPixelCoord(body);
    // Is it off the bottom of the screen?
    //if (pos.y > height + this.w * this.h) {
    //  this.killBody();
    //  return true;
    //}
    if (pos.y > height) {
      killBody();
      return true;
    }

    //var diff=new Date()-this.createTime;
    //if(diff > 3*60*1000) {
    //  this.killBody();
    //  return true;
    //}

    return false;
  }
  
  void killIt() {
    killBody();
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

  boolean done()
  {
    
    // Let's find the screen position of the particle
    //pos = scaleToPixels(this.body.GetPosition());
    Vec2 pos = box2d.getBodyPixelCoord(body);
    // Is it off the bottom of the screen?
    //if (pos.y > height + this.w * this.h) {
    //  this.killBody();
    //  return true;
    //}
    if (pos.y > height) {
      killBody();
      return true;
    }

    //diff=new Date()-this.createTime;
    //if(diff > 60*60*1000) {
    //  this.killBody();
    //  return true;
    //}

    return false;
  }
  
  void killIt() {
    killBody();
  }
}
