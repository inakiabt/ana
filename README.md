# Ana

Ana is a watchOS app for tracking runs and walks on an analog treadmill when no Bluetooth connection is available. Dial in your treadmill's settings, view live metrics from Apple Watch sensors, and save the workout to Apple Health with rich complication support for at-a-glance progress.

## Features

- **Manual workout controls** – Set speed, incline, and preferred distance units directly on the watch and adjust them mid-session with quick plus/minus buttons.
- **Personal stride calibration** – Enter or calibrate your step length in centimeters or inches, accept a height-based suggestion during onboarding, and fine-tune it with the guided calibration flow so distance is driven by your true stride instead of arm motion.
- **Rich live metrics** – See elapsed time, heart rate, estimated pace, distance, cadence, steps, movement intensity, and calorie burn with a prominent heart-rate ring and detailed grid that respects your chosen units.
- **Adaptive motion tracking** – Uses HealthKit live workout data, device motion, and pedometer readings to estimate distance and step count even when the treadmill is disconnected.
- **Automatic pause prompts** – Detects reduced movement to prompt for pause or end options, keeping stats accurate.
- **Workout summaries** – Review distance, energy, heart rate, and step totals after saving, then reset for the next workout.
- **Apple Health integration** – Writes workouts, distance, energy, steps, and heart-rate samples back to HealthKit when complete.
- **Complications** – Multiple complication families surface the latest saved treadmill stats on supported watch faces.
- **Visual identity** – Custom icon, color palette, and assets deliver a cohesive appearance.

## Project structure

- `AnaWatchApp Watch App` – Watch app target with assets and Info plist.
- `AnaWatchApp Watch App Extension` – SwiftUI code, HealthKit manager, motion analyzer, complications, and notifications.
- `AnaWatchApp.xcodeproj` – Xcode project containing the watch app and extension targets.

## Getting started

1. Open `AnaWatchApp.xcodeproj` in Xcode 14 or later.
2. Select the **AnaWatchApp Watch App** scheme and a watchOS simulator or paired watch for deployment.
3. Run the app. The first launch requests HealthKit permissions for workouts, heart rate, steps, distance, and energy.
4. Use the setup screen to dial in treadmill speed, incline, preferred units, and personalize your step length. Provide height and gender for an automatic estimate or run the calibration flow for a precise measurement before starting the workout. Adjust the controls during the session as needed.
5. End the workout to save results to Apple Health and refresh complications with the latest summary.

Health data access, motion tracking, and complication timelines are only available on an actual Apple Watch. Use a paired device to fully experience the app.
