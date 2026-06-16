# -*- coding: utf-8 -*-
import os

langs = {
    'pt': {
        'title': 'Documenta\u00e7\u00e3o da Aba AI Project',
        'intro': 'Esta pasta cont\u00e9m a paleta de componentes do Lazarus sob a aba **AI Project**.',
        'details': 'Refer\u00eancia Detalhada dos Componentes',
        'comp': 'Componente',
        'desc': 'Descri\u00e7\u00e3o',
        'props': 'Propriedades Importantes',
        'methods': 'M\u00e9todos Principais',
        'role': 'Papel do Agente de IA',
        'example': 'Exemplo de C\u00f3digo Lazarus',
        'dir': 'Diret\u00f3rio',
        'unified': 'Ponte de IA e Hardware'
    },
    'en': {
        'title': 'Documentation for AI Project Tab',
        'intro': 'This folder contains the Lazarus components suite under the **AI Project** tab.',
        'details': 'Detailed Component Reference',
        'comp': 'Component',
        'desc': 'Description',
        'props': 'Important Properties',
        'methods': 'Main Methods',
        'role': 'AI Agent Role',
        'example': 'Lazarus Code Example',
        'dir': 'Directory',
        'unified': 'AI and Hardware Bridge'
    },
    'es': {
        'title': 'Documentaci\u00f3n de la Pesta\u00f1a AI Project',
        'intro': 'Esta carpeta contiene la suite de componentes de Lazarus bajo la pesta\u00f1a **AI Project**.',
        'details': 'Referencia Detallada de Componentes',
        'comp': 'Componente',
        'desc': 'Descripci\u00f3n',
        'props': 'Propiedades Importantes',
        'methods': 'M\u00e9todos Principales',
        'role': 'Rol del Agente de IA',
        'example': 'Ejemplo de C\u00f3digo Lazarus',
        'dir': 'Directorio',
        'unified': 'Puente de IA y Hardware'
    },
    'fr': {
        'title': 'Documentation de l\'onglet AI Project',
        'intro': 'Ce dossier contient la suite de composants Lazarus sous l\'onglet **AI Project**.',
        'details': 'R\u00e9f\u00e9rence D\u00e9taill\u00e9e des Composants',
        'comp': 'Composant',
        'desc': 'Description',
        'props': 'Propri\u00e9t\u00e9s Importantes',
        'methods': 'M\u00e9thodes Principales',
        'role': 'R\u00f4le de l\'Agent d\'IA',
        'example': 'Exemple de Code Lazarus',
        'dir': 'Dossier',
        'unified': 'Pont d\'IA et de Mat\u00e9riel'
    },
    'it': {
        'title': 'Documentazione della Scheda AI Project',
        'intro': 'Questa cartella contiene la suite di componenti Lazarus sotto la scheda **AI Project**.',
        'details': 'Riferimento Dettagliato dei Componenti',
        'comp': 'Componente',
        'desc': 'Descrizione',
        'props': 'Propriet\u00e0 Importanti',
        'methods': 'Metodi Principali',
        'role': 'Ruolo dell\'Agente di IA',
        'example': 'Esempio di Codice Lazarus',
        'dir': 'Directory',
        'unified': 'Ponte di IA e Hardware'
    },
    'ar': {
        'title': '\u062a\u0648\u062b\u064a\u0642 \u0639\u0644\u0627\u0645\u0629 \u0627\u0644\u062a\u0628\u0648\u064a\u0628 AI Project',
        'intro': '\u064a\u062d\u062a\u0648\u064a \u0647\u0630\u0627 \u0627\u0644\u0645\u062c\u0645\u0648\u0639\u0629 \u0645\u0643\u0648\u0646\u0627\u062a \u0644\u0627\u0632\u0627\u0631\u0648\u0633 \u0636\u0645\u0646 \u0639\u0644\u0627\u0645\u0629 \u0627\u0644\u062a\u0628\u0648\u064a\u0628 **AI Project**.',
        'details': '\u0645\u0631\u062c\u0639 \u0627\u0644\u0645\u0643\u0648\u0646\u0627\u062a \u0627\u0644\u062a\u0641\u0635\u064a\u0644\u064a',
        'comp': '\u0627\u0644\u0645\u0643\u0648\u0646',
        'desc': '\u0627\u0644\u0648\u0635\u0641',
        'props': '\u0627\u0644\u062e\u0635\u0627\u0626\u0635 \u0627\u0644\u0647\u0627\u0645\u0629',
        'methods': '\u0627\u0644\u0623\u0633\u0627\u0644\u064a\u0628 \u0627\u0644\u0631\u0626\u064a\u0633\u064a\u0629',
        'role': '\u062f\u0648\u0631 \u0648\u0643\u064a\u0644 \u0627\u0644\u0630\u0643\u0627\u0621 \u0627\u0644\u0627\u0635\u0637\u0646\u0627\u0639\u064a',
        'example': '\u0645\u062b\u0627\u0644 \u0639\u0644\u0649 \u0643\u0648\u062f \u0644\u0627\u0632\u0627\u0631\u0648\u0633',
        'dir': '\u0627\u0644\u0645\u062c\u0644\u062f',
        'unified': '\u062c\u0633\u0631 \u0627\u0644\u0630\u0643\u0627\u0621 \u0627\u0644\u0627\u0635\u0637\u0646\u0627\u0639\u064a \u0648\u0627\u0644\u0623\u062c\u0647\u0632\u0629'
    }
}

data = {
    'icon': '[IA]',
    'pt': {
        'desc': 'Coordena\u00e7\u00e3o Avan\u00e7ada de Projetos de IA e Pipelines de Execu\u00e7\u00e3o.',
        'info': 'Centraliza e automatiza a conex\u00e3o entre os diversos m\u00f3dulos do projeto (Inputs, Redes Neurais, Agentes e Outputs de Documentos).',
        'comps': [
            {'name': 'TAIProject', 'desc': 'Coordenador e c\u00e9rebro global do projeto de IA.', 'props': 'ProjectName, Description, ChatGPT, Agent, Pipeline, DefaultProvider, DefaultModel, Token, LocalURL, SafeMode, SimulationMode', 'methods': 'Initialize, TestConnection, ExecuteText, Execute, LoadFromFile, SaveToFile, BuildSystemPrompt', 'role': 'Centralizar chaves de seguran\u00e7a, carregar configura\u00e7\u00f5es de arquivos JSON e disparar execu\u00e7\u00f5es de forma simulada ou em ambiente de produ\u00e7\u00e3o.'},
            {'name': 'TAIPipeline', 'desc': 'Conector de fluxos (Entrada -> Processamento -> Sa\u00edda) estruturados.', 'props': 'Mode (pmTextLLM, pmNumericML, pmAgentAction, pmDocumentGeneration, pmIndustrialMonitor), ChatGPT, NeuralNetwork, Agent, InputData, OutputData, OutputDocs, InputText, OutputText, AutoNormalize, AutoSoftMax', 'methods': 'Run, RunText, RunNumeric, RunAgent, RunDocument, RunIndustrialMonitor', 'role': 'Automatizar a ponte de dados ligando sensores (Input) \u00e0 predi\u00e7\u00e3o de Redes Neurais e formata\u00e7\u00e3o de relat\u00f3rios unificados (Output).'},
            {'name': 'TAIPromptBuilder', 'desc': 'Construtor de prompts din\u00e2micos a partir dos componentes do formul\u00e1rio.', 'props': 'IncludeComponentNames, IncludeOnlyAIComponents, IncludeActions, IncludeOutputs, IncludeInputs, LastPrompt', 'methods': 'BuildFromOwner, BuildFromComponents, ExtractPrompt', 'role': 'Varrer o formul\u00e1rio e agrupar dinamicamente as descri\u00e7\u00f5es (Prompt) de todas as ferramentas dispon\u00edveis para enviar ao ChatGPT.'}
        ]
    },
    'en': {
        'desc': 'Advanced AI Project Coordination and Execution Pipelines.',
        'info': 'Centralizes and automates the flow between various modules (Inputs, Neural Networks, Agents, and Document Exporters).',
        'comps': [
            {'name': 'TAIProject', 'desc': 'Global AI project coordinator and manager.', 'props': 'ProjectName, Description, ChatGPT, Agent, Pipeline, DefaultProvider, DefaultModel, Token, LocalURL, SafeMode, SimulationMode', 'methods': 'Initialize, TestConnection, ExecuteText, Execute, LoadFromFile, SaveToFile, BuildSystemPrompt', 'role': 'Centralize security keys, load JSON project setups, and execute routines under production or simulation modes.'},
            {'name': 'TAIPipeline', 'desc': 'Connects visual flows (Input -> Processing -> Output).', 'props': 'Mode (pmTextLLM, pmNumericML, pmAgentAction, pmDocumentGeneration, pmIndustrialMonitor), ChatGPT, NeuralNetwork, Agent, InputData, OutputData, OutputDocs, InputText, OutputText, AutoNormalize, AutoSoftMax', 'methods': 'Run, RunText, RunNumeric, RunAgent, RunDocument, RunIndustrialMonitor', 'role': 'Automatically bridges raw telemetry data to Neural Network classifiers or document formatters.'},
            {'name': 'TAIPromptBuilder', 'desc': 'Constructs dynamic system prompts scanning available form tools.', 'props': 'IncludeComponentNames, IncludeOnlyAIComponents, IncludeActions, IncludeOutputs, IncludeInputs, LastPrompt', 'methods': 'BuildFromOwner, BuildFromComponents, ExtractPrompt', 'role': 'Scan the owner form and assemble unified descriptions (Prompt) of all available tool components for ChatGPT.'}
        ]
    },
    'es': {
        'desc': 'Coordinaci\u00f3n Avanzada de Proyectos de IA y Pipelines de Ejecuci\u00f3n.',
        'info': 'Centraliza y automatiza la conexi\u00f3n entre los diversos m\u00f3dulos del projeto (Inputs, Redes Neuronales, Agentes y Documentos).',
        'comps': [
            {'name': 'TAIProject', 'desc': 'Coordinador global de proyectos de IA.', 'props': 'ProjectName, Description, ChatGPT, Agent, Pipeline, DefaultProvider, DefaultModel, Token, LocalURL, SafeMode, SimulationMode', 'methods': 'Initialize, TestConnection, ExecuteText, Execute, LoadFromFile, SaveToFile, BuildSystemPrompt', 'role': 'Centralizar credenciales, cargar configuraciones JSON y ejecutar simulaciones o en producci\u00f3n.'},
            {'name': 'TAIPipeline', 'desc': 'Conector de flujos (Entrada -> Procesamiento -> Salida) estruturados.', 'props': 'Mode (pmTextLLM, pmNumericML, pmAgentAction, pmDocumentGeneration, pmIndustrialMonitor), ChatGPT, NeuralNetwork, Agent, InputData, OutputData, OutputDocs, InputText, OutputText, AutoNormalize, AutoSoftMax', 'methods': 'Run, RunText, RunNumeric, RunAgent, RunDocument, RunIndustrialMonitor', 'role': 'Automatizar la transferencia de telemetr\u00ea hacia las Redes Neuronales y exportaci\u00f3n de reportes.'},
            {'name': 'TAIPromptBuilder', 'desc': 'Constructor de prompts din\u00e1micos escaneando componentes del formulario.', 'props': 'IncludeComponentNames, IncludeOnlyAIComponents, IncludeActions, IncludeOutputs, IncludeInputs, LastPrompt', 'methods': 'BuildFromOwner, BuildFromComponents, ExtractPrompt', 'role': 'Escanear el formulario y agrupar las descripciones (Prompt) de todas las herramientas para enviar a ChatGPT.'}
        ]
    },
    'fr': {
        'desc': 'Coordination Avanc\u00e9e de Projets d\'IA et Pipelines de Traitement.',
        'info': 'Centralise et automatise les flux d\'ex\u00e9cution entre les modules (Entr\u00e9e, Mod\u00e8les Neuronaux, Agents, Sortie de Documents).',
        'comps': [
            {'name': 'TAIProject', 'desc': 'Coordonnateur global de projets d\'IA.', 'props': 'ProjectName, Description, ChatGPT, Agent, Pipeline, DefaultProvider, DefaultModel, Token, LocalURL, SafeMode, SimulationMode', 'methods': 'Initialize, TestConnection, ExecuteText, Execute, LoadFromFile, SaveToFile, BuildSystemPrompt', 'role': 'Centraliser les configurations de s\u00e9curit\u00e9, charger les projets JSON et simuler des tests.'},
            {'name': 'TAIPipeline', 'desc': 'Connecteur de flux de donn\u00e9es (Entr\u00e9e -> Calcul -> Sortie).', 'props': 'Mode (pmTextLLM, pmNumericML, pmAgentAction, pmDocumentGeneration, pmIndustrialMonitor), ChatGPT, NeuralNetwork, Agent, InputData, OutputData, OutputDocs, InputText, OutputText, AutoNormalize, AutoSoftMax', 'methods': 'Run, RunText, RunNumeric, RunAgent, RunDocument, RunIndustrialMonitor', 'role': 'Automatiser le flux reliant les capteurs aux pr\u00e9dictions de r\u00e9seaux de neurones et aux PDF/Word.'},
            {'name': 'TAIPromptBuilder', 'desc': 'G\u00e9n\u00e9rateur de prompts dynamiques \u00e0 partir des composants du formulaire.', 'props': 'IncludeComponentNames, IncludeOnlyAIComponents, IncludeActions, IncludeOutputs, IncludeInputs, LastPrompt', 'methods': 'BuildFromOwner, BuildFromComponents, ExtractPrompt', 'role': 'Parcourir le formulaire et regrouper les descriptions (Prompt) de tous les outils disponibles pour ChatGPT.'}
        ]
    },
    'it': {
        'desc': 'Coordinamento Avanzato di Progetti IA e Pipeline di Esecuzione.',
        'info': 'Centralizza e automatizza il flusso di lavoro tra i vari moduli (Input, Reti Neurali, Agenti e Documenti).',
        'comps': [
            {'name': 'TAIProject', 'desc': 'Coordinatore globale di progetti di IA.', 'props': 'ProjectName, Description, ChatGPT, Agent, Pipeline, DefaultProvider, DefaultModel, Token, LocalURL, SafeMode, SimulationMode', 'methods': 'Initialize, TestConnection, ExecuteText, Execute, LoadFromFile, SaveToFile, BuildSystemPrompt', 'role': 'Centralizzare le credenziali API, salvare configurazioni JSON ed effettuare test in modalit\u00e0 simulata.'},
            {'name': 'TAIPipeline', 'desc': 'Connettore di flussi strutturati (Input -> Elaborazione -> Output).', 'props': 'Mode (pmTextLLM, pmNumericML, pmAgentAction, pmDocumentGeneration, pmIndustrialMonitor), ChatGPT, NeuralNetwork, Agent, InputData, OutputData, OutputDocs, InputText, OutputText, AutoNormalize, AutoSoftMax', 'methods': 'Run, RunText, RunNumeric, RunAgent, RunDocument, RunIndustrialMonitor', 'role': 'Inviare automaticamente dati normalizzati alle Reti Neurali e formattare i report.'},
            {'name': 'TAIPromptBuilder', 'desc': 'Costruttore di prompt dinamici scansionando i componenti del form.', 'props': 'IncludeComponentNames, IncludeOnlyAIComponents, IncludeActions, IncludeOutputs, IncludeInputs, LastPrompt', 'methods': 'BuildFromOwner, BuildFromComponents, ExtractPrompt', 'role': 'Scansionare il form e raggruppare le descrizioni (Prompt) di tutti gli strumenti disponibili per ChatGPT.'}
        ]
    },
    'ar': {
        'desc': '\u0627\u0644\u062a\u0646\u0633\u064a\u0642 \u0627\u0644\u0645\u062a\u0642\u062f\u0645 \u0644\u0645\u0634\u0627\u0631\u064a\u0639 \u0627\u0644\u0630\u0643\u0627\u0621 \u0627\u0644\u0627\u0635\u0637\u0646\u0627\u0639\u064a \u0648\u062e\u0637\u0648\u0637 \u0627\u0644\u0623\u0646\u0627\u0628\u064a\u0628 \u0627\u0644\u0628\u0631\u0645\u062c\u064a\u0629.',
        'info': '\u064a\u0631\u0643\u0632 \u0648\u064a\u0624\u062a\u0645\u062a \u0627\u0644\u0627\u062a\u0635\u0627\u0644 \u0628\u064a\u0646 \u0648\u062d\u062f\u0627\u062a \u0627\u0644\u0645\u0634\u0631\u0648\u0639 \u0627\u0644\u0645\u062e\u062a\u0644\u0641\u0629 (\u0627\u0644\u0645\u062f\u062e\u0644\u0627\u062a\u0606 \u0627\u0644\u0634\u0628\u0643\u0627\u062a \u0627\u0644\u0639\u0635\u0628\u064a\u0629\u0606 \u0627\u0644\u0648\u0643\u0644\u0627\u0621 \u0648\u062a\u0635\u062f\u064a\u0631 \u0627\u0644\u0645\u0633\u062a\u0646\u062f\u0627\u062a).',
        'comps': [
            {'name': 'TAIProject', 'desc': '\u0627\u0644\u0645\u0646\u0633\u0642 \u0648\u0627\u0644\u0645\u062d\u0631\u0643 \u0627\u0644\u0639\u0627\u0645 \u0644\u0645\u0634\u0631\u0648\u0639 \u0627\u0644\u0630\u0643\u0627\u0621 \u0627\u0644\u0627\u0635\u0637\u0646\u0627\u0639\u064a.', 'props': 'ProjectName, Description, ChatGPT, Agent, Pipeline, DefaultProvider, DefaultModel, Token, LocalURL, SafeMode, SimulationMode', 'methods': 'Initialize, TestConnection, ExecuteText, Execute, LoadFromFile, SaveToFile, BuildSystemPrompt', 'role': '\u062a\u0631\u0643\u064a\u0632 \u0645\u0641\u0627\u062a\u064a\u062d \u0627\u0644\u0623\u0645\u0627\u0646\u0606 \u062a\u062d\u0645\u064a\u0644 \u0625\u0639\u062f\u0627\u062f\u0627\u062a \u0627\u0644\u0645\u0634\u0627\u0631\u064a\u0639 \u0645\u0646 \u0645\u0644\u0641\u0627\u062a JSON \u0648\u062a\u0634\u063a\u064a\u0644 \u0645\u062d\u0627\u0643\u0627\u0629 \u0627\u0644\u0627\u062e\u062a\u0628\u0627\u0631\u0627\u062a.'},
            {'name': 'TAIPipeline', 'desc': '\u0645\u0648\u0635\u0644 \u062a\u062f\u0641\u0642 \u0627\u0644\u0628\u064a\u0627\u0646\u0627\u062a (\u0627\u0644\u0625\u062f\u062e\u0627\u0644 -> \u0627\u0644\u0645\u0639\u0627\u0644\u062c\u0629 -> \u0627\u0644\u0625\u062e\u0631\u0627\u062c) \u0627\u0644\u0645\u0647\u064a\u0643\u0644.', 'props': 'Mode (pmTextLLM, pmNumericML, pmAgentAction, pmDocumentGeneration, pmIndustrialMonitor), ChatGPT, NeuralNetwork, Agent, InputData, OutputData, OutputDocs, InputText, OutputText, AutoNormalize, AutoSoftMax', 'methods': 'Run, RunText, RunNumeric, RunAgent, RunDocument, RunIndustrialMonitor', 'role': '\u0623\u062a\u0645\u062a\u0629 \u0646\u0642\u0644 \u0628\u064a\u0627\u0646\u0627\u062a \u0627\u0644\u062d\u0633\u0627\u0633\u0627\u062a \u0627\u0644\u062e\u0627\u0645 \u0625\u0644\u064a \u0645\u0635\u0646\u0641\u0627\u062a \u0627\u0644\u0634\u0628\u0643\u0627\u062a \u0627\u0644\u0639\u0635\u0628\u064a\u0629 \u0648\u0625\u0635\u062f\u0627\u0631 \u0627\u0644\u062a\u0642\u0627\u0631\u064a\u0631.'},
            {'name': 'TAIPromptBuilder', 'desc': '\u0628\u0646\u0627\u0621 \u0627\u0644\u062a\u0648\u062c\u064a\u0647\u0627\u062a \u062f\u064a\u0646\u0627\u0645\u064a\u0643\u064a\u0627\u064b \u0645\u0646 \u062e\u0644\u0627\u0644 \u062e\u0627\u0635\u064a\u0629 \u0627\u0644\u0641\u062d\u0635.', 'props': 'IncludeComponentNames, IncludeOnlyAIComponents, IncludeActions, IncludeOutputs, IncludeInputs, LastPrompt', 'methods': 'BuildFromOwner, BuildFromComponents, ExtractPrompt', 'role': '\u0641\u062d\u0635 \u0627\u0644\u0646\u0645\u0648\u0630\u062c \u0648\u062a\u062c\u0645\u064a\u0639 \u0623\u0648\u0635\u0627\u0641 \u0645\u0648\u062d\u062f\u0629 (Prompt) \u0644\u062c\u0645\u064a\u0639 \u0627\u0644\u0645\u0643\u0648\u0646\u0627\u062a \u0648\u0627\u0644\u0623\u062f\u0648\u0627\u062a \u0627\u0644\u0645\u062a\u0627\u062d\u0629 \u0645\u0646 \u0623\u062c\u0644 \u0625\u0631\u0633\u0627\u0644\u0647\u0627 \u0625\u0644\u0649 ChatGPT.'}
        ]
    }
}

lazarus_example = """
```pascal
var
  MyProject: TAIProject;
  MyPipeline: TAIPipeline;
begin
  MyProject := TAIProject.Create(Self);
  MyPipeline := TAIPipeline.Create(Self);
  try
    MyProject.ProjectName := 'Smart Factory AI';
    MyProject.ChatGPT := ChatGPT1;
    MyProject.Pipeline := MyPipeline;
    
    MyPipeline.Mode := pmTextLLM;
    MyPipeline.ChatGPT := ChatGPT1;
    MyPipeline.InputText := 'Como otimizar c\u00f3digo em FPC?';
    
    if MyProject.Execute then
      ShowMessage(MyProject.LastResult)
    else
      ShowMessage(MyProject.LastError);
  finally
    MyPipeline.Free;
    MyProject.Free;
  end;
end;
```
"""

def generate():
    package_root = r"D:\projetos\maurinsoft\CHATGPT\pacote"
    folder_path = os.path.join(package_root, "AI Project")
    if not os.path.exists(folder_path):
        os.makedirs(folder_path)
        
    for lang_code, lang_trans in langs.items():
        lang_data = data[lang_code]
        filename = f"README.{lang_code}.md"
        filepath = os.path.join(folder_path, filename)
        
        # Build markdown content
        content = []
        content.append(f"# {data['icon']} {lang_trans['title']}")
        content.append("")
        content.append(f"> [!NOTE]")
        content.append(f"> {lang_trans['intro']}")
        content.append("")
        content.append(f"## {lang_data['desc']}")
        content.append(f"{lang_data['info']}")
        content.append("")
        content.append(f"### {lang_trans['details']}")
        content.append("")
        
        # Components table
        content.append(f"| {lang_trans['comp']} | {lang_trans['desc']} | {lang_trans['props']} | {lang_trans['methods']} | {lang_trans['role']} |")
        content.append("|---|---|---|---|---|")
        for c in lang_data['comps']:
            content.append(f"| **{c['name']}** | {c['desc']} | `{c['props']}` | `{c['methods']}` | {c['role']} |")
        content.append("")
        
        # Lazarus Code Example
        first_classname = lang_data['comps'][0]['name']
        content.append(f"### [Code] {lang_trans['example']} ({first_classname})")
        ex_code = lazarus_example.replace("{classname}", first_classname)
        content.append(ex_code)
        content.append("")
        
        # Unified Bridge mention
        content.append(f"### [Bridge] {lang_trans['unified']}")
        if lang_code == 'pt':
            content.append("Cada um destes componentes possui uma propriedade published `Prompt` que documenta sua API de forma transparente para orientar Agentes de IA (`TAIAgent`) de forma automática!")
        elif lang_code == 'en':
            content.append("Each of these components features a published `Prompt` property that transparently documents its API to guide AI Agents (`TAIAgent`) autonomously!")
        elif lang_code == 'es':
            content.append("Cada uno de estos componentes cuenta con una propiedad published `Prompt` que documenta de forma transparente su API para guiar a Agentes de IA (`TAIAgent`) de manera autónoma.")
        elif lang_code == 'fr':
            content.append("Chacun de ces composants int\u00e8gre une propri\u00e9t\u00e9 published `Prompt` documentant de mani\u00e8re transparente son API pour guider les agents d'IA (`TAIAgent`) de fa\u00e7on autonome.")
        elif lang_code == 'it':
            content.append("Ciascuno di questi componenti include una propriet\u00e0 published `Prompt` que documenta in modo trasparente le proprie API per orientare gli Agenti IA (`TAIAgent`) autonomamente.")
        elif lang_code == 'ar':
            content.append("\u064a\u062a\u0645\u064a\u0632 \u0643\u0644 \u0645\u0643\u0648\u0646 \u0645\u0646 \u0647\u0630\u0647 \u0627\u0644\u0645\u0643\u0648\u0646\u0627\u062a \u0628\u062e\u0627\u0635\u064a\u0629 \u0646\u0634\u0631 `Prompt` \u0648\u0627\u0644\u062a\u064a \u062a\u0648\u062b\u0642 \u0628\u0634\u0643\u0644 \u0634\u0641\u0627\u0641 \u0648\u062a\u0648\u062b\u064a\u0642 \u0648\u0627\u062c\u0647\u062a\u0647\u0627 \u0627\u0644\u0628\u0631\u0645\u062c\u064a\u0629 \u0644\u062a\u0648\u062c\u064a\u0647 \u0648\u0643\u0644\u0627\u0621 \u0627\u0644\u0630\u0643\u0627\u0621 \u0627\u0644\u0627\u0635\u0637\u0646\u0627\u0639\u064a (`TAIAgent`) \u0630\u0627\u062a\u064a\u0627\u064b!")
            
        content.append("")
        
        # Save file
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write("\n".join(content))
            
        print(f"Generated: {filepath}")

    # Also generate the main landing README.md for the folder
    readme_path = os.path.join(folder_path, "README.md")
    readme_content = """# [IA] Lazarus AI Suite - Tab: `AI Project`

> [!NOTE]
> Advanced AI Project Coordination and Execution Pipelines.

Please select your preferred language for the component reference manual:

---

## [Globe] Select Language / Selecione o Idioma

| Language | Country Flag | Documentation Link |
|---|---|---|
| **Portugu\u00eas (PT)** | BR / PT | [README.pt.md](README.pt.md) |
| **English (EN)** | US / GB | [README.en.md](README.en.md) |
| **Espa\u00f1ol (ES)** | ES / MX | [README.es.md](README.es.md) |
| **Fran\u00e7ais (FR)** | FR | [README.fr.md](README.fr.md) |
| **Italiano (IT)** | IT | [README.it.md](README.it.md) |
| **\u0627\u0644\u0639\u0631\u0628\u064a\u0629 (AR)** | AE / SA | [README.ar.md](README.ar.md) |

---

### [Bridge] AI and Hardware Integration
Each component in this folder features a published `Prompt` property that documents its API structure to automatically guide AI Agents (`TAIAgent`) in runtime.
"""
    with open(readme_path, 'w', encoding='utf-8') as f:
        f.write(readme_content)
    print(f"Generated Landing Index: {readme_path}")

if __name__ == '__main__':
    generate()
