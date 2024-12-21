<br>

<div align="center">
  
[![Build & Analyze](https://github.com/InfiniTimeOrg/InfiniLink/actions/workflows/objective-c-xcode.yml/badge.svg)](https://github.com/InfiniTimeOrg/InfiniLink/actions/workflows/objective-c-xcode.yml)
[![Platforms](https://img.shields.io/badge/platforms-iOS-333333.svg)](https://github.com/InfiniTimeOrg/InfiniLink)
[![GitHub tag](https://img.shields.io/github/tag/InfiniTimeOrg/InfiniLink?include_prereleases=&sort=semver&color=blue)](https://github.com/InfiniTimeOrg/InfiniLink/releases)
[![License](https://img.shields.io/badge/License-MIT-blue)](https://github.com/InfiniTimeOrg/InfiniLink/blob/main/LICENSE)
[![Issues - InfiniLink](https://img.shields.io/github/issues/InfiniTimeOrg/InfiniLink)](https://github.com/InfiniTimeOrg/InfiniLink/issues)
[![Pull Requests - InfiniLink](https://img.shields.io/github/issues-pr/InfiniTimeOrg/InfiniLink)](https://github.com/InfiniTimeOrg/InfiniLink/pulls)
[![Stars - InfiniLink](https://img.shields.io/github/stars/InfiniTimeOrg/InfiniLink?style=social)](https://github.com/InfiniTimeOrg/InfiniLink/stargazers)
[![Forks - InfiniLink](https://img.shields.io/github/forks/InfiniTimeOrg/InfiniLink?style=social)](https://github.com/InfiniTimeOrg/InfiniLink/network/members)

<br>

<img src="InfiniLink/Assets.xcassets/AppIcon-3.appiconset/icon_1024.png" width="115" height="115">

# InfiniLink - The official iOS companion app for InfiniTime

This iOS application allows you to interact with your PineTime smartwatch running [InfiniTime](https://github.com/InfiniTimeOrg/InfiniTime) (and perhaps other watches/OSes, pending testing).

</div>

### Features:
- Discover and connect to nearby InfiniTime devices
- Set time and date immediately after connection
- Retrieve battery level, heart rate, and step data
- Chart persistence, with filters for the last hour, day, and week
- Control Apple Music with InfiniTime's music controls
- Integration with Apple HealthKit
- Weather fetch (using the [NWS API](https://www.weather.gov/documentation/services-web-api) and a secondary fallback on [WeatherAPI](https://www.weatherapi.com)) and push (using InfiniTime 1.14's [Simple Weather Service](https://github.com/InfiniTimeOrg/InfiniTime/blob/main/doc/SimpleWeatherService.md))
- Uploading of [external resource packages](https://github.com/InfiniTimeOrg/InfiniTime/blob/develop/doc/gettingStarted/updating-software.md#updating-resources)
- Check for and download InfiniTime firmware updates with the GitHub API, and send them to the watch (Manual updates can be completed with DFU zip files downloaded from [InfiniTime's GitHub Releases Page](https://github.com/InfiniTimeOrg/InfiniTime/releases))
  
### Currently non-functional features:
- InfiniTime's navigation app. There is currently no API in Swift to access current directions unless the route is started from inside the app, which may not be practical for most users.
- Phone notifications and system-wide music controls - Requires implementation of Apple Media Service (AMS) and Apple Notification Center Service (ANCS) in InfiniTime.

### Installation:
- **Version 1.0.2:** is accessible on the [App Store](https://apps.apple.com/us/app/infinilink/id1582318814).

## License
Released under [GPL-3.0](/LICENSE) by [@InfiniTimeOrg](https://github.com/InfiniTimeOrg).
