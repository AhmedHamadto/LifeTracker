# LifeTracker

A comprehensive iOS app for organizing your entire life - medical documents, medications, inventory tracking, and health & fitness.

![Platform](https://img.shields.io/badge/platform-iOS%2017%2B-blue)
![Swift](https://img.shields.io/badge/swift-6.0-orange)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-green)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

## Features

### Documents & Receipts
- Scan documents using your camera with VisionKit
- Automatic OCR text extraction for searchability
- Categorize: Medical, Receipts, Warranties, IDs, Insurance, etc.
- Track expiry dates with notifications
- Organize with folders and tags
- Full-text search across all documents

### Medication Tracking
- Track medications with dosage and schedules
- Push notification reminders
- Log taken/skipped/missed doses
- Refill tracking and reminders
- Apple Health integration
- Adherence history and reports

### Inventory Management
- Barcode/QR scanning with auto product lookup
- Categories: Electronics, Clothing, Gym, Kitchen, etc.
- Photo attachments for items
- Purchase info and warranty linking
- Location tracking (home, storage, gym bag)
- Total value summary for insurance

### Health & Fitness
- Workout logging with exercises, sets, and reps
- Body measurements tracking
- Progress photos with comparison
- Apple Health sync
- Personal records tracking

## Tech Stack

- **UI**: SwiftUI
- **Data**: SwiftData with CloudKit sync
- **AI/ML**: Apple Vision framework (on-device OCR)
- **Scanning**: VisionKit, AVFoundation
- **Health**: HealthKit integration
- **Notifications**: UserNotifications framework

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 6.0

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/LifeTracker.git
```

2. Open the project in Xcode:
```bash
cd LifeTracker
open LifeTracker.xcodeproj
```

3. Configure signing:
   - Select your development team
   - Update the bundle identifier

4. Add required capabilities in Xcode:
   - iCloud (CloudKit)
   - HealthKit
   - Push Notifications

5. Build and run on your device or simulator

## Project Structure

```
LifeTracker/
├── App/
│   ├── LifeTrackerApp.swift      # App entry point
│   └── ContentView.swift          # Main TabView navigation
├── Core/
│   ├── Models/                    # SwiftData models
│   ├── Services/                  # Business logic
│   ├── Repositories/              # Data access layer
│   └── Extensions/                # Swift extensions
├── Features/
│   ├── Dashboard/                 # Home screen
│   ├── Documents/                 # Document management
│   ├── Medications/               # Medication tracking
│   ├── Inventory/                 # Item inventory
│   └── Health/                    # Health & fitness
├── Shared/
│   ├── Components/                # Reusable UI components
│   ├── Styles/                    # Design system
│   └── Utilities/                 # Helpers
└── Resources/
    └── Assets.xcassets            # App assets
```

## Privacy

LifeTracker is designed with privacy in mind:

- **On-device AI**: All OCR and ML processing happens locally
- **Your iCloud**: Data syncs only to your personal iCloud account
- **No analytics**: No third-party tracking or analytics
- **Health data**: Stays within Apple's secure HealthKit ecosystem

## Roadmap

See [TODO.md](TODO.md) for the complete development roadmap.

### Upcoming Features
- iOS Widgets
- Siri Shortcuts
- Apple Watch app
- iPad optimization
- Receipt auto-categorization with ML

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with SwiftUI and SwiftData
- Icons from SF Symbols
- Inspired by the need to organize life better
