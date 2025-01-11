<div align="center">

<img src="/assets/header.png" width="100%">

<br>
  
[![Build & Analyze](https://github.com/InfiniTimeOrg/InfiniLink/actions/workflows/objective-c-xcode.yml/badge.svg)](https://github.com/InfiniTimeOrg/InfiniLink/actions/workflows/objective-c-xcode.yml)
[![Platforms](https://img.shields.io/badge/platforms-iOS-333333.svg)](https://github.com/InfiniTimeOrg/InfiniLink)
[![GitHub tag](https://img.shields.io/github/tag/InfiniTimeOrg/InfiniLink?include_prereleases=&sort=semver&color=blue)](https://github.com/InfiniTimeOrg/InfiniLink/releases)
[![License](https://img.shields.io/badge/License-MIT-blue)](https://github.com/InfiniTimeOrg/InfiniLink/blob/main/LICENSE)
[![Issues - InfiniLink](https://img.shields.io/github/issues/InfiniTimeOrg/InfiniLink)](https://github.com/InfiniTimeOrg/InfiniLink/issues)
[![Pull Requests - InfiniLink](https://img.shields.io/github/issues-pr/InfiniTimeOrg/InfiniLink)](https://github.com/InfiniTimeOrg/InfiniLink/pulls)
[![Stars - InfiniLink](https://img.shields.io/github/stars/InfiniTimeOrg/InfiniLink?style=social)](https://github.com/InfiniTimeOrg/InfiniLink/stargazers)
[![Forks - InfiniLink](https://img.shields.io/github/forks/InfiniTimeOrg/InfiniLink?style=social)](https://github.com/InfiniTimeOrg/InfiniLink/network/members)

</div>

### Features:
- Discover and connect to nearby InfiniTime devices
- Set time and date immediately after connection
- Retrieve battery level, heart rate, and step data
- Chart persistence, with filters for the last hour, day, and week
- Control Apple Music with InfiniTime's music controls
- Integration with Apple HealthKit
- Weather fetch (using WeatherKit) and push (using InfiniTime 1.14's [Simple Weather Service](https://github.com/InfiniTimeOrg/InfiniTime/blob/main/doc/SimpleWeatherService.md))
- Uploading of [external resource packages](https://github.com/InfiniTimeOrg/InfiniTime/blob/develop/doc/gettingStarted/updating-software.md#updating-resources)
- Download and install InfiniTime firmware updates from releases and GitHub Actions using the GitHub API (local file updates are supported)

### Partially implemented features:
- System-wide notifications—implemented in [#2217](https://github.com/InfiniTimeOrg/InfiniTime/pull/2217), but not available in the main branch yet.

### Currently non-functional features:
- System-wide music controls—requires implementation of Apple Media Service (AMS).

### Planned features:
- InfiniTime navigation service using MapKit

## Installation:
- **Version 1.0.2:** is accessible on the [App Store](https://apps.apple.com/us/app/infinilink/id1582318814).
- **Version 1.1:** is accessible on [TestFlight](https://testflight.apple.com/join/B3PY5HUV).

## License
Released under [GPL-3.0](/LICENSE) by [@InfiniTimeOrg](https://github.com/InfiniTimeOrg).
