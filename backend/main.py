from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
import os
from pathlib import Path
from typing import List

app = FastAPI()

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Get the absolute path of the symlink target
photos_dir = Path("photos").resolve()

@app.get("/api/photos", response_model=List[str])
async def list_photos():
    """List all photos in the photos directory, sorted by modification time (newest first)."""
    try:
        # Get all image files with their modification times
        photo_info = []
        for filename in os.listdir(photos_dir):
            if not os.path.isfile(os.path.join(photos_dir, filename)):
                continue
                
            if not filename.lower().endswith(('.png', '.jpg', '.jpeg', '.gif')):
                continue
                
            file_path = os.path.join(photos_dir, filename)
            photo_info.append({
                'filename': filename,
                'mtime': os.path.getmtime(file_path)
            })
        
        # Sort by modification time, newest first
        photo_info.sort(key=lambda x: x['mtime'], reverse=True)
        
        # Return just the sorted filenames
        return [photo['filename'] for photo in photo_info]
        
    except Exception as e:
        print(f"Error listing photos: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/photos/{filename}")
async def get_photo(filename: str):
    """Serve individual photos."""
    try:
        file_path = os.path.join(photos_dir, filename)
        if not os.path.exists(file_path):
            raise HTTPException(status_code=404, detail="File not found")
        return FileResponse(file_path)
    except Exception as e:
        print(f"Error serving photo {filename}: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))