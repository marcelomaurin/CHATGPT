import sys
import json
import os
import argparse

def return_json(data):
    print(json.dumps(data), flush=True)
    sys.exit(0 if data.get("success", False) else 1)

try:
    import cv2
    import numpy as np
except ImportError as e:
    return_json({
        "success": False,
        "error": "OpenCV Python package not installed"
    })

def main():
    parser = argparse.ArgumentParser(description="TAIOpenCV Python Worker Script")
    parser.add_argument("--action", required=True, choices=["selftest", "info", "none", "gray", "blur", "canny", "threshold", "resize"])
    parser.add_argument("--input", default="")
    parser.add_argument("--output", default="")
    parser.add_argument("--kernel", type=int, default=5)
    parser.add_argument("--threshold", type=int, default=127)
    parser.add_argument("--canny1", type=int, default=100)
    parser.add_argument("--canny2", type=int, default=200)
    parser.add_argument("--width", type=int, default=640)
    parser.add_argument("--height", type=int, default=480)
    
    args = parser.parse_args()
    
    if args.action == "selftest":
        return_json({
            "success": True,
            "version": cv2.__version__,
            "message": "OpenCV available"
        })
        
    # Actions below require input image
    if not args.input:
        return_json({
            "success": False,
            "error": "Input file is required"
        })
        
    if not os.path.exists(args.input):
        return_json({
            "success": False,
            "error": "Input file not found"
        })
        
    img = cv2.imread(args.input)
    if img is None:
        return_json({
            "success": False,
            "error": "Could not read image using OpenCV."
        })
        
    h, w, *c = img.shape
    channels = c[0] if c else 1
    
    if args.action == "info":
        return_json({
            "success": True,
            "width": w,
            "height": h,
            "channels": channels
        })
        
    # Actions below require output image
    if not args.output:
        return_json({
            "success": False,
            "error": "Output file is required."
        })
        
    # Apply filter
    res = img
    if args.action == "none":
        res = img
    elif args.action == "gray":
        res = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    elif args.action == "blur":
        k = args.kernel
        if k <= 0 or k % 2 == 0:
            return_json({
                "success": False,
                "error": "Invalid blur kernel size. Kernel size must be odd and greater than zero."
            })
        res = cv2.blur(img, (k, k))
    elif args.action == "canny":
        if args.canny1 < 0 or args.canny1 > 255 or args.canny2 < 0 or args.canny2 > 255 or args.canny1 >= args.canny2:
            return_json({
                "success": False,
                "error": "Invalid Canny thresholds."
            })
        res = cv2.Canny(img, args.canny1, args.canny2)
    elif args.action == "threshold":
        if args.threshold < 0 or args.threshold > 255:
            return_json({
                "success": False,
                "error": "Invalid threshold value. Expected range: 0..255."
            })
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY) if len(img.shape) == 3 else img
        _, res = cv2.threshold(gray, args.threshold, 255, cv2.THRESH_BINARY)
    elif args.action == "resize":
        if args.width <= 0 or args.height <= 0:
            return_json({
                "success": False,
                "error": "Invalid resize dimensions."
            })
        res = cv2.resize(img, (args.width, args.height))
        
    # Write output image
    try:
        # Make sure output directory exists
        out_dir = os.path.dirname(args.output)
        if out_dir and not os.path.exists(out_dir):
            os.makedirs(out_dir, exist_ok=True)
            
        cv2.imwrite(args.output, res)
    except Exception as e:
        return_json({
            "success": False,
            "error": f"Failed to save processed image: {e}"
        })
        
    # Retrieve new dimensions
    nh, nw, *nc = res.shape
    nchannels = nc[0] if nc else 1
    
    return_json({
        "success": True,
        "message": "Image processed successfully",
        "output": args.output,
        "width": nw,
        "height": nh,
        "channels": nchannels,
        "version": cv2.__version__
    })

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        return_json({
            "success": False,
            "error": str(e)
        })
