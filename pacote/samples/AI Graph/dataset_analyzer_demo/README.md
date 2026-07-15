# Dataset Analyzer Demo

Visual sample that loads a local `dataset.json` file, builds ingredient-to-dish links, analyzes selected ingredient nodes, and exports a ranking report.

## Tabs

- `Load Dataset`: loads and validates the local JSON file, lists ingredients, dishes, and relations, and shows a graph preview.
- `Analyze`: lets you select ingredient nodes and generates the 5 best matching dishes with similarity scores.
- `Report`: builds a text report with the ranking and the similarity degree for each category.

## Dataset model

The sample uses a dish-centric dataset:

- each `dish` is a category
- each ingredient becomes a node
- every ingredient is linked to the dish that uses it

The bundled `dataset.json` contains 50 dishes with ingredient sets inspired by Brazilian food.

## How to use

1. Open the `Load Dataset` tab and load the local JSON file.
2. Go to `Analyze`, select one or more ingredient nodes, and click `Analyze`.
3. Open `Report` to generate or export the classification report.

