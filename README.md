# GainsIQ Mobile - iOS App

## Overview
iOS version of the GainsIQ workout tracker app, built with SwiftUI and following MVVM architecture.

## Project Structure

```
GainsIQMobile/
├── Models/
│   ├── Exercise.swift              # Exercise data model
│   ├── WorkoutSet.swift            # Workout set data model with utilities
│   ├── WeightEntry.swift           # Weight entry data model
│   ├── WeightTrend.swift           # Weight trend data model
│   └── APIModels.swift             # API request/response models
├── Services/
│   ├── GainsIQAPIClient.swift      # Main API client with all endpoints
│   └── UserDefaultsManager.swift   # Settings and preferences manager
├── Utils/
│   ├── NetworkingUtils.swift       # Network monitoring, retry logic, caching
│   ├── Extensions.swift            # Useful extensions for Date, String, Array, etc.
│   └── Constants.swift             # App-wide constants and configuration
└── README.md                       # This file
```
