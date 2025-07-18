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
│   ├── Analysis.swift              # Analysis data model
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

## Core Features Implemented

### 1. Data Models
- **Exercise**: Basic exercise with name and utilities
- **WorkoutSet**: Complete workout set with weight, reps, timestamps, and cutting/bulking state
- **WeightEntry**: Weight logging with timestamps and formatting
- **Analysis**: AI-generated workout analysis
- **WeightTrend**: Weight trend calculations with weekly/monthly changes

### 2. API Client
- **Full REST API integration** matching your backend
- **Async/await support** for modern Swift
- **Comprehensive error handling** with custom error types
- **Automatic retry logic** with exponential backoff
- **Request/response logging** for debugging

### 3. Settings Management
- **Weight unit preferences** (lbs/kg with automatic conversion)
- **Cutting/bulking state** management
- **API configuration** storage
- **Chart preferences** and app settings
- **Onboarding state** tracking

### 4. Utilities
- **Network monitoring** for offline/online states
- **Caching system** for performance
- **Background task management** for sync operations
- **Comprehensive extensions** for common operations
- **Haptic feedback** integration

## API Endpoints Covered

### Exercises
- `GET /exercises` - Get all exercises
- `POST /exercises` - Add new exercise
- `DELETE /exercises` - Delete exercise

### Workout Sets
- `POST /sets/log` - Log workout set
- `GET /sets/last_month` - Get last month's sets
- `GET /sets` - Get sets in date range
- `GET /sets/by_exercise` - Get sets by exercise and date range
- `PUT /sets/edit` - Edit existing set
- `DELETE /sets` - Delete set
- `POST /sets/pop` - Remove last set

### Weight Tracking
- `POST /weight` - Log weight entry
- `GET /weight` - Get all weight entries
- `DELETE /weight` - Delete most recent weight
- `GET /weight/trend` - Get weight trend analysis

### Analysis
- `POST /analysis` - Generate new analysis
- `GET /analysis` - Get latest analysis

## Key Features

### Data Management
- **Offline-first architecture** ready for Core Data integration
- **Automatic unit conversion** between lbs and kg
- **Smart caching** with configurable expiration
- **Background sync** capabilities

### Error Handling
- **Comprehensive error types** for all failure scenarios
- **User-friendly error messages** with localization support
- **Automatic retry** for transient network errors
- **Graceful degradation** for offline scenarios

### Performance
- **Request deduplication** and caching
- **Background task management** for long-running operations
- **Memory-efficient** data structures
- **Lazy loading** support for large datasets

## Next Steps

1. **Create ViewModels** for each major feature
2. **Build SwiftUI Views** for the main screens
3. **Implement Core Data** for local storage
4. **Add Charts** using Swift Charts framework
5. **Implement Navigation** with TabView and NavigationStack
6. **Add Notifications** for workout reminders
7. **Implement Export** functionality
8. **Add Unit Tests** for models and services

## Configuration

Before using the API client, configure it with your actual endpoints:

```swift
let apiClient = GainsIQAPIClient(
    baseURL: "https://your-api-gateway-url.amazonaws.com/prod",
    apiKey: "your-api-key"
)
```

## Dependencies

- SwiftUI (iOS 15+)
- Foundation
- Network (for connectivity monitoring)
- Swift Charts (for data visualization)
- Core Data (for local storage)

## Architecture

The app follows MVVM (Model-View-ViewModel) architecture:
- **Models**: Data structures and business logic
- **ViewModels**: Presentation logic and state management
- **Views**: SwiftUI user interface
- **Services**: API communication and data persistence

This foundation provides a solid base for building out the complete iOS app with all the functionality from your web version.