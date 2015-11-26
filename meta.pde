import ddf.minim.*;
import org.openkinect.processing.*;
KinectTracker tracker;
PImage img;
Minim minim;
AudioInput in;
int lastTime;
boolean shouldMove;
int size;
float lastX;
float lastY;

void setup() {
  size(500, 500);
  img = loadImage("code.png");
  tracker = new KinectTracker(this);
  minim = new Minim(this);
  in = minim.getLineIn(Minim.STEREO, 512);
  lastTime = 0;
  shouldMove = false;
  size = 200;
  lastX = 50; lastY = 50;
  image(img, 0, 0, size, size);
}

void draw() {
  background(255);
  tracker.track();
  tracker.display();
  
  // Get the location 
  if (shouldMove) {
    PVector v1 = tracker.getPos();
    tint(255, 255);
    image(img, max(0, v1.x-size/2), max(0,v1.y-size), size, size);
    lastX = max(0, v1.x-size/2);
    lastY = max(0, v1.y-size/2);
  } else {
    lastX = lastX + random(-20, 20);
    lastY = lastY + random(-20, 20);
    tint(255, 50);
    image(img, max(0, lastX), max(0,lastY), size, size);
    tint(255, 255);
  }
  //print(v1.x, v1.y, "\n");
  for(int i = 0; i < in.bufferSize() - 1; i++) {
    if (in.left.get(i) > .2 && millis()-lastTime > 500) {
      lastTime = millis();
      shouldMove = !shouldMove;
      break;
    }
  }
}












// Additional support thanks to
// Daniel Shiffman and Thomas Sanchez Lengeling and Dan O'Sullivan
// Tracking the average location beyond a given depth threshold
// https://github.com/shiffman/OpenKinect-for-Processing
// http://shiffman.net/p5/kinect/

// Adjust the threshold with key presses
void keyPressed() {
  int t = tracker.getThreshold();
  if (key == CODED) {
    if (keyCode == UP) {
      t +=5;
      tracker.setThreshold(t);
    } else if (keyCode == DOWN) {
      t -=5;
      tracker.setThreshold(t);
    }
  }
}

// Daniel Shiffman
// Tracking the average location beyond a given depth threshold
// Thanks to Dan O'Sullivan

// https://github.com/shiffman/OpenKinect-for-Processing
// http://shiffman.net/p5/kinect/

class KinectTracker {

  // Depth threshold
  int threshold = 745;

  // Raw location
  PVector loc;

  // Interpolated location
  PVector lerpedLoc;

  // Depth data
  int[] depth;

  // What we'll show the user
  PImage display;
  
  //Kinect2 class
  Kinect2 kinect2;
  
  KinectTracker(PApplet pa) {
    
    //enable Kinect2
    kinect2 = new Kinect2(pa);
    kinect2.initDepth();
    kinect2.initDevice();
    
    // Make a blank image
    display = createImage(kinect2.depthWidth, kinect2.depthHeight, RGB);
    
    // Set up the vectors
    loc = new PVector(0, 0);
    lerpedLoc = new PVector(0, 0);
  }

  void track() {
    // Get the raw depth as array of integers
    depth = kinect2.getRawDepth();

    // Being overly cautious here
    if (depth == null) return;

    float sumX = 0;
    float sumY = 0;
    float count = 0;

    for (int x = 0; x < kinect2.depthWidth; x++) {
      for (int y = 0; y < kinect2.depthHeight; y++) {
        // Mirroring the image
        int offset = kinect2.depthWidth - x - 1 + y * kinect2.depthWidth;
        // Grabbing the raw depth
        int rawDepth = depth[offset];

        // Testing against threshold
        if (rawDepth > 0 && rawDepth < threshold) {
          sumX += x;
          sumY += y;
          count++;
        }
      }
    }
    // As long as we found something
    if (count != 0) {
      loc = new PVector(sumX/count, sumY/count);
    }

    // Interpolating the location, doing it arbitrarily for now
    lerpedLoc.x = PApplet.lerp(lerpedLoc.x, loc.x, 0.3f);
    lerpedLoc.y = PApplet.lerp(lerpedLoc.y, loc.y, 0.3f);
  }

  PVector getLerpedPos() {
    return lerpedLoc;
  }

  PVector getPos() {
    return loc;
  }

  void display() {
    PImage img = kinect2.getDepthImage();

    // Being overly cautious here
    if (depth == null || img == null) return;

    // Going to rewrite the depth image to show which pixels are in threshold
    // A lot of this is redundant, but this is just for demonstration purposes
    display.loadPixels();
    for (int x = 0; x < kinect2.depthWidth; x++) {
      for (int y = 0; y < kinect2.depthHeight; y++) {
        // mirroring image
        int offset = (kinect2.depthWidth - x - 1) + y * kinect2.depthWidth;
        // Raw depth
        int rawDepth = depth[offset];
        int pix = x + y*display.width;
        if (rawDepth > 0 && rawDepth < threshold) {
          // A red color instead
          display.pixels[pix] = color(150, 50, 50);
        } else {
          display.pixels[pix] = img.pixels[offset];
        }
      }
    }
    display.updatePixels();

    // Draw the image
    image(display, 0, 0);
  }

  int getThreshold() {
    return threshold;
  }

  void setThreshold(int t) {
    threshold =  t;
  }
}