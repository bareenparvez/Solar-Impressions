import processing.serial.*;
import peasy.*;
import java.util.ArrayList;

Serial port;
PeasyCam cam;
int ldrValue;
String dateTime;
ArrayList<WaveLayer> layers;
int layerCount = 9;
float noiseScale = 0.01;
int pixelOpacity = 160; // Opacity of the pixels, can be changed dynamically

color[] orangePalette = {
  color(60, 0, 0), // Deep Red
  color(255, 69, 0), // Orange
  color(255, 140, 0), // Dark Orange
  color(255, 215, 0), // Gold
  color(255, 255, 224) // Light Yellow
};

color[] bluePalette = {
  color(0, 0, 139), // Dark Blue
  color(0, 0, 255), // Blue
  color(30, 144, 255), // Dodger Blue
  color(135, 206, 235), // Sky Blue
  color(224, 255, 255) // Light Cyan
};

color[] greyPalette = {
  color(47, 79, 79), // Dark Slate Gray
  color(105, 105, 105), // Dim Gray
  color(169, 169, 169), // Dark Gray
  color(211, 211, 211), // Light Gray
  color(245, 245, 245) // White Smoke
};

void setup() {
  fullScreen(P3D);
  background(0);
  smooth();
  
  // Adjust the port name based on your setup
  String portName = Serial.list()[0]; // Automatically picks the first available port
  port = new Serial(this, portName, 115200);
  port.bufferUntil('\n');
  
  cam = new PeasyCam(this, 500);
  layers = new ArrayList<WaveLayer>();
  
  for (int i = 0; i < layerCount; i++) {
    layers.add(new WaveLayer(i));
  }
}

void draw() {
  background(0); // Clear the background each frame
  
  if (port.available() > 0) {
    String data = port.readStringUntil('\n');
    if (data != null) {
      data = trim(data);
      String[] splitData = split(data, ',');
      if (splitData.length == 2) { // Ensure the data is split correctly
        ldrValue = int(splitData[0]);
        dateTime = splitData[1];
        println("LDR Value: " + ldrValue + ", DateTime: " + dateTime);
      }
    }
  }
  
  lights();
  for (WaveLayer layer : layers) {
    layer.update();
    layer.display();
  }
}

class WaveLayer {
  ArrayList<WaveParticle> particles;
  int baseParticleCount = 1000; // Base particle count
  float zOffset;
  color layerColor;
  int layerIndex;
  float targetParticleCount;
  float currentParticleCount;

  WaveLayer(int index) {
    particles = new ArrayList<WaveParticle>();
    zOffset = map(index, 0, layerCount, -300, 300);
    layerColor = getInterpolatedColor(index);
    layerIndex = index;
    targetParticleCount = baseParticleCount;
    currentParticleCount = baseParticleCount;
  }

  void update() {
    targetParticleCount = map(ldrValue, 0, 1023, 50, 3000);
    currentParticleCount = lerp(currentParticleCount, targetParticleCount, 0.05); // Smooth transition
    
    while (particles.size() < currentParticleCount) {
      particles.add(new WaveParticle());
    }
    while (particles.size() > currentParticleCount) {
      particles.remove(particles.size() - 1);
    }
    
    for (WaveParticle p : particles) {
      p.update();
    }
  }

  void display() {
    layerColor = getInterpolatedColor(layerIndex);
    fill(layerColor, pixelOpacity); // Use the pixelOpacity variable
    for (WaveParticle p : particles) {
      p.display(zOffset);
    }
  }

  // Function to get the interpolated color for a given layer index
  color getInterpolatedColor(int index) {
    float ratio = float(index) / (layerCount - 1);
    int baseIndex;
    float blend;
    
    if (ldrValue > 623) { // Transition from orange to blue
      float ldrRatio = map(ldrValue, 1023, 500, 0, 1);
      baseIndex = int(ratio * (orangePalette.length - 1));
      baseIndex = constrain(baseIndex, 0, orangePalette.length - 2); // Ensure valid index
      blend = ratio * (orangePalette.length - 1) - baseIndex;
      color c1 = lerpColor(orangePalette[baseIndex], orangePalette[baseIndex + 1], blend);
      color c2 = lerpColor(bluePalette[baseIndex], bluePalette[baseIndex + 1], blend);
      return lerpColor(c1, c2, ldrRatio);
    } else if (ldrValue > 220) { // Transition from blue to grey
      float ldrRatio = map(ldrValue, 326, 1023, 0, 1);
      baseIndex = int(ratio * (bluePalette.length - 1));
      baseIndex = constrain(baseIndex, 0, bluePalette.length - 2); // Ensure valid index
      blend = ratio * (bluePalette.length - 1) - baseIndex;
      color c1 = lerpColor(bluePalette[baseIndex], bluePalette[baseIndex + 1], blend);
      color c2 = lerpColor(greyPalette[baseIndex], greyPalette[baseIndex + 1], blend);
      return lerpColor(c1, c2, ldrRatio);
    } else { // Grey palette
      float ldrRatio = map(ldrValue, 0, 180, 0, 1);
      baseIndex = int(ratio * (greyPalette.length - 1));
      baseIndex = constrain(baseIndex, 0, greyPalette.length - 2); // Ensure valid index
      blend = ratio * (greyPalette.length - 1) - baseIndex;
      return lerpColor(greyPalette[baseIndex], greyPalette[baseIndex + 1], blend);
    }
  }
}

class WaveParticle {
  PVector pos;
  float size;

  WaveParticle() {
    float angle = random(TWO_PI);
    float radius = randomGaussian() * width / 12; // Gaussian distribution for denser center
    pos = new PVector(width / 2 + cos(angle) * radius, height / 2 + sin(angle) * radius);
    size = random(1, 2);
  }

  void update() {
    float intensityFactor = map(ldrValue, 0, 1023, 0.5, 1.5);
    float n = noise(pos.x * noiseScale * intensityFactor, pos.y * noiseScale * intensityFactor, frameCount * 0.01);
    pos.x += map(n, 0, 1, -2, 2);
    pos.y += map(n, 0, 1, -2, 2);

    // Keep particles within the screen bounds
    pos.x = constrain(pos.x, 0, width);
    pos.y = constrain(pos.y, 0, height);
  }

  void display(float zOffset) {
    noStroke();
    pushMatrix();
    translate(pos.x - width / 2, pos.y - height / 2, zOffset);
    box(size);
    popMatrix();
  }
}

// Function to change the opacity of the pixels
void setPixelOpacity(int newOpacity) {
  pixelOpacity = constrain(newOpacity, 0, 255);
}

// Save a frame when a key is pressed
void keyPressed() {
  if (key == 's' || key == 'S') {
    String filename = "visualization-" + nf(frameCount, 4) + ".png";
    saveFrame(filename);
    println("Saved image: " + filename);
  }
}
