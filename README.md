# InfiniLink - an InfiniTime Companion App for iOS

This iOS application allows you to interact with your PineTime smartwatch running [InfiniTime](https://github.com/JF002/InfiniTime) (and perhaps other watches/OSes, pending testing).

### What works:
- Scan nearby devices and connect to PineTimes
- Set time and date immediately after connection
- Read and chart battery level data and heart rate data from watch
- Chart persistence, with filters for last hour, last day, and last week
- Music controls on InfiniTime can control Apple Music.
- Step counter with current step count, weekly chart, and monthly calendar
- Check for updates to InfiniTime using the GitHub API, download them directly with the app, and send them to the PineTime. 
    - Manual updates can be completed with DFU zip files downloaded from [InfiniTime's GitHub Releases Page](https://github.com/JF002/InfiniTime/releases)

### What doesn't work:
- InfiniTime's navigation app. As far as I can tell, there is no API in Swift to access current directions, so this will likely never work unless it's added into a mapping application.
- Music controls for anything other than Apple Music -- This requires Apple Music Service (AMS) to be implemented in InfiniTime.
- Phone notifications pushing to watch -- This requires a proprietary Apple service as well.

### How to try it out:
Join the TestFlight beta now! Click this link from your iOS device: https://testflight.apple.com/join/Z7u1Jxp4
