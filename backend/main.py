from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from pydantic import BaseModel, Field
import httpx
import os
import string
import random
import hashlib
import aiofiles
import json
from PIL import Image
from pathlib import Path
from typing import List, Dict, Any, Optional
from fastapi.staticfiles import StaticFiles

app = FastAPI()

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Constants
INVOKEAI_BASE_URL = "http://localhost:9090"
ESTIMATED_TIME_PER_IMAGE = 15
THUMBNAIL_SIZE = (300, 300)
THUMBNAIL_QUALITY = 85
CACHE_CONTROL_THUMBNAILS = "public, max-age=604800"
CACHE_CONTROL_FULL = "public, max-age=31536000"
PHOTO_DIR = Path("photos").resolve()
THUMBNAIL_DIR = Path("thumbnails").resolve()

# Create required directories
for directory in [PHOTO_DIR, THUMBNAIL_DIR]:
    if not directory.exists():
        directory.mkdir(parents=True, exist_ok=True)

def _generate_random_id(length: int = 8) -> str:
    return ''.join(random.choices(string.ascii_letters + string.digits, k=length))

def get_thumbnail_path(original_path: Path) -> Path:
    unique_id = str(original_path)
    filename_hash = hashlib.md5(unique_id.encode()).hexdigest()
    return THUMBNAIL_DIR / f"{original_path.stem}_{filename_hash}.webp"

async def create_thumbnail(image_path: Path, thumbnail_path: Path):
    try:
        with Image.open(image_path) as img:
            if img.mode in ('RGBA', 'P'):
                img = img.convert('RGB')
            img.thumbnail(THUMBNAIL_SIZE, Image.Resampling.LANCZOS)
            img.save(thumbnail_path, 'WEBP', quality=THUMBNAIL_QUALITY)
    except Exception as e:
        print(f"Error creating thumbnail for {image_path}: {e}")
        raise HTTPException(status_code=500, detail="Error creating thumbnail")

# Models
class GenerationRequest(BaseModel):
    image_name: str
    additional_prompt: str = ""
    quantity: int = Field(ge=1, le=10, default=1)  # Limiting to max 10 images
    seed: Optional[int] = None
    use_random_seed: bool = True
    metadata: Dict[Any, Any]

class GenerationResponse(BaseModel):
    estimated_time: int
    batch_id: str
    message: str


@app.get("/api/photos", response_model=List[str])
async def list_photos():
    try:
        photos = [f.name for f in PHOTO_DIR.glob("*") if f.is_file()]
        return sorted(photos, key=lambda x: os.path.getmtime(PHOTO_DIR / x), reverse=True)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/photos/{filename}")
async def get_photo(filename: str, thumbnail: bool = False):
    try:
        file_path = PHOTO_DIR / filename
        if not file_path.exists():
            raise HTTPException(status_code=404, detail="Photo not found")
        return FileResponse(
            file_path,
            headers={"Cache-Control": CACHE_CONTROL_FULL}
        )
    except HTTPException as he:
        raise he
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/photos/thumbnail/{filename}")
async def get_photo_thumbnail(filename: str):
    try:
        original_path = PHOTO_DIR / filename
        if not original_path.exists():
            raise HTTPException(status_code=404, detail="Photo not found")
            
        thumbnail_path = get_thumbnail_path(original_path)
        if not thumbnail_path.exists():
            await create_thumbnail(original_path, thumbnail_path)
            
        return FileResponse(
            thumbnail_path,
            headers={"Cache-Control": CACHE_CONTROL_THUMBNAILS}
        )
    except HTTPException as he:
        raise he
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/api/photos/{filename}")
async def delete_photo(filename: str):
    try:
        file_path = PHOTO_DIR / filename
        thumbnail_path = get_thumbnail_path(file_path)
        
        if not file_path.exists():
            raise HTTPException(status_code=404, detail="Photo not found")
            
        file_path.unlink()
        if thumbnail_path.exists():
            thumbnail_path.unlink()
            
        return {"status": "success"}
    except HTTPException as he:
        raise he
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/metadata/{image_name}")
async def get_image_metadata(image_name: str):
    """Retrieve metadata for a specific image from InvokeAI."""
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{INVOKEAI_BASE_URL}/api/v1/images/i/{image_name}/metadata"
            )
            
            if response.status_code != 200:
                raise HTTPException(
                    status_code=response.status_code,
                    detail=f"Failed to get metadata from InvokeAI: {response.text}"
                )
                
            return response.json()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/generate", response_model=GenerationResponse)
async def trigger_generation(request: GenerationRequest):
    """Trigger a new image generation batch based on existing image metadata and additional parameters."""
    try:
        # Extract and preserve original metadata
        generation_params = request.metadata.copy()
        
        # Handle prompt combination
        original_prompt = generation_params.get("prompt", "")
        # Try different metadata locations for the prompt
        if not original_prompt:
            original_prompt = generation_params.get("positive_prompt", "")
        if not original_prompt and "core_metadata" in generation_params:
            original_prompt = generation_params["core_metadata"].get("positive_prompt", "")
            
        combined_prompt = original_prompt
        if request.additional_prompt:
            combined_prompt = f"{original_prompt}, {request.additional_prompt}"
        
        # Handle seed generation
        if request.use_random_seed:
            seeds = [random.randint(1, 1000000) for _ in range(request.quantity)]
        else:
            base_seed = request.seed if request.seed is not None else 1
            seeds = [base_seed for _ in range(request.quantity)]

        # Extract model info from metadata
        model_info = generation_params.get("model", {})
        if not model_info and "core_metadata" in generation_params:
            model_info = generation_params["core_metadata"].get("model", {})

        # Generate graph ID and node IDs
        graph_id = f"sdxl_graph:{_generate_random_id()}"

        # Create node IDs
        nodes = {
            "model_loader": f"sdxl_model_loader:{_generate_random_id()}",
            "pos_cond": f"sdxl_compel_prompt:{_generate_random_id()}",
            "pos_cond_collect": f"collect:{_generate_random_id()}",
            "neg_cond": f"sdxl_compel_prompt:{_generate_random_id()}",
            "neg_cond_collect": f"collect:{_generate_random_id()}",
            "noise": f"noise:{_generate_random_id()}",
            "denoise_latents": f"denoise_latents:{_generate_random_id()}",
            "vae": f"vae_loader:{_generate_random_id()}",
            "core_metadata": f"core_metadata:{_generate_random_id()}",
            "canvas_output": f"l2i:{_generate_random_id()}"
        }

        invoke_request = {
            "prepend": False,
            "batch": {
                "graph": {
                    "id": graph_id,
                    "nodes": {
                        nodes["model_loader"]: {
                            "type": "sdxl_model_loader",
                            "id": nodes["model_loader"],
                            "model": model_info,
                            "is_intermediate": True,
                            "use_cache": True
                        },
                        nodes["pos_cond"]: {
                            "type": "sdxl_compel_prompt",
                            "id": nodes["pos_cond"],
                            "prompt": combined_prompt,
                            "style": combined_prompt,
                            "is_intermediate": True,
                            "use_cache": True
                        },
                        nodes["pos_cond_collect"]: {
                            "type": "collect",
                            "id": nodes["pos_cond_collect"],
                            "is_intermediate": True,
                            "use_cache": True
                        },
                        nodes["neg_cond"]: {
                            "type": "sdxl_compel_prompt",
                            "id": nodes["neg_cond"],
                            "prompt": generation_params.get("negative_prompt", ""),
                            "style": generation_params.get("negative_style_prompt", ""),
                            "is_intermediate": True,
                            "use_cache": True
                        },
                        nodes["neg_cond_collect"]: {
                            "type": "collect",
                            "id": nodes["neg_cond_collect"],
                            "is_intermediate": True,
                            "use_cache": True
                        },
                        nodes["noise"]: {
                            "type": "noise",
                            "id": nodes["noise"],
                            "seed": seeds[0],
                            "width": generation_params.get("width", 1024),
                            "height": generation_params.get("height", 1024),
                            "use_cpu": True,
                            "is_intermediate": True,
                            "use_cache": True
                        },
                        nodes["denoise_latents"]: {
                            "type": "denoise_latents",
                            "id": nodes["denoise_latents"],
                            "cfg_scale": generation_params.get("cfg_scale", 7.5),
                            "cfg_rescale_multiplier": 0,
                            "scheduler": generation_params.get("scheduler", "dpmpp_2m"),
                            "steps": generation_params.get("steps", 20),
                            "denoising_start": 0,
                            "denoising_end": 1,
                            "is_intermediate": True,
                            "use_cache": True
                        },
                        nodes["vae"]: {
                            "type": "vae_loader",
                            "id": nodes["vae"],
                            "vae_model": generation_params.get("vae", {
                                "key": "6415a9ec-819b-49ca-9a0d-44ac478703a6",
                                "hash": "blake3:9b7c3120af571e8d93fa82d50ef3b5f15727507d0edaae822424951937a008a3",
                                "name": "sdxl-vae-fp16-fix",
                                "base": "sdxl",
                                "type": "vae"
                            }),
                            "is_intermediate": True,
                            "use_cache": True
                        },
                        nodes["core_metadata"]: {
                            "id": nodes["core_metadata"],
                            "type": "core_metadata",
                            "is_intermediate": True,
                            "use_cache": True,
                            "generation_mode": "sdxl_txt2img",
                            "cfg_scale": generation_params.get("cfg_scale", 7.5),
                            "cfg_rescale_multiplier": 0,
                            "width": generation_params.get("width", 1024),
                            "height": generation_params.get("height", 1024),
                            "negative_prompt": generation_params.get("negative_prompt", ""),
                            "model": model_info,
                            "steps": generation_params.get("steps", 20),
                            "rand_device": "cpu",
                            "scheduler": generation_params.get("scheduler", "dpmpp_2m"),
                            "vae": generation_params.get("vae", {
                                "key": "6415a9ec-819b-49ca-9a0d-44ac478703a6",
                                "hash": "blake3:9b7c3120af571e8d93fa82d50ef3b5f15727507d0edaae822424951937a008a3",
                                "name": "sdxl-vae-fp16-fix",
                                "base": "sdxl",
                                "type": "vae"
                            })
                        },
                        nodes["canvas_output"]: {
                            "type": "l2i",
                            "id": nodes["canvas_output"],
                            "fp32": False,
                            "is_intermediate": False,
                            "use_cache": False,
                        }
                    },
                    "edges": [
                        {"source": {"node_id": nodes["model_loader"], "field": "unet"},
                         "destination": {"node_id": nodes["denoise_latents"], "field": "unet"}},
                        {"source": {"node_id": nodes["model_loader"], "field": "clip"},
                         "destination": {"node_id": nodes["pos_cond"], "field": "clip"}},
                        {"source": {"node_id": nodes["model_loader"], "field": "clip"},
                         "destination": {"node_id": nodes["neg_cond"], "field": "clip"}},
                        {"source": {"node_id": nodes["model_loader"], "field": "clip2"},
                         "destination": {"node_id": nodes["pos_cond"], "field": "clip2"}},
                        {"source": {"node_id": nodes["model_loader"], "field": "clip2"},
                         "destination": {"node_id": nodes["neg_cond"], "field": "clip2"}},
                        {"source": {"node_id": nodes["pos_cond"], "field": "conditioning"},
                         "destination": {"node_id": nodes["pos_cond_collect"], "field": "item"}},
                        {"source": {"node_id": nodes["neg_cond"], "field": "conditioning"},
                         "destination": {"node_id": nodes["neg_cond_collect"], "field": "item"}},
                        {"source": {"node_id": nodes["pos_cond_collect"], "field": "collection"},
                         "destination": {"node_id": nodes["denoise_latents"], "field": "positive_conditioning"}},
                        {"source": {"node_id": nodes["neg_cond_collect"], "field": "collection"},
                         "destination": {"node_id": nodes["denoise_latents"], "field": "negative_conditioning"}},
                        {"source": {"node_id": nodes["noise"], "field": "noise"},
                         "destination": {"node_id": nodes["denoise_latents"], "field": "noise"}},
                        {"source": {"node_id": nodes["denoise_latents"], "field": "latents"},
                         "destination": {"node_id": nodes["canvas_output"], "field": "latents"}},
                        {"source": {"node_id": nodes["vae"], "field": "vae"},
                         "destination": {"node_id": nodes["canvas_output"], "field": "vae"}},
                        {"source": {"node_id": nodes["core_metadata"], "field": "metadata"},
                         "destination": {"node_id": nodes["canvas_output"], "field": "metadata"}}
                    ]
                },
                "runs": 1,
                "data": [
                    [
                        {"node_path": nodes["noise"], "field_name": "seed", "items": seeds},
                        {"node_path": nodes["core_metadata"], "field_name": "seed", "items": seeds}
                    ],
                    [
                        {"node_path": nodes["pos_cond"], "field_name": "prompt", "items": [combined_prompt]},
                        {"node_path": nodes["core_metadata"], "field_name": "positive_prompt", "items": [combined_prompt]},
                        {"node_path": nodes["pos_cond"], "field_name": "style", "items": [combined_prompt]},
                        {"node_path": nodes["core_metadata"], "field_name": "positive_style_prompt", "items": [combined_prompt]}
                    ]
                ]
            },
            "origin": "photo_gallery",
            "destination": "gallery"
        }
        
        # Send the generation request to InvokeAI
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{INVOKEAI_BASE_URL}/api/v1/queue/default/enqueue_batch",
                json=invoke_request
            )
            
            if response.status_code not in (200, 201):
                print("Error response from InvokeAI:")
                print(response.text)
                raise HTTPException(
                    status_code=response.status_code,
                    detail=f"Failed to trigger generation: {response.text}"
                )
            
            response_data = response.json()
            
            return GenerationResponse(
                estimated_time=ESTIMATED_TIME_PER_IMAGE * request.quantity,
                batch_id=response_data.get("batch_id", "unknown"),
                message=f"Generation started for {request.quantity} images"
            )
            
    except Exception as e:
        print(f"Generation error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))