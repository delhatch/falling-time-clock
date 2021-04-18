# falling-time-clock
A clock that displays the numbers as physical falling numbers.
It is written in the Processing language, and uses the box2d and jbox2d physics engine.

![screenshot](https://github.com/delhatch/falling-time-clock/blob/master/fallingclock1.JPG)

The original concept was created by "arcade perfect", AFAIK. That really cool project can be found at: https://hackaday.io/project/176037-concrete-physics-clock
  
This code base was started using the Daniel Shiffman's example project, Exercise 5.10 "AttractionApplyForce" found at https://github.com/nature-of-code/noc-examples-processing/tree/master/chp05_physicslibraries/box2d/Exercise_5_10_AttractionApplyForce

BTW, Daniel Shiffman's books "Learning Processing" and "Nature of Code" are excellent! Find them at: https://shiffman.net/books/

In addition, I used some of the Box class, and time-keeping code, from JanHBade's version of this type of clock. His version is located at: https://github.com/JanHBade/FallingTime

KNOWN BUGS:
1) There is a memory leak somewhere. Due to the world's walls, the number of bodies does not grow above a certain level (around 84), but the memory usage keeps constantly increasing. This happens even as the number of bodies decreases. Not sure why.
2) If there is no "Minutes" object on the screen, it crashes unpleasantly. At the start of each new minute, the old minute digits "explode." If there is no object to explode, the code crashes. This will be an easy fix, but I haven't done it yet.
