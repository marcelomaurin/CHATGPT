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
    'F': [[1,1,1,1,1],[1,0,0,0,0],[1,1,1,1,0],[1,0,0,0,0],[1,0,0,0,0]],
    'H': [[1,0,0,0,1],[1,0,0,0,1],[1,1,1,1,1],[1,0,0,0,1],[1,0,0,0,1]],
    'K': [[1,0,0,0,1],[1,0,1,0,0],[1,1,0,0,0],[1,0,1,0,0],[1,0,0,0,1]],
    'V': [[1,0,0,0,1],[1,0,0,0,1],[0,1,0,1,0],[0,1,0,1,0],[0,0,1,0,0]],
    '3': [[1,1,1,1,0],[0,0,0,0,1],[0,1,1,1,0],[0,0,0,0,1],[1,1,1,1,0]],
    'Z': [[1,1,1,1,1],[0,0,0,1,0],[0,0,1,0,0],[0,1,0,0,0],[1,1,1,1,1]],
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
C_GRAPHIC = [180, 80, 180]
C_VISION = [0, 150, 150]
C_GRAPH = [100, 100, 255]
C_ML = [255, 128, 0]
C_SIMULATION = [20, 140, 120]

icons_config = {
    # AI Agent
    'AI Agent/aiagent_icon.lrs': [
        ('taiagent', C_AGENT, 'AG'),
        ('taiagentoptions', C_AGENT, 'OP'),
        ('taiagentaction', C_AGENT, 'AC'),
        ('taiagentresource', C_AGENT, 'RS'),
        ('taiagentoutput', C_AGENT, 'AO'),
    ],
    'AI Agent/aiagentsafety_icon.lrs': [
        ('taiagentsafety', C_AGENT, 'SF'),
    ],
    
    # AI Math
    'AI Math/numps_icon.lrs': [
        ('tnumps', C_MATH, 'MA'),
    ],
    
    # AI Input
    'AI Input/aiinput_icon.lrs': [
        ('taiinputdata', C_INPUT, 'IN'),
    ],
    'AI Input/aicapturesource_icon.lrs': [
        ('taicapturesource', C_INPUT, 'CS'),
    ],
    'AI Input/aiaudio_icon.lrs': [
        ('taiaudioinput', C_INPUT, 'AD'),
    ],
    'AI Input/aiwebserver_icon.lrs': [
        ('taiwebapiserver', C_INPUT, 'WS'),
    ],
    'AI Input/aisockets_icon.lrs': [
        ('taisockettcp', C_INPUT, 'TC'),
        ('taisocketudp', C_INPUT, 'UD'),
    ],
    'AI Input/aiserial_icon.lrs': [
        ('taiserialmodem', C_INPUT, 'SR'),
    ],
    'AI Input/aiposprinter_icon.lrs': [
        ('taiposprinter', C_INPUT, 'PR'),
    ],
    'AI Input/aimodbus_icon.lrs': [
        ('taimodbusclient', C_INPUT, 'MB'),
    ],
    'AI Input/aimqtt_icon.lrs': [
        ('taimqttclient', C_INPUT, 'MQ'),
    ],
    'AI Input/aiemail_icon.lrs': [
        ('taiemailclient', C_INPUT, 'EM'),
    ],
    'AI Input/aimessenger_icon.lrs': [
        ('taimessenger', C_INPUT, 'MS'),
    ],
    'AI Input/aiindustrial_icon.lrs': [
        ('taiindustrialbridge', C_INPUT, 'ID'),
    ],
    'AI Input/aichromiumbrowser_icon.lrs': [
        ('taichromiumbrowser', C_INPUT, 'CR'),
    ],
    
    # AI Output
    'AI Output/aioutput_icon.lrs': [
        ('taioutputdata', C_OUTPUT, 'OT'),
    ],
    'AI Output/aioutput_docs_icon.lrs': [
        ('taipdfoutput', C_OUTPUT, 'PD'),
        ('taiwordoutput', C_OUTPUT, 'WD'),
        ('taiexceloutput', C_OUTPUT, 'XL'),
        ('taitxtoutput', C_OUTPUT, 'TX'),
        ('taioutputdocs', C_OUTPUT, 'DO'),
    ],
    
    # AI Voice
    'AI Voice/aivoicesynthesizer_icon.lrs': [
        ('taivoicesynthesizer', C_VOICE, 'VS'),
    ],
    
    # AI Project
    'AI/aiproject_icon.lrs': [
        ('taiproject', C_PROJECT, 'PJ'),
    ],
    'AI/aipipeline_icon.lrs': [
        ('taipipeline', C_PROJECT, 'PL'),
    ],
    'AI/aipromptbuilder_icon.lrs': [
        ('taipromptbuilder', C_PROJECT, 'PB'),
    ],
    
    # AI Graph / Models
    'AI Graph/aigraphmap_icon.lrs': [
        ('taigraphmap', C_GRAPH, 'GM'),
    ],
    'AI Graph/aitrainingexporter_icon.lrs': [
        ('taitrainingexporter', C_GRAPH, 'TE'),
    ],
    'AI Graph/aidatasetanalyzer_icon.lrs': [
        ('taidatasetanalyzer', C_GRAPH, 'DA'),
    ],
    'AI Graph/aitrainingreport_icon.lrs': [
        ('taitrainingreport', C_GRAPH, 'TR'),
    ],
    'AI Graph/aigraphvisualizer_icon.lrs': [
        ('taigraphvisualizer', C_GRAPH, 'GV'),
    ],
    'AI/aimodelregistry_icon.lrs': [
        ('taimodelregistry', C_PROJECT, 'MR'),
    ],
    'AI/aiwizardconfig_icon.lrs': [
        ('taiwizardconfig', C_PROJECT, 'WC'),
    ],
    'AI/matrizcomponent_icon.lrs': [
        ('tamatrizcomponent', C_ML, 'MC'),
    ],

    # AI Graphic
    'AI Graphic/aiscene2d3d_icon.lrs': [
        ('taiscene2d3d', C_GRAPHIC, 'SC'),
    ],
    'AI Graphic/aitrainingenvironment_icon.lrs': [
        ('taitrainingenvironment', C_GRAPHIC, 'EN'),
    ],
    'AI Graphic/aiphysicssimulator_icon.lrs': [
        ('taiphysicssimulator', C_GRAPHIC, 'PH'),
    ],
    'AI Graphic/aisensorvirtual_icon.lrs': [
        ('taisensorvirtual', C_GRAPHIC, 'SV'),
    ],
    'AI Graphic/airewardfunction_icon.lrs': [
        ('tairewardfunction', C_GRAPHIC, 'RF'),
    ],
    'AI Graphic/aimodel3d_icon.lrs': [
        ('taimodel3d', C_GRAPHIC, 'M3'),
    ],
    'AI Graphic/ai3dmodelviewer_icon.lrs': [
        ('tai3dmodelviewer', C_GRAPHIC, 'VW'),
    ],
    'AI Graphic/aiskeletonrig_icon.lrs': [
        ('taiskeletonrig', C_GRAPHIC, 'SK'),
    ],
    'AI Graphic/aiavatarcontroller_icon.lrs': [
        ('taiavatarcontroller', C_GRAPHIC, 'AV'),
    ],
    'AI Graphic/aiposelibrary_icon.lrs': [
        ('taiposelibrary', C_GRAPHIC, 'PS'),
    ],
    'AI Graphic/aianimationsequence_icon.lrs': [
        ('taianimationsequence', C_GRAPHIC, 'AS'),
    ],
    'AI Graphic/aitripo3dclient_icon.lrs': [
        ('taitripo3dclient', C_GRAPHIC, 'T3'),
    ],

    # AI Vision
    'AI Vision/aiopencv_icon.lrs': [
        ('taiopencv', C_VISION, 'CV'),
    ],
    'AI Vision/aicameracapture_icon.lrs': [
    ('', C_VISION, 'CC'),
    ],
    'AI Vision/aiframeprocessor_icon.lrs': [
        ('taiframeprocessor', C_VISION, 'FP'),
    ],
    'AI Vision/aifacetracker_icon.lrs': [
        ('taifacetracker', C_VISION, 'FT'),
    ],
    'AI Vision/aimotiontracker_icon.lrs': [
        ('taimotiontracker', C_VISION, 'MT'),
    ],
    'AI Vision/aiimageinfo_icon.lrs': [
        ('taiimageinfo', C_VISION, 'II'),
    ],
    'AI Vision/aiframebuffer_icon.lrs': [
        ('taiframebuffer', C_VISION, 'FB'),
    ],
    'AI Vision/ainativeimagefilter_icon.lrs': [
        ('tainativeimagefilter', C_VISION, 'NF'),
    ],
    'AI Vision/aiframediff_icon.lrs': [
        ('taiframediff', C_VISION, 'FD'),
    ],

    # AI Simulation
    'AI Simulation/aigridworld_icon.lrs': [
        ('taigridworld', C_SIMULATION, 'GW'),
    ],
    'AI Simulation/aisimentity_icon.lrs': [
        ('taisimentity', C_SIMULATION, 'EN'),
    ],
    'AI Simulation/aientityfactory_icon.lrs': [
        ('taientityfactory', C_SIMULATION, 'EF'),
    ],
    'AI Simulation/aisimulationengine_icon.lrs': [
        ('taisimulationengine', C_SIMULATION, 'SE'),
    ],
    'AI Simulation/airuleengine_icon.lrs': [
        ('tairuleengine', C_SIMULATION, 'RE'),
    ],
    'AI Simulation/aitriggerengine_icon.lrs': [
        ('taitriggerengine', C_SIMULATION, 'TE'),
    ],
    'AI Simulation/aimovementengine_icon.lrs': [
        ('taimovementengine', C_SIMULATION, 'ME'),
    ],
    'AI Simulation/aievolutionengine_icon.lrs': [
        ('taievolutionengine', C_SIMULATION, 'EV'),
    ],
    'AI Simulation/aisimulationstats_icon.lrs': [
        ('taisimulationstats', C_SIMULATION, 'ST'),
    ],
    'AI Simulation/aigridrenderer2d_icon.lrs': [
        ('taigridrenderer2d', C_SIMULATION, 'GR'),
    ],
    'AI Simulation/aiscenarioconfig_icon.lrs': [
        ('taiscenarioconfig', C_SIMULATION, 'SC'),
    ],
    'AI Simulation/aiscenariogenerator_icon.lrs': [
        ('taiscenariogenerator', C_SIMULATION, 'SG'),
    ],
    'AI Simulation/aisimulationexporter_icon.lrs': [
        ('taisimulationexporter', C_SIMULATION, 'EX'),
    ],
    # AI Utilities / Core additions
    'python/aipythonruntime_icon.lrs': [
        ('taipythonruntime', C_MATH, 'PR'),
    ],
    'AI Files/aidisktreescanner_icon.lrs': [
        ('taidisktreescanner', C_MATH, 'TS'),
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
        init_match = re.search(r'^\s*initialization\b', content, re.IGNORECASE | re.MULTILINE)
        if init_match:
            pos = init_match.end()
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
        ('AI Agent/aiagent.pas', 'aiagent_icon.lrs'),
        ('AI Agent/aiagentsafety.pas', 'aiagentsafety_icon.lrs'),
        ('AI Math/numps.pas', 'numps_icon.lrs'),
        ('AI Input/aiinput.pas', 'aiinput_icon.lrs'),
        ('AI Input/aicapturesource.pas', 'aicapturesource_icon.lrs'),
        ('AI Input/aiaudio.pas', 'aiaudio_icon.lrs'),
        ('AI Input/aiwebserver.pas', 'aiwebserver_icon.lrs'),
        ('AI Input/aisockets.pas', 'aisockets_icon.lrs'),
        ('AI Input/aiserial.pas', 'aiserial_icon.lrs'),
        ('AI Input/aiposprinter.pas', 'aiposprinter_icon.lrs'),
        ('AI Input/aimodbus.pas', 'aimodbus_icon.lrs'),
        ('AI Input/aimqtt.pas', 'aimqtt_icon.lrs'),
        ('AI Input/aiemail.pas', 'aiemail_icon.lrs'),
        ('AI Input/aimessenger.pas', 'aimessenger_icon.lrs'),
        ('AI Input/aiindustrial.pas', 'aiindustrial_icon.lrs'),
        ('AI Input/aichromiumbrowser.pas', 'aichromiumbrowser_icon.lrs'),
        ('AI Output/aioutput.pas', 'aioutput_icon.lrs'),
        ('AI Output/aioutput_docs.pas', 'aioutput_docs_icon.lrs'),
        ('AI Voice/aivoicesynthesizer.pas', 'aivoicesynthesizer_icon.lrs'),
        ('AI/aiproject.pas', 'aiproject_icon.lrs'),
        ('AI/aipipeline.pas', 'aipipeline_icon.lrs'),
        ('AI/aipromptbuilder.pas', 'aipromptbuilder_icon.lrs'),
        ('AI Graph/aigraphmap.pas', 'aigraphmap_icon.lrs'),
        ('AI Graph/aitrainingexporter.pas', 'aitrainingexporter_icon.lrs'),
        ('AI Graph/aidatasetanalyzer.pas', 'aidatasetanalyzer_icon.lrs'),
        ('AI Graph/aitrainingreport.pas', 'aitrainingreport_icon.lrs'),
        ('AI Graph/aigraphvisualizer.pas', 'aigraphvisualizer_icon.lrs'),
        ('AI/aimodelregistry.pas', 'aimodelregistry_icon.lrs'),
        ('AI/aiwizardconfig.pas', 'aiwizardconfig_icon.lrs'),
        ('AI/matrizcomponent.pas', 'matrizcomponent_icon.lrs'),
        ('python/aipythonruntime.pas', 'aipythonruntime_icon.lrs'),
        ('AI Files/aidisktreescanner.pas', 'aidisktreescanner_icon.lrs'),
        ('AI Graphic/aiscene2d3d.pas', 'aiscene2d3d_icon.lrs'),
        ('AI Graphic/aitrainingenvironment.pas', 'aitrainingenvironment_icon.lrs'),
        ('AI Graphic/aiphysicssimulator.pas', 'aiphysicssimulator_icon.lrs'),
        ('AI Graphic/aisensorvirtual.pas', 'aisensorvirtual_icon.lrs'),
        ('AI Graphic/airewardfunction.pas', 'airewardfunction_icon.lrs'),
        ('AI Graphic/aimodel3d.pas', 'aimodel3d_icon.lrs'),
        ('AI Graphic/ai3dmodelviewer.pas', 'ai3dmodelviewer_icon.lrs'),
        ('AI Graphic/aiskeletonrig.pas', 'aiskeletonrig_icon.lrs'),
        ('AI Graphic/aiavatarcontroller.pas', 'aiavatarcontroller_icon.lrs'),
        ('AI Graphic/aiposelibrary.pas', 'aiposelibrary_icon.lrs'),
        ('AI Graphic/aianimationsequence.pas', 'aianimationsequence_icon.lrs'),
        ('AI Graphic/aitripo3dclient.pas', 'aitripo3dclient_icon.lrs'),
        ('AI Vision/aiopencv.pas', 'aiopencv_icon.lrs'),
        ('AI Vision/aiframeprocessor.pas', 'aiframeprocessor_icon.lrs'),
        ('AI Vision/aifacetracker.pas', 'aifacetracker_icon.lrs'),
        ('AI Vision/aimotiontracker.pas', 'aimotiontracker_icon.lrs'),
        ('AI Vision/aiimageinfo.pas', 'aiimageinfo_icon.lrs'),
        ('AI Vision/aiframebuffer.pas', 'aiframebuffer_icon.lrs'),
        ('AI Vision/ainativeimagefilter.pas', 'ainativeimagefilter_icon.lrs'),
        ('AI Vision/aiframediff.pas', 'aiframediff_icon.lrs'),
        # AI Simulation
        ('AI Simulation/aigridworld.pas', 'aigridworld_icon.lrs'),
        ('AI Simulation/aisimentity.pas', 'aisimentity_icon.lrs'),
        ('AI Simulation/aientityfactory.pas', 'aientityfactory_icon.lrs'),
        ('AI Simulation/aisimulationengine.pas', 'aisimulationengine_icon.lrs'),
        ('AI Simulation/airuleengine.pas', 'airuleengine_icon.lrs'),
        ('AI Simulation/aitriggerengine.pas', 'aitriggerengine_icon.lrs'),
        ('AI Simulation/aimovementengine.pas', 'aimovementengine_icon.lrs'),
        ('AI Simulation/aievolutionengine.pas', 'aievolutionengine_icon.lrs'),
        ('AI Simulation/aisimulationstats.pas', 'aisimulationstats_icon.lrs'),
        ('AI Simulation/aigridrenderer2d.pas', 'aigridrenderer2d_icon.lrs'),
        ('AI Simulation/aiscenarioconfig.pas', 'aiscenarioconfig_icon.lrs'),
        ('AI Simulation/aiscenariogenerator.pas', 'aiscenariogenerator_icon.lrs'),
        ('AI Simulation/aisimulationexporter.pas', 'aisimulationexporter_icon.lrs'),
    ]
    
    for pas_rel_path, lrs_filename in patches:
        full_pas_path = os.path.join(package_root, pas_rel_path)
        patch_pas_file(full_pas_path, lrs_filename)
        
    print("Done generating and patching!")

if __name__ == '__main__':
    main()