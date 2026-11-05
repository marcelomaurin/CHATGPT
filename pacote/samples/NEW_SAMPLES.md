# Exemplos adicionados após a revisão

Estes exemplos completam as demonstrações ausentes da documentação e das
funcionalidades de conversa e voz. Todos incluem fonte, projeto Lazarus e README.

| Sample | Demonstração |
|---|---|
| [modelregistry_demo](AI%20Core/modelregistry_demo/README.md) | AI Core |
| [promptbuilder_demo](AI%20Core/promptbuilder_demo/README.md) | AI Core |
| [training_exporter_demo](AI%20Graph/training_exporter_demo/README.md) | AI Graph |
| [training_report_demo](AI%20Graph/training_report_demo/README.md) | AI Graph |
| [wizard_config_demo](AI%20Agent/wizard_config_demo/README.md) | AI Agent |
| [chrome_speech_demo](AI%20Voice/chrome_speech_demo/README.md) | AI Voice |
| [topic_continuity_demo](AI%20Agent/topic_continuity_demo/README.md) | AI Agent |
| [person_session_demo](AI%20Agent/person_session_demo/README.md) | AI Agent |
| [presentation_agent_demo](AI%20Agent/presentation_agent_demo/README.md) | AI Agent |

O runner `python tests/run_missing_samples.py` compila e executa os nove exemplos
com FPC e as unidades reais da suíte em uma pasta temporária. A demonstração
de voz real (`--listen`) e o diálogo visual do wizard (`--visual`) são opcionais
e não fazem parte da execução automática. A validação de microfone, serviços
externos e Linux precisa ser registrada separadamente da compilação local.
