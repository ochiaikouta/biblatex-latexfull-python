# LaTeX + Python レポートテンプレート（BibLaTeX 日本語対応, Codespaces対応）

LuaLaTeX + BibLaTeX + Biber + Python（numpy, matplotlib等）+ VS Code (LaTeX Workshop拡張) に対応した、日本語論文・レポート用テンプレートです。  
**GitHub Codespaces** で即使える開発環境も同梱しています。

---

## ✅ 特徴

- LuaLaTeX + BibLaTeX（和文参考文献スタイル `jecon` 使用）
- Python（numpy, matplotlib, jupyter等）も同時に使える
- requirements.txt でPythonパッケージ管理
- VS Code の拡張機能 [LaTeX Workshop](https://marketplace.visualstudio.com/items?itemName=James-Yu.latex-workshop) に最適化済み
- GitHub Codespaces対応（`.devcontainer`ディレクトリ同梱）
- `Makefile` ＆ `build.sh` によるCLIビルドも対応
- 図やセクションの分割管理が可能な `figures/`, `sections/` フォルダ付き
- `.latexmkrc` 同梱で `latexmk` による快適ビルド
- `.vscode/settings.json` により保存時自動ビルドが即使える

---

## 🚀 クイックスタート

### 1. GitHub Codespacesで開く（推奨）

- 「Use this template」からリポジトリを作成し、Codespacesで開くだけでLaTeXとPython環境が自動でセットアップされます。

### 2. ローカルで使う場合

```bash
git clone https://github.com/ochiaikouta/biblatex-latexfull-python.git
cd biblatex-japanese-template
# Pythonパッケージのインストール
pip install -r requirements.txt
```

### 3. PDFをビルド

#### VS Code で

- LaTeX Workshop 拡張を入れて `.tex` を開いて保存するだけでPDFが生成されます（自動ビルド設定済み）

#### CLIで

```bash
make           # PDFをビルド
make bib       # biberだけ走らせたいとき
make clean     # 中間ファイルを削除
make fullclean # PDFや.bblも含めて完全削除
make watch     # 自動で再ビルド（latexmk -pvc）
make view      # PDFを開く（Linuxならxdg-open）
make help      # ヘルプを表示（使い方一覧）
```

---

## ✅ 依存環境（例）

- TeX Live 2023 以上（LuaLaTeX 対応済み）
- `latexmk`, `biber`
- Python 3.11 以上（numpy, matplotlib, jupyter等）
- VS Code + LaTeX Workshop 拡張
- GitHub Codespaces（推奨）

---

## 📂 ディレクトリ構成

```
.
├── main.tex            # メインのLaTeXファイル
├── refs.bib            # 参考文献（BibLaTeX + Biber形式）
├── sections/           # セクション分割用ファイル
│   └── section1.tex
├── figures/            # 画像格納フォルダ
│   └── sample.png
├── notebooks/          # Jupyter Notebook用フォルダ ← 追加
│   └── sample.ipynb
├── .latexmkrc          # latexmk用設定
├── .vscode/settings.json  # LaTeX Workshop用のビルド設定（LuaLaTeX対応済）
├── Makefile            # makeコマンドでのビルド操作
├── build.sh            # シェルスクリプトビルド用（オプション）
├── requirements.txt    # Pythonパッケージ管理用ファイル
├── .devcontainer/      # GitHub Codespaces用設定
└── README.md
```

---

## 📝 使い方の補足

### `figures/` の画像を使いたいとき

```latex
\usepackage{graphicx}
...
\includegraphics[width=\linewidth]{figures/sample.png}
```

### `sections/` に分けた `.tex` を使いたいとき

```latex
\input{sections/section1.tex}
```

---

## 🧠 Tips

- 日本語参考文献出力は `biblatex` + `biber` + `style=jecon` によって行われます。
- `.vscode/settings.json` が含まれているので、**VS Code にクローンして開くだけで即LaTeX環境が整います。**

---

## 📜 ライセンス

MIT