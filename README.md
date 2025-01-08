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
- Control Apple Music with InfiniTime's music controls
- Integration with Apple HealthKit
- Weather fetch (using WeatherKit) and push (using InfiniTime 1.14's [Simple Weather Service](https://github.com/InfiniTimeOrg/InfiniTime/blob/main/doc/SimpleWeatherService.md))
- Uploading of [external resource packages](https://github.com/InfiniTimeOrg/InfiniTime/blob/develop/doc/gettingStarted/updating-software.md#updating-resources)
- Check for and download InfiniTime firmware updates with the GitHub API, and send them to the watch (Manual updates can be completed with DFU zip files downloaded from [InfiniTime's GitHub Releases Page](https://github.com/InfiniTimeOrg/InfiniTime/releases))

### Partially implemented features:
- System-wide notifications—implemented in [#2217](https://github.com/InfiniTimeOrg/InfiniTime/pull/2217), but not available in the main branch yet.

### Currently non-functional features:
- InfiniTime's navigation app—there is currently no API in Swift to access current directions unless the route is started from inside the app, which may not be practical for most users.
- System-wide music controls—requires implementation of Apple Media Service (AMS).

## Installation:
- **Version 1.0.2:** is accessible on the [App Store](https://apps.apple.com/us/app/infinilink/id1582318814).
- **Version 1.1-beta:** is accessible on [TestFlight](https://testflight.apple.com/join/B3PY5HUV).

## License
Released under [GPL-3.0](/LICENSE) by [@InfiniTimeOrg](https://github.com/InfiniTimeOrg).
