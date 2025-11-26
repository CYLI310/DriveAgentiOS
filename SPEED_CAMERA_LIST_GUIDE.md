# Speed Camera List Feature - User Guide

## Overview

The Speed Camera List feature allows you to quickly view the **nearest 10 speed cameras** to your current location, complete with distance and speed limit information. This helps you stay aware of upcoming speed enforcement zones.

## How to Use

### Opening the Speed Camera List

1. **Launch the app** and ensure location services are enabled
2. **Tap the camera icon** (📷) button at the bottom left of the screen
3. The speed camera list will appear as a popup overlay

### Understanding the Display

The list shows the 10 nearest speed cameras, sorted by distance from your current location:

#### Each Camera Entry Shows:
- **Rank Badge**: Color-coded position (1st = Red, 2nd = Orange, 3rd = Yellow, 4th-10th = Blue)
- **Camera Icon**: Red camera symbol indicating a speed enforcement point
- **Speed Limit**: The posted speed limit at that camera location (in km/h)
- **Distance**: How far away the camera is from you (in meters or kilometers)
- **Address**: The exact location/street address of the camera

### Reading the Information

**Distance Format:**
- Less than 1 km: Shown in meters (e.g., "250m")
- 1 km or more: Shown in kilometers (e.g., "1.5 km")

**Speed Limit:**
- Displayed in km/h (e.g., "50 km/h", "80 km/h")
- The ".0" decimal is automatically removed for cleaner display

**Color Coding:**
- 🔴 **1st (Red)**: Closest camera - highest priority
- 🟠 **2nd (Orange)**: Second closest
- 🟡 **3rd (Yellow)**: Third closest
- 🔵 **4th-10th (Blue)**: Other nearby cameras

### Closing the List

You can close the speed camera list in two ways:
1. **Tap the X button** in the top-right corner of the popup
2. **Tap anywhere outside** the popup window

## Features

### Real-Time Updates
- The list is generated based on your **current location** when you open it
- As you drive, tap the button again to refresh and see updated distances

### No Range Limit
- Unlike the proximity alert (which only shows cameras within 500m), the list shows the 10 nearest cameras **regardless of distance**
- This helps you plan ahead and be aware of cameras further down the road

### Beautiful UI
- **Liquid Glass Effect**: Translucent background with blur
- **Smooth Animations**: Elegant fade and scale transitions
- **High Contrast**: Easy to read while driving (when parked!)
- **Scrollable**: Swipe to see all 10 cameras if needed

## Tips

### Best Practices
1. **Check before starting your trip** to see what's ahead
2. **Use when parked** - don't interact with the app while driving
3. **Combine with map view** - tap the map button to see your route
4. **Watch for proximity alerts** - the app will automatically warn you when within 500m of a camera

### Understanding the Data
- Camera locations are loaded from the built-in `speedtraps.geojson` database
- The list includes all types of speed enforcement cameras
- Addresses are in the local language (Chinese for Taiwan locations)

## Button Layout

The app has three main buttons at the bottom:

```
[📷 Camera List]  [🗺️ Map]  [⚙️ Settings]
     (Left)       (Center)    (Right)
```

- **Left Button (📷)**: Opens the nearest speed cameras list ← **NEW!**
- **Center Button (🗺️)**: Toggles the map view
- **Right Button (⚙️)**: Opens settings

## Troubleshooting

### "No speed cameras found"
**Possible causes:**
- Location services are disabled
- GPS signal is weak
- You're in an area with no registered cameras

**Solutions:**
- Check that location permissions are set to "Always"
- Move to an area with better GPS reception
- Ensure the speedtraps.geojson file is included in the app

### List is loading forever
**Possible causes:**
- Large database file is being processed
- Device is low on memory

**Solutions:**
- Wait a few seconds for the initial load
- Close other apps to free up memory
- Restart the app if it doesn't load within 10 seconds

### Distances seem wrong
**Possible causes:**
- GPS hasn't locked on to your exact location yet
- You're moving while the list is loading

**Solutions:**
- Wait for GPS to stabilize (usually takes a few seconds)
- Stand still or park when opening the list
- Close and reopen the list to refresh

## Privacy & Data

- **All data is local**: The speed camera database is stored on your device
- **No internet required**: The list works completely offline
- **No tracking**: Your location is only used to calculate distances, not stored or transmitted

## What's Different from Before?

### Previous Behavior
- The left button was a "recenter location" button
- It would center the map on your current position

### New Behavior
- The left button now opens the speed camera list
- The map automatically centers on your location when opened
- This provides more useful information at a glance

## Future Enhancements

Potential improvements in future versions:
- Filter cameras by type (fixed, mobile, red light, etc.)
- Show cameras on the map with markers
- Navigate to a specific camera
- Export list to other navigation apps
- Customize the number of cameras shown (5, 10, 20, etc.)

---

**Enjoy safer, more informed driving with the Speed Camera List feature!** 🚗📷
