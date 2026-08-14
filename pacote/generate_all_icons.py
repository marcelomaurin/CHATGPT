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
                if x in (3, 20) or y in (3, 20):
                    pixels.extend(border_color)
                else:
                    char1 = label[0] if len(label) > 0 else ' '
                    char2 = label[1] if len(label) > 1 else ' '
                    
                    is_pixel_on = False
                    if 6 <= x <= 10 and 9 <= y <= 13:
                        grid = font.get(char1, font['A'])
                        if grid[y - 9][x - 6] == 1:
                            is_pixel_on = True
                            
                    if 12 <= x <= 16 and 9 <= y <= 13:
                        grid = font.get(char2, font['A'])
                        if grid[y - 9][x - 12] == 1:
                            is_pixel_on = True
                            
                    if is_pixel_on:
                        pixels.extend([20, 24, 35])
                    else:
                        pixels.extend([255, 255, 255])
            else:
                pixels.extend([192, 192, 192])
    return pixels

# Visual palette tokens for all packages
C_CORE       = [50, 150, 255]
C_AGENT      = [180, 100, 240]
C_A2A        = [240, 120, 80]
C_MCP        = [230, 80, 180]
C_DBASE      = [80, 200, 120]
C_EVAL       = [250, 180, 40]
C_FILES      = [100, 180, 240]
C_GRAPH      = [140, 220, 80]
C_HARDWARE   = [240, 80, 80]
C_INDUSTRIAL = [255, 140, 0]
C_INPUT      = [60, 200, 220]
C_OUTPUT     = [160, 120, 240]
C_VOICE      = [255, 100, 160]
C_MATH       = [120, 140, 255]
C_GRAPHIC    = [240, 200, 60]
C_VISION     = [80, 220, 160]
C_SIMULATION = [100, 220, 240]
C_ML         = [220, 100, 100]
C_PROJECT    = [100, 140, 220]
C_OBSERVABILITY = [180, 180, 180]
C_RAG        = [80, 160, 240]
C_SAMPLE     = [120, 200, 80]

icons_config = {
    'AI A2A/aia2a_icon.lrs': [
        ('taia2aclient', C_A2A, 'AA'),
    ],
    'AI A2A/aia2aserver_icon.lrs': [
        ('taia2aserver', C_A2A, 'AA'),
    ],
    'AI Agent/aiagent_icon.lrs': [
        ('taiagent', C_AGENT, 'AG'),
        ('taiagentoptions', C_AGENT, 'AO'),
        ('taiagentaction', C_AGENT, 'AA'),
        ('taiagentresource', C_AGENT, 'AR'),
        ('taiagentoutput', C_AGENT, 'AO'),
    ],
    'AI Agent/aiagent_memorymap_icon.lrs': [
        ('taiagentmemorymap', C_AGENT, 'AM'),
    ],
    'AI Agent/aiagent_orchestrator_icon.lrs': [
        ('taiagentorchestrator', C_AGENT, 'AO'),
        ('taiclassifieragent', C_AGENT, 'CA'),
        ('taidecisionagent', C_AGENT, 'DA'),
        ('taiactionbuilderagent', C_AGENT, 'AB'),
        ('taiactionexecutor', C_AGENT, 'AE'),
    ],
    'AI Agent/aiagent_sourceactions_icon.lrs': [
        ('taisourcereadaction', C_AGENT, 'SR'),
        ('taisourcereplaceaction', C_AGENT, 'SR'),
        ('taiprojectbuildaction', C_AGENT, 'PB'),
    ],
    'AI Agent/aiagent_testaction_icon.lrs': [
        ('taitrustedprojecttestaction', C_AGENT, 'TP'),
    ],
    'AI Agent/aiagentgraph_icon.lrs': [
        ('taiagentgraph', C_AGENT, 'AG'),
    ],
    'AI Agent/aiagentsafety_icon.lrs': [
        ('taiagentsafety', C_AGENT, 'AS'),
    ],
    'AI Agent/aiagentserial_icon.lrs': [
        ('taiagentserial', C_AGENT, 'AS'),
    ],
    'AI Agent/aicommonserviceagents_icon.lrs': [
        ('taigitlabagent', C_AGENT, 'GL'),
        ('taitelegramagent', C_AGENT, 'TA'),
        ('taiemailagent', C_AGENT, 'EA'),
        ('tairssagent', C_AGENT, 'RS'),
        ('taiwebagent', C_AGENT, 'WA'),
        ('taisshagent', C_AGENT, 'SS'),
        ('taidatabaseagent', C_AGENT, 'DA'),
        ('taiwhatsappagent', C_AGENT, 'WA'),
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
    'AI Agent/aipipeline_icon.lrs': [
        ('taipipeline', C_AGENT, 'PI'),
    ],
    'AI Agent/airosagent_icon.lrs': [
        ('tairosagent', C_AGENT, 'RO'),
        ('tairobotagent', C_AGENT, 'RA'),
    ],
    'AI Agent/aiserviceagents_icon.lrs': [
        ('taigithubagent', C_AGENT, 'GH'),
        ('taifacebookagent', C_AGENT, 'FA'),
        ('taiyoutubeagent', C_AGENT, 'YT'),
    ],
    'AI Agent/aitools_icon.lrs': [
        ('taitoolregistry', C_AGENT, 'TR'),
    ],
    'AI Agent/aiwizardconfig_icon.lrs': [
        ('taiwizardconfig', C_AGENT, 'WC'),
    ],
    'AI DBase/aidb_register_icon.lrs': [
        ('taipostgresqldictionary', C_DBASE, 'PS'),
        ('taimysqldictionary', C_DBASE, 'MS'),
        ('taisqlitedictionary', C_DBASE, 'SQ'),
        ('taifirebirddictionary', C_DBASE, 'FD'),
        ('taisqlserverdictionary', C_DBASE, 'SQ'),
        ('taioracledictionary', C_DBASE, 'OD'),
    ],
    'AI DBase/aidbase_icon.lrs': [
        ('taidbase', C_DBASE, 'DB'),
    ],
    'AI Evaluation/aievaluation_icon.lrs': [
        ('taievaluationdataset', C_EVAL, 'ED'),
        ('tailexicalevaluator', C_EVAL, 'LE'),
        ('taillmjudge', C_EVAL, 'LL'),
        ('tairegressionreporter', C_EVAL, 'RR'),
    ],
    'AI Files/ai_docfilesmanager_icon.lrs': [
        ('tai_docfilesmanager', C_FILES, 'DO'),
    ],
    'AI Files/aidisktreescanner_icon.lrs': [
        ('taidisktreescanner', C_FILES, 'DT'),
    ],
    'AI Filtros Sonoros/soundfilters_icon.lrs': [
        ('tlowpassfilter', C_VOICE, 'LP'),
        ('thighpassfilter', C_VOICE, 'HP'),
        ('taveragefilter', C_VOICE, 'VE'),
        ('tfdmmultiplexer', C_VOICE, 'FD'),
        ('ttdmmultiplexer', C_VOICE, 'TD'),
        ('tcdmmultiplexer', C_VOICE, 'CD'),
        ('tofdmmultiplexer', C_VOICE, 'OF'),
    ],
    'AI Graph/aidatasetanalyzer_icon.lrs': [
        ('taidatasetanalyzer', C_GRAPH, 'DA'),
    ],
    'AI Graph/aidependencygraph_icon.lrs': [
        ('taidependencygraph', C_GRAPH, 'DG'),
    ],
    'AI Graph/aigeojsonrouteimporter_icon.lrs': [
        ('taigeojsonrouteimporter', C_GRAPH, 'GJ'),
    ],
    'AI Graph/aigraphmap_icon.lrs': [
        ('taigraphmap', C_GRAPH, 'GM'),
    ],
    'AI Graph/aigraphstructuraladapter_icon.lrs': [
        ('taigraphstructuraladapter', C_GRAPH, 'GS'),
    ],
    'AI Graph/aigraphvisualizer_icon.lrs': [
        ('taigraphvisualizer', C_GRAPH, 'GV'),
    ],
    'AI Graph/airoutecalculator_icon.lrs': [
        ('tairoutecalculator', C_GRAPH, 'RC'),
    ],
    'AI Graph/airoutecityindex_icon.lrs': [
        ('tairoutecityindex', C_GRAPH, 'RC'),
    ],
    'AI Graph/airoutegraph_icon.lrs': [
        ('tairoutegraph', C_GRAPH, 'RG'),
    ],
    'AI Graph/airoutespeedprofile_icon.lrs': [
        ('tairoutespeedprofile', C_FILES, 'RS'),
    ],
    'AI Graph/aitrainingexporter_icon.lrs': [
        ('taitrainingexporter', C_GRAPH, 'TE'),
    ],
    'AI Graph/aitrainingreport_icon.lrs': [
        ('taitrainingreport', C_GRAPH, 'TR'),
    ],
    'AI Graphic/ai3dmodelviewer_icon.lrs': [
        ('tai3dmodelviewer', C_GRAPH, 'DM'),
    ],
    'AI Graphic/aianimationsequence_icon.lrs': [
        ('taianimationsequence', C_GRAPH, 'AS'),
    ],
    'AI Graphic/aiavatarcontroller_icon.lrs': [
        ('taiavatarcontroller', C_GRAPH, 'AC'),
    ],
    'AI Graphic/aimodel3d_icon.lrs': [
        ('taimodel3d', C_GRAPH, 'MD'),
    ],
    'AI Graphic/aiphysicssimulator_icon.lrs': [
        ('taiphysicssimulator', C_GRAPH, 'PS'),
    ],
    'AI Graphic/aiposelibrary_icon.lrs': [
        ('taiposelibrary', C_GRAPH, 'PL'),
    ],
    'AI Graphic/airewardfunction_icon.lrs': [
        ('tairewardfunction', C_GRAPH, 'RF'),
    ],
    'AI Graphic/aiscene2d3d_icon.lrs': [
        ('taiscene2d3d', C_GRAPH, 'SD'),
    ],
    'AI Graphic/aisensorvirtual_icon.lrs': [
        ('taisensorvirtual', C_GRAPH, 'SV'),
    ],
    'AI Graphic/aiskeletonrig_icon.lrs': [
        ('taiskeletonrig', C_GRAPH, 'SR'),
    ],
    'AI Graphic/aitrainingenvironment_icon.lrs': [
        ('taitrainingenvironment', C_GRAPH, 'TE'),
    ],
    'AI Graphic/aitripo3dclient_icon.lrs': [
        ('taitripo3dclient', C_GRAPH, 'TD'),
    ],
    'AI Hardware/ai_tasks_icon.lrs': [
        ('taitasks', C_HARDWARE, 'TA'),
    ],
    'AI Hardware/aicpu_icon.lrs': [
        ('taicpu', C_HARDWARE, 'CP'),
    ],
    'AI Hardware/aidisk_icon.lrs': [
        ('taidisk', C_HARDWARE, 'DI'),
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
    'AI Image/imagefilters_icon.lrs': [
        ('tgrayscalefilter', C_VISION, 'GF'),
        ('tnegativefilter', C_VISION, 'NF'),
        ('tbrightnesscontrastfilter', C_VISION, 'BC'),
        ('tbinarizationfilter', C_VISION, 'BF'),
        ('tblurfilter', C_VISION, 'BF'),
        ('tsharpenfilter', C_VISION, 'SF'),
        ('tsobelfilter', C_VISION, 'SF'),
        ('terosiondilationfilter', C_VISION, 'ED'),
    ],
    'AI Industrial/aiarduinomodbuspinmap_icon.lrs': [
        ('taiarduinomodbuspinmap', C_INDUSTRIAL, 'AM'),
    ],
    'AI Industrial/aiarm_robot_icon.lrs': [
        ('tai_arm_robot', C_INDUSTRIAL, '_A'),
        ('tai_arm_robotviewer', C_INDUSTRIAL, 'AV'),
        ('tai_arm_robotposition', C_INDUSTRIAL, 'AP'),
    ],
    'AI Industrial/aiarm_robotcontrol_icon.lrs': [
        ('tai_arm_robotcontrol', C_INDUSTRIAL, 'AR'),
    ],
    'AI Industrial/aiindustrial_icon.lrs': [
        ('taiindustrialbridge', C_INDUSTRIAL, 'IB'),
    ],
    'AI Industrial/aimodbus_icon.lrs': [
        ('taimodbusclient', C_INDUSTRIAL, 'MC'),
    ],
    'AI Industrial/aimodbuscommandmap_icon.lrs': [
        ('taimodbuscommandmap', C_INDUSTRIAL, 'MC'),
    ],
    'AI Industrial/aimqtt_icon.lrs': [
        ('taimqttclient', C_INDUSTRIAL, 'MQ'),
    ],
    'AI Input/AIAudio/aiaudio_icon.lrs': [
        ('taiaudioinput', C_INPUT, 'AI'),
    ],
    'AI Input/AICaptureSource/aicapturesource_icon.lrs': [
        ('taicapturesource', C_INPUT, 'CS'),
    ],
    'AI Input/AIChromiumBrowser/aichromiumbrowser_icon.lrs': [
        ('taichromiumbrowser', C_INPUT, 'CB'),
    ],
    'AI Input/AIEmail/aiemail_icon.lrs': [
        ('taiemailclient', C_INPUT, 'EC'),
    ],
    'AI Input/AIInput/aiinput_icon.lrs': [
        ('taiinputdata', C_INPUT, 'ID'),
    ],
    'AI Input/AIKinect/aikinectaudio_icon.lrs': [
        ('taikinectaudio', C_INPUT, 'KA'),
    ],
    'AI Input/AIKinect/aikinectcolor_icon.lrs': [
        ('taikinectcolorstream', C_INPUT, 'KC'),
    ],
    'AI Input/AIKinect/aikinectdepth_icon.lrs': [
        ('taikinectdepthstream', C_INPUT, 'KD'),
    ],
    'AI Input/AIKinect/aikinectsensor_icon.lrs': [
        ('taikinectsensor', C_INPUT, 'KS'),
    ],
    'AI Input/AIKinect/aikinectskeleton_icon.lrs': [
        ('taikinectskeleton', C_INPUT, 'KS'),
    ],
    'AI Input/AIMessenger/aimessenger_icon.lrs': [
        ('taimessenger', C_INPUT, 'ME'),
    ],
    'AI Input/AISerial/ailistserialdevices_icon.lrs': [
        ('tailistserialdevices', C_INPUT, 'LS'),
    ],
    'AI Input/AISerial/aiserial_icon.lrs': [
        ('taiserialmodem', C_INPUT, 'SM'),
    ],
    'AI Input/AISockets/aisockets_icon.lrs': [
        ('taisockettcp', C_INPUT, 'ST'),
        ('taisocketudp', C_INPUT, 'SU'),
    ],
    'AI Input/AIUSB/aiusb_register_icon.lrs': [
        ('taiusb', C_INPUT, 'US'),
    ],
    'AI Input/AIWebServer/aiwebserver_icon.lrs': [
        ('taiwebapiserver', C_INPUT, 'WA'),
    ],
    'AI Input/aidocumentreader_icon.lrs': [
        ('taidocumentinput', C_INPUT, 'DI'),
    ],
    'AI Input/aidocxinput_icon.lrs': [
        ('taidocxinput', C_INPUT, 'DO'),
    ],
    'AI Input/aiexcelinput_icon.lrs': [
        ('taiexcelinput', C_INPUT, 'EI'),
    ],
    'AI Input/aipdfinput_icon.lrs': [
        ('taipdfinput', C_INPUT, 'PD'),
    ],
    'AI LlamaCpp/aillamacppinference_icon.lrs': [
        ('taillamacppinference', C_CORE, 'LC'),
    ],
    'AI LlamaCpp/aillamacpplora_icon.lrs': [
        ('taillamacpplora', C_CORE, 'LC'),
    ],
    'AI LlamaCpp/aillamacppmodel_icon.lrs': [
        ('taillamacppmodel', C_CORE, 'LC'),
    ],
    'AI LlamaCpp/aillamacppquantizer_icon.lrs': [
        ('taillamacppquantizer', C_CORE, 'LC'),
    ],
    'AI LlamaCpp/aillamacppruntime_icon.lrs': [
        ('taillamacppruntime', C_CORE, 'LC'),
    ],
    'AI LlamaCpp/aillamacppserver_icon.lrs': [
        ('taillamacppserver', C_CORE, 'LC'),
    ],
    'AI MCP/aimcp_icon.lrs': [
        ('taimcpclient', C_MCP, 'MC'),
        ('taimcpserver', C_MCP, 'MC'),
        ('taimcptoolregistrybridge', C_MCP, 'MC'),
    ],
    'AI Math/numps_icon.lrs': [
        ('tnumps', C_MATH, 'NP'),
    ],
    'AI Observability/aitrace_icon.lrs': [
        ('taitrace', C_OBSERVABILITY, 'TR'),
    ],
    'AI Output/aioutput_docs_icon.lrs': [
        ('taipdfoutput', C_OUTPUT, 'PD'),
        ('taiwordoutput', C_OUTPUT, 'WO'),
        ('taiexceloutput', C_OUTPUT, 'EO'),
        ('taitxtoutput', C_OUTPUT, 'TX'),
        ('taioutputdocs', C_OUTPUT, 'OD'),
    ],
    'AI Output/aioutput_icon.lrs': [
        ('taioutputdata', C_OUTPUT, 'OD'),
    ],
    'AI Output/aiposprinter_icon.lrs': [
        ('taiposprinter', C_OUTPUT, 'PO'),
    ],
    'AI Output/aiworddocument_icon.lrs': [
        ('taiworddocument', C_OUTPUT, 'WD'),
    ],
    'AI Output/aiwordviewer_icon.lrs': [
        ('taiwordviewer', C_OUTPUT, 'WV'),
    ],
    'AI Project/aiproject_actions_icon.lrs': [
        ('taitaskactions', C_PROJECT, 'TA'),
    ],
    'AI Project/aiproject_agentmanager_icon.lrs': [
        ('taiagentmanagerframe', C_AGENT, 'AM'),
    ],
    'AI Project/aiproject_agents_icon.lrs': [
        ('taiprojectagents', C_AGENT, 'PA'),
    ],
    'AI Project/aiproject_dependencies_icon.lrs': [
        ('taiprojectdependencies', C_PROJECT, 'PD'),
    ],
    'AI Project/aiproject_description_icon.lrs': [
        ('taiprojectdescription', C_PROJECT, 'PD'),
    ],
    'AI Project/aiproject_documents_icon.lrs': [
        ('taiagiledocuments', C_PROJECT, 'AD'),
    ],
    'AI Project/aiproject_gantt_icon.lrs': [
        ('taiprojectgantt', C_PROJECT, 'PG'),
    ],
    'AI Project/aiproject_icon.lrs': [
        ('taiproject', C_PROJECT, 'PR'),
    ],
    'AI Project/aiproject_llmconfig_icon.lrs': [
        ('taiprojectllmconfig', C_PROJECT, 'PL'),
    ],
    'AI Project/aiproject_reports_icon.lrs': [
        ('taiprojectreports', C_PROJECT, 'PR'),
    ],
    'AI Project/aiproject_reportviewer_icon.lrs': [
        ('taiprojectreportviewer', C_PROJECT, 'PR'),
    ],
    'AI Project/aiproject_revisions_icon.lrs': [
        ('taiprojectrevisions', C_VISION, 'PR'),
    ],
    'AI Project/aiproject_riskmatrix_icon.lrs': [
        ('tairiskmatrix', C_PROJECT, 'RM'),
    ],
    'AI Project/aiproject_specification_icon.lrs': [
        ('taiprojectspecification', C_PROJECT, 'PS'),
    ],
    'AI Project/aiproject_statuspanel_icon.lrs': [
        ('taiprojectstatuspanel', C_PROJECT, 'PS'),
    ],
    'AI Project/aiproject_storage_icon.lrs': [
        ('taiprojectstorage', C_PROJECT, 'PS'),
    ],
    'AI Project/aiproject_taskactionpanel_icon.lrs': [
        ('taitaskactionpanel', C_PROJECT, 'TA'),
    ],
    'AI Project/aiproject_taskgrid_icon.lrs': [
        ('taiprojecttaskgrid', C_PROJECT, 'PT'),
    ],
    'AI Project/aiproject_tasks_icon.lrs': [
        ('taiprojecttasks', C_PROJECT, 'PT'),
    ],
    'AI Project/aiproject_timeline_icon.lrs': [
        ('taiprojecttimeline', C_PROJECT, 'PT'),
    ],
    'AI RAG/airag_icon.lrs': [
        ('tairag', C_RAG, 'RA'),
    ],
    'AI Schedule/iaschedule_icon.lrs': [
        ('tjsongroupstorage', C_CORE, 'JS'),
        ('tiaschedule', C_CORE, 'IA'),
    ],
    'AI Simulation/aientityfactory_icon.lrs': [
        ('taientityfactory', C_SIMULATION, 'EF'),
    ],
    'AI Simulation/aievolutionengine_icon.lrs': [
        ('taievolutionengine', C_SIMULATION, 'EE'),
    ],
    'AI Simulation/aigridrenderer2d_icon.lrs': [
        ('taigridrenderer2d', C_SIMULATION, 'GR'),
    ],
    'AI Simulation/aigridworld_icon.lrs': [
        ('taigridworld', C_SIMULATION, 'GW'),
    ],
    'AI Simulation/aimovementengine_icon.lrs': [
        ('taimovementengine', C_SIMULATION, 'ME'),
    ],
    'AI Simulation/airuleengine_icon.lrs': [
        ('tairuleengine', C_SIMULATION, 'RE'),
    ],
    'AI Simulation/aiscenarioconfig_icon.lrs': [
        ('taiscenarioconfig', C_SIMULATION, 'SC'),
    ],
    'AI Simulation/aiscenariogenerator_icon.lrs': [
        ('taiscenariogenerator', C_SIMULATION, 'SG'),
    ],
    'AI Simulation/aisimentity_icon.lrs': [
        ('taisimentity', C_SIMULATION, 'SE'),
    ],
    'AI Simulation/aisimulationengine_icon.lrs': [
        ('taisimulationengine', C_SIMULATION, 'SE'),
    ],
    'AI Simulation/aisimulationexporter_icon.lrs': [
        ('taisimulationexporter', C_SIMULATION, 'SE'),
    ],
    'AI Simulation/aisimulationstats_icon.lrs': [
        ('taisimulationstats', C_SIMULATION, 'SS'),
    ],
    'AI Simulation/aitriggerengine_icon.lrs': [
        ('taitriggerengine', C_SIMULATION, 'TE'),
    ],
    'AI Vision/aifacetracker_icon.lrs': [
        ('taifacetracker', C_VISION, 'FT'),
    ],
    'AI Vision/aiframebuffer_icon.lrs': [
        ('taiframebuffer', C_VISION, 'FB'),
    ],
    'AI Vision/aiframediff_icon.lrs': [
        ('taiframediff', C_VISION, 'FD'),
    ],
    'AI Vision/aiframeprocessor_icon.lrs': [
        ('taiframeprocessor', C_VISION, 'FP'),
    ],
    'AI Vision/aihumanposedetector_icon.lrs': [
        ('taihumanposedetector', C_VISION, 'HP'),
    ],
    'AI Vision/aiimageinfo_icon.lrs': [
        ('taiimageinfo', C_VISION, 'II'),
    ],
    'AI Vision/aimotiontracker_icon.lrs': [
        ('taimotiontracker', C_VISION, 'MT'),
    ],
    'AI Vision/ainativeimagefilter_icon.lrs': [
        ('tainativeimagefilter', C_VISION, 'NI'),
    ],
    'AI Vision/aiopencv_icon.lrs': [
        ('taiopencv', C_VISION, 'OC'),
    ],
    'AI Voice/aiaudioplayback_icon.lrs': [
        ('taiaudioplayer', C_VOICE, 'AP'),
    ],
    'AI Voice/aif5ttsengine_icon.lrs': [
        ('taif5ttsprocessengine', C_VOICE, 'FT'),
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
    'AI Voice/aivoicesynthesizer_icon.lrs': [
        ('taivoicesynthesizer', C_VOICE, 'VS'),
    ],
    'AI Voice/aiwhisperengine_icon.lrs': [
        ('taiwhisperprocessengine', C_VOICE, 'WP'),
    ],
    'AI/aicodeassistant_icon.lrs': [
        ('taicodeassistant', C_CORE, 'CA'),
    ],
    'AI/aidatasetgenerator_icon.lrs': [
        ('taidatasetgenerator', C_CORE, 'DG'),
    ],
    'AI/aimodelregistry_icon.lrs': [
        ('taimodelregistry', C_CORE, 'MR'),
    ],
    'AI/aimodelrouter_icon.lrs': [
        ('taimodelrouter', C_CORE, 'MR'),
    ],
    'AI/aipromptbuilder_icon.lrs': [
        ('taipromptbuilder', C_CORE, 'PB'),
    ],
    'AI/aiunifiedllm_icon.lrs': [
        ('taiunifiedllm', C_CORE, 'UL'),
    ],
    'AI/chatgpt_icon.lrs': [
        ('tchatgpt', C_CORE, 'CH'),
    ],
    'AI/cnnclassifier_icon.lrs': [
        ('tcnnclassifier', C_CORE, 'CN'),
    ],
    'AI/dbtokenlist_icon.lrs': [
        ('tdbtokenlist', C_CORE, 'DB'),
    ],
    'AI/facedetection_icon.lrs': [
        ('tfacedetection', C_CORE, 'FD'),
    ],
    'AI/groupresponse_icon.lrs': [
        ('tgroupresponse', C_CORE, 'GR'),
    ],
    'AI/lstmpredictor_icon.lrs': [
        ('tlstmpredictor', C_CORE, 'LS'),
    ],
    'AI/matrizcomponent_icon.lrs': [
        ('tamatrizcomponent', C_CORE, 'MC'),
    ],
    'AI/neuralnetwork_icon.lrs': [
        ('tneuralnetwork', C_CORE, 'NN'),
    ],
    'AI/perceptron_icon.lrs': [
        ('tperceptron', C_CORE, 'PE'),
    ],
    'AI/pythonconnector_icon.lrs': [
        ('tpythonconnector', C_ML, 'PC'),
    ],
    'AI/sommap_icon.lrs': [
        ('tsommap', C_CORE, 'SO'),
    ],
    'AI/tokenizer_icon.lrs': [
        ('ttokenlist', C_CORE, 'TL'),
    ],
    'AI/yolodetect_icon.lrs': [
        ('tyolo', C_CORE, 'YO'),
    ],
    'compchatgpt_icon.lrs': [
        ('tmycomponent', C_CORE, 'MC'),
    ],
    'python/aipythonruntime_icon.lrs': [
        ('taipythonruntime', C_ML, 'PR'),
    ],
}

patches = [
    ('AI A2A/aia2a.pas', 'aia2a_icon.lrs'),
    ('AI A2A/aia2aserver.pas', 'aia2aserver_icon.lrs'),
    ('AI Agent/aiagent.pas', 'aiagent_icon.lrs'),
    ('AI Agent/aiagent_memorymap.pas', 'aiagent_memorymap_icon.lrs'),
    ('AI Agent/aiagent_orchestrator.pas', 'aiagent_orchestrator_icon.lrs'),
    ('AI Agent/aiagent_sourceactions.pas', 'aiagent_sourceactions_icon.lrs'),
    ('AI Agent/aiagent_testaction.pas', 'aiagent_testaction_icon.lrs'),
    ('AI Agent/aiagentgraph.pas', 'aiagentgraph_icon.lrs'),
    ('AI Agent/aiagentsafety.pas', 'aiagentsafety_icon.lrs'),
    ('AI Agent/aiagentserial.pas', 'aiagentserial_icon.lrs'),
    ('AI Agent/aicommonserviceagents.pas', 'aicommonserviceagents_icon.lrs'),
    ('AI Agent/aidevagents.pas', 'aidevagents_icon.lrs'),
    ('AI Agent/aiguardrails.pas', 'aiguardrails_icon.lrs'),
    ('AI Agent/aipipeline.pas', 'aipipeline_icon.lrs'),
    ('AI Agent/airosagent.pas', 'airosagent_icon.lrs'),
    ('AI Agent/aiserviceagents.pas', 'aiserviceagents_icon.lrs'),
    ('AI Agent/aitools.pas', 'aitools_icon.lrs'),
    ('AI Agent/aiwizardconfig.pas', 'aiwizardconfig_icon.lrs'),
    ('AI DBase/aidb_register.pas', 'aidb_register_icon.lrs'),
    ('AI DBase/aidbase.pas', 'aidbase_icon.lrs'),
    ('AI Evaluation/aievaluation.pas', 'aievaluation_icon.lrs'),
    ('AI Files/ai_docfilesmanager.pas', 'ai_docfilesmanager_icon.lrs'),
    ('AI Files/aidisktreescanner.pas', 'aidisktreescanner_icon.lrs'),
    ('AI Filtros Sonoros/soundfilters.pas', 'soundfilters_icon.lrs'),
    ('AI Graph/aidatasetanalyzer.pas', 'aidatasetanalyzer_icon.lrs'),
    ('AI Graph/aidependencygraph.pas', 'aidependencygraph_icon.lrs'),
    ('AI Graph/aigeojsonrouteimporter.pas', 'aigeojsonrouteimporter_icon.lrs'),
    ('AI Graph/aigraphmap.pas', 'aigraphmap_icon.lrs'),
    ('AI Graph/aigraphstructuraladapter.pas', 'aigraphstructuraladapter_icon.lrs'),
    ('AI Graph/aigraphvisualizer.pas', 'aigraphvisualizer_icon.lrs'),
    ('AI Graph/airoutecalculator.pas', 'airoutecalculator_icon.lrs'),
    ('AI Graph/airoutecityindex.pas', 'airoutecityindex_icon.lrs'),
    ('AI Graph/airoutegraph.pas', 'airoutegraph_icon.lrs'),
    ('AI Graph/airoutespeedprofile.pas', 'airoutespeedprofile_icon.lrs'),
    ('AI Graph/aitrainingexporter.pas', 'aitrainingexporter_icon.lrs'),
    ('AI Graph/aitrainingreport.pas', 'aitrainingreport_icon.lrs'),
    ('AI Graphic/ai3dmodelviewer.pas', 'ai3dmodelviewer_icon.lrs'),
    ('AI Graphic/aianimationsequence.pas', 'aianimationsequence_icon.lrs'),
    ('AI Graphic/aiavatarcontroller.pas', 'aiavatarcontroller_icon.lrs'),
    ('AI Graphic/aimodel3d.pas', 'aimodel3d_icon.lrs'),
    ('AI Graphic/aiphysicssimulator.pas', 'aiphysicssimulator_icon.lrs'),
    ('AI Graphic/aiposelibrary.pas', 'aiposelibrary_icon.lrs'),
    ('AI Graphic/airewardfunction.pas', 'airewardfunction_icon.lrs'),
    ('AI Graphic/aiscene2d3d.pas', 'aiscene2d3d_icon.lrs'),
    ('AI Graphic/aisensorvirtual.pas', 'aisensorvirtual_icon.lrs'),
    ('AI Graphic/aiskeletonrig.pas', 'aiskeletonrig_icon.lrs'),
    ('AI Graphic/aitrainingenvironment.pas', 'aitrainingenvironment_icon.lrs'),
    ('AI Graphic/aitripo3dclient.pas', 'aitripo3dclient_icon.lrs'),
    ('AI Hardware/ai_tasks.pas', 'ai_tasks_icon.lrs'),
    ('AI Hardware/aicpu.pas', 'aicpu_icon.lrs'),
    ('AI Hardware/aidisk.pas', 'aidisk_icon.lrs'),
    ('AI Hardware/aigpu.pas', 'aigpu_icon.lrs'),
    ('AI Hardware/ailistprinters.pas', 'ailistprinters_icon.lrs'),
    ('AI Hardware/aimemory.pas', 'aimemory_icon.lrs'),
    ('AI Hardware/aiso.pas', 'aiso_icon.lrs'),
    ('AI Image/imagefilters.pas', 'imagefilters_icon.lrs'),
    ('AI Industrial/aiarduinomodbuspinmap.pas', 'aiarduinomodbuspinmap_icon.lrs'),
    ('AI Industrial/aiarm_robot.pas', 'aiarm_robot_icon.lrs'),
    ('AI Industrial/aiarm_robotcontrol.pas', 'aiarm_robotcontrol_icon.lrs'),
    ('AI Industrial/aiindustrial.pas', 'aiindustrial_icon.lrs'),
    ('AI Industrial/aimodbus.pas', 'aimodbus_icon.lrs'),
    ('AI Industrial/aimodbuscommandmap.pas', 'aimodbuscommandmap_icon.lrs'),
    ('AI Industrial/aimqtt.pas', 'aimqtt_icon.lrs'),
    ('AI Input/AIAudio/aiaudio.pas', 'aiaudio_icon.lrs'),
    ('AI Input/AICaptureSource/aicapturesource.pas', 'aicapturesource_icon.lrs'),
    ('AI Input/AIChromiumBrowser/aichromiumbrowser.pas', 'aichromiumbrowser_icon.lrs'),
    ('AI Input/AIEmail/aiemail.pas', 'aiemail_icon.lrs'),
    ('AI Input/AIInput/aiinput.pas', 'aiinput_icon.lrs'),
    ('AI Input/AIKinect/aikinectaudio.pas', 'aikinectaudio_icon.lrs'),
    ('AI Input/AIKinect/aikinectcolor.pas', 'aikinectcolor_icon.lrs'),
    ('AI Input/AIKinect/aikinectdepth.pas', 'aikinectdepth_icon.lrs'),
    ('AI Input/AIKinect/aikinectsensor.pas', 'aikinectsensor_icon.lrs'),
    ('AI Input/AIKinect/aikinectskeleton.pas', 'aikinectskeleton_icon.lrs'),
    ('AI Input/AIMessenger/aimessenger.pas', 'aimessenger_icon.lrs'),
    ('AI Input/AISerial/ailistserialdevices.pas', 'ailistserialdevices_icon.lrs'),
    ('AI Input/AISerial/aiserial.pas', 'aiserial_icon.lrs'),
    ('AI Input/AISockets/aisockets.pas', 'aisockets_icon.lrs'),
    ('AI Input/AIUSB/aiusb_register.pas', 'aiusb_register_icon.lrs'),
    ('AI Input/AIWebServer/aiwebserver.pas', 'aiwebserver_icon.lrs'),
    ('AI Input/aidocumentreader.pas', 'aidocumentreader_icon.lrs'),
    ('AI Input/aidocxinput.pas', 'aidocxinput_icon.lrs'),
    ('AI Input/aiexcelinput.pas', 'aiexcelinput_icon.lrs'),
    ('AI Input/aipdfinput.pas', 'aipdfinput_icon.lrs'),
    ('AI LlamaCpp/aillamacppinference.pas', 'aillamacppinference_icon.lrs'),
    ('AI LlamaCpp/aillamacpplora.pas', 'aillamacpplora_icon.lrs'),
    ('AI LlamaCpp/aillamacppmodel.pas', 'aillamacppmodel_icon.lrs'),
    ('AI LlamaCpp/aillamacppquantizer.pas', 'aillamacppquantizer_icon.lrs'),
    ('AI LlamaCpp/aillamacppruntime.pas', 'aillamacppruntime_icon.lrs'),
    ('AI LlamaCpp/aillamacppserver.pas', 'aillamacppserver_icon.lrs'),
    ('AI MCP/aimcp.pas', 'aimcp_icon.lrs'),
    ('AI Math/numps.pas', 'numps_icon.lrs'),
    ('AI Observability/aitrace.pas', 'aitrace_icon.lrs'),
    ('AI Output/aioutput.pas', 'aioutput_icon.lrs'),
    ('AI Output/aioutput_docs.pas', 'aioutput_docs_icon.lrs'),
    ('AI Output/aiposprinter.pas', 'aiposprinter_icon.lrs'),
    ('AI Output/aiworddocument.pas', 'aiworddocument_icon.lrs'),
    ('AI Output/aiwordviewer.pas', 'aiwordviewer_icon.lrs'),
    ('AI Project/aiproject.pas', 'aiproject_icon.lrs'),
    ('AI Project/aiproject_actions.pas', 'aiproject_actions_icon.lrs'),
    ('AI Project/aiproject_agentmanager.pas', 'aiproject_agentmanager_icon.lrs'),
    ('AI Project/aiproject_agents.pas', 'aiproject_agents_icon.lrs'),
    ('AI Project/aiproject_dependencies.pas', 'aiproject_dependencies_icon.lrs'),
    ('AI Project/aiproject_description.pas', 'aiproject_description_icon.lrs'),
    ('AI Project/aiproject_documents.pas', 'aiproject_documents_icon.lrs'),
    ('AI Project/aiproject_gantt.pas', 'aiproject_gantt_icon.lrs'),
    ('AI Project/aiproject_llmconfig.pas', 'aiproject_llmconfig_icon.lrs'),
    ('AI Project/aiproject_reports.pas', 'aiproject_reports_icon.lrs'),
    ('AI Project/aiproject_reportviewer.pas', 'aiproject_reportviewer_icon.lrs'),
    ('AI Project/aiproject_revisions.pas', 'aiproject_revisions_icon.lrs'),
    ('AI Project/aiproject_riskmatrix.pas', 'aiproject_riskmatrix_icon.lrs'),
    ('AI Project/aiproject_specification.pas', 'aiproject_specification_icon.lrs'),
    ('AI Project/aiproject_statuspanel.pas', 'aiproject_statuspanel_icon.lrs'),
    ('AI Project/aiproject_storage.pas', 'aiproject_storage_icon.lrs'),
    ('AI Project/aiproject_taskactionpanel.pas', 'aiproject_taskactionpanel_icon.lrs'),
    ('AI Project/aiproject_taskgrid.pas', 'aiproject_taskgrid_icon.lrs'),
    ('AI Project/aiproject_tasks.pas', 'aiproject_tasks_icon.lrs'),
    ('AI Project/aiproject_timeline.pas', 'aiproject_timeline_icon.lrs'),
    ('AI RAG/airag.pas', 'airag_icon.lrs'),
    ('AI Schedule/iaschedule.pas', 'iaschedule_icon.lrs'),
    ('AI Simulation/aientityfactory.pas', 'aientityfactory_icon.lrs'),
    ('AI Simulation/aievolutionengine.pas', 'aievolutionengine_icon.lrs'),
    ('AI Simulation/aigridrenderer2d.pas', 'aigridrenderer2d_icon.lrs'),
    ('AI Simulation/aigridworld.pas', 'aigridworld_icon.lrs'),
    ('AI Simulation/aimovementengine.pas', 'aimovementengine_icon.lrs'),
    ('AI Simulation/airuleengine.pas', 'airuleengine_icon.lrs'),
    ('AI Simulation/aiscenarioconfig.pas', 'aiscenarioconfig_icon.lrs'),
    ('AI Simulation/aiscenariogenerator.pas', 'aiscenariogenerator_icon.lrs'),
    ('AI Simulation/aisimentity.pas', 'aisimentity_icon.lrs'),
    ('AI Simulation/aisimulationengine.pas', 'aisimulationengine_icon.lrs'),
    ('AI Simulation/aisimulationexporter.pas', 'aisimulationexporter_icon.lrs'),
    ('AI Simulation/aisimulationstats.pas', 'aisimulationstats_icon.lrs'),
    ('AI Simulation/aitriggerengine.pas', 'aitriggerengine_icon.lrs'),
    ('AI Vision/aifacetracker.pas', 'aifacetracker_icon.lrs'),
    ('AI Vision/aiframebuffer.pas', 'aiframebuffer_icon.lrs'),
    ('AI Vision/aiframediff.pas', 'aiframediff_icon.lrs'),
    ('AI Vision/aiframeprocessor.pas', 'aiframeprocessor_icon.lrs'),
    ('AI Vision/aihumanposedetector.pas', 'aihumanposedetector_icon.lrs'),
    ('AI Vision/aiimageinfo.pas', 'aiimageinfo_icon.lrs'),
    ('AI Vision/aimotiontracker.pas', 'aimotiontracker_icon.lrs'),
    ('AI Vision/ainativeimagefilter.pas', 'ainativeimagefilter_icon.lrs'),
    ('AI Vision/aiopencv.pas', 'aiopencv_icon.lrs'),
    ('AI Voice/aiaudioplayback.pas', 'aiaudioplayback_icon.lrs'),
    ('AI Voice/aif5ttsengine.pas', 'aif5ttsengine_icon.lrs'),
    ('AI Voice/aispeechrecognizer.pas', 'aispeechrecognizer_icon.lrs'),
    ('AI Voice/aivoiceassistant.pas', 'aivoiceassistant_icon.lrs'),
    ('AI Voice/aivoiceclone.pas', 'aivoiceclone_icon.lrs'),
    ('AI Voice/aivoicerecognizer.pas', 'aivoicerecognizer_icon.lrs'),
    ('AI Voice/aivoicesynthesizer.pas', 'aivoicesynthesizer_icon.lrs'),
    ('AI Voice/aiwhisperengine.pas', 'aiwhisperengine_icon.lrs'),
    ('AI/aicodeassistant.pas', 'aicodeassistant_icon.lrs'),
    ('AI/aidatasetgenerator.pas', 'aidatasetgenerator_icon.lrs'),
    ('AI/aimodelregistry.pas', 'aimodelregistry_icon.lrs'),
    ('AI/aimodelrouter.pas', 'aimodelrouter_icon.lrs'),
    ('AI/aipromptbuilder.pas', 'aipromptbuilder_icon.lrs'),
    ('AI/aiunifiedllm.pas', 'aiunifiedllm_icon.lrs'),
    ('AI/chatgpt.pas', 'chatgpt_icon.lrs'),
    ('AI/cnnclassifier.pas', 'cnnclassifier_icon.lrs'),
    ('AI/dbtokenlist.pas', 'dbtokenlist_icon.lrs'),
    ('AI/facedetection.pas', 'facedetection_icon.lrs'),
    ('AI/groupresponse.pas', 'groupresponse_icon.lrs'),
    ('AI/lstmpredictor.pas', 'lstmpredictor_icon.lrs'),
    ('AI/matrizcomponent.pas', 'matrizcomponent_icon.lrs'),
    ('AI/neuralnetwork.pas', 'neuralnetwork_icon.lrs'),
    ('AI/perceptron.pas', 'perceptron_icon.lrs'),
    ('AI/pythonconnector.pas', 'pythonconnector_icon.lrs'),
    ('AI/sommap.pas', 'sommap_icon.lrs'),
    ('AI/tokenizer.pas', 'tokenizer_icon.lrs'),
    ('AI/yolodetect.pas', 'yolodetect_icon.lrs'),
    ('compchatgpt.pas', 'compchatgpt_icon.lrs'),
    ('python/aipythonruntime.pas', 'aipythonruntime_icon.lrs'),
]

def patch_pas_file(file_path, lrs_filename, check_only=False):
    if not os.path.exists(file_path):
        print(f"Pascal file not found: {file_path}")
        return False
        
    with open(file_path, 'r', encoding='utf-8') as f:
        original_content = f.read()
        
    content = original_content
        
    # 1. Patch uses clause to add LResources if missing anywhere in file
    if not re.search(r'\bLResources\b', content, re.IGNORECASE):
        uses_match = re.search(r'\buses\b([\s\S]*?);', content, re.IGNORECASE)
        if uses_match:
            uses_clause = uses_match.group(1)
            uses_end_pos = uses_match.end(1)
            separator = ', ' if len(uses_clause.strip()) > 0 else ''
            content = content[:uses_end_pos] + separator + 'LResources' + content[uses_end_pos:]
            
    # 2. Check if resource file is already included
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
        else:
            content = content[:idx] + f"initialization\n  {include_str}\n\n" + content[idx:]
        
    if content != original_content:
        if check_only:
            print(f"[DIFF] {file_path} needs icon resource patching ({lrs_filename})")
            return False
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Saved changes to {file_path}")
    else:
        if not check_only:
            print(f"No changes needed for {file_path}")
    return True

def main():
    import sys
    check_mode = '--check' in sys.argv
    package_root = os.path.dirname(os.path.abspath(__file__))
    has_diff = False
    
    # 1. Generate / Check LRS files
    for relative_lrs_path, configs in icons_config.items():
        lrs_contents = []
        for class_name, border_color, label in configs:
            pixels = draw_icon(border_color, label)
            bmp_bytes = make_bmp(pixels)
            lrs_contents.append(format_lrs_resource(class_name, bmp_bytes))
            
        expected_text = "\n".join(lrs_contents) + "\n"
        full_lrs_path = os.path.join(package_root, relative_lrs_path)
        
        if check_mode:
            if not os.path.exists(full_lrs_path):
                print(f"[DIFF] Missing LRS file: {relative_lrs_path}")
                has_diff = True
            else:
                with open(full_lrs_path, 'r', encoding='utf-8') as f:
                    actual_text = f.read()
                if actual_text != expected_text:
                    print(f"[DIFF] LRS file differs from generator: {relative_lrs_path}")
                    has_diff = True
        else:
            os.makedirs(os.path.dirname(full_lrs_path), exist_ok=True)
            if not os.path.exists(full_lrs_path) or open(full_lrs_path, 'r', encoding='utf-8').read() != expected_text:
                with open(full_lrs_path, 'w', encoding='utf-8') as f:
                    f.write(expected_text)
                print(f"Generated LRS: {full_lrs_path}")
            
    # 2. Patch / Check Pascal source files
    for pas_rel_path, lrs_filename in patches:
        full_pas_path = os.path.join(package_root, pas_rel_path)
        ok = patch_pas_file(full_pas_path, lrs_filename, check_only=check_mode)
        if not ok:
            has_diff = True
            
    if check_mode:
        if has_diff:
            print("\n[CHECK FAILED] Icon resources or source files are out of sync with generator.")
            sys.exit(1)
        else:
            print("\n[CHECK PASS] All icon resources and source units are up-to-date.")
            sys.exit(0)
    else:
        print("Done generating and patching all component icons!")

if __name__ == '__main__':
    main()
