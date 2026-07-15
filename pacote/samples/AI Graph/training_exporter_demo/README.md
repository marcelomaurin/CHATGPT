# Training Exporter Demo (aitrainingexporter)

This sample shows how to load a local JSON dataset, train a `TAIGraphMap`, validate the generated training pairs, and export them with `TAITrainingExporter`.

## What this demo is for
- Load a real dataset from the sample folder.
- Convert ingredient-to-dish relations into training pairs.
- Preview the resulting graph visually.
- Export the same training data to CSV, JSON, JSONL, Graph JSON, GraphViz DOT, TXT, ARFF, or CSV ranking formats.

## Sample flow
1. Open the `Source Data` tab and load `dataset.json`.
2. Review the graph, categories, ingredients, and relation list.
3. Open the `Export` tab, choose the format, and export the file.
4. Read the `Report` tab for validation and summary details.

## Notes
- The demo does not use simulation mode.
- `TAIGraphMap` is required because the exporter uses the trained graph for validation, ranking, and graph-based export formats.
- The sample dataset is stored locally in the same folder as the project.

## Build and run
1. Open the project folder in Lazarus.
2. Make sure the `openai_graph` package is available.
3. Build the project with `Ctrl+F9` or `lazbuild`.
4. Run the demo and load the dataset if needed.
