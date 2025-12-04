# UI Fix: Mutually Exclusive Map and Speed Trap List

## Issue
The map view and speed trap list were stacking on top of each other when both were opened, creating a weird display.

## Solution
Made the map view and speed trap list **mutually exclusive** - only one can be shown at a time.

## Changes Made

### 1. **Changed Layout Structure**
```swift
// Before: Both could be shown simultaneously
if isMapVisible {
    // Map view
}

if showingSpeedTrapList {
    // Speed trap list
}

// After: Only one can be shown at a time
if isMapVisible {
    // Map view
} else if showingSpeedTrapList {
    // Speed trap list
}
```

### 2. **Updated Button Actions**
```swift
// Speed trap list button - now closes map first
Button {
    withAnimation(.spring()) {
        isMapVisible = false  // Close map if open
        showingSpeedTrapList = true
    }
}

// Map button - now closes speed trap list first
Button {
    withAnimation(.spring()) {
        showingSpeedTrapList = false  // Close speed trap list if open
        isMapVisible.toggle()
    }
}
```

## Behavior

### Before Fix
- ❌ Clicking map button → Map appears
- ❌ Clicking speed trap button → Speed trap list appears **on top of map**
- ❌ Both views stacked, creating weird display
- ❌ Had to close both manually

### After Fix
- ✅ Clicking map button → Map appears, speed trap list closes (if open)
- ✅ Clicking speed trap button → Speed trap list appears, map closes (if open)
- ✅ Only one overlay shown at a time
- ✅ Clean, non-overlapping display
- ✅ Smooth transitions between views

## User Experience

1. **Opening Map**:
   - If speed trap list is open, it closes automatically
   - Map opens with smooth animation
   - Toggle map button to close

2. **Opening Speed Trap List**:
   - If map is open, it closes automatically
   - Speed trap list opens with smooth animation
   - Use close button or tap outside to dismiss

3. **Switching Between Views**:
   - Direct switching with smooth transitions
   - No stacking or overlap
   - Clean, professional appearance

## Technical Details

### File Modified
- `ContentView.swift`

### Changes
1. Combined map and speed trap list into `if-else` structure (line ~423)
2. Added `isMapVisible = false` to speed trap button action (line ~463)
3. Added `showingSpeedTrapList = false` to map button action (line ~471)

### Lines Changed
- **Layout structure**: Changed from separate `if` statements to `if-else`
- **Button actions**: Added 2 lines to close the other view

## Testing

- [x] Open map → verify it appears
- [x] Open speed trap list while map is open → verify map closes
- [x] Open map while speed trap list is open → verify list closes
- [x] Toggle map button → verify it opens/closes correctly
- [x] Verify smooth animations
- [x] Verify no stacking or overlap

## Benefits

1. **Cleaner UI**: No more stacked overlays
2. **Better UX**: Intuitive behavior - one overlay at a time
3. **Professional**: Smooth transitions between views
4. **Simpler Logic**: Clear mutual exclusivity
5. **No Confusion**: Users always know which view is active
