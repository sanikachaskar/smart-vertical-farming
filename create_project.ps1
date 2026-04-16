# Smart Vertical Farming - Complete Project Generator
# Run this script to create all project files

Write-Host "🌱 Creating Smart Vertical Farming Project Files..." -ForegroundColor Green

# Function to create file with content
function Create-File {
    param($Path, $Content)
    $dir = Split-Path $Path -Parent
    if ($dir -and !(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    Set-Content -Path $Path -Value $Content -Encoding UTF8
    Write-Host "  ✓ Created: $Path" -ForegroundColor Gray
}

# ==================== ARDUINO FIRMWARE ====================
$arduinoCode = @'
/*
 * Smart Vertical Farming System - Arduino Firmware
 * Version: 1.0.0
 */

#include <DHT.h>

#define DHTPIN 2
#define SOIL_MOISTURE_PIN A0
#define LIGHT_SENSOR_PIN A1
#define PH_SENSOR_PIN A2
#define PUMP_RELAY 4
#define LED_RELAY 5
#define FAN_RELAY 6
#define DHTTYPE DHT22

DHT dht(DHTPIN, DHTTYPE);
unsigned long lastReading = 0;
bool autoMode = true;

void setup() {
  Serial.begin(115200);
  dht.begin();
  pinMode(PUMP_RELAY, OUTPUT);
  pinMode(LED_RELAY, OUTPUT);
  pinMode(FAN_RELAY, OUTPUT);
  digitalWrite(PUMP_RELAY, HIGH);
  digitalWrite(LED_RELAY, HIGH);
  digitalWrite(FAN_RELAY, HIGH);
  Serial.println(F("Smart Vertical Farm Ready"));
}

void loop() {
  if (Serial.available()) {
    String cmd = Serial.readStringUntil('\n');
    if (cmd == "AUTO_ON") autoMode = true;
    else if (cmd == "AUTO_OFF") autoMode = false;
    else if (cmd == "PUMP_ON") digitalWrite(PUMP_RELAY, LOW);
    else if (cmd == "PUMP_OFF") digitalWrite(PUMP_RELAY, HIGH);
    else if (cmd == "LED_ON") digitalWrite(LED_RELAY, LOW);
    else if (cmd == "LED_OFF") digitalWrite(LED_RELAY, HIGH);
  }
  
  if (millis() - lastReading >= 2000) {
    float temp = dht.readTemperature();
    float hum = dht.readHumidity();
    int soil = map(analogRead(SOIL_MOISTURE_PIN), 520, 260, 0, 100);
    int light = map(analogRead(LIGHT_SENSOR_PIN), 0, 1023, 0, 100);
    
    Serial.print(F("{\"temp\":"));
    Serial.print(temp);
    Serial.print(F(",\"humidity\":"));
    Serial.print(hum);
    Serial.print(F(",\"soil\":"));
    Serial.print(soil);
    Serial.print(F(",\"light\":"));
    Serial.print(light);
    Serial.println(F("}"));
    
    if (autoMode) {
      if (soil < 30) digitalWrite(PUMP_RELAY, LOW);
      else digitalWrite(PUMP_RELAY, HIGH);
      if (temp > 30) digitalWrite(FAN_RELAY, LOW);
      else digitalWrite(FAN_RELAY, HIGH);
    }
    lastReading = millis();
  }
}
'@
Create-File "firmware/smart_farm_controller/smart_farm_controller.ino" $arduinoCode

# ==================== LIBRARIES ====================
Create-File "firmware/libraries.txt" @"
DHT sensor library by Adafruit (v1.4.4+)
Adafruit Unified Sensor (v1.1.9+)
"@

# ==================== BACKEND SERVER ====================
$pythonServer = @'
#!/usr/bin/env python3
"""Smart Vertical Farming - Flask Backend Server"""

from flask import Flask, jsonify, render_template, request
from flask_cors import CORS
import sqlite3
import json
import time
from datetime import datetime

app = Flask(__name__, static_folder='../frontend', template_folder='../frontend')
CORS(app)

def init_db():
    conn = sqlite3.connect('farm_data.db')
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS readings
                 (id INTEGER PRIMARY KEY, timestamp TEXT, temp REAL, 
                  humidity REAL, soil INTEGER, light INTEGER)''')
    conn.commit()
    conn.close()

@app.route('/')
def index():
    return render_template('dashboard.html')

@app.route('/api/status')
def status():
    return jsonify({
        'temperature': 23.5,
        'humidity': 65.0,
        'soil_moisture': 45,
        'light_level': 78,
        'pump': False,
        'led': True,
        'fan': False,
        'timestamp': datetime.now().isoformat()
    })

@app.route('/api/control/<device>/<action>')
def control(device, action):
    return jsonify({'success': True, 'device': device, 'action': action})

if __name__ == '__main__':
    init_db()
    app.run(host='0.0.0.0', port=5000, debug=True)
'@
Create-File "backend/server.py" $pythonServer

Create-File "backend/requirements.txt" @"
Flask==2.3.3
flask-cors==4.0.0
pyserial==3.5
"@

# ==================== FRONTEND DASHBOARD ====================
$htmlDashboard = @'
<!DOCTYPE html>
<html>
<head>
    <title>🌱 Smart Vertical Farm</title>
    <style>
        body { font-family: Arial; margin: 20px; background: #0a1a0f; color: #fff; }
        .grid { display: grid; grid-template-columns: repeat(4,1fr); gap: 20px; }
        .card { background: #1a3a2a; padding: 20px; border-radius: 10px; text-align: center; }
        .value { font-size: 48px; font-weight: bold; color: #4CAF50; }
        .controls { margin-top: 30px; display: flex; gap: 10px; }
        button { padding: 15px 30px; font-size: 18px; border: none; border-radius: 5px; cursor: pointer; }
        .on { background: #4CAF50; color: white; }
        .off { background: #f44336; color: white; }
    </style>
</head>
<body>
    <h1>🌱 Smart Vertical Farming Dashboard</h1>
    <div class="grid">
        <div class="card"><div>🌡️ Temperature</div><div class="value" id="temp">--°C</div></div>
        <div class="card"><div>💧 Humidity</div><div class="value" id="hum">--%</div></div>
        <div class="card"><div>🌿 Soil Moisture</div><div class="value" id="soil">--%</div></div>
        <div class="card"><div>☀️ Light Level</div><div class="value" id="light">--%</div></div>
    </div>
    <div class="controls">
        <button class="on" onclick="control('pump','on')">💧 Pump ON</button>
        <button class="off" onclick="control('pump','off')">💧 Pump OFF</button>
        <button class="on" onclick="control('led','on')">💡 LED ON</button>
        <button class="off" onclick="control('led','off')">💡 LED OFF</button>
    </div>
    <script>
        async function fetchStatus() {
            const res = await fetch('/api/status');
            const data = await res.json();
            document.getElementById('temp').textContent = data.temperature.toFixed(1) + '°C';
            document.getElementById('hum').textContent = data.humidity.toFixed(1) + '%';
            document.getElementById('soil').textContent = data.soil_moisture + '%';
            document.getElementById('light').textContent = data.light_level + '%';
        }
        async function control(device, action) {
            await fetch('/api/control/' + device + '/' + action);
        }
        setInterval(fetchStatus, 3000);
        fetchStatus();
    </script>
</body>
</html>
'@
Create-File "frontend/dashboard.html" $htmlDashboard

# ==================== HARDWARE DOCS ====================
Create-File "hardware/parts_list.md" @"
# Parts List - Smart Vertical Farming

| Component | Quantity | Estimated Cost |
|-----------|----------|----------------|
| Arduino Uno R3 | 1 | $25 |
| DHT22 Sensor | 1 | $5 |
| Soil Moisture Sensor | 1 | $3 |
| Relay Module (4ch) | 1 | $8 |
| Water Pump 12V | 1 | $10 |
| LED Grow Light | 1 | $15 |
| Jumper Wires | 20 | $5 |
| **Total** | | **~$71** |
"@

Create-File "hardware/wiring_guide.md" @"
# Wiring Guide

- DHT22: VCC→5V, GND→GND, DATA→Pin 2
- Soil Sensor: VCC→5V, GND→GND, AOUT→A0
- Relay Module: IN1→Pin 4 (Pump), IN2→Pin 5 (LED)
"@

# ==================== DOCS ====================
Create-File "docs/setup_guide.md" @"
# Setup Guide

1. Upload `firmware/smart_farm_controller.ino` to Arduino
2. Install Python requirements: `pip install -r backend/requirements.txt`
3. Run server: `python backend/server.py`
4. Open http://localhost:5000
"@

