# Python Connector Demo (`python_demo`)

このドキュメントは、Lazarus/Free Pascal アプリケーションで **`TPythonConnector`** コンポーネントを使うためのサンプル **`python_demo`** の説明です。

## 🌐 翻訳

| 言語 | ファイル |
|---|---|
| Português | `README.md` |
| English | `README.en.md` |
| Español | `README.es.md` |
| العربية | `README.ar.md` |
| Italiano | `README.it.md` |
| 日本語 | `README.ja.md` |
| 中文 | `README.zh.md` |
| Русский | `README.ru.md` |
| हिन्दी | `README.hi.md` |

---

## 1. 目的

このサンプルは、**`TPythonConnector`** を使って Lazarus アプリケーションに Python インタプリタを統合する方法を示します。Python の起動、スクリプト実行、出力取得、式の評価、Pascal と Python 間の変数交換を確認できます。

**CHATGPT** プロジェクト内で AI、画像処理、音声処理、機械学習などのより複雑なコンポーネントを使う前に、Python runtime が正しくインストールまたは組み込まれているかを検証するための基本サンプルです。

---

## 2. このサンプルで確認できること

- アプリケーションのアーキテクチャに合った Python ライブラリまたは実行ファイルの選択。
- Python インタプリタの有効化と無効化。
- 2 つの実行モード:
  - **`pemDLL`**: `python3.dll`、`python312.dll`、`libpython3.so` などを読み込む。
  - **`pemProcess`**: Python を永続的な外部プロセスとして実行する。
- **`ExecString`** によるスクリプト実行。
- **`LastOutput`** と **`LastError`** による標準出力とエラーの取得。
- **`GetVar`** と **`SetVar`** によるグローバル変数の読み書き。
- **`Eval`** による式の動的評価。
- アーキテクチャ、Python バージョン、実行モード、読み込まれたライブラリ、失敗した段階を含む診断レポート。

---

## 3. サンプル構成

```text
pacote/samples/AI/python_demo/
├── python_demo.lpi      # Lazarus プロジェクト
├── python_demo.lpr      # メインプログラム
├── main.pas             # フォームのロジックと TPythonConnector 連携
├── main.lfm             # フォーム定義
└── README.md            # ポルトガル語ドキュメント
```

このプロジェクトは **`LCL`** と **`openai_core`** パッケージに依存します。

---

## 4. 必要条件

### Lazarus / Free Pascal

- Lazarus がインストールされていること。
- **`openai_core`** パッケージがプロジェクトのパスから参照できること。
- **`python_demo.lpi`** からプロジェクトを開くこと。

### Python

このコンポーネントは Python **3.8 から 3.14** を対象に設定されています。

アーキテクチャは一致している必要があります。

| コンパイル済みアプリ | 必要な Python |
|---|---|
| Windows 64-bit | 64-bit Python |
| Windows 32-bit | 32-bit Python |
| Linux 64-bit | 64-bit の `libpython`/`python3` |
| Linux ARM/ARM64 | 同じアーキテクチャの `libpython`/`python3` |

**DLL/SO** モードを使う場合、環境によっては Python 開発用ライブラリも必要です。

Debian/Ubuntu の例:

```bash
sudo apt install python3 python3-dev libpython3-dev
```

---

## 5. ビルド方法

1. Lazarus を開きます。
2. 次のファイルを開きます。

```text
pacote/samples/AI/python_demo/python_demo.lpi
```

3. 以下でビルドします。

```text
Run > Build
```

または:

```text
Ctrl + F9
```

4. 生成された実行ファイルを起動します。

- Windows: `python_demo.exe`
- Linux: `python_demo`

---

## 6. 使い方

1. 一覧から Python の DLL、SO、または実行ファイルを選択します。
2. 最初のテストでは **Use External Process** を有効にしたままにします。
3. **Activate Python interpreter** をクリックします。
4. ログパネルを確認します。
5. デフォルトスクリプトを実行するか、memo に独自のスクリプトを書きます。
6. **SetVar**、**GetVar**、**Eval** を使って Pascal と Python 間のデータ交換を確認します。

---

## 7. 推奨クイックテスト

### スクリプト

memo に次を貼り付けます。

```python
x = 10
print("Hello from Python")
print("x =", x)
```

Python 実行ボタンをクリックします。

### 変数の読み取り

**Variable Name** に次を入力します。

```text
x
```

**GetVar** をクリックします。

期待値:

```text
10
```

### 式の評価

式フィールドに次を入力します。

```python
x + 50
```

期待される結果:

```text
60
```

### `SetVar` に関する注意

現在、**`SetVar` は値を文字列として保存します**。たとえば:

```text
Name: y
Value: 10
```

この場合、Eval では次を使ってください。

```python
int(y) + 50
```

次の式は避けます。

```python
y + 50
```

---

## 8. 実行モード

### `pemProcess` — 外部プロセス

最初のテストに推奨されるモードです。

利点:

- Python を Lazarus プロセスから分離しやすい。
- DLL/SO の競合によるクラッシュを減らせる。
- TensorFlow、OpenCV、Torch、Keras など重いライブラリの初期テストに向いている。
- `python.exe`、`python3.exe`、`python3` など、システムで見つかる実行ファイルを使う。

### `pemDLL` — 動的ライブラリ

Python をアプリケーションプロセス内に直接読み込みます。

利点:

- Python C API とより直接的に統合できる。
- 単純な呼び出しでは高速な場合がある。

注意点:

- アーキテクチャが完全に一致している必要がある。
- ライブラリが必須の C API 関数を export している必要がある。
- Python ライブラリのエラーが Lazarus プロセス全体を終了させる可能性がある。

---

## 9. 診断

Python を有効化すると、ログパネルに次の情報を含む診断レポートが表示されます。

- 検出された OS;
- Lazarus のアーキテクチャ;
- 実行モード;
- 設定されたパス;
- 読み込まれたライブラリまたは実行ファイル;
- Python バージョン;
- アーキテクチャ互換性;
- 見つかった必須関数;
- 最後の読み込みステップ;
- 最後のエラー。

コンポーネントの問題と判断する前に、このレポートを確認してください。多くの場合、原因はアーキテクチャ不一致、ライブラリ不足、または PATH の問題です。

---

## 10. よくある問題

| 症状 | 主な原因 | 対応 |
|---|---|---|
| `Failed to load python3.dll` | Python 未インストール、DLL 不足、またはアーキテクチャ不一致 | 実行ファイルと同じアーキテクチャの Python をインストールする |
| `Failed to load libpython` | Linux の開発パッケージ不足 | `python3-dev`/`libpython3-dev` をインストールする |
| Python は起動するが `GetVar` が失敗する | DLL モードで任意 API 関数が不足 | `pemProcess` を試す |
| `SetVar` 後に `y + 50` が失敗する | `SetVar` が文字列を注入する | `int(y) + 50` を使うか、スクリプトで `y = 10` を定義する |
| 出力が表示されない | `print` がない、または実行失敗 | `LastError` とログを確認する |
| ターミナルでは動くが Lazarus では動かない | IDE 内の PATH が異なる | Python の絶対パスを使う |

---

## 11. ベストプラクティス

- まず **`pemProcess`** でテストする。
- **`pemDLL`** は C API との直接統合が必要な場合に使う。
- Python と Lazarus のアーキテクチャを一致させる。
- 配布時は Python runtime をアプリケーションフォルダまたは `libs` サブフォルダに配置する。
- エラー報告時は診断レポートを必ず添付する。
- memo に長いスクリプトを直接書かず、短いテストから段階的に確認する。

---

## 12. CHATGPT プロジェクトとの関係

このサンプルは Lazarus ↔ Python の橋渡しを検証します。次のような Python 依存コンポーネントの基盤になります。

- 画像分類;
- CNN モデル;
- YOLO;
- OpenCV;
- 顔検出;
- 音声処理;
- 機械学習ライブラリ。

複雑な AI コンポーネントのエラーを調べる前に、このサンプルで Python が正しく読み込まれることを確認してください。

---

## 13. 今後の改善案

- `python.exe`、`python3`、DLL、SO、dylib を手動選択するボタンを追加する。
- 選択中の項目が実行ファイルかライブラリかを明確に表示する。
- 画面を「設定」「スクリプト」「変数」「Eval」「診断」のタブに分ける。
- **診断をコピー** ボタンを追加する。
- 最後に使用した設定を保存する。
- 有効化前に選択ファイルの存在を検証する。
- `SetVar` に数値を入力した場合、文字列として扱われることを警告する。

---

## 14. まとめ

**`python_demo`** は、CHATGPT パッケージで Python 連携を確認する最初のテストとして推奨されます。このサンプルでインタプリタの起動、スクリプト実行、変数読み取り、式評価が成功すれば、Python 連携の基盤は動作しています。