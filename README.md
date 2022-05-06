# InfiniLink - an InfiniTime Companion App for iOS

This is a UI redesign for the InfiniLink app, currently still needs work though.
![IMG_1235](https://user-images.githubusercontent.com/87885710/166810295-43358d55-6eaf-4525-a45b-bf90b5b34965.png)



### Todo List:
- Redesign the heart and battery views.
- Clean up the new UI code.

### What works:
- Scan nearby devices and connect to PineTimes
- Set time and date immediately after connection
- Read and chart battery level data and heart rate data from watch
- Chart persistence, with filters for last hour, last day, and last week
- Music controls on InfiniTime can control Apple Music.
- Step counter with current step count, weekly chart, and monthly calendar
- Check for updates to InfiniTime using the GitHub API, download them directly with the app, and send them to the PineTime. 

### What doesn't work:
- InfiniTime's navigation app. As far as I can tell, there is no API in Swift to access current directions, so this will likely never work unless it's added into a mapping application.
- Music controls for anything other than Apple Music -- This requires Apple Music Service (AMS) to be implemented in InfiniTime.
- Phone notifications pushing to watch -- This requires a proprietary Apple service as well.
