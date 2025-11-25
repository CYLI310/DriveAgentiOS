# DriveAgentiOS

DriveAgentiOS is a powerful and intuitive SwiftUI application designed to enhance your driving experience. It provides real-time speed and location tracking, a sleek "liquid glass" user interface, and customizable widgets to keep you informed on the go.

## Features

- **Real-Time Speed and Location Tracking:** Get accurate, up-to-the-second information on your speed and GPS coordinates.
- **Interactive Map View:** Visualize your current location on a dynamic map with smooth animations and user-friendly controls.
- **"Liquid Glass" UI:** A stunning, modern interface with translucent elements and fluid animations that create a unique "liquid glass" effect.
- **Dynamic Particle Effects:** A visually stunning particle effect that responds to your acceleration and deceleration.
- **System Information Display:** Keep an eye on your device's battery level and network status directly within the app.
- **Live Activities:** Keep track of your trip's progress with Live Activities on your lock screen and Dynamic Island.
- **Customizable Widgets:** Add widgets to your home screen to get quick access to your speed and other driving data.
- **Customizable App Themes:** Choose between light, dark, and system-default themes to personalize your experience.
- **Selectable Units:** Switch between metric and imperial units for speed and distance.
- **Trip Information and Management:** View your current trip's distance and max speed, with the ability to reset at any time.
- **Configurable Alert Proximity:** Set the distance for upcoming alerts to suit your preferences.
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
- **WidgetKit:** For creating the home screen widgets.

## Known Issues

- **Xcode Build Cache:** The project may fail to build on the first attempt due to a stale Xcode cache. If you encounter a build error related to a duplicate `SpeedActivityAttributes` struct, please try cleaning the build folder (`Cmd+Shift+K`) and rebuilding the project.
- **`CLGeocoder` Deprecation:** The `CLGeocoder` class is deprecated in iOS 16.0. The app currently uses this deprecated API and will be updated in a future release.

## Contributing

We welcome contributions from the community! If you'd like to contribute to DriveAgentiOS, please follow these steps:

1. **Fork the repository.**
2. **Create a new branch for your feature or bug fix.**
3. **Make your changes and commit them with a descriptive message.**
4. **Push your changes to your forked repository.**
5. **Open a pull request with a detailed description of your changes.**

## License

DriveAgentiOS is licensed under the MIT License. See the `LICENSE` file for more information.
