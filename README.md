# Infini-iOS - an InfiniTime Companion App for iOS

This is a proof-of-concept, barely-functional iOS application to interact with your PineTime running (at least) InfiniTime 1.3.0 (and maybe more, I haven't tested it against other watches or OSes).

### What works:
- Scan nearby devices and allow the user to select a device to connect to 
  - so far this is card coded to be a device named 'InfiniTime' because I don't have anything else to test it against and I don't want to fat-finger the wrong device and have it break
- Connect to a PineTime running InfiniTime 1.3.0
- Set time and date immediately after connection
- Read heart rate, and subscribe to HRM's notifier for updated values
- Read battery level, and subscribe to battery level's notifier for updated values
- Display heart rate, battery level, and connection/bluetooth/scanning status to app main page

### What sort of works but mostly just sucks:
- The UI: It's just a proof of concept so far, so I put as little effort as possible into the UI.
- Notifications: I can send a test notification to the PineTime, but can't send phone notifications to the watch yet.
- Music controls: I have subscribed to the InfiniTime music app notifier, but so far have only implemented printing music control button presses to console. They do print though, so it should be doable if I can access the phone's music controls somehow!

### What's next:
- Figure out how to send phone notifications to watch
- Figure out how to control music from watch
- Optional auto-connect: save some device-specific characteristic (MAC address? Serial number?) to the app, and allow users to automatically connect to their device. I know I probably won't want to connect to anything other than my own pinetime with very few exceptions, so it'd save me a few taps if it just snagged my watch automatically when I open the app.
- Learn anything whatsoever about making an app design in SwiftUI that isn't a horrific clusterwhoops 
- Send notifications to the phone, probably. Might be nice to get a buzz on your phone if the watch disconnects for some reason
- User-configurable settings:
  - select device for autoconnect
  - enable/disable notifications
  - taking suggestions
- Clean everything up. Still tons of commented lines and code blocks from debugging and trial and error stuff that I should really remove. Probably should add a few more explanatory comments here and there too, mostly for my own benefit...
- I mean, there's the navigation thing? I guess poke at that. I'm not super sure that's a priority for me at all, but if that's something that people want I can definitely look into it sooner.

### How to try it out
- Snag this repo and open it in XCode on a Mac
- Plug an iPhone into your computer and select it as the build target in XCode
- Make sure you're signed into your appleID in XCode and that you've done whatever it wants you to do to flag yourself as a code signer
- Change the code signing information in the Infini-iOS properties:
  - Click the main project in the files sidebar
  - Navigate to the 'Signing and Capabilities' tab
  - Change the 'Team' pulldown to reflect your appleID that you used to sign into XCode
- Build and run!

### Disclaimers
**This is the first time I've worked with Swift, SwiftUI, XCode, BLE, or anything else in this application. I take no responsibility for what happens if you interact with this repository in any way. If it breaks your phone or your watch or your brain,** ***that's on you buddy!***
