import os
import math

def make_bmp(pixels_rgb_flat):
    # pixels_rgb_flat is a list of 24 * 24 * 3 bytes in RGB order.
    # BMP expects bottom-to-top row ordering and BGR color ordering.
    file_header = bytearray([
        0x42, 0x4D,             # 'BM'
        0xF6, 0x06, 0x00, 0x00, # File size: 1782 bytes
        0x00, 0x00, 0x00, 0x00, # Reserved
        0x36, 0x00, 0x00, 0x00  # Offset to pixel data: 54 bytes
    ])
    
    dib_header = bytearray([
        0x28, 0x00, 0x00, 0x00, # DIB header size: 40 bytes
        0x18, 0x00, 0x00, 0x00, # Width: 24
        0x18, 0x00, 0x00, 0x00, # Height: 24
        0x01, 0x00,             # Color planes: 1
        0x18, 0x00,             # Bits per pixel: 24 (RGB)
        0x00, 0x00, 0x00, 0x00, # Compression: none
        0xC0, 0x06, 0x00, 0x00, # Image size: 1728 bytes
        0xC4, 0x0E, 0x00, 0x00, # X pixels per meter: 3780
        0xC4, 0x0E, 0x00, 0x00, # Y pixels per meter: 3780
        0x00, 0x00, 0x00, 0x00, # Colors count: 0
        0x00, 0x00, 0x00, 0x00  # Important colors: 0
    ])
    
    pixel_data = bytearray(1728)
    for y in range(24):
        src_y = 23 - y # Bottom-to-top mapping
        for x in range(24):
            src_idx = (src_y * 24 + x) * 3
            r = pixels_rgb_flat[src_idx]
            g = pixels_rgb_flat[src_idx + 1]
            b = pixels_rgb_flat[src_idx + 2]
            
            dest_idx = (y * 24 + x) * 3
            pixel_data[dest_idx] = b     # B
            pixel_data[dest_idx + 1] = g # G
            pixel_data[dest_idx + 2] = r # R
            
    return file_header + dib_header + pixel_data

def format_lrs_resource(name, bmp_bytes):
    # Formats the BMP bytes as:
    # LazarusResources.Add('name','BMP',[
    #   #66#77...
    # ]);
    byte_strs = "".join(f"#{b}" for b in bmp_bytes)
    return f"LazarusResources.Add('{name.lower()}','BMP',[\n  {byte_strs}\n]);"

def generate_icons():
    # 1. Grayscale Filter: Smooth horizontal/diagonal gray gradient inside a rectangle
    grayscale_pixels = []
    for y in range(24):
        for x in range(24):
            if 3 <= x <= 20 and 3 <= y <= 20:
                # Border
                if x == 3 or x == 20 or y == 3 or y == 20:
                    grayscale_pixels.extend([50, 50, 50])
                else:
                    # Diagonal gradient from 30 to 220
                    val = int(30 + ((x - 4) + (y - 4)) / 30.0 * 190.0)
                    grayscale_pixels.extend([val, val, val])
            else:
                grayscale_pixels.extend([255, 255, 255]) # White background
                
    # 2. Negative Filter: Diagonal color split + inverted center circle
    negative_pixels = []
    for y in range(24):
        for x in range(24):
            if 3 <= x <= 20 and 3 <= y <= 20:
                # Square border
                if x == 3 or x == 20 or y == 3 or y == 20:
                    negative_pixels.extend([50, 50, 50])
                else:
                    # Center circle radius 6
                    dx = x - 12
                    dy = y - 12
                    in_circle = (dx*dx + dy*dy) <= 36
                    
                    # Diagonal division
                    is_top_right = (x + y) >= 23
                    
                    if is_top_right:
                        # Base color: Dodger Blue (30, 144, 255)
                        color = [30, 144, 255]
                    else:
                        # Base color: Dark Orange (255, 140, 0)
                        color = [255, 140, 0]
                        
                    if in_circle:
                        # Invert color
                        color = [255 - c for c in color]
                        
                    negative_pixels.extend(color)
            else:
                negative_pixels.extend([255, 255, 255])

    # 3. Brightness & Contrast Filter: Split sun shape
    brightness_pixels = []
    for y in range(24):
        for x in range(24):
            dx = x - 12
            dy = y - 12
            dist_sq = dx*dx + dy*dy
            
            # Sun body (radius 6)
            if dist_sq <= 36:
                if x < 12:
                    # Bright Yellow/White side
                    brightness_pixels.extend([255, 230, 100])
                else:
                    # Contrast dark gray/blue side
                    brightness_pixels.extend([60, 60, 100])
            # Sun rays (mathematically placed at specific angles)
            elif 36 < dist_sq <= 81 and (dx == 0 or dy == 0 or abs(dx) == abs(dy)):
                if x < 12:
                    brightness_pixels.extend([255, 165, 0]) # Orange ray
                else:
                    brightness_pixels.extend([100, 100, 150]) # Darker ray
            else:
                brightness_pixels.extend([255, 255, 255])

    # 4. Binarization Filter: High-contrast pure black and white diagonal divide
    binarization_pixels = []
    for y in range(24):
        for x in range(24):
            if 3 <= x <= 20 and 3 <= y <= 20:
                if x == 3 or x == 20 or y == 3 or y == 20:
                    binarization_pixels.extend([0, 0, 0]) # Sharp black border
                else:
                    # Sharp diagonal divide
                    if x + y < 23:
                        binarization_pixels.extend([0, 0, 0]) # Pure black
                    else:
                        binarization_pixels.extend([255, 255, 255]) # Pure white
            else:
                binarization_pixels.extend([255, 255, 255])

    # 5. Blur Filter: Three overlapping soft-edged circles
    blur_pixels = []
    for y in range(24):
        for x in range(24):
            # Compute contributions from three blurred centers
            # C1: (9, 9), C2: (15, 10), C3: (12, 15)
            d1 = math.sqrt((x-9)**2 + (y-9)**2)
            d2 = math.sqrt((x-15)**2 + (y-10)**2)
            d3 = math.sqrt((x-12)**2 + (y-15)**2)
            
            # Radii of blur
            r = 7.0
            w1 = max(0.0, 1.0 - d1/r)
            w2 = max(0.0, 1.0 - d2/r)
            w3 = max(0.0, 1.0 - d3/r)
            
            # Colors
            # C1: Dodger Blue (30, 144, 255)
            # C2: Pink (255, 50, 150)
            # C3: Green (50, 205, 50)
            tr = int(w1*30 + w2*255 + w3*50 + (1.0 - max(w1, w2, w3))*255)
            tg = int(w1*144 + w2*50 + w3*205 + (1.0 - max(w1, w2, w3))*255)
            tb = int(w1*255 + w2*150 + w3*50 + (1.0 - max(w1, w2, w3))*255)
            
            # Clamp
            tr = min(255, max(0, tr))
            tg = min(255, max(0, tg))
            tb = min(255, max(0, tb))
            blur_pixels.extend([tr, tg, tb])

    # 6. Sharpen Filter: Geometric sharp red/cyan focused triangles
    sharpen_pixels = []
    for y in range(24):
        for x in range(24):
            # Check if pixel is inside a triangle with top (12, 3), bottom-left (3, 19), bottom-right (21, 19)
            # Standard barycentric check or linear bounds:
            # y >= 3, and inside the lines from (12,3) to (3,19) and (12,3) to (21,19)
            # Line 1: x >= 12 - (9/16)*(y - 3)  => x >= 12 - 0.5625*(y-3)
            # Line 2: x <= 12 + (9/16)*(y - 3)  => x <= 12 + 0.5625*(y-3)
            if 3 <= y <= 19 and (12 - 0.58 * (y - 3)) <= x <= (12 + 0.58 * (y - 3)):
                # Draw sharp borders
                dist_to_edge = min(
                    y - 3, 19 - y,
                    abs(x - (12 - 0.58 * (y - 3))),
                    abs((12 + 0.58 * (y - 3)) - x)
                )
                if dist_to_edge < 1.5:
                    sharpen_pixels.extend([255, 69, 0]) # Orange-red sharp boundary
                elif dist_to_edge < 3.0:
                    sharpen_pixels.extend([255, 255, 255]) # White spacing
                else:
                    sharpen_pixels.extend([0, 191, 255]) # Glowing sharp cyan center
            else:
                sharpen_pixels.extend([255, 255, 255])

    # 7. Sobel Filter: Dark canvas with a glowing green neon edge
    sobel_pixels = []
    for y in range(24):
        for x in range(24):
            if 3 <= x <= 20 and 3 <= y <= 20:
                # Square boundary (edge)
                is_edge = (x == 7 or x == 16 or y == 7 or y == 16) and (7 <= x <= 16) and (7 <= y <= 16)
                is_outer_edge = (x == 5 or x == 18 or y == 5 or y == 18) and (5 <= x <= 18) and (5 <= y <= 18)
                
                if is_edge:
                    sobel_pixels.extend([0, 255, 255]) # Neon cyan glowing edge
                elif is_outer_edge:
                    sobel_pixels.extend([255, 0, 255]) # Neon magenta edge
                else:
                    sobel_pixels.extend([30, 30, 30]) # Dark background
            else:
                sobel_pixels.extend([255, 255, 255])

    # 8. Erosion & Dilation Filter: concentric expanding/shrinking cross shapes
    erosion_pixels = []
    for y in range(24):
        for x in range(24):
            # Center is (12, 12)
            dx = abs(x - 12)
            dy = abs(y - 12)
            
            # Small cross (Erosion): arm length 3, width 2
            is_small_cross = (dx <= 1 and dy <= 4) or (dy <= 1 and dx <= 4)
            # Large cross (Dilation): arm length 7, width 6
            is_large_cross = (dx <= 3 and dy <= 8) or (dy <= 3 and dx <= 8)
            
            if is_small_cross:
                erosion_pixels.extend([0, 0, 139]) # Dark Blue (Erosion - shrunk core)
            elif is_large_cross:
                erosion_pixels.extend([135, 206, 250]) # Light Sky Blue (Dilation - expanded outer region)
            elif (dx <= 4 and dy <= 9) or (dy <= 4 and dx <= 9):
                # Thin dark blue boundary for the dilation cross
                erosion_pixels.extend([70, 130, 180])
            else:
                erosion_pixels.extend([255, 255, 255])

    # Build BMP files
    grayscale_bmp = make_bmp(grayscale_pixels)
    negative_bmp = make_bmp(negative_pixels)
    brightness_bmp = make_bmp(brightness_pixels)
    binarization_bmp = make_bmp(binarization_pixels)
    blur_bmp = make_bmp(blur_pixels)
    sharpen_bmp = make_bmp(sharpen_pixels)
    sobel_bmp = make_bmp(sobel_pixels)
    erosion_bmp = make_bmp(erosion_pixels)

    # Format LRS contents
    lrs_contents = []
    lrs_contents.append(format_lrs_resource('tgrayscalefilter', grayscale_bmp))
    lrs_contents.append(format_lrs_resource('tnegativefilter', negative_bmp))
    lrs_contents.append(format_lrs_resource('tbrightnesscontrastfilter', brightness_bmp))
    lrs_contents.append(format_lrs_resource('tbinarizationfilter', binarization_bmp))
    lrs_contents.append(format_lrs_resource('tblurfilter', blur_bmp))
    lrs_contents.append(format_lrs_resource('tsharpenfilter', sharpen_bmp))
    lrs_contents.append(format_lrs_resource('tsobelfilter', sobel_bmp))
    lrs_contents.append(format_lrs_resource('terosiondilationfilter', erosion_bmp))

    # Save to file
    output_path = os.path.join(os.path.dirname(__file__), 'imagefilters_icon.lrs')
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write("\n".join(lrs_contents) + "\n")
        
    print(f"Successfully generated {output_path} with 8 gorgeous custom component icons!")

if __name__ == '__main__':
    generate_icons()
