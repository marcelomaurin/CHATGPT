# Project TaskList AI Demo

このサンプルは、Lazarus AI Suite の **AI Project** パッケージのコンポーネントを使用し、LLM の支援を受けた簡単なプロジェクト計画フローを作成する方法を示します。

このサンプルの現在の目的は、Lazarus フォームで次のことを実践的に示すことです。

1. AI プロバイダー/モデルを設定する。
2. プロジェクトの基本情報を入力する。
3. LLM に初期仕様を JSON 形式で生成させる。
4. LLM に技術タスクを生成させる。
5. プロジェクト状態を `ProjectData` に保存する。
6. タスクをグリッド、ステータス、JSON/log に表示する。
7. `.aiproj.json` ファイルを保存および読み込む。

> 重要: この README は、このサンプルが **現在実際に行っていること** を説明しています。将来的な理想形のデモを説明するものではありません。

---

## サンプルの実際の目的

`project_tasklist_ai_demo` は、次の要素の統合を示す概念実証です。

- Lazarus フォーム。
- `TCHATGPT` コンポーネント。
- 中心コンポーネント `TAIProject`。
- `AI Project` パッケージの補助コンポーネント。
- `AIProject1.ProjectData` に保持されるプロジェクト JSON 構造。

これはまだ完全なプロジェクト管理ツールではありません。また、このバージョンでは、完全にカプセル化されたコンポーネントだけで構成されたクリーンなデモでもありません。プロンプト、検証、JSON 統合の重要な部分は、まだ `main.pas` に実装されています。

---

## 現在実装されているフロー

### 1. AI 設定

**Config IA** タブで、ユーザーは次を選択します。

- プロバイダー。
- モデル。
- トークン。
- エンドポイント/ローカル URL。
- `TCHATGPT` コンポーネントの AI バージョン。

**Aplicar Configuração** をクリックすると、フォームは `AIProjectLLMConfig1` に値を設定し、`AIProject1` に設定を適用し、さらに `ChatGPT1` コンポーネントも直接更新します。

**Testar IA** ボタンは `ChatGPT1` に簡単な質問を送り、LLM の応答を待ちます。

### 2. プロジェクト基本情報

**Projeto** タブで、ユーザーは次を入力します。

- プロジェクト名。
- 説明/目的。
- 制約。
- 期待される成果物。

これらの情報は、`ProjectName`、`Goal`、`Constraints`、`ExpectedDeliverables` などの `AIProject1` プロパティにコピーされます。

### 3. AI による仕様生成

**Gerar Descrição Elaborada (IA)** ボタンは、仕様生成フローを実行します。

現在の実装では、プロンプトは `main.pas` 内で組み立てられ、`ChatGPT1.SendQuestion` によって送信され、JSON として解析され、`AIProject1.ProjectData` に統合されます。

期待される構造は次のとおりです。

```json
{
  "project": {
    "name": "...",
    "description": "...",
    "goal": "...",
    "context": "...",
    "scope": "...",
    "constraints": "...",
    "expected_deliverables": "..."
  },
  "agile_documents": {
    "business_vision": "...",
    "functional_requirements": [],
    "non_functional_requirements": [],
    "stakeholders": [],
    "risk_map": [],
    "epics": [],
    "user_stories": []
  }
}
```

生成されたドキュメントは `ProjectData.project` と `ProjectData.agile_documents` に統合されます。

### 4. AI によるタスク生成

**Gerar Tarefas com IA** ボタンは、現在のプロジェクト JSON を LLM に送信し、技術タスクの一覧を要求します。

期待される構造は次のとおりです。

```json
{
  "planning": {
    "tasks": [
      {
        "id": "T001",
        "epic_id": "E001",
        "title": "...",
        "description": "...",
        "long_description": "...",
        "acceptance_criteria": "...",
        "priority": "alta",
        "status": "draft",
        "dependency_type": "serial",
        "dependencies": [],
        "can_run_in_parallel": false,
        "estimated_hours": {
          "intern": 8,
          "junior": 6,
          "mid_level": 4,
          "senior": 2
        },
        "suggested_skill_level": "mid_level",
        "assigned_skill_level": "mid_level",
        "assigned_to": "DEV",
        "responsible_profile": "DEV",
        "planned_start_date": "2026-06-26",
        "planned_end_date": "2026-06-27",
        "estimated_duration_days": 1,
        "progress_percent": 0,
        "deliverable": "...",
        "notes": "...",
        "revision_created": 1,
        "revision_updated": 1
      }
    ]
  }
}
```

応答を検証した後、サンプルは `ProjectData.planning.tasks` を返されたタスクで置き換え、`AIProjectTasks1.RecalculateEstimates` を呼び出します。

### 5. タスク表示

**Tarefas** タブでは次を使用します。

- ステータス概要用の `TAIProjectStatusPanel`。
- タスク一覧用の `TAIProjectTaskGrid`。
- 選択されたタスクの詳細説明を表示する `MemoTaskDescription`。

グリッドで行を選択すると、サンプルは ID でタスクを検索し、`long_description` または `description` を memo に表示します。

### 6. JSON とログ

**JSON/Log** タブには次が表示されます。

- `AIProject1.ProjectData` の完全な JSON。
- 実行されたフローのログメッセージ。
- 解析または検証エラー発生時の LLM の元応答。

### 7. プロジェクトの保存と読み込み

**Salvar Projeto** ボタンは `AIProjectStorage1.SaveProjectToFile` を使用して次のファイルを保存します。

```text
project_tasklist_demo.aiproj.json
```

**Carregar Projeto** ボタンは `AIProjectStorage1.LoadProjectFromFile` を使用して同じファイルを読み込みます。

現在のバージョンでは、保存と読み込み時にも検証/要約のための補助的な LLM 呼び出しが行われます。これは現在のサンプルの挙動ですが、プロジェクト永続化には必須ではありません。

---

## 現在のフローで実際に統合されているコンポーネント

### `TCHATGPT` / `ChatGPT1`

LLM 通信に実際に使用されているコンポーネントです。

サンプルは直接次を呼び出します。

```pascal
ChatGPT1.SendQuestion(APrompt)
```

このコンポーネントは次に使用されます。

- 接続テスト。
- 仕様生成。
- タスク生成。
- 追加タスク生成。
- 要約生成。
- テキストレポート生成。
- JSON 検証/エクスポート。
- 保存前検証。
- クリア確認。

### `TAIProject` / `AIProject1`

このサンプルの中心コンポーネントです。

主構造は次に保持されます。

```pascal
AIProject1.ProjectData
```

サンプルは `AIProject1` を使用して次を保存します。

- プロジェクトデータ。
- `agile_documents` 内のアジャイル文書。
- `planning.tasks` 内のタスク一覧。
- 基本的なプロジェクト設定。
- `.aiproj.json` としてシリアライズ可能な状態。

また、次を呼び出します。

```pascal
AIProject1.EnsureProjectStructure;
```

これは最小限の JSON 構造が存在することを保証します。

### `TAIProjectLLMConfig` / `AIProjectLLMConfig1`

**Config IA** タブのデータを受け取り、`AIProject1` と `ChatGPT1` に設定を適用するために使用されます。

サンプルは次を使用します。

```pascal
AIProjectLLMConfig1.ApplyToProject;
```

さらにフォームは、モデル、トークン、エンドポイント、チャットタイプなど、一部の `ChatGPT1` プロパティを直接更新しています。

### `TAIProjectStorage` / `AIProjectStorage1`

プロジェクト永続化に使用されます。

使用されるメソッドは次のとおりです。

```pascal
AIProjectStorage1.SaveProjectToFile(...)
AIProjectStorage1.LoadProjectFromFile(...)
```

このコンポーネントは保存と読み込みのフローに実際に統合されています。

### `TAIProjectTasks` / `AIProjectTasks1`

`ProjectData` にすでに保存されているタスクを扱うために使用されます。

現在のバージョンでは主に次に使用されます。

```pascal
AIProjectTasks1.RecalculateEstimates;
AIProjectTasks1.TaskLongDescription[TaskID];
```

タスク生成自体はまだ `main.pas` で行われ、手動プロンプトが `ChatGPT1` に送信されます。

### `TAIProjectSpecification` / `AIProjectSpecification1`

このコンポーネントはフォームに存在し、`AIProject1` に接続されています。

ただし現在のサンプルでは、仕様生成はこのコンポーネントの公開メソッドを直接呼び出していません。仕様生成フローは `main.pas` で、手動プロンプト、手動解析、`ProjectData` への手動統合によって実行されています。

したがって、このコンポーネントは **存在して接続されています** が、**現在のフローの主な実行主体ではありません**。

### `TAIProjectTaskGrid` / `TaskGrid1`

実際に統合されている視覚コンポーネントです。

`ProjectData.planning.tasks` をグリッド形式で表示するために使用されます。

フォームは次を呼び出します。

```pascal
TaskGrid1.LoadTasks;
```

### `TAIProjectStatusPanel` / `StatusPanel1`

実際に統合されている視覚コンポーネントです。

現在のプロジェクトに基づいてステータスパネルを更新するために使用されます。

フォームは次を呼び出します。

```pascal
StatusPanel1.RefreshStatus;
```

### `TAITaskActions` / `AITaskActions1`

このコンポーネントはフォームに存在し、プロジェクトに接続されています。

現在のバージョンでは、示されている視覚フローの中心部分ではありません。このサンプルには、ユーザーに表示される完全なタスクアクション用タブまたはパネルはありません。

### `TAIProjectDescription` / `AIProjectDescription1`

このコンポーネントは存在し、プロジェクトに接続されています。

現在のサンプルでは、仕様生成またはタスク生成のメインフローで直接使用されていません。

---

## 存在または言及されているが、完全には示されていないコンポーネント

### Agents

以前のドキュメントでは、agents はサンプルから削除されたと説明されていました。しかし現在のプロジェクト状態では、削除はまだ完全ではありません。

サンプルにはまだ次が含まれています。

- `Agent` タブ。
- `TAIAgentManagerFrame`。
- agent units への参照。
- agent 生成に関係するボタンとメソッド。
- `.lpi` 内の `openai_agent` パッケージ依存。

そのため、agents は **部分的に存在** していますが、サンプルの主なフローは仕様生成とタスク生成です。

### Gantt と Timeline

以前の README では、Gantt と Timeline タブがメインフローの一部として説明されていました。

現在のバージョンでは、これらのタブはメインインターフェースで完全には示されていません。

`TAIProjectGantt` コンポーネントは `main.pas` で宣言されていますが、現在の画面にはフローに統合された完全な Gantt タブはありません。また、現在のフォームには完全な Timeline タブもありません。

### レポート

このサンプルには、要約、タスクレポート、agent レポート、Markdown エクスポート、JSON エクスポート用のボタンとメソッドがあります。

現在のバージョンでは、これらのレポートは `TAIProjectReports` に基づく完全な視覚フローではなく、フォーム内の LLM 呼び出しによって生成されます。

---

## 生成されるファイル

このサンプルはプロジェクトを固定ファイル名で保存します。

```text
project_tasklist_demo.aiproj.json
```

このファイルには、次を含む完全なプロジェクト JSON が格納されます。

- `project`。
- `agile_documents`。
- `planning.tasks`。
- `AIProject1.EnsureProjectStructure` によって保証されるその他の構造。

---

## 現在のフローの実行方法

1. Lazarus で `project_tasklist_ai_demo.lpi` を開きます。
2. コンパイルして実行します。
3. **Config IA** タブを開きます。
4. プロバイダーとモデルを選択します。
5. プロバイダーに応じて token または endpoint を入力します。
6. **Aplicar Configuração** をクリックします。
7. **Testar IA** をクリックして通信を検証します。
8. **Projeto** タブに移動します。
9. 名前、目的、制約、成果物を入力します。
10. 現在 **Tarefas** タブにある **Gerar Descrição Elaborada (IA)** で仕様を生成します。
11. **Gerar Tarefas com IA** でタスクを生成します。
12. **Tarefas** タブで結果を確認します。
13. **JSON/Log** タブで JSON とログを確認します。
14. **Salvar Projeto** でプロジェクトを保存します。
15. **Carregar Projeto** で再度読み込みます。

---

## このバージョンの既知の制限

- フォームにはまだ多くのプロンプト、解析、JSON 検証ロジックが集中しています。
- `TAIProjectSpecification` は接続されていますが、現在の仕様生成フローはまだ `main.pas` によって手動実行されています。
- `TAIProjectTasks` はタスクの再計算と参照に使われていますが、タスク生成はまだフォーム内で行われています。
- agents はまだサンプル内に部分的に残っていますが、デモの主目的ではありません。
- Gantt と Timeline はまだ完全なタブとしてフォームに表示されていません。
- Markdown エクスポートと JSON 検証は、専用のレポート/エクスポートコンポーネントだけでなく、まだ LLM 呼び出しを使用しています。
- 保存、読み込み、クリアにはまだ補助的な LLM 呼び出しがありますが、これらの操作はローカルで実行可能です。
- 保存ファイル名は固定の `project_tasklist_demo.aiproj.json` です。

---

## このバージョンの実際の範囲

このサンプルは、`TCHATGPT`、`TAIProject`、`TAIProjectLLMConfig`、`TAIProjectStorage`、`TAIProjectTasks`、`TAIProjectTaskGrid`、`TAIProjectStatusPanel` の初期統合を示す実践的なデモとして理解してください。

まだ `AI Project` パッケージの理想的なアーキテクチャを示す最終例として扱うべきではありません。
