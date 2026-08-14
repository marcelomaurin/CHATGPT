import os
import re
from pathlib import Path

# Complete 5x5 font definition: A-Z, 0-9
font = {
    'A': [[0,1,1,1,0],[1,0,0,0,1],[1,1,1,1,1],[1,0,0,0,1],[1,0,0,0,1]],
    'B': [[1,1,1,1,0],[1,0,0,0,1],[1,1,1,1,0],[1,0,0,0,1],[1,1,1,1,0]],
    'C': [[0,1,1,1,1],[1,0,0,0,0],[1,0,0,0,0],[1,0,0,0,0],[0,1,1,1,1]],
    'D': [[1,1,1,1,0],[1,0,0,0,1],[1,0,0,0,1],[1,0,0,0,1],[1,1,1,1,0]],
    'E': [[1,1,1,1,1],[1,0,0,0,0],[1,1,1,1,0],[1,0,0,0,0],[1,1,1,1,1]],
    'F': [[1,1,1,1,1],[1,0,0,0,0],[1,1,1,1,0],[1,0,0,0,0],[1,0,0,0,0]],
    'G': [[0,1,1,1,1],[1,0,0,0,0],[1,0,1,1,1],[1,0,0,0,1],[0,1,1,1,0]],
    'H': [[1,0,0,0,1],[1,0,0,0,1],[1,1,1,1,1],[1,0,0,0,1],[1,0,0,0,1]],
    'I': [[0,1,1,1,0],[0,0,1,0,0],[0,0,1,0,0],[0,0,1,0,0],[0,1,1,1,0]],
    'J': [[0,0,0,0,1],[0,0,0,0,1],[0,0,0,0,1],[1,0,0,0,1],[0,1,1,1,0]],
    'K': [[1,0,0,0,1],[1,0,1,0,0],[1,1,0,0,0],[1,0,1,0,0],[1,0,0,0,1]],
    'L': [[1,0,0,0,0],[1,0,0,0,0],[1,0,0,0,0],[1,0,0,0,0],[1,1,1,1,1]],
    'M': [[1,0,0,0,1],[1,1,0,1,1],[1,0,1,0,1],[1,0,0,0,1],[1,0,0,0,1]],
    'N': [[1,0,0,0,1],[1,1,0,0,1],[1,0,1,0,1],[1,0,0,1,1],[1,0,0,0,1]],
    'O': [[0,1,1,1,0],[1,0,0,0,1],[1,0,0,0,1],[1,0,0,0,1],[0,1,1,1,0]],
    'P': [[1,1,1,1,0],[1,0,0,0,1],[1,1,1,1,0],[1,0,0,0,0],[1,0,0,0,0]],
    'Q': [[0,1,1,1,0],[1,0,0,0,1],[1,0,1,0,1],[1,0,0,1,0],[0,1,1,0,1]],
    'R': [[1,1,1,1,0],[1,0,0,0,1],[1,1,1,1,0],[1,0,0,1,0],[1,0,0,0,1]],
    'S': [[0,1,1,1,1],[1,0,0,0,0],[0,1,1,1,0],[0,0,0,0,1],[1,1,1,1,0]],
    'T': [[1,1,1,1,1],[0,0,1,0,0],[0,0,1,0,0],[0,0,1,0,0],[0,0,1,0,0]],
    'U': [[1,0,0,0,1],[1,0,0,0,1],[1,0,0,0,1],[1,0,0,0,1],[0,1,1,1,0]],
    'V': [[1,0,0,0,1],[1,0,0,0,1],[0,1,0,1,0],[0,1,0,1,0],[0,0,1,0,0]],
    'W': [[1,0,0,0,1],[1,0,0,0,1],[1,0,1,0,1],[1,1,0,1,1],[1,0,0,0,1]],
    'X': [[1,0,0,0,1],[0,1,0,1,0],[0,0,1,0,0],[0,1,0,1,0],[1,0,0,0,1]],
    'Y': [[1,0,0,0,1],[0,1,0,1,0],[0,0,1,0,0],[0,0,1,0,0],[0,0,1,0,0]],
    'Z': [[1,1,1,1,1],[0,0,0,1,0],[0,0,1,0,0],[0,1,0,0,0],[1,1,1,1,1]],
    '0': [[0,1,1,1,0],[1,0,0,1,1],[1,0,1,0,1],[1,1,0,0,1],[0,1,1,1,0]],
    '1': [[0,0,1,0,0],[0,1,1,0,0],[0,0,1,0,0],[0,0,1,0,0],[0,1,1,1,0]],
    '2': [[1,1,1,1,0],[0,0,0,0,1],[0,1,1,1,0],[1,0,0,0,0],[1,1,1,1,1]],
    '3': [[1,1,1,1,0],[0,0,0,0,1],[0,1,1,1,0],[0,0,0,0,1],[1,1,1,1,0]],
    '4': [[1,0,0,1,0],[1,0,0,1,0],[1,1,1,1,1],[0,0,0,1,0],[0,0,0,1,0]],
    '5': [[1,1,1,1,1],[1,0,0,0,0],[1,1,1,1,0],[0,0,0,0,1],[1,1,1,1,0]],
    '6': [[0,1,1,1,0],[1,0,0,0,0],[1,1,1,1,0],[1,0,0,0,1],[0,1,1,1,0]],
    '7': [[1,1,1,1,1],[0,0,0,1,0],[0,0,1,0,0],[0,1,0,0,0],[0,1,0,0,0]],
    '8': [[0,1,1,1,0],[1,0,0,0,1],[0,1,1,1,0],[1,0,0,0,1],[0,1,1,1,0]],
    '9': [[0,1,1,1,0],[1,0,0,0,1],[0,1,1,1,1],[0,0,0,0,1],[0,1,1,1,0]],
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
    label = label.upper()
    pixels = []
    for y in range(24):
        for x in range(24):
            if 3 <= x <= 20 and 3 <= y <= 20:
                # Border (2px border for strong visual crispness)
                if x in (3, 20) or y in (3, 20):
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
                        pixels.extend([20, 20, 20]) # dark text
                    else:
                        pixels.extend([242, 244, 246]) # modern light gray fill
            else:
                pixels.extend([255, 255, 255]) # white outer canvas
    return pixels

# Palette Colors per functional category
C_AGENT         = [220, 50, 50]    # Crimson Red - Agents, Guardrails, Dev Agents
C_CORE          = [20, 120, 230]   # Modern Blue - Core LLM, ChatGPT, UnifiedLLM
C_A2A           = [170, 40, 160]   # Magenta / Violet - Agent-to-Agent Client/Server
C_MCP           = [75, 70, 210]    # Deep Indigo - Model Context Protocol
C_DBASE         = [190, 110, 20]   # Amber / Orange-Brown - Database Dictionaries
C_EVAL          = [130, 50, 190]   # Purple / Violet - LLM Evaluation & Judges
C_FILES         = [30, 160, 110]   # Emerald / Forest Green - File & Document Management
C_GRAPH         = [80, 100, 240]   # Cobalt Blue - Graphs, Routes, Maps
C_HARDWARE      = [230, 95, 25]    # Copper / Rust Orange - Hardware (Disk, GPU, Memory, OS)
C_INDUSTRIAL    = [40, 145, 65]    # Industrial Green - Modbus, Arm Robot, Pinmaps
C_INPUT         = [50, 175, 50]    # Vibrant Green - Input sources, USB, Audio, Cameras
C_OUTPUT        = [45, 95, 215]    # Royal Blue - Outputs, Document Generators, Viewers
C_VOICE         = [235, 125, 20]   # Amber Orange - Speech, Synthesis, Whisper, Voice Clone
C_MATH          = [150, 50, 200]   # Violet - Math, NumPy, Matrix
C_GRAPHIC       = [180, 70, 180]   # Pinkish Magenta - 3D Graphics, Avatars, Physics
C_VISION        = [0, 150, 160]    # Teal / Cyan - Computer Vision, OpenCV, MediaPipe
C_SIMULATION    = [20, 140, 120]   # Sea Green - Simulation, GridWorld, Scenarios
C_ML            = [250, 120, 0]    # Deep Amber - ML models, perceptrons
C_PROJECT       = [50, 175, 175]   # Soft Cyan - Project Management
C_OBSERVABILITY = [140, 40, 180]   # Lavender Purple - Traces, Observability
C_RAG           = [25, 155, 185]   # Azure Cyan - RAG retrieval & indexing
C_SAMPLE        = [120, 120, 120]  # Neutral Gray - General Samples

icons_config = {
    # AI Core
    'AI/chatgpt_icon.lrs': [
        ('tchatgpt', C_CORE, 'GP'),
    ],
    'AI/aiunifiedllm_icon.lrs': [
        ('taiunifiedllm', C_CORE, 'UL'),
    ],
    'AI/aimodelrouter_icon.lrs': [
        ('taimodelrouter', C_CORE, 'MR'),
    ],
    'AI/aiproject_icon.lrs': [
        ('taiproject', C_PROJECT, 'PJ'),
    ],
    'AI/aipipeline_icon.lrs': [
        ('taipipeline', C_PROJECT, 'PL'),
    ],
    'AI/aipromptbuilder_icon.lrs': [
        ('taipromptbuilder', C_PROJECT, 'PB'),
    ],
    'AI/aimodelregistry_icon.lrs': [
        ('taimodelregistry', C_PROJECT, 'RG'),
    ],
    'AI/aiwizardconfig_icon.lrs': [
        ('taiwizardconfig', C_PROJECT, 'WC'),
    ],
    'AI/matrizcomponent_icon.lrs': [
        ('tamatrizcomponent', C_ML, 'MC'),
    ],

    # AI A2A
    'AI A2A/aia2a_icon.lrs': [
        ('taia2aclient', C_A2A, '2C'),
    ],
    'AI A2A/aia2aserver_icon.lrs': [
        ('taia2aserver', C_A2A, '2S'),
    ],

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
    'AI Agent/aiagentgraph_icon.lrs': [
        ('taiagentgraph', C_AGENT, 'GR'),
    ],
    'AI Agent/aiagent_sourceactions_icon.lrs': [
        ('taisourcereadaction', C_AGENT, 'SR'),
        ('taisourcereplaceaction', C_AGENT, 'SP'),
        ('taiprojectbuildaction', C_AGENT, 'PB'),
    ],
    'AI Agent/aiagent_testaction_icon.lrs': [
        ('taitrustedprojecttestaction', C_AGENT, 'TT'),
    ],
    'AI Agent/aicommonserviceagents_icon.lrs': [
        ('taigitlabagent', C_AGENT, 'GL'),
        ('taitelegramagent', C_AGENT, 'TG'),
        ('taiemailagent', C_AGENT, 'EA'),
        ('tairssagent', C_AGENT, 'RS'),
        ('taiwebagent', C_AGENT, 'WA'),
        ('taisshagent', C_AGENT, 'SH'),
        ('taidatabaseagent', C_AGENT, 'DA'),
        ('taiwhatsappagent', C_AGENT, 'WP'),
    ],
    'AI Agent/aidevagents_icon.lrs': [
        ('taisourceagent', C_AGENT, 'SA'),
        ('tailazarusbuildagent', C_AGENT, 'LB'),
        ('taitestagent', C_AGENT, 'TA'),
        ('tainetworkagent', C_AGENT, 'NA'),
    ],
    'AI Agent/aiguardrails_icon.lrs': [
        ('taiinputguardrail', C_AGENT, 'IG'),
        ('taioutputguardrail', C_AGENT, 'OG'),
        ('taitoolguardrail', C_AGENT, 'TG'),
    ],
    'AI Agent/airosagent_icon.lrs': [
        ('tairosagent', C_AGENT, 'RO'),
        ('tairobotagent', C_AGENT, 'RB'),
    ],
    'AI Agent/aiserviceagents_icon.lrs': [
        ('taigithubagent', C_AGENT, 'GH'),
        ('taifacebookagent', C_AGENT, 'FB'),
        ('taiyoutubeagent', C_AGENT, 'YT'),
    ],
    'AI Agent/aitools_icon.lrs': [
        ('taitoolregistry', C_AGENT, 'TR'),
    ],

    # AI DBase
    'AI DBase/aidb_register_icon.lrs': [
        ('taipostgresqldictionary', C_DBASE, 'PG'),
        ('taimysqldictionary', C_DBASE, 'MY'),
        ('taisqlitedictionary', C_DBASE, 'SL'),
        ('taifirebirddictionary', C_DBASE, 'FB'),
        ('taisqlserverdictionary', C_DBASE, 'SS'),
        ('taioracledictionary', C_DBASE, 'OR'),
    ],

    # AI Evaluation
    'AI Evaluation/aievaluation_icon.lrs': [
        ('taievaluationdataset', C_EVAL, 'ED'),
        ('tailexicalevaluator', C_EVAL, 'LE'),
        ('taillmjudge', C_EVAL, 'LJ'),
        ('tairegressionreporter', C_EVAL, 'RR'),
    ],

    # AI Files
    'AI Files/ai_docfilesmanager_icon.lrs': [
        ('tai_docfilesmanager', C_FILES, 'DF'),
    ],
    'AI Files/aidisktreescanner_icon.lrs': [
        ('taidisktreescanner', C_FILES, 'TS'),
    ],

    # AI Graph
    'AI Graph/aidependencygraph_icon.lrs': [
        ('taidependencygraph', C_GRAPH, 'DG'),
    ],
    'AI Graph/aigeojsonrouteimporter_icon.lrs': [
        ('taigeojsonrouteimporter', C_GRAPH, 'GJ'),
    ],
    'AI Graph/aigraphstructuraladapter_icon.lrs': [
        ('taigraphstructuraladapter', C_GRAPH, 'GS'),
    ],
    'AI Graph/airoutecalculator_icon.lrs': [
        ('tairoutecalculator', C_GRAPH, 'RC'),
    ],
    'AI Graph/airoutecityindex_icon.lrs': [
        ('tairoutecityindex', C_GRAPH, 'CI'),
    ],
    'AI Graph/airoutegraph_icon.lrs': [
        ('tairoutegraph', C_GRAPH, 'RG'),
    ],
    'AI Graph/airoutespeedprofile_icon.lrs': [
        ('tairoutespeedprofile', C_GRAPH, 'SP'),
    ],
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

    # AI Hardware
    'AI Hardware/aidisk_icon.lrs': [
        ('taidisk', C_HARDWARE, 'DK'),
    ],
    'AI Hardware/aigpu_icon.lrs': [
        ('taigpu', C_HARDWARE, 'GP'),
    ],
    'AI Hardware/ailistprinters_icon.lrs': [
        ('tailistprinters', C_HARDWARE, 'LP'),
    ],
    'AI Hardware/aimemory_icon.lrs': [
        ('taimemory', C_HARDWARE, 'ME'),
    ],
    'AI Hardware/aiso_icon.lrs': [
        ('taios', C_HARDWARE, 'OS'),
    ],
    'AI Hardware/ai_tasks_icon.lrs': [
        ('taitasks', C_HARDWARE, 'TK'),
    ],

    # AI Industrial
    'AI Industrial/aiarduinomodbuspinmap_icon.lrs': [
        ('taiarduinomodbuspinmap', C_INDUSTRIAL, 'PM'),
    ],
    'AI Industrial/aiarm_robot_icon.lrs': [
        ('tai_arm_robot', C_INDUSTRIAL, 'AR'),
        ('tai_arm_robotviewer', C_INDUSTRIAL, 'AV'),
        ('tai_arm_robotposition', C_INDUSTRIAL, 'AP'),
    ],
    'AI Industrial/aiarm_robotcontrol_icon.lrs': [
        ('tai_arm_robotcontrol', C_INDUSTRIAL, 'AC'),
    ],
    'AI Industrial/aimodbuscommandmap_icon.lrs': [
        ('taimodbuscommandmap', C_INDUSTRIAL, 'CM'),
    ],
    'AI Industrial/aiposprinter_icon.lrs': [
        ('taiposprinter', C_INDUSTRIAL, 'PR'),
    ],
    'AI Industrial/aimodbus_icon.lrs': [
        ('taimodbusclient', C_INDUSTRIAL, 'MB'),
    ],
    'AI Industrial/aimqtt_icon.lrs': [
        ('taimqttclient', C_INDUSTRIAL, 'MQ'),
    ],
    'AI Industrial/aiindustrial_icon.lrs': [
        ('taiindustrialbridge', C_INDUSTRIAL, 'ID'),
    ],

    # AI Input
    'AI Input/AIInput/aiinput_icon.lrs': [
        ('taiinputdata', C_INPUT, 'IN'),
    ],
    'AI Input/AICaptureSource/aicapturesource_icon.lrs': [
        ('taicapturesource', C_INPUT, 'CS'),
    ],
    'AI Input/AIAudio/aiaudio_icon.lrs': [
        ('taiaudioinput', C_INPUT, 'AD'),
    ],
    'AI Input/AIWebServer/aiwebserver_icon.lrs': [
        ('taiwebapiserver', C_INPUT, 'WS'),
    ],
    'AI Input/AISockets/aisockets_icon.lrs': [
        ('taisockettcp', C_INPUT, 'TC'),
        ('taisocketudp', C_INPUT, 'UD'),
    ],
    'AI Input/AISerial/aiserial_icon.lrs': [
        ('taiserialmodem', C_INPUT, 'SR'),
        ('tailistserialdevices', C_INPUT, 'SD'),
    ],
    'AI Input/AIUSB/aiusb_icon.lrs': [
        ('taiusb', C_INPUT, 'UB'),
    ],
    'AI Input/AIUSB/aiusb_register_icon.lrs': [
        ('taiusb', C_INPUT, 'US'),
    ],
    'AI Input/AIEmail/aiemail_icon.lrs': [
        ('taiemailclient', C_INPUT, 'EM'),
    ],
    'AI Input/AIMessenger/aimessenger_icon.lrs': [
        ('taimessenger', C_INPUT, 'MS'),
    ],
    'AI Input/AIChromiumBrowser/aichromiumbrowser_icon.lrs': [
        ('taichromiumbrowser', C_INPUT, 'CR'),
    ],
    'AI Input/AIKinect/aikinect_icon.lrs': [
        ('taikinectsensor', C_INPUT, 'KS'),
        ('taikinectcolorstream', C_INPUT, 'KC'),
        ('taikinectdepthstream', C_INPUT, 'KD'),
        ('taikinectskeleton', C_INPUT, 'KK'),
        ('taikinectaudio', C_INPUT, 'KA'),
    ],
    'AI Input/aidocumentreader_icon.lrs': [
        ('taidocumentinput', C_INPUT, 'DI'),
    ],
    'AI Input/aidocxinput_icon.lrs': [
        ('taidocxinput', C_INPUT, 'DX'),
    ],
    'AI Input/aiexcelinput_icon.lrs': [
        ('taiexcelinput', C_INPUT, 'XI'),
    ],
    'AI Input/aipdfinput_icon.lrs': [
        ('taipdfinput', C_INPUT, 'PI'),
    ],

    # AI MCP
    'AI MCP/aimcp_icon.lrs': [
        ('taimcpclient', C_MCP, 'MC'),
        ('taimcpserver', C_MCP, 'MS'),
        ('taimcptoolregistrybridge', C_MCP, 'MB'),
    ],

    # AI Observability
    'AI Observability/aitrace_icon.lrs': [
        ('taitrace', C_OBSERVABILITY, 'TR'),
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
    'AI Output/aiworddocument_icon.lrs': [
        ('taiworddocument', C_OUTPUT, 'WD'),
    ],
    'AI Output/aiwordviewer_icon.lrs': [
        ('taiwordviewer', C_OUTPUT, 'WV'),
    ],

    # AI RAG
    'AI RAG/airag_icon.lrs': [
        ('tairag', C_RAG, 'RG'),
    ],

    # AI Voice
    'AI Voice/aiaudioplayback_icon.lrs': [
        ('taiaudioplayer', C_VOICE, 'AP'),
    ],
    'AI Voice/aif5ttsengine_icon.lrs': [
        ('taif5ttsprocessengine', C_VOICE, 'F5'),
    ],
    'AI Voice/aispeechrecognizer_icon.lrs': [
        ('taispeechrecognizer', C_VOICE, 'SR'),
    ],
    'AI Voice/aivoiceassistant_icon.lrs': [
        ('taivoiceassistant', C_VOICE, 'VA'),
    ],
    'AI Voice/aivoiceclone_icon.lrs': [
        ('taivoiceclone', C_VOICE, 'VC'),
    ],
    'AI Voice/aivoicerecognizer_icon.lrs': [
        ('taivoicerecognizer', C_VOICE, 'VR'),
    ],
    'AI Voice/aiwhisperengine_icon.lrs': [
        ('taiwhisperprocessengine', C_VOICE, 'WH'),
    ],
    'AI Voice/aivoicesynthesizer_icon.lrs': [
        ('taivoicesynthesizer', C_VOICE, 'VS'),
    ],

    # AI Math
    'AI Math/numps_icon.lrs': [
        ('tnumps', C_MATH, 'MA'),
    ],

    # AI Python
    'python/aipythonruntime_icon.lrs': [
        ('taipythonruntime', C_MATH, 'PR'),
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
        ('taicameracapture', C_VISION, 'CC'),
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

    # Root Sample
    'compchatgpt_icon.lrs': [
        ('tmycomponent', C_SAMPLE, 'MC'),
    ],
}

patches = [
    # AI Core
    ('AI/chatgpt.pas', 'chatgpt_icon.lrs'),
    ('AI/aiunifiedllm.pas', 'aiunifiedllm_icon.lrs'),
    ('AI/aimodelrouter.pas', 'aimodelrouter_icon.lrs'),
    ('AI/aiproject.pas', 'aiproject_icon.lrs'),
    ('AI Agent/aipipeline.pas', 'aipipeline_icon.lrs'),
    ('AI/aipromptbuilder.pas', 'aipromptbuilder_icon.lrs'),
    ('AI/aimodelregistry.pas', 'aimodelregistry_icon.lrs'),
    ('AI Agent/aiwizardconfig.pas', 'aiwizardconfig_icon.lrs'),
    ('AI/matrizcomponent.pas', 'matrizcomponent_icon.lrs'),

    # AI A2A
    ('AI A2A/aia2a.pas', 'aia2a_icon.lrs'),
    ('AI A2A/aia2aserver.pas', 'aia2aserver_icon.lrs'),

    # AI Agent
    ('AI Agent/aiagent.pas', 'aiagent_icon.lrs'),
    ('AI Agent/aiagentsafety.pas', 'aiagentsafety_icon.lrs'),
    ('AI Agent/aiagentgraph.pas', 'aiagentgraph_icon.lrs'),
    ('AI Agent/aiagent_sourceactions.pas', 'aiagent_sourceactions_icon.lrs'),
    ('AI Agent/aiagent_testaction.pas', 'aiagent_testaction_icon.lrs'),
    ('AI Agent/aicommonserviceagents.pas', 'aicommonserviceagents_icon.lrs'),
    ('AI Agent/aidevagents.pas', 'aidevagents_icon.lrs'),
    ('AI Agent/aiguardrails.pas', 'aiguardrails_icon.lrs'),
    ('AI Agent/airosagent.pas', 'airosagent_icon.lrs'),
    ('AI Agent/aiserviceagents.pas', 'aiserviceagents_icon.lrs'),
    ('AI Agent/aitools.pas', 'aitools_icon.lrs'),

    # AI DBase
    ('AI DBase/aidb_register.pas', 'aidb_register_icon.lrs'),

    # AI Evaluation
    ('AI Evaluation/aievaluation.pas', 'aievaluation_icon.lrs'),

    # AI Files
    ('AI Files/ai_docfilesmanager.pas', 'ai_docfilesmanager_icon.lrs'),
    ('AI Files/aidisktreescanner.pas', 'aidisktreescanner_icon.lrs'),

    # AI Graph
    ('AI Graph/aidependencygraph.pas', 'aidependencygraph_icon.lrs'),
    ('AI Graph/aigeojsonrouteimporter.pas', 'aigeojsonrouteimporter_icon.lrs'),
    ('AI Graph/aigraphstructuraladapter.pas', 'aigraphstructuraladapter_icon.lrs'),
    ('AI Graph/airoutecalculator.pas', 'airoutecalculator_icon.lrs'),
    ('AI Graph/airoutecityindex.pas', 'airoutecityindex_icon.lrs'),
    ('AI Graph/airoutegraph.pas', 'airoutegraph_icon.lrs'),
    ('AI Graph/airoutespeedprofile.pas', 'airoutespeedprofile_icon.lrs'),
    ('AI Graph/aigraphmap.pas', 'aigraphmap_icon.lrs'),
    ('AI Graph/aitrainingexporter.pas', 'aitrainingexporter_icon.lrs'),
    ('AI Graph/aidatasetanalyzer.pas', 'aidatasetanalyzer_icon.lrs'),
    ('AI Graph/aitrainingreport.pas', 'aitrainingreport_icon.lrs'),
    ('AI Graph/aigraphvisualizer.pas', 'aigraphvisualizer_icon.lrs'),

    # AI Hardware
    ('AI Hardware/aidisk.pas', 'aidisk_icon.lrs'),
    ('AI Hardware/aigpu.pas', 'aigpu_icon.lrs'),
    ('AI Hardware/ailistprinters.pas', 'ailistprinters_icon.lrs'),
    ('AI Hardware/aimemory.pas', 'aimemory_icon.lrs'),
    ('AI Hardware/aiso.pas', 'aiso_icon.lrs'),
    ('AI Hardware/ai_tasks.pas', 'ai_tasks_icon.lrs'),

    # AI Industrial
    ('AI Industrial/aiarduinomodbuspinmap.pas', 'aiarduinomodbuspinmap_icon.lrs'),
    ('AI Industrial/aiarm_robot.pas', 'aiarm_robot_icon.lrs'),
    ('AI Industrial/aiarm_robotcontrol.pas', 'aiarm_robotcontrol_icon.lrs'),
    ('AI Industrial/aimodbuscommandmap.pas', 'aimodbuscommandmap_icon.lrs'),
    ('AI Industrial/aiposprinter.pas', 'aiposprinter_icon.lrs'),
    ('AI Industrial/aimodbus.pas', 'aimodbus_icon.lrs'),
    ('AI Industrial/aimqtt.pas', 'aimqtt_icon.lrs'),
    ('AI Industrial/aiindustrial.pas', 'aiindustrial_icon.lrs'),

    # AI Input
    ('AI Input/AIInput/aiinput.pas', 'aiinput_icon.lrs'),
    ('AI Input/AICaptureSource/aicapturesource.pas', 'aicapturesource_icon.lrs'),
    ('AI Input/AIAudio/aiaudio.pas', 'aiaudio_icon.lrs'),
    ('AI Input/AIWebServer/aiwebserver.pas', 'aiwebserver_icon.lrs'),
    ('AI Input/AISockets/aisockets.pas', 'aisockets_icon.lrs'),
    ('AI Input/AISerial/aiserial.pas', 'aiserial_icon.lrs'),
    ('AI Input/AISerial/ailistserialdevices.pas', 'aiserial_icon.lrs'),
    ('AI Input/AIUSB/aiusb.pas', 'aiusb_icon.lrs'),
    ('AI Input/AIUSB/aiusb_register.pas', 'aiusb_register_icon.lrs'),
    ('AI Input/AIEmail/aiemail.pas', 'aiemail_icon.lrs'),
    ('AI Input/AIMessenger/aimessenger.pas', 'aimessenger_icon.lrs'),
    ('AI Input/AIChromiumBrowser/aichromiumbrowser.pas', 'aichromiumbrowser_icon.lrs'),
    ('AI Input/AIKinect/aikinectsensor.pas', 'aikinect_icon.lrs'),
    ('AI Input/AIKinect/aikinectcolor.pas', 'aikinect_icon.lrs'),
    ('AI Input/AIKinect/aikinectdepth.pas', 'aikinect_icon.lrs'),
    ('AI Input/AIKinect/aikinectskeleton.pas', 'aikinect_icon.lrs'),
    ('AI Input/AIKinect/aikinectaudio.pas', 'aikinect_icon.lrs'),
    ('AI Input/aidocumentreader.pas', 'aidocumentreader_icon.lrs'),
    ('AI Input/aidocxinput.pas', 'aidocxinput_icon.lrs'),
    ('AI Input/aiexcelinput.pas', 'aiexcelinput_icon.lrs'),
    ('AI Input/aipdfinput.pas', 'aipdfinput_icon.lrs'),

    # AI MCP
    ('AI MCP/aimcp.pas', 'aimcp_icon.lrs'),

    # AI Observability
    ('AI Observability/aitrace.pas', 'aitrace_icon.lrs'),

    # AI Output
    ('AI Output/aioutput.pas', 'aioutput_icon.lrs'),
    ('AI Output/aioutput_docs.pas', 'aioutput_docs_icon.lrs'),
    ('AI Output/aiworddocument.pas', 'aiworddocument_icon.lrs'),
    ('AI Output/aiwordviewer.pas', 'aiwordviewer_icon.lrs'),

    # AI RAG
    ('AI RAG/airag.pas', 'airag_icon.lrs'),

    # AI Voice
    ('AI Voice/aiaudioplayback.pas', 'aiaudioplayback_icon.lrs'),
    ('AI Voice/aif5ttsengine.pas', 'aif5ttsengine_icon.lrs'),
    ('AI Voice/aispeechrecognizer.pas', 'aispeechrecognizer_icon.lrs'),
    ('AI Voice/aivoiceassistant.pas', 'aivoiceassistant_icon.lrs'),
    ('AI Voice/aivoiceclone.pas', 'aivoiceclone_icon.lrs'),
    ('AI Voice/aivoicerecognizer.pas', 'aivoicerecognizer_icon.lrs'),
    ('AI Voice/aiwhisperengine.pas', 'aiwhisperengine_icon.lrs'),
    ('AI Voice/aivoicesynthesizer.pas', 'aivoicesynthesizer_icon.lrs'),

    # AI Math
    ('AI Math/numps.pas', 'numps_icon.lrs'),

    # AI Python
    ('python/aipythonruntime.pas', 'aipythonruntime_icon.lrs'),

    # AI Graphic
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

    # AI Vision
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

    # Root Sample
    ('compchatgpt.pas', 'compchatgpt_icon.lrs'),
]

def patch_pas_file(file_path, lrs_filename):
    if not os.path.exists(file_path):
        print(f"Pascal file not found: {file_path}")
        return
        
    with open(file_path, 'r', encoding='utf-8') as f:
        original_content = f.read()
        
    content = original_content
        
    # 1. Patch uses clause to add LResources if missing anywhere in file
    if not re.search(r'\bLResources\b', content, re.IGNORECASE):
        uses_match = re.search(r'\buses\b([\s\S]*?);', content, re.IGNORECASE)
        if uses_match:
            uses_clause = uses_match.group(1)
            # Insert LResources right before the trailing semicolon
            uses_end_pos = uses_match.end(1)
            separator = ', ' if len(uses_clause.strip()) > 0 else ''
            content = content[:uses_end_pos] + separator + 'LResources' + content[uses_end_pos:]
            print(f"Added LResources to uses clause in {file_path}")
            
    # 2. Check if resource file is already included
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
        os.makedirs(os.path.dirname(full_lrs_path), exist_ok=True)
        with open(full_lrs_path, 'w', encoding='utf-8') as f:
            f.write("\n".join(lrs_contents) + "\n")
        print(f"Generated LRS: {full_lrs_path}")
        
    # 2. Patch Pascal source files
    for pas_rel_path, lrs_filename in patches:
        full_pas_path = os.path.join(package_root, pas_rel_path)
        patch_pas_file(full_pas_path, lrs_filename)
        
    print("Done generating and patching all component icons!")

if __name__ == '__main__':
    main()