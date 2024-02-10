# InfiniLink - The official iOS companion app for InfiniTime

This iOS application allows you to interact with your PineTime smartwatch running [InfiniTime](https://github.com/InfiniTimeOrg/InfiniTime) (and perhaps other watches/OSes, pending testing).

### Features:
- Discover and connect to nearby InfiniTime devices
- Set time and date immediately after connection
- Retrieve battery level, heart rate, and step data
- Chart persistence, with filters for the last hour, day, and week
- Control Apple Music with InfiniTime's music controls
- Integration with Apple HealthKit
- Weather fetch (using the [NWS API](https://www.weather.gov/documentation/services-web-api) and a secondary fallback on [WeatherAPI](https://www.weatherapi.com)) and push (using InfiniTime 1.14's [Simple Weather Service](https://github.com/InfiniTimeOrg/InfiniTime/blob/main/doc/SimpleWeatherService.md))
- Uploading of [external resource packages](https://github.com/InfiniTimeOrg/InfiniTime/blob/develop/doc/gettingStarted/updating-software.md#updating-resources)
- Check for and download InfiniTime firmware updates with the GitHub API, and send them to the watch (Manual updates can be completed with DFU zip files downloaded from [InfiniTime's GitHub Releases Page](https://github.com/JF002/InfiniTime/releases))
  
### Currently non-functional features:
- InfiniTime's navigation app. There is currently no API in Swift to access current directions, so this will likely never work unless it's added into a mapping application.
- Phone notifications and system-wide music controls - Requires implementation of Apple Media Service (AMS) and Apple Notification Center Service (ANCS) in InfiniTime.

### Installation:
InfiniLink is now accessible on the [App Store](https://apps.apple.com/us/app/infinilink/id1582318814)!
