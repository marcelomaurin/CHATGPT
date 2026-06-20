# -*- coding: utf-8 -*-
import os
import re
import xml.etree.ElementTree as ET

# Configuration of languages and translations for headers
langs = {
    'pt': {
        'title': 'Projetos de Demonstração (Samples)',
        'intro': 'Este diretório contém a suíte completa de exemplos desenvolvidos para demonstrar e testar todos os componentes de Inteligência Artificial, Aprendizado de Máquina (Machine Learning), Processamento de Imagens, Processamento de Sinais (DSP), Automação de Hardware e Geração de Documentos da Lazarus AI Suite.',
        'gui_title': '🖥️ Demonstrações em Interface Gráfica (GUI)',
        'gui_desc': 'Os exemplos a seguir são projetos visuais prontos para compilação e execução interativa através do Lazarus:',
        'console_title': '💻 Demonstrações em Linha de Comando (Console)',
        'console_desc': 'Estes exemplos demonstram a invocação direta de componentes via linha de comando para cenários de depuração rápida ou automação de rotinas:',
        'screenshots_title': '🖼️ Galeria de Capturas de Tela (Screenshots)',
        'col_sample': 'Exemplo / Caminho',
        'col_desc': 'Descrição',
        'col_pkg': 'Pacote Necessário',
        'col_comps': 'Componentes Usados',
        'no_desc': 'Nenhuma descrição disponível.',
        'category': 'Categoria'
    },
    'en': {
        'title': 'Demonstration Projects (Samples)',
        'intro': 'This directory contains the complete suite of examples developed to demonstrate and test all Artificial Intelligence, Machine Learning, Image Processing, Digital Signal Processing (DSP), Hardware Automation, and Document Generation components of the Lazarus AI Suite.',
        'gui_title': '🖥️ Graphical User Interface (GUI) Demonstrations',
        'gui_desc': 'The following examples are visual projects ready for compilation and interactive execution through Lazarus:',
        'console_title': '💻 Command Line Interface (Console) Demonstrations',
        'console_desc': 'These examples demonstrate direct component invocation via command line for rapid debugging or automation scenarios:',
        'screenshots_title': '🖼️ Screenshots Gallery',
        'col_sample': 'Sample / Path',
        'col_desc': 'Description',
        'col_pkg': 'Required Package',
        'col_comps': 'Used Components',
        'no_desc': 'No description available.',
        'category': 'Category'
    },
    'es': {
        'title': 'Proyectos de Demostración (Samples)',
        'intro': 'Este directorio contiene la suite completa de ejemplos desarrollados para demostrar y probar todos los componentes de Inteligencia Artificial, Aprendizaje Automático (Machine Learning), Procesamiento de Imágenes, Procesamiento de Señales (DSP), Automatización de Hardware y Generación de Documentos de la suite Lazarus AI Suite.',
        'gui_title': '🖥️ Demostraciones de Interfaz Gráfica (GUI)',
        'gui_desc': 'Los siguientes ejemplos son proyectos visuales listos para compilar y ejecutar interactivamente en Lazarus:',
        'console_title': '💻 Demostraciones de Línea de Comando (Consola)',
        'console_desc': 'Estos ejemplos demuestran la invocación directa de componentes a través de la línea de comandos para depuración rápida o automatización:',
        'screenshots_title': '🖼️ Galería de Capturas de Pantalla (Screenshots)',
        'col_sample': 'Ejemplo / Ruta',
        'col_desc': 'Descripción',
        'col_pkg': 'Paquete Requerido',
        'col_comps': 'Componentes Usados',
        'no_desc': 'Sin descripción disponible.',
        'category': 'Categoría'
    },
    'fr': {
        'title': 'Projets de Démonstration (Samples)',
        'intro': 'Ce dossier contient la suite complète d\'exemples développés pour tester tous les composants d\'Intelligence Artificielle, d\'Apprentissage Automatique, de traitement d\'images, de traitement de signaux (DSP), d\'automatisation matérielle et de génération de documents de la suite Lazarus AI Suite.',
        'gui_title': '🖥️ Démonstrations en Interface Graphique (GUI)',
        'gui_desc': 'Les exemples suivants sont des projets visuels prêts à être compilés et exécutés via Lazarus :',
        'console_title': '💻 Démonstrations en Ligne de Commande (Console)',
        'console_desc': 'Ces exemples illustrent l\'utilisation directe des composants en ligne de commande pour le débogage rapide :',
        'screenshots_title': '🖼️ Galerie de Captures d\'Écran',
        'col_sample': 'Exemple / Chemin',
        'col_desc': 'Description',
        'col_pkg': 'Package Requis',
        'col_comps': 'Composants Utilisés',
        'no_desc': 'Aucune description disponible.',
        'category': 'Catégorie'
    },
    'it': {
        'title': 'Progetti di Dimostrazione (Samples)',
        'intro': 'Questa directory contiene la suite completa di esempi sviluppati per dimostrare e testare tutti i componenti di Intelligenza Artificiale, Machine Learning, Elaborazione Immagini, Elaborazione Segnali (DSP), Automazione Hardware e Generazione Documenti della suite Lazarus AI Suite.',
        'gui_title': '🖥️ Demo ad Interfaccia Grafica (GUI)',
        'gui_desc': 'I seguenti esempi sono progetti visuali pronti per la compilazione e l\'esecuzione interattiva tramite Lazarus:',
        'console_title': '💻 Demo a Riga di Comando (Console)',
        'console_desc': 'Questi esempi mostrano l\'invocazione diretta dei componentes da riga di comando per debug rapido o automazione:',
        'screenshots_title': '🖼️ Galleria degli Screenshot',
        'col_sample': 'Esempio / Percorso',
        'col_desc': 'Descrizione',
        'col_pkg': 'Pacchetto Richiesto',
        'col_comps': 'Componenti Usati',
        'no_desc': 'Nessuna descrizione disponibile.',
        'category': 'Categoria'
    },
    'ar': {
        'title': 'مشاريع توضيحية (Samples)',
        'intro': 'يحتوي هذا المجلد على مجموعة كاملة من الأمثلة والمشاريع المطورة لتوضيح واختبار جميع مكونات الذكاء الاصطناعي، تعلم الآلة، معالجة الصور، معالجة الإشارات الرقمية (DSP)، أتمتة الأجهزة، وتوليد المستندات لحزمة Lazarus AI Suite.',
        'gui_title': '🖥️ مشاريع توضيحية لواجهات المستخدم الرسومية (GUI)',
        'gui_desc': 'الأمثلة التالية عبارة عن مشاريع مرئية جاهزة للتجميع والتشغيل التفاعلي عبر لازاروس:',
        'console_title': '💻 مشاريع توضيحية لسطر الأوامر (Console)',
        'console_desc': 'توضح هذه الأمثلة الاستدعاء المباشر للمكونات عبر سطر الأوامر لسيناريوهات تصحيح الأخطاء السريعة وأتمتة العمليات الدورية:',
        'screenshots_title': '🖼️ معرض لقطات الشاشة (Screenshots)',
        'col_sample': 'المشروع / المسار',
        'col_desc': 'الوصف',
        'col_pkg': 'الحزمة المطلوبة',
        'col_comps': 'المكونات المستخدمة',
        'no_desc': 'لا يوجد وصف متاح.',
        'category': 'الفئة'
    }
}

# Known console samples and their descriptions
console_descriptions = {
    'pt': {
        'aiinput_sample.lpr': 'Demonstração em linha de comando de envio/recebimento de dados usando componentes da aba AI Input.',
        'numps_sample.lpr': 'Demonstração simples de console para operações matemáticas de matrizes e vetores com o NUMPS.',
        'aioutput_sample.lpr': 'Demonstração de console do componente de saída de dados estruturados em JSON ou texto puro.',
        'math_output_docs_demo.lpr': 'Geração simplificada de documentos e planilhas matemáticas via linha de comando.',
        'aivoicesynthesizer_sample.lpr': 'Invocação direta de sintetização síncrona/assíncrona de voz via console.',
        'aicodeassistant_sample.lpr': 'Rotina em console para otimização e documentação automática de código pascal.',
        'aidatasetgenerator_sample.lpr': 'Loop de compilação e exportação de base de dados em formato JSONL.',
        'chatgpt_sample.lpr': 'Envio de perguntas e auditoria de respostas brutas em OpenAI, Claude e Gemini.',
        'neuralnetwork_sample.lpr': 'Treinamento clássico de perceptron multicamadas XOR em Pascal puro.'
    },
    'en': {
        'aiinput_sample.lpr': 'Command-line demonstration of data input/output handling using AI Input components.',
        'numps_sample.lpr': 'Simple console application performing vector and matrix mathematical operations using NUMPS.',
        'aioutput_sample.lpr': 'Console test for structured JSON and plaintext output generation components.',
        'math_output_docs_demo.lpr': 'Simplified mathematical document and spreadsheet generator via command line.',
        'aivoicesynthesizer_sample.lpr': 'Direct console invocation of synchronous/asynchronous voice synthesis (TTS).',
        'aicodeassistant_sample.lpr': 'Console-based assistant to optimize and automatically document Delphi/Pascal code.',
        'aidatasetgenerator_sample.lpr': 'Automated dataset generation loop exporting data to JSONL format.',
        'chatgpt_sample.lpr': 'Query invocation and raw JSON payload audit for OpenAI, Claude, and Gemini.',
        'neuralnetwork_sample.lpr': 'Classic Multilayer Perceptron training simulator for XOR logic gates.'
    }
}

# Add default translated translations for other languages from English
for code in ['es', 'fr', 'it', 'ar']:
    console_descriptions[code] = console_descriptions['en']

KNOWN_COMPONENTS = {
    'TCHATGPT', 'TAISQLiteDictionary', 'TAIPostgreSQLDictionary', 'TAIVoiceSynthesizer', 
    'TYOLO', 'TCNNClassifier', 'TLSTMPredictor', 'TFaceDetection', 'TPythonConnector', 
    'TNeuralNetwork', 'TPerceptron', 'TSOMMap', 'TTokenList', 'TAIImageFilters', 
    'TAISoundFilters', 'TIASchedule', 'TAICameraInput', 'TAIMQTTClient', 'TAIEmailClient', 
    'TAIMessenger', 'TAIIndustrialBridge', 'TAIChromiumBrowser', 'TAIOSInputCapture', 
    'TAIGraphMap', 'TAITripo3dClient', 'TAI3DModelViewer', 'TAIModel3D', 'TAIOpenCV', 
    'TAIFrameProcessor', 'TAIFaceTracker', 'TAIMotionTracker', 'TAIScene2D3D', 
    'TAIAgent', 'TAIAgentOptions', 'TAIAgentAction', 'TAIAgentResource', 'TAIAgentOutput'
}

# Mapping between sample directories/names and their screenshots
SCREENSHOT_MAPPING = {
    'aiframeprocessor_demo': ('TAIFrameProcessor Demo.jpg', 'TAIFrameProcessor Demo'),
    'ai_sqlite_query_assistant_demo': ('ai_sqlite_query_assistant_demo.jpg', 'AI SQLite Query Assistant Demo'),
    'cnn_classifier_complete_demo': ('cnn_classifier_complete_demo.jpg', 'CNN Classifier Complete Demo'),
    'cnn_demo': ('cnn_demo.jpg', 'CNN Demo'),
    'db_dictionary_demo': ('db_dicitionary_demo.jpg', 'Database Dictionary Demo'),
    'disk_tree_ai_dataset_demo': ('disk_tree_ai_dataset_demo.jpg', 'Disk Tree AI Dataset Demo'),
    'docfilesmanager_demo': ('docfilesmanager_demo.jpg', 'Doc Files Manager Demo'),
    'image_info_demo': ('image_info_demo.jpg', 'Image Info Demo'),
    'math_input_output_demo': ('math_input_output_demo.jpg', 'Math Input Output Demo'),
    'pose_detector_demo': ('pose_detector_demo.jpg', 'Pose Detector Demo'),
    'python_demo': ('python_demo.jpg', 'Python Playground Demo'),
    'python_runtime_check_demo': ('python_runtime_check_demo.jpg', 'Python Runtime Check Demo'),
    'som_demo': ('som_demo.jpg', 'SOM Map Demo'),
    'sound_filters_demo': ('sound_filters.jpg', 'Sound Filters Demo'),
    'voicesynthesizer_demo': ('voicesynthesizer.jpg', 'Voice Synthesizer Demo')
}

def parse_readme_info(dir_path, lang_code, default_name, no_desc_text):
    candidates = [f"README.{lang_code}.md", "README.md"]
    for cand in candidates:
        filepath = os.path.join(dir_path, cand)
        if os.path.exists(filepath):
            try:
                content = ""
                for enc in ['utf-8', 'latin-1', 'cp1252']:
                    try:
                        with open(filepath, 'r', encoding=enc) as f:
                            content = f.read()
                        break
                    except Exception:
                        continue
                if not content:
                    continue
                
                lines = content.splitlines()
                title = default_name
                desc = no_desc_text
                
                # Find title
                for line in lines:
                    if line.strip().startswith('# '):
                        title = line.replace('# ', '').strip()
                        break
                        
                # Find first paragraph
                found_title = False
                for line in lines:
                    line_stripped = line.strip()
                    if line_stripped.startswith('# '):
                        found_title = True
                        continue
                    if found_title and line_stripped and not any(line_stripped.startswith(x) for x in ['#', '>', '*', '-', '|', '```']):
                        desc = line_stripped
                        break
                return title, desc
            except Exception:
                pass
    return default_name, no_desc_text

def scan_samples(samples_root, lang_code, trans):
    gui_samples = {}
    console_samples = {}
    
    gui_dir_set = set()
    
    for root, dirs, files in os.walk(samples_root):
        if any(x in root.lower() for x in ['backup', 'lib', '__pycache__']):
            continue
        lpi_files = [f for f in files if f.endswith('.lpi')]
        if lpi_files:
            gui_dir_set.add(root)
            lpi_file = lpi_files[0]
            lpi_path = os.path.join(root, lpi_file)
            
            rel_path = os.path.relpath(root, samples_root)
            parts = rel_path.split(os.sep)
            category = parts[0] if parts else "General"
            if category == ".":
                category = "General"
                
            packages = []
            try:
                tree = ET.parse(lpi_path)
                xml_root = tree.getroot()
                for pkg in xml_root.findall('.//RequiredPackages/Item/PackageName'):
                    val = pkg.attrib.get('Value')
                    if val and val != 'LCL':
                        packages.append(val)
            except Exception:
                pass
                
            found_comps = set()
            for f in files:
                if f.endswith('.pas') or f.endswith('.lpr'):
                    f_path = os.path.join(root, f)
                    try:
                        with open(f_path, 'r', encoding='utf-8', errors='ignore') as pf:
                            file_content = pf.read()
                            for comp in KNOWN_COMPONENTS:
                                if comp.lower() in file_content.lower():
                                    found_comps.add(comp)
                    except Exception:
                        pass
            
            title, desc = parse_readme_info(root, lang_code, lpi_file[:-4], trans['no_desc'])
            
            if category not in gui_samples:
                gui_samples[category] = []
                
            gui_samples[category].append({
                'name': lpi_file[:-4],
                'rel_path': rel_path.replace('\\', '/'),
                'title': title,
                'desc': desc,
                'packages': packages,
                'components': sorted(list(found_comps))
            })
            
    for root, dirs, files in os.walk(samples_root):
        if any(x in root.lower() for x in ['backup', 'lib', '__pycache__']):
            continue
        if root in gui_dir_set:
            continue
            
        lpr_files = [f for f in files if f.endswith('.lpr')]
        for lpr in lpr_files:
            rel_path = os.path.relpath(root, samples_root)
            parts = rel_path.split(os.sep)
            category = parts[0] if parts else "General"
            if category == ".":
                category = "General"
                
            lpr_path = os.path.join(root, lpr)
            found_comps = set()
            try:
                with open(lpr_path, 'r', encoding='utf-8', errors='ignore') as pf:
                    file_content = pf.read()
                    for comp in KNOWN_COMPONENTS:
                        if comp.lower() in file_content.lower():
                            found_comps.add(comp)
            except Exception:
                pass
                
            desc = console_descriptions.get(lang_code, {}).get(lpr, trans['no_desc'])
            
            if category not in console_samples:
                console_samples[category] = []
                
            console_samples[category].append({
                'name': lpr,
                'rel_path': os.path.join(rel_path, lpr).replace('\\', '/'),
                'desc': desc,
                'components': sorted(list(found_comps))
            })
            
    return gui_samples, console_samples

def generate():
    samples_root = r"D:\projetos\maurinsoft\CHATGPT\pacote\samples"
    
    for lang_code, trans in langs.items():
        gui, console = scan_samples(samples_root, lang_code, trans)
        
        if lang_code == 'pt':
            filenames = ["README.pt.md", "README.md"]
        else:
            filenames = [f"README.{lang_code}.md"]
            
        for filename in filenames:
            filepath = os.path.join(samples_root, filename)
            
            content = []
            content.append(f"# 📂 {trans['title']}")
            content.append("")
            content.append(f"> [!NOTE]")
            content.append(f"> {trans['intro']}")
            content.append("")
            
            content.append(f"## {trans['gui_title']}")
            content.append(trans['gui_desc'])
            content.append("")
            
            for category in sorted(gui.keys()):
                content.append(f"### 📦 {category}")
                content.append("")
                content.append(f"| {trans['col_sample']} | {trans['col_desc']} | {trans['col_pkg']} | {trans['col_comps']} |")
                content.append("|---|---|---|---|")
                
                for item in sorted(gui[category], key=lambda x: x['title']):
                    pkg_str = ", ".join(f"`{p}`" for p in item['packages']) if item['packages'] else "-"
                    comp_str = ", ".join(f"`{c}`" for c in item['components']) if item['components'] else "-"
                    
                    # Check if there is a screenshot mapping
                    link_suffix = ""
                    # match the folder name or project name
                    proj_name = item['name']
                    # check folder name as well (last part of rel_path)
                    folder_name = item['rel_path'].split('/')[-1]
                    
                    screenshot_file = None
                    for key, (sc_file, sc_title) in SCREENSHOT_MAPPING.items():
                        if key == proj_name or key == folder_name:
                            screenshot_file = sc_file
                            break
                            
                    if screenshot_file:
                        link_suffix = f" <br> <sub>[📷 Screenshot](../../screenshots/{screenshot_file})</sub>"
                        
                    content.append(f"| **[{item['title']}]({item['rel_path']}/)**{link_suffix} | {item['desc']} | {pkg_str} | {comp_str} |")
                content.append("")
                
            if console:
                content.append(f"## {trans['console_title']}")
                content.append(trans['console_desc'])
                content.append("")
                
                for category in sorted(console.keys()):
                    content.append(f"### ⌨️ {category}")
                    content.append("")
                    content.append(f"| {trans['col_sample']} | {trans['col_desc']} | {trans['col_comps']} |")
                    content.append("|---|---|---|")
                    
                    for item in sorted(console[category], key=lambda x: x['name']):
                        comp_str = ", ".join(f"`{c}`" for c in item['components']) if item['components'] else "-"
                        content.append(f"| **[{item['name']}]({item['rel_path']})** | {item['desc']} | {comp_str} |")
                    content.append("")
            
            # Add Screenshots Gallery Section at the end of the file
            content.append(f"## {trans['screenshots_title']}")
            content.append("")
            content.append("<p align=\"center\">")
            for key, (sc_file, sc_title) in sorted(SCREENSHOT_MAPPING.items(), key=lambda x: x[1][1]):
                content.append(f"  <img src=\"../../screenshots/{sc_file}\" width=\"45%\" alt=\"{sc_title}\" title=\"{sc_title}\" style=\"margin: 5px; border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);\" />")
            content.append("</p>")
            content.append("")
            
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write("\n".join(content))
                
            print(f"Generated: {filepath}")

if __name__ == '__main__':
    generate()