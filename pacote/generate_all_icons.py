import os

# 5x5 font definition
font = {
    'A': [[0,1,1,1,0],[1,0,0,0,1],[1,1,1,1,1],[1,0,0,0,1],[1,0,0,0,1]],
    'B': [[1,1,1,1,0],[1,0,0,0,1],[1,1,1,1,0],[1,0,0,0,1],[1,1,1,1,0]],
    'C': [[0,1,1,1,1],[1,0,0,0,0],[1,0,0,0,0],[1,0,0,0,0],[0,1,1,1,1]],
    'D': [[1,1,1,1,0],[1,0,0,0,1],[1,0,0,0,1],[1,0,0,0,1],[1,1,1,1,0]],
    'E': [[1,1,1,1,1],[1,0,0,0,0],[1,1,1,1,0],[1,0,0,0,0],[1,1,1,1,1]],
    'G': [[0,1,1,1,1],[1,0,0,0,0],[1,0,1,1,1],[1,0,0,0,1],[0,1,1,1,0]],
    'I': [[0,1,1,1,0],[0,0,1,0,0],[0,0,1,0,0],[0,0,1,0,0],[0,1,1,1,0]],
    'L': [[1,0,0,0,0],[1,0,0,0,0],[1,0,0,0,0],[1,0,0,0,0],[1,1,1,1,1]],
    'M': [[1,0,0,0,1],[1,1,0,1,1],[1,0,1,0,1],[1,0,0,0,1],[1,0,0,0,1]],
    'N': [[1,0,0,0,1],[1,1,0,0,1],[1,0,1,0,1],[1,0,0,1,1],[1,0,0,0,1]],
    'O': [[0,1,1,1,0],[1,0,0,0,1],[1,0,0,0,1],[1,0,0,0,1],[0,1,1,1,0]],
    'P': [[1,1,1,1,0],[1,0,0,0,1],[1,1,1,1,0],[1,0,0,0,0],[1,0,0,0,0]],
    'R': [[1,1,1,1,0],[1,0,0,0,1],[1,1,1,1,0],[1,0,0,1,0],[1,0,0,0,1]],
    'S': [[0,1,1,1,1],[1,0,0,0,0],[0,1,1,1,0],[0,0,0,0,1],[1,1,1,1,0]],
    'T': [[1,1,1,1,1],[0,0,1,0,0],[0,0,1,0,0],[0,0,1,0,0],[0,0,1,0,0]],
    'U': [[1,0,0,0,1],[1,0,0,0,1],[1,0,0,0,1],[1,0,0,0,1],[0,1,1,1,0]],
    'W': [[1,0,0,0,1],[1,0,0,0,1],[1,0,1,0,1],[1,1,0,1,1],[1,0,0,0,1]],
    'X': [[1,0,0,0,1],[0,1,0,1,0],[0,0,1,0,0],[0,1,0,1,0],[1,0,0,0,1]],
    'Y': [[1,0,0,0,1],[0,1,0,1,0],[0,0,1,0,0],[0,0,1,0,0],[0,0,1,0,0]],
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
    return f"LazarusResources.Add('{name.lower()}','BMP',[\n  {byte_strs}\n]);"

def draw_icon(border_color, label):
    pixels = []
    for y in range(24):
        for x in range(24):
            if 3 <= x <= 20 and 3 <= y <= 20:
                # Border
                if x == 3 or x == 20 or y == 3 or y == 20:
                    pixels.extend(border_color)
                else:
                    char1 = label[0] if len(label) > 0 else ' '
                    char2 = label[1] if len(label) > 1 else ' '
                    
                    is_pixel_on = False
                    # Left char: starts at x=6, y=9
                    if 6 <= x <= 10 and 9 <= y <= 13 and char1 in font:
                        is_pixel_on = font[char1][y - 9][x - 6] == 1
                    # Right char: starts at x=13, y=9
                    elif 13 <= x <= 17 and 9 <= y <= 13 and char2 in font:
                        is_pixel_on = font[char2][y - 9][x - 13] == 1
                        
                    if is_pixel_on:
                        pixels.extend([0, 0, 0]) # black text
                    else:
                        pixels.extend([240, 240, 240]) # light gray background
            else:
                pixels.extend([255, 255, 255]) # pure white
    return pixels

# Colors per category
C_AGENT = [200, 50, 50]
C_INPUT = [50, 180, 50]
C_OUTPUT = [50, 100, 220]
C_MATH = [150, 50, 200]
C_PROJECT = [50, 180, 180]
C_VOICE = [230, 130, 20]

icons_config = {
    # IA Agent
    'IA Agent/aiagent_icon.lrs': [
        ('taiagent', C_AGENT, 'AG'),
        ('taiagentoptions', C_AGENT, 'OP'),
        ('taiagentaction', C_AGENT, 'AC'),
        ('taiagentresource', C_AGENT, 'RS'),
        ('taiagentoutput', C_AGENT, 'AO'),
    ],
    'IA Agent/aiagentsafety_icon.lrs': [
        ('taiagentsafety', C_AGENT, 'SF'),
    ],
    
    # IA Math
    'IA Math/numps_icon.lrs': [
        ('tnumps', C_MATH, 'MA'),
    ],
    
    # IA Input
    'IA Input/aiinput_icon.lrs': [
        ('taiinputdata', C_INPUT, 'IN'),
    ],
    'IA Input/aicamera_icon.lrs': [
        ('taicamerainput', C_INPUT, 'CM'),
    ],
    'IA Input/aiaudio_icon.lrs': [
        ('taiaudioinput', C_INPUT, 'AD'),
    ],
    'IA Input/aiwebserver_icon.lrs': [
        ('taiwebapiserver', C_INPUT, 'WS'),
    ],
    'IA Input/aisockets_icon.lrs': [
        ('taisockettcp', C_INPUT, 'TC'),
        ('taisocketudp', C_INPUT, 'UD'),
    ],
    'IA Input/aiserial_icon.lrs': [
        ('taiserialmodem', C_INPUT, 'SR'),
    ],
    'IA Input/aiposprinter_icon.lrs': [
        ('taiposprinter', C_INPUT, 'PR'),
    ],
    'IA Input/aicftvip_icon.lrs': [
        ('taicftvip', C_INPUT, 'CF'),
    ],
    'IA Input/aimodbus_icon.lrs': [
        ('taimodbusclient', C_INPUT, 'MB'),
    ],
    'IA Input/aimqtt_icon.lrs': [
        ('taimqttclient', C_INPUT, 'MQ'),
    ],
    'IA Input/aiemail_icon.lrs': [
        ('taiemailclient', C_INPUT, 'EM'),
    ],
    'IA Input/aimessenger_icon.lrs': [
        ('taimessenger', C_INPUT, 'MS'),
    ],
    'IA Input/aiindustrial_icon.lrs': [
        ('taiindustrialbridge', C_INPUT, 'ID'),
    ],
    'IA Input/aichromiumbrowser_icon.lrs': [
        ('taichromiumbrowser', C_INPUT, 'CR'),
    ],
    'IA Input/aioscapture_icon.lrs': [
        ('taiosinputcapture', C_INPUT, 'OS'),
    ],
    
    # IA Output
    'IA Output/aioutput_icon.lrs': [
        ('taioutputdata', C_OUTPUT, 'OT'),
    ],
    'IA Output/aioutput_docs_icon.lrs': [
        ('taipdfoutput', C_OUTPUT, 'PD'),
        ('taiwordoutput', C_OUTPUT, 'WD'),
        ('taiexceloutput', C_OUTPUT, 'XL'),
        ('taitxtoutput', C_OUTPUT, 'TX'),
        ('taioutputdocs', C_OUTPUT, 'DO'),
    ],
    
    # IA Voice
    'IA Voice/aivoicesynthesizer_icon.lrs': [
        ('taivoicesynthesizer', C_VOICE, 'VS'),
    ],
    
    # IA Project
    'IA/aiproject_icon.lrs': [
        ('taiproject', C_PROJECT, 'PJ'),
    ],
    'IA/aipipeline_icon.lrs': [
        ('taipipeline', C_PROJECT, 'PL'),
    ],
    'IA/aipromptbuilder_icon.lrs': [
        ('taipromptbuilder', C_PROJECT, 'PB'),
    ],
}

def patch_pas_file(file_path, lrs_filename):
    if not os.path.exists(file_path):
        print(f"Pascal file not found: {file_path}")
        return
        
    with open(file_path, 'r', encoding='utf-8') as f:
        original_content = f.read()
        
    content = original_content
        
    # 1. Patch uses clause to add LResources if missing
    import re
    uses_match = re.search(r'\buses\b([\s\S]*?);', content, re.IGNORECASE)
    if uses_match:
        uses_clause = uses_match.group(1)
        if 'LResources' not in uses_clause:
            # Add LResources to uses clause
            uses_end_pos = uses_match.end(1)
            # Check if there is already something in uses clause to format nicely
            separator = ', ' if len(uses_clause.strip()) > 0 else ''
            content = content[:uses_end_pos] + separator + 'LResources' + content[uses_end_pos:]
            print(f"Added LResources to uses clause in {file_path}")
            
    # Check if resource file is already included
    include_str = f"{{$I {lrs_filename}}}"
    if include_str.lower() not in content.lower():
        # Locate the final "end."
        idx = content.rfind("end.")
        if idx == -1:
            print(f"Could not find ending 'end.' in {file_path}")
            return
            
        # Add initialization section before end.
        init_idx = content.lower().rfind("initialization")
        if init_idx != -1 and init_idx > content.lower().rfind("implementation"):
            pos = init_idx + len("initialization")
            content = content[:pos] + f"\n  {include_str}\n" + content[pos:]
            print(f"Patched existing initialization block in {file_path}")
        else:
            content = content[:idx] + f"initialization\n  {include_str}\n\n" + content[idx:]
            print(f"Created new initialization block in {file_path}")
        
    # Save only if content changed
    if content != original_content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Saved changes to {file_path}")
    else:
        print(f"No changes needed for {file_path}")

def main():
    package_root = os.path.dirname(os.path.abspath(__file__))
    
    # 1. Generate LRS files
    for relative_lrs_path, configs in icons_config.items():
        lrs_contents = []
        for class_name, border_color, label in configs:
            pixels = draw_icon(border_color, label)
            bmp_bytes = make_bmp(pixels)
            lrs_contents.append(format_lrs_resource(class_name, bmp_bytes))
            
        full_lrs_path = os.path.join(package_root, relative_lrs_path)
        # Ensure target subdirectory exists
        os.makedirs(os.path.dirname(full_lrs_path), exist_ok=True)
        with open(full_lrs_path, 'w', encoding='utf-8') as f:
            f.write("\n".join(lrs_contents) + "\n")
        print(f"Generated LRS: {full_lrs_path}")
        
    # 2. Patch Pascal source files
    patches = [
        ('IA Agent/aiagent.pas', 'aiagent_icon.lrs'),
        ('IA Agent/aiagentsafety.pas', 'aiagentsafety_icon.lrs'),
        ('IA Math/numps.pas', 'numps_icon.lrs'),
        ('IA Input/aiinput.pas', 'aiinput_icon.lrs'),
        ('IA Input/aicamera.pas', 'aicamera_icon.lrs'),
        ('IA Input/aiaudio.pas', 'aiaudio_icon.lrs'),
        ('IA Input/aiwebserver.pas', 'aiwebserver_icon.lrs'),
        ('IA Input/aisockets.pas', 'aisockets_icon.lrs'),
        ('IA Input/aiserial.pas', 'aiserial_icon.lrs'),
        ('IA Input/aiposprinter.pas', 'aiposprinter_icon.lrs'),
        ('IA Input/aicftvip.pas', 'aicftvip_icon.lrs'),
        ('IA Input/aimodbus.pas', 'aimodbus_icon.lrs'),
        ('IA Input/aimqtt.pas', 'aimqtt_icon.lrs'),
        ('IA Input/aiemail.pas', 'aiemail_icon.lrs'),
        ('IA Input/aimessenger.pas', 'aimessenger_icon.lrs'),
        ('IA Input/aiindustrial.pas', 'aiindustrial_icon.lrs'),
        ('IA Input/aichromiumbrowser.pas', 'aichromiumbrowser_icon.lrs'),
        ('IA Input/aioscapture.pas', 'aioscapture_icon.lrs'),
        ('IA Output/aioutput.pas', 'aioutput_icon.lrs'),
        ('IA Output/aioutput_docs.pas', 'aioutput_docs_icon.lrs'),
        ('IA Voice/aivoicesynthesizer.pas', 'aivoicesynthesizer_icon.lrs'),
        ('IA/aiproject.pas', 'aiproject_icon.lrs'),
        ('IA/aipipeline.pas', 'aipipeline_icon.lrs'),
        ('IA/aipromptbuilder.pas', 'aipromptbuilder_icon.lrs'),
    ]
    
    for pas_rel_path, lrs_filename in patches:
        full_pas_path = os.path.join(package_root, pas_rel_path)
        patch_pas_file(full_pas_path, lrs_filename)
        
    print("Done generating and patching!")

if __name__ == '__main__':
    main()
