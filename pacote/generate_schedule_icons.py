import os
import math

def make_bmp(pixels_rgb_flat):
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
    byte_strs = "".join(f"#{b}" for b in bmp_bytes)
    return f"LazarusResources.Add('{name.lower()}','BMP',[\n  {byte_strs}\n]);"

def generate_icons():
    # 1. TJSONGroupStorage: A database disc/folder with a curly bracket JSON symbol
    storage_pixels = []
    for y in range(24):
        for x in range(24):
            # Let's draw a nice file document/disk cylinder:
            # Document body at x from 4 to 19, y from 3 to 20
            if 4 <= x <= 19 and 3 <= y <= 20:
                if x == 4 or x == 19 or y == 3 or y == 20:
                    storage_pixels.extend([139, 69, 19]) # Brown folder outline
                elif 5 <= y <= 7:
                    storage_pixels.extend([255, 215, 0]) # Golden folder tab/top
                else:
                    # White/cream inside
                    # Let's draw green curly braces '{' and '}' in the center (x=10..13)
                    # '{' at x=8, y=10..14
                    is_left_brace = (x == 8 and 10 <= y <= 14) or (y == 10 and 8 <= x <= 10) or (y == 14 and 8 <= x <= 10) or (y == 12 and 6 <= x <= 8)
                    # '}' at x=15, y=10..14
                    is_right_brace = (x == 15 and 10 <= y <= 14) or (y == 10 and 13 <= x <= 15) or (y == 14 and 13 <= x <= 15) or (y == 12 and 15 <= x <= 17)
                    
                    if is_left_brace or is_right_brace:
                        storage_pixels.extend([34, 139, 34]) # Forest Green brace
                    else:
                        storage_pixels.extend([255, 250, 240]) # Floral White folder inner
            else:
                storage_pixels.extend([255, 255, 255]) # Pure white (transparent)

    # 2. TIASchedule: Calendar grid with checkbox and clock
    schedule_pixels = []
    for y in range(24):
        for x in range(24):
            # Draw a nice calendar shape: x from 3 to 20, y from 3 to 20
            if 3 <= x <= 20 and 3 <= y <= 20:
                # Border
                if x == 3 or x == 20 or y == 3 or y == 20:
                    schedule_pixels.extend([128, 128, 128]) # Gray calendar boundary
                elif 4 <= y <= 7:
                    schedule_pixels.extend([220, 20, 60]) # Crimson Red calendar header
                else:
                    # White sheet with some blue grid lines
                    is_grid = (x == 8 or x == 14) or (y == 12 or y == 16)
                    # Draw a nice green checkmark in the bottom-right
                    # Checkmark lines at y - x relations
                    is_checkmark = False
                    if 14 <= x <= 18 and 12 <= y <= 17:
                        # simple checkmark equation:
                        # (x=14, y=14), (x=15, y=15), (x=16, y=14), (x=17, y=13), (x=18, y=12)
                        is_checkmark = (x - y == 0 and 14 <= x <= 15) or (x + y == 30 and 15 <= x <= 18)
                        
                    if is_checkmark:
                        schedule_pixels.extend([50, 205, 50]) # Lime Green checkmark
                    elif is_grid:
                        schedule_pixels.extend([224, 224, 224]) # Light gray grid
                    else:
                        schedule_pixels.extend([255, 255, 255]) # White calendar sheet
            else:
                schedule_pixels.extend([255, 255, 255]) # Pure white (transparent)

    storage_bmp = make_bmp(storage_pixels)
    schedule_bmp = make_bmp(schedule_pixels)

    lrs_contents = []
    lrs_contents.append(format_lrs_resource('tjsongroupstorage', storage_bmp))
    lrs_contents.append(format_lrs_resource('tiaschedule', schedule_bmp))

    output_path = os.path.join(os.path.dirname(__file__), 'iaschedule_icon.lrs')
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write("\n".join(lrs_contents) + "\n")
        
    print(f"Successfully generated {output_path} with 2 custom schedule tab component icons!")

if __name__ == '__main__':
    generate_icons()
