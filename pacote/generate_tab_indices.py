# -*- coding: utf-8 -*-
import os

tabs = {
    'AI': {'icon': '🧠', 'desc': 'Core Artificial Intelligence & Neural Connectivity components.'},
    'AI Graph': {'icon': '📊', 'desc': 'Explainable weighted graph text classification models.'},
    'AI Agent': {'icon': '🤖', 'desc': 'Autonomous cognitive execution models and hardware pipelines.'},
    'AI Filtros Sonoros': {'icon': '🎵', 'desc': 'Linear wave filtering and noise-reduction signal processors.'},
    'AI Image': {'icon': '🖼️', 'desc': 'High-performance computer vision matrix filters.'},
    'AI Math': {'icon': '📐', 'desc': 'High-speed multi-threaded tensor algebra.'},
    'AI Input': {'icon': '🔌', 'desc': 'Sensors, cameras, Modbus, MQTT, CLP gateways, and OS-level inputs.'},
    'AI Output': {'icon': '📄', 'desc': 'Automated formal PDF, Word, Excel, and TXT document generators.'},
    'AI Schedule': {'icon': '📅', 'desc': 'Advanced cron-based periodic task engines.'},
    'AI Voice': {'icon': '🗣️', 'desc': 'Native multi-timbre Text-To-Speech (TTS) synthesizers.'},
    'AI Files': {'icon': '📁', 'desc': 'Directory scanning and structured document management for RAG and AI dataset preparation.'}
}

def generate_tab_indices():
    package_root = r"D:\projetos\maurinsoft\CHATGPT\pacote"
    for tab_name, info in tabs.items():
        folder_path = os.path.join(package_root, tab_name)
        if not os.path.exists(folder_path):
            os.makedirs(folder_path)
            
        readme_path = os.path.join(folder_path, "README.md")
        
        content = []
        content.append(f"# {info['icon']} Lazarus AI Suite — Tab: `{tab_name}`")
        content.append("")
        content.append(f"> [!NOTE]")
        content.append(f"> {info['desc']}")
        content.append("")
        content.append("Please select your preferred language for the component reference manual:")
        content.append("")
        content.append("---")
        content.append("")
        content.append("## 🌐 Select Language / Selecione o Idioma")
        content.append("")
        content.append("| Language | Country Flag | Documentation Link |")
        content.append("|---|---|---|")
        content.append("| **Português (PT)** | 🇧🇷 / 🇵🇹 | 📄 [README.pt.md](README.pt.md) |")
        content.append("| **English (EN)** | 🇺🇸 / 🇬🇧 | 📄 [README.en.md](README.en.md) |")
        content.append("| **Español (ES)** | 🇪🇸 / 🇲🇽 | 📄 [README.es.md](README.es.md) |")
        content.append("| **Français (FR)** | 🇫🇷 | 📄 [README.fr.md](README.fr.md) |")
        content.append("| **Italiano (IT)** | 🇮🇹 | 📄 [README.it.md](README.it.md) |")
        content.append("| **العربية (AR)** | 🇦🇪 / 🇸🇦 | 📄 [README.ar.md](README.ar.md) |")
        content.append("")
        content.append("---")
        content.append("")
        content.append("### ⚡ AI and Hardware Integration")
        content.append("Each component in this folder features a published `Prompt` property that documents its API structure to automatically guide AI Agents (`TAIAgent`) in runtime.")
        content.append("")
        
        with open(readme_path, 'w', encoding='utf-8') as f:
            f.write("\n".join(content))
            
        print(f"Generated Tab Index README: {readme_path}")

if __name__ == '__main__':
    generate_tab_indices()
