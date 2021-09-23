# Infini-iOS - an InfiniTime Companion App for iOS

This iOS application allows you to interact with your PineTime smartwatch running [InfiniTime](https://github.com/JF002/InfiniTime) (and perhaps other watches/OSes, pending testing).

### What works:
- Scan nearby devices and connect to PineTimes
- Set time and date immediately after connection
- Read and chart battery level data and heart rate data from watch
- Music controls on InfiniTime can control Apple Music.
- DFU - send [firmware updates](https://github.com/JF002/InfiniTime/releases) to the PineTime

### What doesn't work:
- InfiniTime's navigation app. As far as I can tell, there is no API in Swift to access current directions, so this will likely never work unless it's added into a mapping application.
- Music controls for anything other than Apple Music -- This requires Apple Music Service (AMS) to be implemented in InfiniTime.
- Phone notifications pushing to watch -- This requires a proprietary Apple service as well.

### How to try it out:
Join the TestFlight beta now! Click this link from your iOS device: https://testflight.apple.com/join/Z7u1Jxp4

### Contributions:
I'm not interested in profiting from this app, but the Apple Developer License was not cheap! If you've enjoyed the app and have some disposable income, consider donating. If not, no problem!

[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://paypal.me/alexemry)
