import sys
import json
import os
import argparse

def return_error(msg):
    # Print both to stderr (as ERROR: msg) and output error json to stdout for structured parsing
    print(f"ERROR: {msg}", file=sys.stderr)
    # Output json format to stdout
    print(json.dumps({"success": False, "error": msg}), file=sys.stdout, flush=True)
    sys.exit(1)

def return_success(data):
    print(json.dumps(data), file=sys.stdout, flush=True)
    sys.exit(0)

try:
    import cv2
    import numpy as np
except ImportError as e:
    return_error("OpenCV or numpy Python package not installed. Install with: pip install opencv-python numpy")

def main():
    parser = argparse.ArgumentParser(description="TAICameraCapture Python Helper Script")
    parser.add_argument("--action", default="capture", choices=["capture", "selftest", "list"])
    parser.add_argument("--camera", type=int, default=0)
    parser.add_argument("--width", type=int, default=640)
    parser.add_argument("--height", type=int, default=480)
    parser.add_argument("--output", default="")
    parser.add_argument("--max-scan", type=int, default=5)
    
    args = parser.parse_args()
    
    if args.action == "list":
        available_cameras = []
        max_scan = max(1, args.max_scan)
        for i in range(max_scan + 1):
            # Try with CAP_DSHOW on Windows first for speed, then fall back
            cap = cv2.VideoCapture(i, cv2.CAP_DSHOW) if os.name == 'nt' else cv2.VideoCapture(i)
            if not cap.isOpened():
                cap = cv2.VideoCapture(i)
            if cap.isOpened():
                ret, frame = cap.read()
                if ret:
                    available_cameras.append(i)
                    print(f"{i} - Camera disponível")
                cap.release()
        
        # Also return structured JSON for code that prefers parsing it
        # (Though we print the plain lines as requested by specification)
        sys.exit(0)
        
    elif args.action == "selftest":
        # Check cv2 version
        ver = cv2.__version__
        # Try opening the requested camera index
        cap = cv2.VideoCapture(args.camera, cv2.CAP_DSHOW) if os.name == 'nt' else cv2.VideoCapture(args.camera)
        if not cap.isOpened():
            cap = cv2.VideoCapture(args.camera)
            
        if not cap.isOpened():
            return_error(f"Camera index {args.camera} could not be opened.")
            
        ret, frame = cap.read()
        cap.release()
        if not ret or frame is None:
            return_error(f"Camera index {args.camera} opened but failed to capture frame.")
            
        return_success({
            "success": True,
            "version": ver,
            "message": f"Environment and camera index {args.camera} are operational"
        })
        
    elif args.action == "capture":
        if not args.output:
            return_error("Output file path (--output) is required for capture action.")
            
        cap = cv2.VideoCapture(args.camera, cv2.CAP_DSHOW) if os.name == 'nt' else cv2.VideoCapture(args.camera)
        if not cap.isOpened():
            cap = cv2.VideoCapture(args.camera)
            
        if not cap.isOpened():
            return_error(f"Camera index {args.camera} could not be opened.")
            
        # Set resolution if requested
        if args.width > 0 and args.height > 0:
            cap.set(cv2.CAP_PROP_FRAME_WIDTH, args.width)
            cap.set(cv2.CAP_PROP_FRAME_HEIGHT, args.height)
            
        # Warm up the camera sensor (grab a few frames)
        frame = None
        for _ in range(5):
            ret, frame = cap.read()
            if not ret:
                break
                
        cap.release()
        
        if frame is None:
            return_error("Frame capture failed or returned empty frame.")
            
        # Write output image
        try:
            # Ensure target output directory exists
            out_dir = os.path.dirname(args.output)
            if out_dir and not os.path.exists(out_dir):
                os.makedirs(out_dir, exist_ok=True)
                
            success = cv2.imwrite(args.output, frame)
            if not success:
                return_error(f"OpenCV cv2.imwrite failed to write to: {args.output}")
        except Exception as e:
            return_error(f"Failed to save captured image: {e}")
            
        h, w, *c = frame.shape
        channels = c[0] if c else 1
        
        return_success({
            "success": True,
            "message": "Frame captured successfully",
            "output": args.output,
            "width": w,
            "height": h,
            "channels": channels,
            "version": cv2.__version__
        })

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        return_error(str(e))
