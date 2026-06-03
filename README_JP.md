# TCHATGPT — Lazarus / Free Pascal 向け AI Component Suite

🌍 **Languages / 言語**

* [Português (PT-BR)](README.md)
* [English (EN)](README_EN.md)
* [Español (ES)](README_ES.md)
* [Français (FR)](README_FR.md)
* [Italiano (IT)](README_IT.md)
* [العربية (AR)](README_AR.md)
* [中文 (ZH-CN)](README_ZH.md)
* [Русский (RU)](README_RU.md)
* [日本語 (JA)](README_JA.md)

---

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Lazarus](https://img.shields.io/badge/Lazarus-3.x-orange.svg)](https://www.lazarus-ide.org/)
[![Free Pascal](https://img.shields.io/badge/Free%20Pascal-FPC-blue.svg)](https://www.freepascal.org/)
[![Status](https://img.shields.io/badge/status-in%20development-yellow.svg)]()

---

## プロジェクト概要

**TCHATGPT** は、**Lazarus / Free Pascal** 向けのオープンソースのコンポーネントスイートです。
視覚コンポーネントおよび非視覚コンポーネントを提供し、デスクトップアプリケーション、産業向けシステム、教育用ソフトウェア、企業システムへ人工知能機能を統合しやすくすることを目的としています。

本プロジェクトは、LLM プロバイダーへの接続、ローカルモデル、データ処理、機械学習、音声合成、画像処理、インテリジェントエージェント、グラフ構造、入力・出力チャネルなどの機能を提供します。
また、コンピュータビジョンや 3D グラフィック関連の実験的コンポーネントも含まれています。

> 本プロジェクトは、**Lazarus アプリケーションへ AI を統合するためのコンポーネントスイート**として位置付けられます。
> 専門的な学習フレームワーク、MLOps プラットフォーム、大規模なモデルデプロイ基盤を置き換える完全な AI プラットフォームではありません。

---

## プロジェクトの目的

本プロジェクトの主な目的は、Lazarus / Free Pascal 開発者が、シンプルで再利用可能なコンポーネントベースの方法により、自身のシステムへ人工知能機能を追加できるようにすることです。

このスイートは、以下のような用途を想定しています。

* 生成 AI アシスタントの作成；
* LLM API との統合；
* 互換サーバーを通じたローカルモデルの利用；
* データセットの生成と分析；
* 簡易的なテキスト分類；
* インテリジェントエージェントによる自動化；
* テキスト読み上げ；
* 基本的な画像処理；
* デジタル音声フィルタ；
* デバイス、センサー、外部チャネルとの統合；
* Lazarus による AI アプリケーションのプロトタイピング。

---

## 現在のプロジェクト状態

本プロジェクトは現在も活発に開発中であり、各コンポーネントの成熟度と安定性には差があります。

### 比較的成熟しているコンポーネント

* `TCHATGPT`
* `TAIBaseComponent`
* `TNeuralNetwork`
* `TTokenList`
* `TAICodeAssistant`
* `TAIDatasetGenerator`
* `TAIVoiceSynthesizer`
* 画像フィルタ
* 音声フィルタ
* グラフおよびデータセット関連コンポーネント

### 実験的または発展中のコンポーネント

* Python 統合；
* CNN、YOLO、LSTM、SOM コンポーネント；
* 自律型エージェントコンポーネント；
* 高度な入力・出力コンポーネント；
* OpenCV コンポーネント；
* 3D 可視化；
* Tripo3D 統合；
* 産業向け、カメラ、音声、ブラウザ、MQTT、Modbus、CCTV 関連コンポーネント。

---

## コンポーネントパレットの分類

このパッケージは、Lazarus のコンポーネントパレットにコンポーネントをインストールし、機能領域ごとに分類します。

---

## AI Core

生成 AI、機械学習、プロジェクト基盤を支援する主要コンポーネントです。

### `TCHATGPT`

生成 AI プロバイダー向けの主要コネクタです。

プロンプト送信、プロバイダー設定、モデル選択、構造化された応答の取得を行えます。

対応予定または対応済みのプロバイダー：

* OpenAI；
* Google Gemini；
* Anthropic Claude；
* OpenRouter；
* Cerebras；
* `/v1/chat/completions` と互換性のあるローカルサーバー；
* Ollama または類似のローカルサービス。

### `TNeuralNetwork`

Pascal で実装されたシンプルな多層ニューラルネットワークです。

以下の用途に利用できます。

* ローカルニューラルネットワークの作成；
* 入力層、隠れ層、出力層の設定；
* epoch 単位での学習；
* loss の計算；
* モデルの保存と読み込み。

### `TTokenList`

基本的なテキストトークン化用の補助コンポーネントです。

以下に利用できます。

* 分類；
* テキスト分析；
* 前処理；
* 意思決定グラフ；
* データセット準備。

### `TAICodeAssistant`

LLM ベースのコードアシスタントコンポーネントです。

以下に利用できます。

* コードレビュー；
* 改善提案；
* コメント生成；
* コードブロックの説明；
* テスト支援；
* ルーチンの変換または文書化。

### `TAIDatasetGenerator`

学習、fine-tuning、またはローカル分類向けのデータセット生成コンポーネントです。

対応予定または対応済みの構造：

* CSV；
* JSON；
* JSONL；
* ローカル学習用の入力・出力行列。

### `TAIModelRegistry`

モデル、プロバイダー、endpoint、パラメータを管理する中央レジストリです。

以下を整理できます。

* モデル名；
* プロバイダー；
* endpoint；
* temperature；
* token 上限；
* デフォルトパラメータ。

### `TAIWizardConfig`

新しい AI プロジェクト向けの設定ウィザードです。

以下のようなプロジェクト準備に利用できます。

* chatbot；
* classifier；
* pipeline；
* agent；
* 技術アシスタント。

---

## AI Sound Filters

デジタル信号処理および音声フィルタリング用のコンポーネントです。

### `TLowPassFilter`

一次 IIR ローパスフィルタです。

急激な変化を滑らかにし、高周波ノイズを低減するために使用されます。

### `THighPassFilter`

一次 IIR ハイパスフィルタです。

低周波成分、オフセット、DC ノイズを除去するために使用されます。

### `TAverageFilter`

移動平均フィルタです。

信号の単純な平滑化に使用されます。

### `TFDMMultiplexer`

周波数分割多重化コンポーネントです。

異なる周波数帯域上の複数チャネルをシミュレーションできます。

### `TTDMMultiplexer`

時分割多重化コンポーネントです。

時間スロットによって複数チャネルを交互に扱うことができます。

### `TCDMMultiplexer`

CDM/CDMA コンポーネントです。

直交コードを使用して信号を分離します。

### `TOFDMMultiplexer`

FFT/IFFT を使用する OFDM コンポーネントです。

通信分野の学習、研究、シミュレーションに役立ちます。

---

## AI Image

基本的な画像処理用コンポーネントです。

### `TGrayscaleFilter`

画像をグレースケールへ変換します。

### `TNegativeFilter`

色の反転を適用します。

### `TBrightnessContrastFilter`

明るさとコントラストを調整します。

### `TBinarizationFilter`

しきい値処理を適用し、白黒画像を生成します。

### `TBlurFilter`

畳み込みにより画像を平滑化します。

### `TSharpenFilter`

畳み込みカーネルを使って画像の鮮明度を向上させます。

### `TSobelFilter`

Sobel 演算子を使用してエッジを検出します。

### `TErosionDilationFilter`

収縮および膨張などのモルフォロジー処理を実行します。

---

## AI Schedule

タスクの整理、永続化、依存関係管理のためのコンポーネントです。

### `TJSONGroupStorage`

JSON 形式でグループ化されたデータを保存するコンポーネントです。

以下に利用できます。

* 設定の保存；
* パラメータの永続化；
* テキストの保存；
* グループ単位でのデータ整理。

### `TIASchedule`

依存関係制御を備えたタスク管理コンポーネントです。

以下をモデル化できます。

* 親タスク；
* 子タスク；
* 依存関係；
* 実行可能状態；
* 簡易的な実行制御。

---

## AI Voice

音声合成用コンポーネントです。

### `TAIVoiceSynthesizer`

Text-to-Speech コンポーネントです。

Windows では SAPI を利用できます。
Linux では eSpeak/eSpeak-NG を利用できます。

主な機能：

* テキストの読み上げ；
* 音量調整；
* 読み上げ速度の調整；
* 利用可能な音声一覧の取得；
* 非同期実行；
* デスクトップアプリケーションとの統合。

---

## AI Agent

インテリジェントエージェントおよび構造化された意思決定のためのコンポーネントです。

### `TAIAgent`

インテリジェントエージェントのオーケストレーションコンポーネントです。

LLM へ指示を送信し、構造化された応答を解釈し、アクションを調整できます。

### `TAIAgentOptions`

コンテキスト、質問、指示、分析ルールを保存します。

### `TAIAgentAction`

エージェントが実行可能なアクションを定義します。

以下を設定できます。

* 利用可能なアクション；
* 期待されるパラメータ；
* 実行コールバック。

### `TAIAgentResource`

エージェントが呼び出せる外部リソースを表します。

例：

* ファイル；
* email；
* HTTP；
* SMS；
* WhatsApp；
* TCP/UDP；
* Web APIs。

### `TAIAgentOutput`

エージェントの判断を実際のシステムリソースへ接続する出力層です。

---

## AI Graph

データ構造化、グラフ、データセット処理用のコンポーネントです。

### `TAIGraphMap`

token ベースの分類および分析に使用する重み付きグラフです。

以下に利用できます。

* テキスト分類；
* 概念のグループ化；
* 用語間の関係；
* 簡易的なトピック分析。

### `TAITrainingExporter`

学習データのエクスポートコンポーネントです。

対応予定または対応済みの形式：

* CSV；
* JSON；
* JSONL；
* ARFF；
* 数値ベクトル。

### `TAIDatasetAnalyzer`

データセット品質分析コンポーネントです。

以下を検出できます。

* 空のカテゴリ；
* 重複サンプル；
* クラス不均衡；
* 短すぎるテキスト；
* 長すぎるテキスト。

### `TAITrainingReport`

学習に関する技術レポート生成コンポーネントです。

以下を記録できます。

* accuracy；
* error；
* loss；
* token 数；
* 平均 confidence；
* データセット統計。

### `TAIGraphVisualizer`

グラフのエクスポートおよび可視化コンポーネントです。

対応予定または対応済みの形式：

* DOT / GraphViz；
* Mermaid；
* 可視化用 JSON。

---

## AI Input

データ入力および外部ソース統合用のコンポーネントです。

この分類には、情報取得、通信、デバイスやシステムとの統合に関するコンポーネントが含まれます。

対応予定または開発中のコンポーネント：

* カメラ；
* 音声；
* Web サーバー；
* sockets；
* シリアル通信；
* POS プリンタ；
* CCTV/IP；
* Modbus；
* MQTT；
* email；
* messaging；
* OS キャプチャ；
* 組み込みブラウザ；
* 産業用入力。

> この分類の一部コンポーネントは、外部ライブラリ、ドライバ、OS 権限、追加サービスを必要とする場合があります。

---

## AI Output

データ出力、文書生成、外部送信先との統合用コンポーネントです。

対応予定または開発中のリソース：

* 文書生成；
* 応答のエクスポート；
* 構造化出力；
* 外部チャネル統合；
* 応答の自動化。

---

## AI Vision

コンピュータビジョン用コンポーネントです。

対応予定または開発中のコンポーネント：

* OpenCV；
* カメラ取得；
* フレーム処理；
* 顔追跡；
* 動き追跡；
* 画像分類；
* 物体検出。

> 完全なデモ、依存関係の文書化、統合テストが整備されるまでは、この領域は実験的機能として扱うべきです。

---

## AI Graphic

AI、シミュレーション、可視化に関連するグラフィックおよび 3D コンポーネントです。

対応予定または開発中のコンポーネント：

* 2D/3D シーン；
* 学習環境；
* 物理シミュレータ；
* 仮想センサー；
* reward function；
* 3D モデル可視化；
* skeleton rig；
* avatar controller；
* ポーズライブラリ；
* アニメーションシーケンス；
* 3D モデル生成との統合。

### `TAI3DModelViewer`

3D モデルビューアです。

目的：

* 3D モデルの読み込み；
* mesh の表示；
* 回転；
* 拡大；
* 縮小；
* solid、wireframe、point モードの切り替え。

### `TAITripo3DClient`

外部 3D モデル生成サービスとの統合クライアントです。

目的：

* テキストからモデルを生成；
* 画像からモデルを生成；
* 複数画像からモデルを生成；
* 生成された 3D モデルをダウンロード。

> 外部サービスとの統合は、利用するプロバイダーの公式 API ドキュメントに基づいて検証する必要があります。

---

## Lazarus へのパッケージインストール

1. Lazarus を開きます。
2. **Package > Open Package File (.lpk)** を選択します。
3. `pacote/openai.lpk` を選択します。
4. **Compile** をクリックします。
5. 次に **Use > Install** をクリックします。
6. Lazarus は IDE の再構築を要求します。
7. 再起動後、コンポーネントはコンポーネントパレットに表示されます。

---

## LLM プロバイダー

| プロバイダー                      | Enum             | 種類              |
| --------------------------- | ---------------- | --------------- |
| OpenAI                      | `AIP_OPENAI`     | 外部 API          |
| OpenRouter                  | `AIP_OPENROUTER` | 外部 API / アグリゲータ |
| Cerebras                    | `AIP_CEREBRAS`   | 外部 API          |
| Google Gemini               | `AIP_GEMINI`     | 外部 API          |
| Anthropic Claude            | `AIP_CLAUDE`     | 外部 API          |
| Local / Ollama / compatible | `AIP_LOCAL`      | ローカルサーバー        |

> モデル名、制限、料金、利用可能性はプロバイダーごとに変更される可能性があります。使用するサービスの公式ドキュメントを必ず確認してください。

---

## 要件

### 主な環境

* Lazarus 3.x 以上；
* 互換性のある Free Pascal バージョン；
* Windows または Linux；
* `openai.lpk` パッケージ；
* 外部プロバイダー利用時のインターネット接続；
* オフラインモデル利用時のローカルサーバー設定。

### Windows

HTTPS 通信には、アプリケーションのアーキテクチャに対応した OpenSSL DLL が必要になる場合があります。

`pacote/lib/` フォルダを確認してください。

必要な DLL を最終実行ファイルと同じフォルダにコピーすることを推奨します。

### Linux

使用するコンポーネントによっては、以下の追加パッケージが必要になる場合があります。

* OpenSSL；
* eSpeak/eSpeak-NG；
* libpython；
* カメラまたは音声ライブラリ；
* コンピュータビジョン関連ライブラリ。

要件は使用するコンポーネントによって異なる場合があります。

---

## Screenshots

> 以下の画像は、すでにテスト済み、または現在開発中の機能を示しています。
> 新しいコンポーネントには、まだ完全な視覚デモが存在しない場合があります。

### CNN Demo

![CNN Demo](screenshots/cnn_demo.jpg)

画像分類デモ。

### Math Input / Output Demo

![Math Input Output Demo](screenshots/math_input_output_demo.jpg)

数学コンポーネントのデモ。

### Python Connector Demo

![Python Demo](screenshots/python_demo.jpg)

Python 統合デモ。

### SOM Demo

![SOM Demo](screenshots/som_demo.jpg)

自己組織化マップのデモ。

### Sound Filters Demo

![Sound Filters](screenshots/sound_filters.jpg)

音声フィルタのデモ。

### Voice Synthesizer Demo

![Voice Synthesizer](screenshots/voicesynthesizer.jpg)

音声合成デモ。

---

## 既知の制限

本プロジェクトは現在も開発中であり、安定性の異なるコンポーネントを含んでいます。

現在想定される制限：

* 一部のコンポーネントは実験段階である可能性があります；
* すべてのコンポーネントに完全なデモがあるわけではありません；
* 外部統合は第三者 API に依存します；
* コンピュータビジョンコンポーネントは外部ライブラリを必要とする場合があります；
* Python コンポーネントは互換性のあるバージョンとアーキテクチャに依存します；
* production 利用前に各コンポーネントを検証する必要があります；
* 自動テストと継続的インテグレーションは今後拡張が必要です。

---

## Roadmap

### 短期

* コンポーネント文書の見直し；
* コンポーネントパレット分類名を英語へ統一；
* 安定コンポーネントと実験コンポーネントを分離；
* 各コンポーネントに最小デモを追加；
* Windows および Linux でのパッケージコンパイル検証；
* README とソースコード間の不整合を修正。

### 中期

* 自動テストの作成；
* `lazbuild` による pipeline 作成；
* バージョン付き release の作成；
* 外部依存関係の文書化；
* エラー処理の改善；
* LLM、音声、画像、エージェントを使用した実用デモの作成。

### 長期

* プロジェクトテンプレートの作成；
* AI 設定用の視覚アシスタント作成；
* OpenCV コンポーネントの安定化；
* 3D コンポーネントの安定化；
* ローカルモデル統合の改善；
* 安全制御付きエージェントの発展；
* production 利用向けの完全な文書作成。

---

## このプロジェクトに適した利用者

このプロジェクトは以下に適しています。

* Lazarus 開発者；
* Free Pascal 開発者；
* 教師および学生；
* デスクトップ AI プロジェクト；
* ローカル自動化；
* 既存の企業システム；
* 教育アプリケーション；
* AI プロトタイプ；
* AI とデバイスの統合；
* コードベース全体を Python や JavaScript に移行せずに AI を必要とするシステム。

---

## 現時点でこのプロジェクトが適さない用途

現段階では、本プロジェクトは以下を置き換えるものではありません。

* 完全な machine learning framework；
* MLOps プラットフォーム；
* 企業向け training pipeline；
* 専門的なモデルデプロイサービス；
* PyTorch、TensorFlow、scikit-learn、完全な OpenCV などの専門ライブラリ；
* エンタープライズ規模の AI インフラ。

---

## コントリビューション

コントリビューションを歓迎します。

優先的な貢献領域：

* bug 修正；
* 機能デモ；
* 文書；
* 自動テスト；
* Windows/Linux 互換性；
* アイコンおよび screenshots；
* コンポーネント検証；
* エラー処理改善；
* AI プロバイダー統合；
* 各 Lazarus コンポーネント分類向け demo。

---

## License

本プロジェクトは **GNU General Public License v3.0** のもとで公開されています。

`LICENSE` ファイルを参照してください。

---

## Notice

本プロジェクトは外部 AI サービスを使用または統合します。
これらのサービスの利用には、費用、API 制限、プロバイダー固有のポリシー、第三者へのデータ送信が伴う場合があります。

production 環境で利用する前に：

* プロバイダーの利用条件を確認してください；
* API keys を保護してください；
* 許可なく機密データを送信しないでください；
* セキュリティ、プライバシー、コンプライアンスを検証してください；
* 実環境でコンポーネントの動作をテストしてください。

---

## 結論

**TCHATGPT** は、Lazarus / Free Pascal エコシステムに AI リソースを導入するための有望なコンポーネントスイートです。

その主な価値は、従来型アプリケーションと現代的な AI リソースをつなぐ実用的な橋渡しを提供することにあります。
これにより、デスクトップ、産業、教育、企業向けシステムは、LLM、音声、画像、グラフ、自動化、ローカルモデルをコンポーネントベースで統合できます。

本プロジェクトはまだ発展中ですが、Lazarus 向け AI コンポーネントの open source リファレンスとなるための重要な基盤をすでに備えています。
