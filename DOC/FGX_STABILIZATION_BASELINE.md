# Lazarus AI Suite - Stabilization Baseline

This document keeps CI evidence only. Local runs are excluded.

## C7.5 - Clean 16 x 2 CI baseline

Topological order follows C7.4. The previous alphabetical table is discarded.

| Package | Linux | Windows |
|---|---|---|
| `openai_core.lpk` | FAIL: Fatal: Can't find unit zcomponent | PASS |
| `openai_ml.lpk` | FAIL: Fatal: Can't find unit openai_core | PASS |
| `openai_files.lpk` | FAIL: Fatal: Can't find unit openai_core | PASS |
| `openai_output.lpk` | FAIL: Fatal: Can't find unit openai_core | PASS |
| `openai_input.lpk` | FAIL: Fatal: Can't find unit cef4delphi_lazarus | PASS |
| `openai_python.lpk` | FAIL: Fatal: Can't find unit openai_core | PASS |
| `openai_image.lpk` | FAIL: Fatal: Can't find unit openai_core | PASS |
| `openai_graphic.lpk` | FAIL: Fatal: Can't find unit openai_core | PASS |
| `openai_simulation.lpk` | FAIL: Fatal: Can't find unit openai_core | PASS |
| `openai_aidbase.lpk` | FAIL: Fatal: Can't find unit zcomponent | PASS |
| `openai_agent.lpk` | FAIL: Fatal: Can't find unit openai_core | PASS |
| `openai_industrial.lpk` | FAIL: Fatal: Can't find unit openai_core | PASS |
| `openai_vision.lpk` | FAIL: Fatal: Can't find unit openai_core | PASS |
| `openai_voice.lpk` | FAIL: Fatal: Can't find unit openai_core | PASS |
| `openai_project.lpk` | FAIL: Fatal: Can't find unit openai_core | PASS |
| `openai_graph.lpk` | FAIL: Fatal: Can't find unit openai_core | PASS |

Windows results come from `baseline-results/Windows.tsv`.

## C8 - Orphan Components

Computed from `DOC/fgx/factual_graph.json` as `component` nodes minus `demonstrated_by` edges.

- Components: 139
- With sample: 116
- Orphans: 23

| Component | Package |
|---|---|
| `TAIAgentOutput` | `openai_agent` |
| `TAIAgentResource` | `openai_agent` |
| `TAIAgentSafety` | `openai_agent` |
| `TAIAgileDocuments` | `openai_project` |
| `TAIEntityFactory` | `openai_simulation` |
| `TAIEvolutionEngine` | `openai_simulation` |
| `TAIFrameBuffer` | `openai_vision` |
| `TAIKinectAudio` | `openai_input` |
| `TAIProjectAgents` | `openai_project` |
| `TAIProjectDependencies` | `openai_project` |
| `TAIProjectReports` | `openai_project` |
| `TAIProjectReportViewer` | `openai_project` |
| `TAIProjectRevisions` | `openai_project` |
| `TAIProjectTimeline` | `openai_project` |
| `TAIPythonRuntime` | `openai_python` |
| `TAIRewardFunction` | `openai_graphic` |
| `TAIRiskMatrix` | `openai_project` |
| `TAIScenarioConfig` | `openai_simulation` |
| `TAIScenarioGenerator` | `openai_simulation` |
| `TAISensorVirtual` | `openai_graphic` |
| `TAITaskActionPanel` | `openai_project` |
| `TDBTokenList` | `openai_core` |
| `TGroupResponse` | `openai_core` |
