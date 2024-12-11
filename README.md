# Self-Hosted Photo Gallery

A privacy-focused, self-hosted solution for managing and accessing your personal photo collection across devices. This project aims to provide the convenience of commercial cloud services while maintaining complete control over your data.

## 🌟 Vision

This project was born from the desire to create a self-hosted alternative to commercial photo storage solutions. Key motivations include:

- Complete control over personal photo storage and access
- Independence from subscription-based services
- Protection from service discontinuation or policy changes
- Learning opportunity for full-stack development
- Customizable features tailored to personal needs

## 🚧 Current Status - Work In Progress

The project is in active development, currently focused on Phase 1 essential features.

### What's Working

#### Backend (FastAPI)
- Basic photo serving functionality on port 8000
- Support for common image formats (PNG, JPG, JPEG, GIF)
- Directory listing with modification time sorting
- Symlinked photo directories support
- Basic error handling
- CORS enabled for cross-origin requests

#### Frontend (Flutter)
- Basic gallery view implementation
- Grid view of photos with pull-to-refresh
- Network image caching
- Loading states and error handling
- Works on Android devices and emulator
- Handles HTTP connections

### Current Limitations
- Local network access only
- No authentication system
- Basic UI without advanced features
- No offline mode
- No image organization features

## 🗺️ Roadmap

### Phase 1 (Current Focus)
- Basic photo viewing and navigation
- Remote access capability
- Secure authentication
- Local network functionality
- Basic image organization

### Future Phases
- Enhanced organization (smart albums, advanced search, tags)
- Sharing & collaboration features
- Advanced media management
- AI-powered features (optional/local)
- Face recognition (optional/local)

## 🛠️ Tech Stack

- Backend: FastAPI (Python)
- Frontend: Flutter
- Future Database: PostgreSQL (planned)

## 📋 Prerequisites

- Python 3.10+
- Flutter SDK
- Java 17 (for Android build compatibility)

## 🚀 Getting Started

### Backend Setup
```bash
cd backend
# Install dependencies
pip install -r requirements.txt
# Run the server
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

### Frontend Setup
```bash
cd frontend
# Get Flutter dependencies
flutter pub get
# Run the app
flutter run
```

### Building APK
```bash
cd frontend
flutter build apk
```

## 🔜 Next Steps

Immediate priorities:
1. Add offline mode support
2. Implement image organization features
3. Add full-screen image viewing
4. Implement authentication system
5. Improve UI/UX with additional features

## 📝 Development Principles

1. **Privacy-First Design**
   - Local processing priority
   - Minimal data collection
   - User control over all data

2. **Sustainable Development**
   - Modular architecture
   - Clear documentation
   - Maintainable code

3. **User-Centric Approach**
   - Intuitive interface
   - Fast performance
   - Reliable operation

## 🤝 Contributing

This project is currently in early development. Contribution guidelines will be added as the project matures.

## 📄 License

[License information to be added]

## 📞 Contact

[Contact information to be added]

---
**Note**: This project is in active development. Features and implementation details may change significantly as development progresses.