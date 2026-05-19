# DriveAgentiOS

DriveAgentiOS is a powerful, privacy-focused driving assistant built with SwiftUI. It provides real-time speed tracking, advanced speed camera alerts, and safety features designed to enhance your driving experience while keeping your data secure on your device.

## 🚀 Core Features

### 1. Advanced Speedometers
*   **Dual Display Modes:** Switch between a modern **Digital Speedometer** and a precision-engineered **Analog Speedometer**.
*   **Acceleration-Responsive UI:** The analog speedometer changes color based on your driving state—blue for accelerating, green for decelerating, teal for steady speed, and gray when stopped.
*   **Unit Flexibility:** Support for both Metric (km/h) and Imperial (mph) units.

### 2. Intelligent Speed Camera Detection
*   **Global Data Support:** Supports multiple data formats, including GeoJSON for Taiwan and JSON for the US.
*   **Smart Filtering:** Uses direction-aware logic and street name matching to minimize false alerts from cameras on opposite roads or nearby streets.
*   **ASE Zone Monitoring:** Specifically detects Average Speed Enforcement (ASE) zones, providing distance-to-entry and speed limit reminders.
*   **Infinite Proximity Mode:** An optional "Always-On" detection mode that ignores standard distance limits.

### 3. Multi-Sensory Safety Alerts
*   **Visual Alerts:** Dynamic "Liquid Glass" UI effects and ambient red glows that pulse when exceeding speed limits.
*   **Custom Audio:** Features the "Navigation Pop" custom alert sound, designed for high-clarity and minimal driver distraction.
*   **Adaptive Intervals:** Alert frequency automatically increases (from 4s to 2s) during severe speeding (10+ units over).
*   **Haptic Feedback:** Precision vibrations synchronized with audio alerts.
*   **Voice Announcements:** Localized voice alerts in 16 languages that announce distance to cameras and speed limits.

### 4. Distraction Detection
*   **TrueDepth ARKit Integration:** Uses Apple's TrueDepth API to monitor driver attention.
*   **Real-Time Warnings:** Provides an immediate visual overlay if the driver looks at the screen for too long while driving at high speeds.
*   **Privacy-First:** All face tracking data is processed in real-time on-device; no facial images are ever stored or transmitted.

## 🎨 UI/UX & Customization

*   **Glassmorphism Design:** A modern aesthetic featuring ultra-thin materials and glass-like button overlays.
*   **Horizontal Dashboard:** A dedicated landscape view for professional mounting, maximizing screen real estate for speed and trip statistics.
*   **Picture-in-Picture (PiP):** A custom HUD that continues to display speed and camera alerts in a floating window when the app is in the background.
*   **Theme Engine:** Support for System, Light, and Dark modes with customizable "Analog Dash" color schemes (Black/White).
*   **Integrated Media Controls:** Control your music (Spotify, Apple Music) directly from the dashboard without switching apps.
*   **System Monitoring:** Real-time display of battery level, network status, and current street name.

## 🌍 Localization

Fully localized in **16 languages**:
English, Traditional Chinese, Simplified Chinese, Japanese, Korean, Vietnamese, Thai, Filipino, Hindi, Arabic, Spanish, German, French, Italian, Portuguese, and Russian.

## 🛠 Technical Details

*   **Architecture:** Built 100% with **SwiftUI** and **Combine**.
*   **Frameworks:** MapKit, CoreLocation, ARKit, AVFoundation, WidgetKit.
*   **Background Processing:** Utilizes `UIBackgroundModes` for continuous location updates and Live Activities.
*   **Privacy-First Design:** Local-first architecture ensures that sensitive GPS and face-tracking data never leave the device.

## 📦 Getting Started

### Prerequisites
*   macOS with Xcode 15+ installed.
*   A physical iOS device (TrueDepth API features require a physical device).

### Build Instructions
To build the project without code signing:
```bash
xcodebuild -project DriveAgentiOS.xcodeproj -scheme DriveAgentiOS build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
```

### Manual Asset Setup
The custom alert sound must be manually associated with the target in Xcode:
1. Open `DriveAgentiOS.xcodeproj` in Xcode.
2. Add `DriveAgentiOS/navigation_pop.mp3` to the project.
3. Ensure the "DriveAgentiOS" target membership is checked for the file.

---

## 🔒 Privacy Policy

**Last Updated: October 26, 2023**

DriveAgentiOS ("we", "us", or "our") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, and safeguard your information when you use our mobile application.

### 1. Information We Collect

#### 1.1 Location Data
DriveAgentiOS requires access to your device's location to provide its core features, including:
- Real-time speed tracking and speedometer display.
- Displaying your current position on the map.
- Detecting nearby speed cameras and providing proximity alerts.
- Calculating trip statistics such as distance and maximum speed.

We may request "Always" location permissions to provide background updates, enabling Live Activities and background speed camera alerts while the app is not in the foreground.

#### 1.2 Face Tracking Data (ARKit)
The "Distraction Alert" feature uses Apple's ARKit and the **TrueDepth API** technology to detect if you are looking at the screen while driving at high speeds. **This data is processed entirely on your device in real-time.** We do not capture, store, or transmit any facial images or biometric data to any external servers.

#### 1.3 Device and System Information
We monitor basic system information to enhance the user interface, including:
- Battery level and charging status.
- Network connectivity status (WiFi, Cellular, or No Connection).

### 2. Use of Your Information
All information collected is used solely to provide and improve the functionality of DriveAgentiOS. Specifically:
- Location data is used to calculate speed and provide navigation-related alerts.
- Reverse geocoding is used to display the name of the street you are currently on.
- Trip statistics (distance, max speed) are stored locally on your device for your personal reference.

### 3. Data Sharing and Disclosure
**We do not sell, trade, or otherwise transfer your personal data to third parties.**

The app interacts with the following services:
- **Apple Maps/MapKit:** Location data is shared with Apple's MapKit service to render the map and perform reverse geocoding. This is subject to Apple's Privacy Policy.

### 4. Data Retention
DriveAgentiOS is designed with a "privacy-first" approach. Most data is transient and processed in real-time. Trip statistics and user settings are stored locally on your device and are deleted if the application is uninstalled.

### 5. User Rights and Choices
You have full control over the data shared with DriveAgentiOS:
- You can enable or disable location services in your device settings at any time.
- You can enable or disable the Distraction Alert (Camera/ARKit) feature within the app's settings.
- You can reset your trip statistics within the app.

### 6. Security
We implement a variety of security measures to maintain the safety of your information. Since the majority of your data stays on your device, the security of your data is also protected by your device's own security features.

### 7. Changes to This Privacy Policy
We may update our Privacy Policy from time to time. Any changes will be reflected by the "Last Updated" date at the top of this page.

### 8. Contact Us
If you have any questions or suggestions about our Privacy Policy, do not hesitate to contact us at chengyangli3041@gmail.com.

---
&copy; 2026 Cheng Yang Li. All rights reserved.
