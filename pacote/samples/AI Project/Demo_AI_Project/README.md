# Demo_AI_Project

Incremental AI Project Planner visual GUI sample for Lazarus and Free Pascal.

This sample demonstrates the full lifecycle of the `TAIProject` component integrated with `TCHATGPT` to plan, revise, estimate, and schedule agile projects using LLMs or simulated data.

## Features Demonstrated

1. **LLM Connection Settings**: Set up OpenAI, OpenRouter, Cerebras, Claude, Gemini, or local Ollama configurations.
2. **Project Description**: Input project metadata (Goal, Scope, Context, Constraints) to build the planning prompts.
3. **Agile Documentation**: Displays automatically generated Business Vision, Functional/Non-Functional Requirements, Epics, User Stories, and a graphical **Risk Heat Matrix** (`TAIRiskMatrix`).
4. **Autonomous Project Agents**: Manage agents with specific tech roles (UI, DBA, DEV, Infra) and check task execution permissions.
5. **Interactive Gantt & Timeline**: Canvas-based rendering of project schedule progress (`TAIProjectGantt`) and timeline event milestones (`TAIProjectTimeline`).
6. **Revision Management**: Apply incremental project corrections (e.g., adding platform backends) and compare revision state JSON/Markdown.
7. **JSON Export & Storage**: Complete serialization of project states to `.aiproj.json` files.

## Running the Sample

1. Compile using Lazarus or `lazbuild`:
   ```bash
   lazbuild Demo_AI_Project.lpi
   ```
2. Launch `Demo_AI_Project` executable.
3. Keep the **Simulation Mode** checked to test offline with mock data, or uncheck and provide API keys/endpoint URLs to query your LLM provider.
