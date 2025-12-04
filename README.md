# DriveAgentiOS

DriveAgentiOS is a powerful and intuitive SwiftUI application designed to enhance your driving experience. It provides real-time speed and location tracking, a sleek liquid glass user interface, and customizable widgets to keep you informed on the go.

## Features

- **Real-Time Speed and Location Tracking:** Get accurate, up-to-the-second information on your speed and GPS coordinates.
- **Speed Camera Detection:** View the nearest speed cameras with distance and speed limit information. Infinite proximity mode allows you to always see the closest camera regardless of distance.
- **Multi-Sensory Speed Limit Alerts:** When exceeding the speed limit near a camera, receive:
  - **Visual Feedback:** Red blinking particle effects and glowing border
  - **Audio Feedback:** Navigation Pop alert sound with adaptive intervals (4s normal, 2s severe)
  - **Haptic Feedback:** Gentle warning vibrations synchronized with audio
- **Interactive Map View:** Visualize your current location on a dynamic map with smooth animations and user-friendly controls.
- **Customizable Particle Effects:** Choose from multiple stunning visual effects including Orbit and Gradient styles, or turn them off entirely.
- **Distraction Detection:** Optional face-tracking feature that warns you if you look at the screen while driving fast (on supported devices).
- **Dynamic Island & Live Activities:** Keep track of your trip's progress with Live Activities on your lock screen and Dynamic Island.
- **Customizable Widgets:** Add widgets to your home screen to get quick access to your speed and other driving data.
- **Multi-Language Support:** Full support for 16 languages including English, Chinese (Traditional & Simplified), Korean, Japanese, Vietnamese, Thai, Filipino, Hindi, Arabic, Spanish, German, French, Italian, Portuguese, and Russian.
- **Theme Customization:** Choose between System, Light, or Dark themes to match your preference.
- **Trip Statistics:** Track your trip distance and maximum speed with easy reset functionality.
- **Permissions Handling:** A user-friendly permissions system that guides users to enable location services when necessary.

## Widgets

DriveAgentiOS comes with two powerful widgets:

- **SpeedWidget:** A compact widget that displays your current speed in a clear, easy-to-read format.
- **Widget:** A versatile widget that can be customized to show various driving-related data.

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
3. **Build and run the app:**
   - Select your target device from the Xcode toolbar.
   - Click the "Run" button or press `Cmd+R`.

## Dependencies

DriveAgentiOS is built with SwiftUI and relies on the following Apple frameworks:

- **CoreLocation:** For accessing GPS data and tracking the user's location.
- **MapKit:** For displaying the interactive map view.
- **Combine:** For handling asynchronous events and data streams.
- **WidgetKit:** For creating the home screen widgets and Live Activities.
- **AVFoundation:** For playing alert sounds and audio feedback.
- **ARKit:** For face tracking and distraction detection (on supported devices).
- **UIKit:** For haptic feedback and system integrations.

## Contributing

We welcome contributions from the community! If you'd like to contribute to DriveAgentiOS, please follow these steps:

1. **Fork the repository.**
2. **Create a new branch for your feature or bug fix.**
3. **Make your changes and commit them with a descriptive message.**
4. **Push your changes to your forked repository.**
5. **Open a pull request with a detailed description of your changes.**

## License

DriveAgentiOS is licensed under the MIT License. See the `LICENSE` file for more information.
