# Photo Gallery Backend

This is the backend service for the Self-Hosted Photo Gallery project, built with FastAPI. It handles photo storage, retrieval, and management operations.

## 🚧 Current Implementation

### API Endpoints

- `GET /api/photos` - Lists all photos, sorted by modification time (newest first)
- `GET /photos/{filename}` - Serves individual photo files

### Features

- Supports symlinked photo directories
- Handles common image formats (PNG, JPG, JPEG, GIF)
- Basic error handling for file operations
- CORS enabled for cross-origin requests
- Modification time-based sorting

## 🛠️ Technical Stack

- FastAPI
- Python 3.10+
- uvicorn (ASGI server)

## 📋 Dependencies

```
fastapi
uvicorn
python-multipart
aiofiles
```

## 🚀 Setup and Running

1. Create and activate a Python virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Run the server:
```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

The server will be available at `http://localhost:8000`

## 📁 Project Structure

```
backend/
├── main.py           # Main application entry point
├── requirements.txt  # Python dependencies
└── README.md        # This file
```

## 🔜 Planned Features

- Authentication and authorization
- Image metadata handling
- Advanced search and filtering
- Image processing capabilities
- Database integration
- Backup system
- Remote access security

## 🔍 Development Notes

- The server runs in development mode with `--reload` flag
- CORS is currently configured to accept all origins for development
- File operations are handled asynchronously
- Error handling includes basic file operation errors

## 🧪 Testing

[Testing instructions to be added as implementation progresses]

## 🔒 Security Considerations

Current development setup is for local network use only. Security features planned:
- Authentication system
- API rate limiting
- Request validation
- Secure file handling
- Access control
- HTTPS support