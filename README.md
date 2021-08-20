# Infini-iOS - an InfiniTime Companion App for iOS

This is an alpha-verging-on-beta iOS application that allows you to interact with your PineTime running (at least) InfiniTime 1.3.0 (and perhaps other watches/OSes, pending testing).

### What works:
- Scan nearby devices and allow the user to select an InfiniTime device to connect to
- Connect to a PineTime running InfiniTime 1.3.0
- Set time and date immediately after connection
- Read heart rate, and subscribe to HRM's notifier for updated values
- Read battery level, and subscribe to battery level's notifier for updated values
- Display heart rate, battery level, and connection/bluetooth/scanning status to app main page
- Music controls on InfiniTime can control Apple Music. I can't access system-level music controls or system volume from within an app, so the controls literally only work on Apple Music.
- DFU - updates to InfiniTime, bootloader, and recovery firmware have all been successful in testing
- Limited user-configurable settings. I'm counting on testers to let me know what other things should be optional preferences!

### What doesn't work:
- Navigation app.
- Music controls for anything other than Apple Music -- This requires Apple Music Service (AMS) to be implemented in InfiniTime. Once I feel like Infini-iOS has reached a semi-stable state, I'll try to help implement this service!
- Phone notifications pushing to watch -- This requires a proprietary Apple service that behaves in more or less the exact same way as the notification service already implemented in InfiniTime, but this one has Apple in the name... as with AMS, I'll work on getting this implemented in Infini-iOS once I feel like the app is stable enough to leave alone for a while

### How to try it out:
- Snag this repo and open it in XCode on a Mac
- Plug an iPhone into your computer and select it as the build target in XCode
- Make sure you're signed into your appleID in XCode and that you've done whatever it wants you to do to flag yourself as a code signer
- Change the code signing information in the Infini-iOS properties:
  - Click the main project in the files sidebar
  - Navigate to the 'Signing and Capabilities' tab
  - Change the 'Team' pulldown to reflect your appleID that you used to sign into XCode
  - Change the Bundle Identifier to match your team
- Build and run!

### Disclaimer
**This is the first time I've worked with Swift, SwiftUI, XCode, BLE, or anything else in this application. I take no responsibility for what happens if you interact with this repository in any way. If it breaks your phone, your watch, or your brain,** ***that's on you buddy!***
