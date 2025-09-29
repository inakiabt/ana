# Ana Apple Watch App - UI Flow Demonstration

## 1. Launch Screen (ContentView)
```
┌─────────────────────┐
│                     │
│        Ana          │ ← Large title
│                     │
│  Treadmill Workout  │ ← Subtitle
│      Tracker        │
│                     │
│   ┌─────────────┐   │
│   │Start Workout│   │ ← Primary action button (green)
│   └─────────────┘   │
│                     │
│  Grant Health Perms │ ← If permissions not granted
│                     │
└─────────────────────┘
```

## 2. Setup Screen (SetupView)
```
┌─────────────────────┐
│   Workout Setup     │ ← Navigation title
│                     │
│ Speed               │
│ 3.5 mph            │ ← Current value
│ ████████░░░░░░░░░░  │ ← Slider (1.0-12.0)
│ 1.0           12.0  │
│                     │
│ Incline             │
│ 2.0%               │ ← Current value  
│ ████░░░░░░░░░░░░░░  │ ← Slider (0-15%)
│ 0%             15%  │
│                     │
│ Quick Presets       │
│ ┌─────┐ ┌─────────┐ │
│ │Easy │ │ Brisk   │ │
│ │Walk │ │ Walk    │ │
│ │2.5  │ │ 3.5     │ │
│ │0%   │ │ 2%      │ │
│ └─────┘ └─────────┘ │
│ ┌─────┐ ┌─────────┐ │
│ │Hill │ │ Light   │ │
│ │Walk │ │ Jog     │ │
│ │3.0  │ │ 5.0     │ │
│ │5%   │ │ 1%      │ │
│ └─────┘ └─────────┘ │
│                     │
│ ┌─────────────────┐ │
│ │ ▶ Start Workout │ │ ← Green button
│ └─────────────────┘ │
└─────────────────────┘
```

## 3. Active Workout Screen - Metrics Tab
```
┌─────────────────────┐
│      12:34          │ ← Timer (MM:SS format)
│                     │
│  ⏸️  🛑              │ ← Pause & Stop buttons
│                     │
│ Heart Rate          │
│    142 BPM          │ ← Large, prominent display
│  Avg: 138           │ ← Average in smaller text
│                     │
│ ┌─────────┬─────────┐ │
│ │Distance │  Pace   │ │
│ │ 0.89 mi │ 17:08   │ │
│ │         │  /mi    │ │
│ └─────────┴─────────┘ │
│                     │
│ ┌─────────┬─────────┐ │
│ │ Steps   │Calories │ │
│ │  1,247  │   89    │ │
│ │         │  cal    │ │
│ └─────────┴─────────┘ │
│                     │
│ • •                 │ ← Page indicators
└─────────────────────┘
```

## 4. Active Workout Screen - Settings Tab  
```
┌─────────────────────┐
│  Current Settings   │ ← Header
│                     │
│ ┌─────────────────┐ │
│ │ Speed     3.5mph│ │ ← Current speed
│ │                 │ │
│ │ Incline    2.0% │ │ ← Current incline  
│ └─────────────────┘ │
│                     │
│   Tip: You can      │ ← Helpful hint
│   adjust these on   │
│   your treadmill    │
│                     │
│                     │
│                     │
│                     │
│                     │
│ •   •               │ ← Page indicators
└─────────────────────┘
```

## 5. Pause State
```
┌─────────────────────┐
│      12:34          │ ← Timer (paused)
│     PAUSED          │ ← Status indicator
│                     │
│  ▶️  🛑              │ ← Resume & Stop buttons
│                     │
│ Heart Rate          │
│    142 BPM          │ ← Last reading maintained
│  Avg: 138           │
│                     │
│ ┌─────────┬─────────┐ │
│ │Distance │  Pace   │ │
│ │ 0.89 mi │ 17:08   │ │ ← Values frozen
│ │         │  /mi    │ │
│ └─────────┴─────────┘ │
│                     │
│ ┌─────────┬─────────┐ │
│ │ Steps   │Calories │ │
│ │  1,247  │   89    │ │
│ │         │  cal    │ │
│ └─────────┴─────────┘ │
└─────────────────────┘
```

## 6. End Workout Confirmation
```
┌─────────────────────┐
│    End Workout      │ ← Alert title
│                     │
│  Are you sure you   │
│  want to end your   │
│     workout?        │
│                     │
│ ┌─────────────────┐ │
│ │     Cancel      │ │ ← Default button
│ └─────────────────┘ │
│                     │
│ ┌─────────────────┐ │
│ │      End        │ │ ← Destructive button (red)
│ └─────────────────┘ │
└─────────────────────┘
```

## Key UI Features

### 🎨 Design Elements
- **Large, readable fonts** optimized for Apple Watch
- **Color-coded metrics** (red for heart rate, blue for distance, etc.)
- **Prominent control buttons** with clear iconography
- **Card-based layout** for easy scanning of information
- **Consistent spacing** and Apple Watch design guidelines

### 📱 Navigation
- **Tab-based workout view** for easy switching between metrics and settings
- **Modal setup screen** for workout configuration
- **Alert dialogs** for important actions like ending workout
- **Swipe gestures** supported for tab navigation

### ⚡ Real-time Updates
- **1-second timer updates** for duration display
- **Live heart rate** with visual prominence
- **Progressive metrics** showing continuous calculation updates
- **Smooth transitions** between paused and active states

### 🎯 Accessibility
- **High contrast colors** for outdoor visibility
- **Large touch targets** for easy interaction during exercise
- **Clear hierarchy** with appropriate font weights and sizes
- **Descriptive button labels** for screen readers

This UI design prioritizes:
1. **Quick glanceability** during workouts
2. **Easy one-handed operation** 
3. **Clear workout status indication**
4. **Prominent safety controls** (pause/stop)
5. **Logical information grouping**