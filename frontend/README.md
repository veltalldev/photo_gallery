# Photo Gallery Frontend

Flutter-based frontend application for the Self-Hosted Photo Gallery project. This app provides a responsive and intuitive interface for viewing and managing your photo collection.

## 🚧 Current Implementation

### Features

- Grid view of photos
- Pull-to-refresh functionality
- Refresh button in app bar
- Loading states and error handling
- Network image caching
- Basic responsive layout

### Platform Support

Currently tested on:
- Android emulator
- Physical Android devices
- Handles HTTP (non-HTTPS) connections

## 🛠️ Technical Stack

- Flutter SDK
- Dart
- http package for network requests
- cached_network_image for image caching

## 📋 Dependencies

From pubspec.yaml:
```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^[version]
  cached_network_image: ^[version]
```

## 🚀 Setup and Running

1. Ensure Flutter is installed and configured:
```bash
flutter doctor
```

2. Get dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

4. Build APK:
```bash
flutter build apk
```

## 📁 Project Structure

```
frontend/
├── lib/
│   ├── main.dart          # Application entry point
│   ├── screens/           # Screen widgets
│   ├── widgets/           # Reusable widgets
│   ├── models/           # Data models
│   └── services/         # API services
├── pubspec.yaml          # Flutter dependencies
└── README.md            # This file
```

## 🔜 Planned Features

- Full-screen image viewing
- Image organization features
- Offline mode support
- Advanced UI components
- Search functionality
- Album organization
- Sharing capabilities
- User authentication UI
- Settings management

## 🎯 Development Focus

Current development priorities:
1. Implement offline mode
2. Add image organization features
3. Enhance UI/UX
4. Add authentication screens
5. Implement settings interface

## 📱 Platform Specific Notes

### Android
- AndroidManifest.xml configured for cleartext traffic (development)
- Network permissions configured
- Minimum SDK version: [version]

### iOS
[To be implemented]

## 🧪 Testing

[Testing instructions to be added as implementation progresses]

## 📝 Development Notes

- Backend URL is configurable via baseUrl constant
- Currently using local network IP for device access
- Development focused on Android platform initially
- UI designed for both phone and tablet layouts

## 🔄 State Management

[State management strategy to be documented as implementation progresses]