# DriveAgentiOS

DriveAgentiOS is a powerful and intuitive SwiftUI application designed to enhance your driving experience. It provides real-time speed and location tracking, a sleek liquid glass (glassmorphism) user interface, and intelligent safety alerts to keep you informed and safe on the road.

## Features

### Core Driving Tools
- **Analog & Digital Speedometers:** Choose between a classic high-precision analog gauge or a clean digital display to monitor your current speed.
- **Horizontal Dashboard:** Automatically switches to a wide-screen dashboard layout when in landscape mode, placing speed, trip stats, and map controls side-by-side for optimal viewing.
- **Real-Time Tracking:** Accurate, up-to-the-second speed and GPS coordinate tracking.
- **Interactive Map View:** Integrated dynamic map with smooth animations and one-touch centering.
- **Acceleration-Responsive UI:** The interface dynamically changes colors based on your driving behavior—accelerating (blue), decelerating (green), steady (teal), or stopped (gray).

### Intelligent Safety & Alerts
- **Global Speed Camera Detection:** Built-in support for regional speed trap data (currently featuring Taiwan and USA) with intelligent matching based on road name and driving direction.
- **Smart Proximity Alerts:**
  - **Infinite Proximity Mode:** Always shows the absolute closest camera regardless of distance.
  - **Standard Mode:** Focused alerts for cameras within a 2km range.
- **Multi-Sensory Speed Warnings:** Receive immediate feedback when exceeding the limit near a camera:
  - **Visual:** Red pulsing "breathing" alerts, ambient screen glows, and blinking particle effects.
  - **Audio:** High-quality "Navigation Pop" alert sound with adaptive intervals (4s for standard speeding, 2s for severe speeding >10 units over).
  - **Haptic:** Synchronized physical vibrations for non-intrusive warnings.
- **Distraction Detection:** Advanced ARKit-powered face tracking that warns you if your attention drifts from the road while driving at speed.

### System & Trip Monitoring
- **Glassmorphism Top Bar:** Sleek, translucent overlay showing real-time system status:
  - **Battery Level:** Current percentage and status icon.
  - **Network Status:** Real-time signal strength and connectivity monitoring.
  - **Current Street:** Automatic reverse-geocoding to display the street name you are currently on.
- **Detailed Trip Statistics:** Track total distance, maximum speed, and current coordinates.

### Customization
- **Multi-Language Support:** Fully localized for 16 languages including English, Chinese (Traditional/Simplified), Korean, Japanese, Spanish, German, French, and more.
- **Theme Engine:** Supports System, Light, and Dark modes with custom glass effects.
- **Particle Styles:** Personalize your experience with Orbit, Gradient, or minimal particle effects that respond to your speed.
- **Widgets & Live Activities:** Stay informed even when the app is in the background with Home Screen widgets and Lock Screen Live Activities (Dynamic Island support).

## Technologies Used

DriveAgentiOS is built with modern Apple frameworks:

- **SwiftUI:** For the responsive and fluid "Liquid Glass" user interface.
- **CoreLocation:** For high-precision GPS tracking and geocoding.
- **MapKit:** For the interactive mapping experience.
- **ARKit:** For driver distraction detection via face tracking.
- **AVFoundation:** For the custom Navigation Pop audio alert system.
- **Combine:** For reactive data streams and state management.
- **WidgetKit:** For Home Screen widgets and Live Activities.
- **UIKit:** For specialized haptic feedback and system integrations.

## Getting Started

To get started with DriveAgentiOS, you'll need Xcode 15 or later and a device running iOS 17 or later.

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/DriveAgentiOS.git
   ```
2. **Open the project in Xcode:**
   ```bash
   open DriveAgentiOS/DriveAgentiOS.xcodeproj
   ```
3. **Add the `navigation_pop.mp3` file to the project:**
   - In Xcode's Project Navigator, right-click on the `DriveAgentiOS` folder.
   - Select "Add Files to 'DriveAgentiOS'..."
   - Choose the `navigation_pop.mp3` file, which is located in the `DriveAgentiOS/` directory.
   - Ensure "Copy items if needed" is checked and the "DriveAgentiOS" target is selected.
4. **Build and run the app:**
   - Select your target device from the Xcode toolbar.
   - Click the "Run" button or press `Cmd+R`.

## Project Structure

- `DriveAgentiOS/`: Main application source code.
- `SpeedWidget/`: Source code for the compact speed widget.
- `Widget/`: Source code for the versatile dashboard widget.
- `speedtraps.geojson`: Taiwan-region speed trap data.
- `usspeedtraps.json`: USA-region speed trap data.

## License

DriveAgentiOS is licensed under the MIT License. See the `LICENSE` file for more information.
