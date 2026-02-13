/**
 * Blind Obstacle Avoidance Experiment (Processing 4) — FULL VERSION
 * - Player (blue dot) navigates corridor with obstacles.
 * - 5 forward "sensor rays" compute nearest distance (sr.minD).
 * - Trial ends on collision or success (reach right edge).
 * - Press R to reset (works even after noLoop()).
 * - Automatically logs one CSV row per trial: blind_obstacle_log.csv
 *
 * Controls:
 *   W / Up    = forward
 *   S / Down  = backward
 *   A / Left  = rotate left
 *   D / Right = rotate right
 */

PVector pos;
float heading = 0;     // radians
float radius = 12;

float speed = 2.2;
float turnSpeed = 0.045;

int worldW = 1000;
int worldH = 600;

// Corridor bounds
float wallPad = 60;

// Obstacles
ArrayList<Obstacle> obs = new ArrayList<Obstacle>();

// Sensor rays
float[] rayAngles = { -0.35, -0.17, 0, 0.17, 0.35 }; // relative to heading (radians)
float rayMax = 220;

// ===== Experiment Logging =====
int trialID = 1;
int collisionCount = 0;

float minDistanceOverall = 999999;
float minDistanceSum = 0;
int minDistanceSamples = 0;

int trialStartTime;
int trialEndTime;

PrintWriter logWriter;

// Trial state
boolean trialEnded = false;
String endMessage = "";

void setup() {
  size(1000, 600);
  smooth(4);

  // Player start
  pos = new PVector(90, height/2);
  heading = 0;

  // Init obstacles
  initObstacles(7); // seed for reproducibility

  // CSV logger (one file, multiple trials)
  logWriter = createWriter("blind_obstacle_log.csv");
  logWriter.println("trial_id,start_time_ms,end_time_ms,duration_ms,collision_count,min_distance_overall,mean_min_distance,outcome");
  logWriter.flush();

  startTrial();
}

void draw() {
  background(14);

  drawCorridor();

  // Sense FIRST (so you can log distance even if player doesn't move this frame)
  SensorResult sr = sense();

  // Accumulate distance stats while trial active
  if (!trialEnded) {
    minDistanceOverall = min(minDistanceOverall, sr.minD);
    minDistanceSum += sr.minD;
    minDistanceSamples++;
  }

  // Move only if trial active
  if (!trialEnded) {
    handleMovement();
  }

  // Draw obstacles + player + rays
  for (Obstacle o : obs) o.draw();
  drawPlayer();
  drawRays(sr);

  // HUD
  drawHUD(sr);

  // End conditions (only check if still active)
  if (!trialEnded) {
    if (isColliding()) {
      collisionCount++;
      endTrial("collision");
    } else if (pos.x > width - 30) {
      endTrial("success");
    }
  }

  // End overlay
  if (trialEnded) {
    drawEndOverlay();
  }
}

void keyPressed() {
  // Reset works even after noLoop() because key events still fire
  if (key == 'r' || key == 'R') {
    resetTrial();
  }
}

void startTrial() {
  trialEnded = false;
  endMessage = "";
  trialStartTime = millis();

  // reset stats
  collisionCount = 0;
  minDistanceOverall = 999999;
  minDistanceSum = 0;
  minDistanceSamples = 0;

  // ensure draw loop running
  loop();
}

void resetTrial() {
  // New trial id
  trialID++;

  // Reset player
  pos = new PVector(90, height/2);
  heading = 0;

  // (Optional) re-randomize obstacles per trial:
  // initObstacles((int)random(1, 100000)); // uncomment if you want different layouts each trial

  startTrial();
}

void endTrial(String outcome) {
  trialEnded = true;
  trialEndTime = millis();
  int duration = trialEndTime - trialStartTime;

  float meanMinDistance = (minDistanceSamples > 0) ? (minDistanceSum / minDistanceSamples) : 0;

  // Write one row to CSV
  logWriter.println(
    trialID + "," +
    trialStartTime + "," +
    trialEndTime + "," +
    duration + "," +
    collisionCount + "," +
    nf(minDistanceOverall, 0, 2) + "," +
    nf(meanMinDistance, 0, 2) + "," +
    outcome
  );
  logWriter.flush();

  if (outcome.equals("success")) {
    endMessage = "SUCCESS — press R to start next trial";
  } else {
    endMessage = "COLLISION — press R to start next trial";
  }

  // Stop animation loop (but keyPressed still works)
  noLoop();
}

void exit() {
  // Ensure CSV is saved properly
  if (logWriter != null) {
    logWriter.flush();
    logWriter.close();
  }
  super.exit();
}

// ================== World / Rendering ==================

void initObstacles(int seed) {
  obs.clear();

  randomSeed(seed);
  for (int i = 0; i < 18; i++) {
    float w = random(35, 80);
    float h = random(35, 120);
    float x = random(220, worldW - 80);

    float yMin = wallPad + h/2 + 10;
    float yMax = height - wallPad - h/2 - 10;
    float y = random(yMin, yMax);

    obs.add(new Obstacle(x, y, w, h));
  }
}

void drawCorridor() {
  noStroke();
  fill(40);
  rect(0, 0, width, wallPad);
  rect(0, height - wallPad, width, wallPad);

  stroke(70);
  for (int x = 0; x < width; x += 25) {
    point(x, height/2);
  }
}

void handleMovement() {
  if (!keyPressed) return;

  // rotate
  if (key == 'a' || key == 'A' || keyCode == LEFT) heading -= turnSpeed;
  if (key == 'd' || key == 'D' || keyCode == RIGHT) heading += turnSpeed;

  // forward/back
  PVector dir = new PVector(cos(heading), sin(heading));
  if (key == 'w' || key == 'W' || keyCode == UP) pos.add(PVector.mult(dir, speed));
  if (key == 's' || key == 'S' || keyCode == DOWN) pos.sub(PVector.mult(dir, speed));

  pos.x = constrain(pos.x, 10, width - 10);
  pos.y = constrain(pos.y, 10, height - 10);
}

void drawPlayer() {
  noStroke();
  fill(90, 170, 255);
  ellipse(pos.x, pos.y, radius*2, radius*2);

  stroke(200);
  PVector tip = PVector.add(pos, new PVector(cos(heading), sin(heading)).mult(radius + 10));
  line(pos.x, pos.y, tip.x, tip.y);
}

void drawHUD(SensorResult sr) {
  fill(220);
  textSize(14);
  textAlign(LEFT, TOP);
  text("trial: " + trialID, 12, 12);
  text("min distance (this frame): " + nf(sr.minD, 0, 1) + " px", 12, 30);
  text("controls: W/A/S/D (or arrows) | R = next trial", 12, 48);

  // simple warning bar
  float d = sr.minD;
  float silentBeyond = 180;
  float danger = 45;

  float warn = map(constrain(d, danger, silentBeyond), silentBeyond, danger, 0, 1);
  noStroke();
  fill(255, 200, 60);
  rect(12, 70, 180 * warn, 10);

  if (d < danger + 8) {
    fill(255, 80, 80);
    text("TOO CLOSE", 12, 86);
  }
}

void drawEndOverlay() {
  fill(0, 180);
  noStroke();
  rect(0, 0, width, 110);

  fill(255);
  textSize(20);
  textAlign(CENTER, CENTER);
  text(endMessage, width/2, 55);
}

// ================== Sensing ==================

class SensorResult {
  float[] d;        // distance per ray
  PVector[] hit;    // hit point per ray
  float minD;
  int minIdx;
  SensorResult(int n) {
    d = new float[n];
    hit = new PVector[n];
    minD = 1e9;
    minIdx = 0;
  }
}

SensorResult sense() {
  SensorResult sr = new SensorResult(rayAngles.length);

  for (int i = 0; i < rayAngles.length; i++) {
    float ang = heading + rayAngles[i];
    PVector rayDir = new PVector(cos(ang), sin(ang));
    PVector rayEnd = PVector.add(pos, PVector.mult(rayDir, rayMax));

    float bestD = rayMax;
    PVector bestHit = rayEnd.copy();

    // Corridor inner edges: y = wallPad and y = height - wallPad
    if (abs(rayDir.y) > 1e-6) {
      float tTop = (wallPad - pos.y) / rayDir.y;
      if (tTop > 0 && tTop < bestD) {
        float xAt = pos.x + tTop * rayDir.x;
        if (xAt >= 0 && xAt <= width) {
          bestD = tTop;
          bestHit = new PVector(xAt, wallPad);
        }
      }

      float tBot = ((height - wallPad) - pos.y) / rayDir.y;
      if (tBot > 0 && tBot < bestD) {
        float xAt = pos.x + tBot * rayDir.x;
        if (xAt >= 0 && xAt <= width) {
          bestD = tBot;
          bestHit = new PVector(xAt, height - wallPad);
        }
      }
    }

    // Obstacle intersection via stepping (robust + easy)
    float step = 3.0;
    for (float t = 0; t <= bestD; t += step) {
      PVector p = PVector.add(pos, PVector.mult(rayDir, t));
      if (pointInAnyObstacle(p)) {
        bestD = t;
        bestHit = p;
        break;
      }
    }

    sr.d[i] = bestD;
    sr.hit[i] = bestHit;

    if (bestD < sr.minD) {
      sr.minD = bestD;
      sr.minIdx = i;
    }
  }

  return sr;
}

boolean pointInAnyObstacle(PVector p) {
  for (Obstacle o : obs) {
    if (o.contains(p.x, p.y)) return true;
  }
  return false;
}

void drawRays(SensorResult sr) {
  for (int i = 0; i < rayAngles.length; i++) {
    float d = sr.d[i];
    PVector h = sr.hit[i];

    float a = map(constrain(d, 0, rayMax), rayMax, 0, 60, 220);
    stroke(255, a);
    line(pos.x, pos.y, h.x, h.y);

    noStroke();
    fill(255, a);
    ellipse(h.x, h.y, 5, 5);
  }

  PVector hc = sr.hit[sr.minIdx];
  stroke(255, 220, 100);
  strokeWeight(2);
  line(pos.x, pos.y, hc.x, hc.y);
  strokeWeight(1);
}

// ================== Collision ==================

boolean isColliding() {
  // Corridor walls
  if (pos.y - radius < wallPad) return true;
  if (pos.y + radius > height - wallPad) return true;

  // Obstacles
  for (Obstacle o : obs) {
    if (circleRect(pos.x, pos.y, radius, o.x - o.w/2, o.y - o.h/2, o.w, o.h)) return true;
  }
  return false;
}

boolean circleRect(float cx, float cy, float r, float rx, float ry, float rw, float rh) {
  float closestX = constrain(cx, rx, rx + rw);
  float closestY = constrain(cy, ry, ry + rh);
  float dx = cx - closestX;
  float dy = cy - closestY;
  return (dx*dx + dy*dy) <= r*r;
}

// ================== Obstacle ==================

class Obstacle {
  float x, y, w, h;
  Obstacle(float x, float y, float w, float h) {
    this.x = x; this.y = y; this.w = w; this.h = h;
  }

  void draw() {
    noStroke();
    fill(120);
    rectMode(CENTER);
    rect(x, y, w, h, 6);
    rectMode(CORNER);
  }

  boolean contains(float px, float py) {
    return (px >= x - w/2 && px <= x + w/2 && py >= y - h/2 && py <= y + h/2);
  }
}
