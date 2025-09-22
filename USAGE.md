# Ana - Apple Watch Treadmill Workout Tracker

## Overview
Ana is a comprehensive Apple Watch app designed to track indoor treadmill workouts without requiring Bluetooth connectivity. The app provides manual speed and incline input with real-time health and fitness tracking.

## Features

### ✅ Core Functionality
- **Manual Speed & Incline Input**: Set your treadmill speed (1.0-12.0 mph / 1.6-19.3 km/h) and incline (0-15%)
- **Configurable Unit System**: Choose between Imperial (mph/miles) or Metric (km/h/km) units
- **Customizable Step Estimation**: Configure steps per mile for walking (1800-2800) and running (1400-2200)
- **Real-time Heart Rate Monitoring**: Live BPM display with average heart rate calculation
- **Distance & Pace Tracking**: Automatic calculation based on speed and workout duration
- **Step Estimation**: Advanced algorithms to estimate steps during treadmill workouts
- **Calorie Calculation**: METs-based calorie estimation using user weight, speed, and incline
- **Workout Controls**: Start, pause, resume, and end workout sessions
- **Health App Integration**: Automatically saves workout data to Apple Health

### 🎯 User Interface
- **Setup Screen**: Easy speed/incline configuration with quick presets
- **Real-time Metrics**: Large, easy-to-read displays optimized for Apple Watch
- **Tabbed Workout View**: Switch between metrics and settings during workout
- **Quick Presets**: Pre-configured settings for common workout types

## How to Use

### 1. First Launch
1. Open Ana on your Apple Watch
2. Grant Health permissions when prompted
3. Tap "Start Workout" to begin

### 2. Workout Setup
1. **Choose Unit System**: Select Imperial (mph/miles) or Metric (km/h/km)
2. **Adjust Speed**: Use the slider or enter manually
   - Imperial: 1.0-12.0 mph
   - Metric: 1.6-19.3 km/h
3. **Set Incline**: Adjust incline percentage (0-15%)
4. **Configure Advanced Settings** (optional):
   - Customize walking steps per mile (1800-2800)
   - Customize running steps per mile (1400-2200)
5. **Use Presets**: Choose from:
   - Easy Walk (2.5 mph / 4.0 km/h, 0% incline)
   - Brisk Walk (3.5 mph / 5.6 km/h, 2% incline)
   - Hill Walk (3.0 mph / 4.8 km/h, 5% incline)
   - Light Jog (5.0 mph / 8.0 km/h, 1% incline)
6. **Start Workout**: Tap the green "Start Workout" button

### 3. During Workout
#### Metrics View (Tab 1):
- **Duration**: Real-time workout timer
- **Heart Rate**: Current BPM + average BPM
- **Distance**: Calculated distance traveled
- **Pace**: Current pace (minutes per mile)
- **Step Estimation**: Estimated step count based on treadmill speed and duration
- **Calories**: Real-time calorie burn

#### Controls:
- **Pause/Resume**: Orange pause or green play button
- **Stop**: Red stop button (with confirmation dialog)

#### Settings View (Tab 2):
- View current speed, incline, and unit system settings  
- Reminder that you can adjust these on your treadmill

### 4. Ending Workout
1. Tap the red stop button
2. Confirm to end workout
3. Data is automatically saved to Apple Health

## Technical Features

### Health Integration
- **HealthKit Permissions**: Reads heart rate, body weight; writes workouts, calories, distance, steps
- **Workout Sessions**: Proper HKWorkoutSession integration
- **Live Data Collection**: Real-time health data during workouts
- **Health App Sync**: Automatic synchronization with Apple Health

### Motion Tracking
- **Step Estimation**: Speed-based algorithms optimized for desk treadmill workouts
- **Stationary Arm Support**: Works perfectly with desk treadmills where arms remain stationary
- **Distance Calculation**: Based on treadmill speed settings rather than arm movement

### Calculations
- **Distance**: `Distance = Speed × Time`
- **Pace**: `Pace = 60 ÷ Speed (minutes per distance unit)`
- **Steps**: `Steps = Distance × Steps_per_Mile` (customizable: 1800-2800 for walking, 1400-2200 for running)
- **Calories**: METs-based formula incorporating:
  - User weight
  - Speed (walking vs running METs)
  - Incline adjustment (significantly affects calorie burn)
  - Duration
- **Average Heart Rate**: Running average of all recorded heart rate measurements

### Data Persistence
- Settings maintained during workout sessions
- Real-time stat updates every second
- Automatic Health app data saving on workout completion

## Quick Start Presets

| Preset | Imperial Speed | Metric Speed | Incline | Use Case |
|--------|---------------|--------------|---------|----------|
| Easy Walk | 2.5 mph | 4.0 km/h | 0% | Gentle warm-up or recovery |
| Brisk Walk | 3.5 mph | 5.6 km/h | 2% | Standard cardio workout |
| Hill Walk | 3.0 mph | 4.8 km/h | 5% | Strength and endurance training |
| Light Jog | 5.0 mph | 8.0 km/h | 1% | Light running session |

## Requirements
- Apple Watch Series 3 or later
- watchOS 9.0 or later
- Health app permissions for optimal functionality
- **Perfect for desk treadmills** where arms remain stationary while working

## Privacy & Permissions
Ana requires the following permissions:
- **Health Data**: To read heart rate and write workout data
- **Motion & Fitness**: To track steps and movement
- All data remains on your device and is only shared with Apple Health

## Tips for Best Results
1. **Calibrate**: Use the treadmill's speed/incline readings for accuracy
2. **Heart Rate**: Ensure your Apple Watch fits snugly for best heart rate readings
3. **Consistency**: Maintain steady speed/incline for accurate calculations
4. **Health Data**: Keep your weight updated in the Health app for accurate calorie calculations
5. **Desk Treadmill**: Perfect for desk treadmills - steps and distance are calculated from your speed settings, not arm movement
6. **Personalize**: Adjust steps per mile in Advanced Settings to match your stride length
7. **Unit Preference**: Choose your preferred unit system (Imperial/Metric) for comfort

## Support
For issues or feature requests, please visit the GitHub repository.