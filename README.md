# Infini-iOS - an InfiniTime Companion App for iOS

This is a proof-of-concept, barely-functional iOS application to interact with your PineTime running (at least) InfiniTime 1.3.0 (and maybe more, I haven't tested it against other watches or OSes).

### What works:
- Scan nearby devices and allow the user to select an InfiniTime device to connect to
- Connect to a PineTime running InfiniTime 1.3.0
- Set time and date immediately after connection
- Read heart rate, and subscribe to HRM's notifier for updated values
- Read battery level, and subscribe to battery level's notifier for updated values
- Display heart rate, battery level, and connection/bluetooth/scanning status to app main page
- Music controls on InfiniTime can control Apple Music. I can't access system-level music controls or system volume from within an app, so the controls literally only work on Apple Music.

### What sort of works but mostly just sucks:
- The UI: It's just a proof of concept so far, so I put as little effort as possible into the UI.
- Notifications: I can send a test notification to the PineTime, but can't send phone notifications to the watch yet. Apple requires the ANCS protocol and bonding to be implemented on the peripheral device, so there's some big hills to climb before notifications are functional.

### What's next:
- Learn anything whatsoever about making an app design in SwiftUI that isn't an awful mess 
- Send notifications to the phone, probably. Might be nice to get a buzz on your phone if the watch disconnects for some reason or if the watch battery is running low
- User-configurable settings, like enabling or disabling Apple Music controls, notifications, etc
- Clean everything up. Being my first major foray into larger-scale coding projects, I have not done a great job of compartmentalizing my code, so the BLEManager.swift file is pretty monolithic. 
- Watch navigation app. This is a lower priority to me personally, but I'll definitely give it a shot eventually. Based on how the music control and notifications have gone, I'm guessing there's another proprietary Apple service that will need to be implemented to make this work.

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
