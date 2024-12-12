from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from pydantic import BaseModel, Field
import httpx
import os
import string
import random
from pathlib import Path
from typing import List, Dict, Any, Optional

# Create FastAPI app instance first
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
ESTIMATED_TIME_PER_IMAGE = 15  # seconds, adjust based on your setup

# Get the absolute path of the symlink target
photos_dir = Path("photos").resolve()

def _generate_random_id(length: int = 8) -> str:
    """Generate a random ID string of specified length."""
    return ''.join(random.choices(string.ascii_letters + string.digits, k=length))

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

# Original photo listing endpoint
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
            seeds = [base_seed + i for i in range(request.quantity)]

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
                            "board": {"board_id": generation_params.get("board_id", "")}
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
                "runs": request.quantity,
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

        print("========================================")
        print("Sending request to InvokeAI:")
        print(invoke_request)
        
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