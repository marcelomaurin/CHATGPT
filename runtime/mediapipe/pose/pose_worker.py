import sys
import os
import numpy as np
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision

def main():
    if len(sys.argv) < 3:
        print("ERROR: Missing arguments. Usage: pose_worker.py <model_path> <raw_image_path>", file=sys.stderr)
        sys.exit(1)
        
    model_path = sys.argv[1]
    image_path = sys.argv[2]
    
    if not os.path.exists(model_path):
        print(f"ERROR: Model file not found: {model_path}", file=sys.stderr)
        sys.exit(1)
    if not os.path.exists(image_path):
        print(f"ERROR: Image file not found: {image_path}", file=sys.stderr)
        sys.exit(1)
        
    try:
        # Read raw image: width (4 bytes), height (4 bytes), then raw RGB data
        with open(image_path, "rb") as f:
            width = int.from_bytes(f.read(4), byteorder='little')
            height = int.from_bytes(f.read(4), byteorder='little')
            raw_data = f.read()
            
        # Convert raw RGB data to numpy array
        image_np = np.frombuffer(raw_data, dtype=np.uint8).reshape((height, width, 3))
        
        # Load MediaPipe Image
        mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=image_np)
        
        # Initialize Pose Landmarker
        base_options = python.BaseOptions(model_asset_path=model_path)
        options = vision.PoseLandmarkerOptions(
            base_options=base_options,
            running_mode=vision.RunningMode.IMAGE,
            output_segmentation_masks=False
        )
        
        with vision.PoseLandmarker.create_from_options(options) as landmarker:
            result = landmarker.detect(mp_image)
            
            if not result.pose_landmarks:
                print("POSES: 0")
                return
                
            print(f"POSES: {len(result.pose_landmarks)}")
            for pose_idx, landmarks in enumerate(result.pose_landmarks):
                print(f"POSE: {pose_idx}")
                for lm_idx, lm in enumerate(landmarks):
                    # In Python MediaPipe, world landmarks are also available in result.pose_world_landmarks
                    world_lm = result.pose_world_landmarks[pose_idx][lm_idx] if result.pose_world_landmarks else None
                    wx = world_lm.x if world_lm else 0.0
                    wy = world_lm.y if world_lm else 0.0
                    wz = world_lm.z if world_lm else 0.0
                    print(f"{lm.x} {lm.y} {lm.z} {lm.visibility} {lm.presence} {wx} {wy} {wz}")
                    
    except Exception as e:
        print(f"ERROR: {str(e)}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
