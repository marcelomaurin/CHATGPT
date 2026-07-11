import os
import re

# Color map: character to RGB tuple
COLOR_MAP = {
    '.': [255, 255, 255], # white background (transparent/white)
    '#': [40, 44, 52],     # dark gray outline/lines
    'r': [220, 80, 80],    # red
    'g': [80, 200, 120],   # green
    'b': [80, 150, 240],   # blue
    'y': [240, 180, 50],   # yellow
    'p': [180, 100, 220],  # purple
    'c': [80, 200, 220],   # cyan
    'w': [240, 240, 245],  # light gray/blue fill
    'd': [100, 110, 120],  # dark gray fill
    'o': [255, 128, 0],    # orange
}

# Icon pixel art definitions (24x24) - verified to be exactly 24 chars per line
ICONS = {
    'taiagentserial': [
        "........................",
        ".........######.........",
        ".......##cccccc##.......",
        "......#cccccccccc#......",
        ".....#cccccccccccc#.....",
        "....#ccc########ccc#....",
        "....#cc#...##...#cc#....",
        "....#cc#..####..#cc#....",
        "....#cc#...##...#cc#....",
        "....#cc##......##cc#....",
        "....#ccc########ccc#....",
        ".....#cccccccccccc#.....",
        "......#cccccccccc#......",
        ".......##cccccc##.......",
        ".........######.........",
        "..........####..........",
        "..........#oo#..........",
        ".......##########.......",
        "......#oooooooooo#......",
        "......#o##o##o##o#......",
        "......#oooooooooo#......",
        ".......##########.......",
        "........................",
        "........................"
    ],
    'taiagentorchestrator': [
        "........................",
        ".........######.........",
        ".......##pppppp##.......",
        "......#pppppppppp#......",
        ".....#pppppppppppp#.....",
        "....#ppp########ppp#....",
        "....#pp#...##...#pp#....",
        "....#pp#..####..#pp#....",
        "....#pp#...##...#pp#....",
        "....#pp##......##pp#....",
        "....#ppp########ppp#....",
        ".....#pppppppppppp#.....",
        "......#pppppppppp#......",
        ".......##pppppp##.......",
        ".....##..######..##.....",
        "....#bb#........#rr#....",
        "....#bb#........#rr#....",
        ".....##..........##.....",
        "........................",
        ".....##..........##.....",
        "....#gg#........#yy#....",
        "....#gg#........#yy#....",
        ".....##..........##.....",
        "........................"
    ],
    'taiclassifieragent': [
        "........................",
        "....################....",
        "....#bbbbbbbbbbbbbb#....",
        "....#bbbbbbbbbbbbbb#....",
        ".....#bbbbbbbbbbbb#.....",
        "......#bbbbbbbbbb#......",
        ".......#bbbbbbbb#.......",
        "........#bbbbbb#........",
        ".........#bbbb#.........",
        "..........#bb#..........",
        "..........#bb#..........",
        "..........#bb#..........",
        "..........#bb#..........",
        "..........####..........",
        "...........##...........",
        "...........##...........",
        ".........######.........",
        "........#cccccc#........",
        "........#cccccc#........",
        "........#cccccc#........",
        ".........######.........",
        "........................",
        "........................",
        "........................"
    ],
    'taidecisionagent': [
        "........................",
        ".........######.........",
        "........#yyyyyy#........",
        "........#y####y#........",
        "........#y#..#y#........",
        "........#y####y#........",
        "........#yyyyyy#........",
        ".........######.........",
        "...........##...........",
        "......############......",
        ".....#............#.....",
        "....#..###....###..#....",
        "....#.#rrr#..#ggg#.#....",
        "....#.#rrr#..#ggg#.#....",
        "....#..###....###..#....",
        ".....#............#.....",
        "......############......",
        "...........##...........",
        "...........##...........",
        ".........######.........",
        "........#dddddd#........",
        "........#dddddd#........",
        ".........######.........",
        "........................"
    ],
    'taiactionbuilderagent': [
        "........................",
        "......############......",
        ".....#dddddddddddd#.....",
        "....#dddddddddddddd#....",
        "....#dd##########dd#....",
        "....#dd#        #dd#....",
        "....#dd#  ####  #dd#....",
        "....#dd# #yyyy# #dd#....",
        "....#dd# #yyyy# #dd#....",
        "....#dd#  ####  #dd#....",
        "....#dd##########dd#....",
        ".....#dddddddddddd#.....",
        "......############......",
        "........##....##........",
        "........##....##........",
        "......############......",
        ".....#bbbbbbbbbbbb#.....",
        "....#bbbbbbbbbbbbbb#....",
        "....#bb##########bb#....",
        "....#bb#        #bb#....",
        "....#bb#  ####  #bb#....",
        "....#bb# #gggg# #bb#....",
        ".....##..######..##.....",
        "........................"
    ],
    'taiactionexecutor': [
        "........................",
        ".........######.........",
        ".......##cccccc##.......",
        "......#cccccccccc#......",
        ".....#cccccccccccc#.....",
        "....#ccc########ccc#....",
        "....#cc#...##...#cc#....",
        "....#cc#..#yy#..#cc#....",
        "....#cc#.#yyyy#.#cc#....",
        "....#cc#.#yyyy#.#cc#....",
        "....#cc#..#yy#..#cc#....",
        "....#cc#...##...#cc#....",
        "....#ccc########ccc#....",
        ".....#cccccccccccc#.....",
        "......#cccccccccc#......",
        ".......##cccccc##.......",
        ".........######.........",
        "..........####..........",
        ".........#rrrr#.........",
        "........#rrrrrr#........",
        "........#r####r#........",
        ".........######.........",
        "........................",
        "........................"
    ],
    'taiagentmemorymap': [
        "........................",
        "......############......",
        ".....#pppppppppppp#.....",
        "....#pppppppppppppp#....",
        "....#pp##########pp#....",
        "....#pp#        #pp#....",
        "....#pp#  ####  #pp#....",
        "....#pp# #yyyy# #pp#....",
        "....#pp#  ####  #pp#....",
        "....#pp#        #pp#....",
        "....#pp#  ####  #pp#....",
        "....#pp# #gggg# #pp#....",
        "....#pp#  ####  #pp#....",
        "....#pp#        #pp#....",
        "....#pp#  ####  #pp#....",
        "....#pp# #bbbb# #pp#....",
        "....#pp#  ####  #pp#....",
        "....#pp#        #pp#....",
        "....#pp##########pp#....",
        "....#pppppppppppppp#....",
        ".....#pppppppppppp#.....",
        "......############......",
        "........................",
        "........................"
    ],
    'taiagentsafety': [
        "........................",
        ".........######.........",
        ".......##rrrrrr##.......",
        "......#rrrrrrrrrr#......",
        ".....#rrrrrrrrrrrr#.....",
        ".....#rr########rr#.....",
        ".....#rr#      #rr#.....",
        ".....#rr#  ##  #rr#.....",
        ".....#rr# #### #rr#.....",
        ".....#rr#  ##  #rr#.....",
        ".....#rr########rr#.....",
        ".....#rrrrrrrrrrrr#.....",
        "......#rrrrrrrrrr#......",
        ".......##rrrrrr##.......",
        ".........######.........",
        "..........####..........",
        ".........#dddd#.........",
        "........#dddddd#........",
        "........#d####d#........",
        ".........######.........",
        "........................",
        "........................",
        "........................",
        "........................"
    ],
    'taipipeline': [
        "........................",
        "....######....######....",
        "...#bbbbbb#..#gggggg#...",
        "....######....######....",
        "......##........##......",
        "......##........##......",
        "....######....######....",
        "...#cccccc#..#yyyyyy#...",
        "....######....######....",
        "......##........##......",
        "......##........##......",
        "....######....######....",
        "...#pppppp#..#rrrrrr#...",
        "....######....######....",
        "......##........##......",
        "......##........##......",
        "....######....######....",
        "...#dddddd#..#wwwwww#...",
        "....######....######....",
        "........................",
        "........................",
        "........................",
        "........................",
        "........................"
    ],
    'taiwizardconfig': [
        "........................",
        "...............######...",
        "..............#yyyyyy#..",
        "...............######...",
        "..............##........",
        ".............#pp#.......",
        "............#pppp#......",
        "...........#pppppp#.....",
        "..........#pppppppp#....",
        ".........#pppppppppp#...",
        "........#pppppppppppp#..",
        ".......#pppppppppppppp#.",
        "......#pppp########pppp#",
        ".....#ppp#........#ppp#.",
        "....#ppp#..........#ppp#",
        "....#pp#............#pp#",
        "....#pp#............#pp#",
        "....#pp#............#pp#",
        "....#pp#............#pp#",
        "....#pp#............#pp#",
        ".....##..............##.",
        "........................",
        "........................",
        "........................"
    ]
}

def make_bmp(pixels_rgb_flat):
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
    return f"LazarusResources.Add('{name.upper()}','BMP',[\n  {byte_strs}\n]);"

def patch_pas_file(file_path, lrs_filename):
    if not os.path.exists(file_path):
        print(f"Pascal file not found: {file_path}")
        return False
        
    with open(file_path, 'r', encoding='utf-8') as f:
        original_content = f.read()
        
    content = original_content
        
    # 1. Patch uses clause to add LResources if missing
    uses_match = re.search(r'\buses\b([\s\S]*?);', content, re.IGNORECASE)
    if uses_match:
        uses_clause = uses_match.group(1)
        if 'LResources' not in uses_clause:
            uses_end_pos = uses_match.end(1)
            separator = ', ' if len(uses_clause.strip()) > 0 else ''
            content = content[:uses_end_pos] + separator + 'LResources' + content[uses_end_pos:]
            print(f"Added LResources to uses clause in {file_path}")
            
    # Check if resource file is already included
    include_str = f"{{$I {lrs_filename}}}"
    if include_str.lower() not in content.lower():
        idx = content.rfind("end.")
        if idx == -1:
            print(f"Could not find ending 'end.' in {file_path}")
            return False
            
        init_match = re.search(r'^\s*initialization\b', content, re.IGNORECASE | re.MULTILINE)
        if init_match:
            pos = init_match.end()
            content = content[:pos] + f"\n  {include_str}\n" + content[pos:]
            print(f"Patched existing initialization block in {file_path}")
        else:
            content = content[:idx] + f"initialization\n  {include_str}\n\n" + content[idx:]
            print(f"Created new initialization block in {file_path}")
        
    if content != original_content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Saved changes to {file_path}")
        return True
    else:
        print(f"No changes needed for {file_path}")
        return False

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    
    comp_to_file = {
        'taiagentserial': 'aiagentserial.pas',
        'taiagentorchestrator': 'aiagent_orchestrator.pas',
        'taiclassifieragent': 'aiagent_classifier.pas',
        'taidecisionagent': 'aiagent_decision.pas',
        'taiactionbuilderagent': 'aiagent_actionbuilder.pas',
        'taiactionexecutor': 'aiagent_executor.pas',
        'taiagentmemorymap': 'aiagent_memorymap.pas',
        'taiagentsafety': 'aiagentsafety.pas',
        'taipipeline': 'aipipeline.pas',
        'taiwizardconfig': 'aiwizardconfig.pas'
    }
    
    for comp_name, art_lines in ICONS.items():
        # Validate drawing size
        if len(art_lines) != 24:
            raise ValueError(f"Component {comp_name} has {len(art_lines)} lines, expected 24")
        for i, line in enumerate(art_lines):
            if len(line) != 24:
                raise ValueError(f"Component {comp_name} line {i} has length {len(line)}, expected 24")
                
        # Build RGB flat array
        pixels_rgb = []
        for line in art_lines:
            for char in line:
                color = COLOR_MAP.get(char, [255, 255, 255])
                pixels_rgb.extend(color)
                
        bmp_bytes = make_bmp(pixels_rgb)
        lrs_content = format_lrs_resource(comp_name, bmp_bytes)
        
        # Write .lrs file
        lrs_filename = f"{comp_name}_icon.lrs"
        lrs_path = os.path.join(script_dir, lrs_filename)
        with open(lrs_path, 'w', encoding='utf-8') as f:
            f.write(lrs_content + "\n")
        print(f"Generated LRS resource: {lrs_path}")
        
        # Patch corresponding .pas file
        pas_file_name = comp_to_file.get(comp_name)
        if pas_file_name:
            pas_path = os.path.join(script_dir, pas_file_name)
            patch_pas_file(pas_path, lrs_filename)
            
    print("Successfully completed icon generation for AI Agents package!")

if __name__ == '__main__':
    main()
