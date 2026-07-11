# Sample: agent_task_memory_action_demo

## 利用可能な翻訳

- [Português](README.md)
- [English](README.en.md)
- [Français](README.fr.md)
- [日本語](README.ja.md)
- [Deutsch](README.de.md)
- [Русский](README.ru.md)
- [中文](README.zh.md)
- [Español](README.es.md)
- [Italiano](README.it.md)
- [العربية](README.ar.md)

---

このサンプルは、実行メモリ、LLM によるタスク計画、認知処理、実際の Chromium ブラウザ自動化、アクション生成、メール送信を組み合わせた、タスク指向のマルチエージェントワークフローを示します。

中心となる考え方は、ユーザーの自由入力プロンプトを監査可能なタスク列へ変換することです。各タスクには ID、順序、種類、説明、担当エージェント、推奨アクション、依存関係、パラメータ、状態、結果が含まれます。

---

## サンプルの目的

**AI Agent** パッケージのコンポーネントが連携して、複合的な要求を処理する方法を示します。

1. 実際の Web サイトを Chromium で開く。
2. ページ本文を取得する。
3. LLM で中間タスクを作成する。
4. 取得した内容を認知処理する。
5. プロフェッショナルな要約を生成する。
6. 結果をフォームの結果欄へコピーする。
7. メール本文を準備する。
8. `TAIEmailClient` でユーザー確認後にメールを送信する。
9. 全処理をメモリマップへ記録する。

これは単なるテスト画面ではなく、エージェント、実アクション、実行メモリ、Web UI 自動化の実用的なオーケストレーション例です。

---

## 標準シナリオのプロンプト

```text
Entre no site https://maurinsoft.com.br/wp/sobre-nos/ pegue meu curriculo na pagina e crie um resumo profissional. Mande este resumo profissional e mande para o email marcelomaurinmartins@gmail.com. Não grave arquivo. Não gere TXT, DOCX ou Word. Copie o texto do resumo diretamente no corpo do e-mail.
```

ブラウザシナリオボタンは同等のプロンプトを読み込みます。

```text
Entre no site https://maurinsoft.com.br/wp/sobre-nos/ pegue meu curriculo, analise e crie um resumo e mande para marcelomaurinmartins@gmail.com. Não grave arquivo. Não gere TXT, DOCX ou Word. Copie o texto do resumo diretamente no corpo do e-mail.
```

重要なルールは、**生成された要約をメール本文へ直接コピーすること**です。TXT、DOCX、Word、添付ファイルは生成しません。

---

## ワークフローの動作

### 1. ユーザー入力

**Prompt** タブで、AI プロバイダ、モデル、トークン、Base URL、メインプロンプトを設定します。OpenAI と `/v1/chat/completions` 互換のローカルエンドポイントをサポートします。

### 2. URL 検出

`ExtractURLFromPrompt` がプロンプト内の最初の URL を検出します。URL が見つかると Chromium を初期化して実ページへ移動します。

### 3. ページ取得

ナビゲーション後、`TAIChromiumBrowser` が `body` セレクタのテキストを取得します。内容は `FCapturedWebText`、`browser.last_text`、`browser.last_result_text` に保存されます。

### 4. 分類

`TAIClassifierAgent` は元のプロンプトと取得済みコンテンツを受け取り、要求を分類し、`TAIAgentMemoryMap` にステップを記録します。

### 5. タスク計画

`TAIDecisionAgent` ベースの `FTaskPlannerAgent` が要求を JSON タスクリストに変換します。`LoadTasksFromPlannerJSON` が JSON を読み込み、依存関係を正規化し、タスクグリッドに表示します。

```json
{
  "tasks": [
    {
      "id": "T001",
      "order": 1,
      "type": "browser",
      "description": "Navigate to the requested page",
      "agent": "task_processor_agent",
      "suggested_action": "BROWSER_NAVIGATE",
      "depends_on": "",
      "parameters": { "url": "https://example.com" }
    }
  ]
}
```

### 6. 正規化

サンプルは ID、順序、依存関係、メール宛先、送信後のキャプチャ、許可されるアクション、要約アクションの認知タスク化を調整します。

### 7. 実行

実行前に状態、依存関係、必須パラメータを確認します。`BROWSER_*` タスクは `TAIActionExecutor` によって直接実行され、LLM がアクションを誤って変更することを防ぎます。認知タスクは `FTaskProcessorAgent` が処理します。

### 8. アクション実行

`SEND_EMAIL`、`CREATE_TEXT_DOCUMENT`、`REGISTER_RESULT` などは `BuildSingleActionJSON` で決定的に生成できます。必要に応じて `TAIActionBuilderAgent.BuildActionsWithRecovery` が認知結果を有効な操作パラメータへ変換します。

### 9. 最終結果

生成された要約は `memConteudoCurriculo`、`memCorpoEmail`、`last_summary_text`、`last_text_content` に入る必要があります。`<resumo_gerado>`、`[EMAIL]`、汎用テキストのまま送信してはいけません。

---

## 使用コンポーネント

- `TCHATGPT`: LLM 通信用コンポーネント。
- `TAIAgentMemoryMap`: 実行経路、分析、説明、アクション、質問、出力、情報損失を記録。
- `TAIClassifierAgent`: 初期プロンプトを分類。
- `TAIDecisionAgent` / `FTaskPlannerAgent`: タスクリストを生成。
- `TAIDecisionAgent` / `FTaskProcessorAgent`: 個別タスクを処理し認知結果を生成。
- `TAIActionBuilderAgent`: 認知結果を操作アクションへ変換。
- `TAIActionExecutor`: 登録済みアクションを実行し `ExecutionContext` を保持。
- `TAIEmailClient`: SMTP メール送信。
- `TAIChromiumBrowser` と `TChromiumWindow`: Chromium の実自動化。

登録済みブラウザアクション: `BROWSER_NAVIGATE`, `BROWSER_WAIT_SELECTOR`, `BROWSER_READ_PAGE`, `BROWSER_DOM_LIST`, `BROWSER_CAPTURE_TEXT`, `BROWSER_SET_VALUE`, `BROWSER_FOCUS`, `BROWSER_CLICK`, `BROWSER_PRESS_ENTER`, `BROWSER_SUBMIT_FORM`, `BROWSER_SCREENSHOT`。

---

## 画面タブ

- **Prompt**: 入力とプロバイダ設定。
- **Tarefas**: LLM が生成したタスク一覧。
- **Agente**: 現在のエージェント監査。
- **Mapa de Memória**: 構造化された実行履歴。
- **Resultado**: 生成テキストとメール項目。
- **Log**: 実行ログ。
- **Navegador Chromium**: 実ブラウザ。

---

## 実行コンテキスト

`FActionExecutor.ExecutionContext` はアクション間の共有メモリです。主なキーは `browser.last_dom_kind`、`browser.last_dom_selector`、`browser.last_dom_json`、`browser.last_text`、`browser.last_result_text`、`last_text_content`、`last_summary_text`、`last_text_filename` です。

---

## パイプライン概要

```text
Prompt
  -> TAIClassifierAgent.Classify
  -> TAIDecisionAgent.DecideAsTaskList
  -> LoadTasksFromPlannerJSON
  -> Task grid
  -> TaskProcessorAgent.ProcessTask
  -> ActionBuilderAgent.BuildActionsWithRecovery, when needed
  -> ActionExecutor.ExecutePreparedActionsReal
  -> Browser / E-mail / Result
  -> MemoryMap / Log
```

---

## 安全性と検証

空の宛先、プレースホルダー宛先、空のメール本文、プレースホルダー本文、不明なアクション、必須パラメータ不足をブロックします。実メール送信には必ず手動確認が必要です。

---

## 期待される結果

正しく実行されると、タスク生成、Chromium の実ナビゲーション、ページ内容の取得、**Resultado** へのプロ要約表示、メール本文への同じ要約のコピー、詳細ログ、エージェントのメモリマップが確認できます。
