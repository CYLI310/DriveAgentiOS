# Audio & Haptic Feedback System

## Overview
The AlertFeedbackManager provides multi-sensory alerts when the user exceeds speed limits near speed cameras.

## Components

### AlertFeedbackManager
Location: `/DriveAgentiOS/AlertFeedbackManager.swift`

**Purpose**: Manages repeating audio chimes and haptic feedback for speeding alerts

**Key Features**:
- ✅ Soft, non-intrusive chime sound
- ✅ Gentle haptic warning vibration
- ✅ Repeats every 2 seconds while speeding
- ✅ Automatically stops when user slows down
- ✅ Mixes with other audio (won't pause music)
- ✅ Proper cleanup and lifecycle management

## Audio System

### Sound Selection
- **System Sound ID**: 1013 (soft chime)
- **Type**: System sound (no file bundling required)
- **Duration**: ~0.5 seconds
- **Volume**: Controlled by system volume

### Audio Session Configuration
```swift
AVAudioSession.sharedInstance()
    .setCategory(.playback, mode: .default, options: [.mixWithOthers])
```

**Why `.mixWithOthers`?**
- Allows the chime to play alongside user's music/podcasts
- Non-intrusive - won't interrupt other audio
- Better user experience during navigation

### Alternative System Sounds
If you want to change the chime sound, here are some alternatives:

| Sound ID | Description |
|----------|-------------|
| 1013 | Soft chime (current) |
| 1003 | SMS received tone |
| 1015 | SMS received 2 |
| 1016 | SMS received 3 |
| 1057 | Anticipate |
| 1073 | Bloom |
| 1103 | Chord |

To change: Edit line in `AlertFeedbackManager.swift`:
```swift
AudioServicesPlaySystemSound(1013) // Change this number
```

## Haptic System

### Haptic Type
- **Generator**: `UINotificationFeedbackGenerator`
- **Style**: `.warning`
- **Intensity**: System-controlled (medium)

### Why `.warning`?
- Appropriate urgency level for speed alerts
- Not too strong (like `.error`)
- Not too weak (like `.success`)
- Universally recognized as cautionary

### Alternative Haptic Styles
```swift
.success  // Light, positive feedback
.warning  // Medium, cautionary (current)
.error    // Strong, urgent feedback
```

## Timing & Repetition

### Current Settings
- **Initial Trigger**: Immediate when speeding detected
- **Repeat Interval**: 2.0 seconds
- **Synchronization**: Audio and haptic fire together

### Why 2 Seconds?
- Frequent enough to maintain awareness
- Not so frequent as to be annoying
- Allows user time to react between alerts
- Balances safety with user experience

### Customizing Interval
To change the repeat interval, edit `AlertFeedbackManager.swift`:
```swift
Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) // Change 2.0
```

Recommended range: 1.5 - 3.0 seconds

## Lifecycle Management

### When Alerts Start
1. User speed exceeds speed limit
2. Speed camera is within range (or infinite mode enabled)
3. `speedTrapDetector.isSpeeding` becomes `true`
4. `alertFeedbackManager.startSpeedingAlert()` called
5. Initial chime + haptic fires immediately
6. Timer starts for repeating alerts

### When Alerts Stop
1. User slows below speed limit, OR
2. Moves out of camera range (if not in infinite mode), OR
3. App goes to background
4. `alertFeedbackManager.stopSpeedingAlert()` called
5. Timer invalidated
6. Audio stops
7. No more haptics

### Background/Foreground Behavior
- **Background**: Alerts stop to prevent unwanted sounds
- **Foreground**: Alerts resume if still speeding
- **Reason**: Better battery life and user experience

## Testing

### How to Test Audio
1. Build and run app on physical device (simulator has limited audio)
2. Enable a speed camera alert
3. Drive or simulate speed above limit
4. Listen for soft chime every 2 seconds
5. Verify it doesn't interrupt music if playing

### How to Test Haptics
1. Must use physical device (simulator doesn't support haptics)
2. Enable a speed camera alert
3. Drive or simulate speed above limit
4. Feel for gentle vibration every 2 seconds
5. Verify it syncs with audio chime

### Debugging
Enable debug prints by adding to `AlertFeedbackManager`:
```swift
private func playChime() {
    print("🔔 Playing chime at \(Date())")
    AudioServicesPlaySystemSound(1013)
}

private func triggerHaptic() {
    print("📳 Triggering haptic at \(Date())")
    hapticGenerator.notificationOccurred(.warning)
    hapticGenerator.prepare()
}
```

## Troubleshooting

### No Sound Playing
- Check device is not in silent mode
- Verify volume is up
- Ensure audio session is configured (check console for errors)
- Test on physical device (simulator may have issues)

### No Haptic Feedback
- Must use physical device
- Check Settings > Sounds & Haptics > System Haptics is enabled
- Verify device supports haptics (iPhone 7 and later)

### Alerts Not Stopping
- Check `stopSpeedingAlert()` is being called
- Verify timer is being invalidated
- Look for memory leaks (timer should be weak self)

### Alerts Not Repeating
- Verify timer is created with `repeats: true`
- Check timer isn't being invalidated prematurely
- Ensure `isPlayingAlert` flag is set correctly

## Performance Impact

### CPU Usage
- Minimal: Timer runs on main thread but only fires every 2s
- System sounds are hardware-accelerated
- Haptics are system-managed

### Battery Impact
- Low: System sounds are efficient
- Haptics use minimal power
- Timer overhead is negligible

### Memory Usage
- ~1KB for manager instance
- No audio file loading (uses system sounds)
- Haptic generator pre-allocated

## Future Enhancements

### Possible Improvements
1. **Customizable Sounds**: Allow user to select from different chimes
2. **Volume Control**: Separate volume slider for alerts
3. **Haptic Patterns**: Custom vibration patterns
4. **Escalating Alerts**: Increase frequency if speeding persists
5. **Voice Alerts**: Spoken warnings ("Slow down")
6. **Settings Toggle**: Option to disable audio/haptic separately

### Implementation Ideas
```swift
// User preferences
@Published var alertSoundEnabled: Bool = true
@Published var alertHapticEnabled: Bool = true
@Published var alertInterval: Double = 2.0
@Published var selectedSoundID: UInt32 = 1013

// In startSpeedingAlert()
if alertSoundEnabled {
    playChime()
}
if alertHapticEnabled {
    triggerHaptic()
}
```

## Best Practices

### Do's ✅
- Keep alerts gentle and non-intrusive
- Sync audio and haptic for coherent feedback
- Stop alerts when app backgrounds
- Clean up timers properly
- Use system sounds for consistency

### Don'ts ❌
- Don't use jarring or loud sounds
- Don't repeat too frequently (< 1 second)
- Don't interrupt user's music
- Don't forget to stop alerts
- Don't use custom audio files unnecessarily

## Summary

The audio and haptic feedback system provides a sophisticated, multi-sensory alert that:
- Enhances safety by reminding users to slow down
- Maintains premium user experience
- Integrates seamlessly with existing features
- Respects user's audio environment
- Performs efficiently with minimal resource usage

The 2-second repeating soft chime with synchronized haptic creates an effective yet pleasant reminder system that encourages safe driving without being annoying.
