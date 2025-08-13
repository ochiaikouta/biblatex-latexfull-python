# Dev Container + upLaTeX + upBibTeX + Python

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/ochiaikouta/uplatex-upbibtex-devcontainer-ja)
![build](https://github.com/ochiaikouta/uplatex-upbibtex-devcontainer-ja/actions/workflows/ci.yml/badge.svg)

>upLaTeX + upBibTeX + VS Code (LaTeX Workshop) による日本語テンプレートです。  Dev Container / Codespaces で即利用できます。

**ベースイメージ**: [Paperist/texlive-ja](https://github.com/Paperist/texlive-ja.git)

---

## ✅ 特徴

- **upLaTeX + upBibTeX** - 日本語LaTeXの標準環境
- **自動文献検索** - `tex/`ディレクトリ内の`.bib`ファイルを自動検出
- **Bibファイル管理** - ターミナルで簡単に追加・作成・検索
- **Python科学計算環境** - numpy, matplotlib, jupyter, pandas, scipy 等
- **VS Code LaTeX Workshop** - [James-Yu/LaTeX-Workshop](https://github.com/James-Yu/LaTeX-Workshop) に最適化
- **Dev Container/Codespaces** - すぐに利用可能
- **latexmk設定** - `.latexmkrc`と`Makefile`によるラッパー（Lualatexなどにも変更可能）
- **latexindent** - LaTeXコードのフォーマッター
- **CI/CD対応** - GitHub Actionsで自動ビルドとダミー画像生成

---

## 📥 セットアップ

### 1. リポジトリをクローン

```bash
# HTTPS
git clone https://github.com/ochiaikouta/uplatex-upbibtex-devcontainer-ja.git
cd uplatex-upbibtex-devcontainer-ja
```
```bash
# SSH（推奨）
git clone git@github.com:ochiaikouta/uplatex-upbibtex-devcontainer-ja.git
cd uplatex-upbibtex-devcontainer-ja
```

### 2. Dev Container で開く

VS Code でフォルダを開き、「`Reopen in Container`」を選択します。

---

## 🚀 クイックスタート

### 1. Dev Container/Codespaces で開く（推奨）

- VS Code で「`Reopen in Container`」または Codespaces で起動します。

### 2. Makefile を使う（tex/ 配下にプロジェクト作成）

```bash
make c-project   # テンプレートからtex/main.texを作成
make watch       # 変更を監視して自動ビルド
make dev         # フォーマット → 完全ビルド
make view        # PDF を開く
```

---

## 📚 文献管理

### 自動検索機能
- `tex/`ディレクトリ内の`.bib`ファイルを自動検出
- 複数の`.bib`ファイルを同時に使用可能
- 設定不要で利用可能

### 使用方法

#### 1. 自動検知

Makeコマンドに含まれています。`workspace/`で
```bash
# tex/*.bib を自動検出して処理
make bib
```
```bash
# いきなりbuildしても使えます
make f-build
make dev
```

#### 2. 読み込み

`main.tex` 内で複数の`.bib`ファイルを指定してください(`a.bib`, `b.bib`, ...)
```latex
% texファイル内で指定
\bibliography{a, b}
```



---

## 🚀 CI/CD と GitHub Actions

### 自動ビルドシステム
- **GitHub Actions**: プッシュ・プルリクエスト時に自動ビルド
- **Docker環境**: 既存のDev Container環境を活用
- **PDF生成**: ビルド結果をアーティファクトとして保存

### ダミー画像自動生成
- **LaTeX解析**: `\includegraphics`の参照を自動検出
- **ダミー画像**: カメラアイコン風のデザイン
- **CI環境対応**: 画像ファイルが不足していても自動生成
- **Git管理不要**: 画像ファイルは`.gitignore`で除外

### ワークフロー設定
```yaml
# .github/workflows/ci.yml
- name: Generate CI Images
  run: python3 scripts/generate_ci_images.py
- name: Build PDF
  run: make f-build
```

### メリット
- **テンプレート化**: 画像ファイルなしでも即座に利用可能
- **一貫性**: CI環境とローカル環境で同じ品質
- **保守性**: 画像ファイルの管理が不要
- **再利用性**: 他のプロジェクトでも簡単に導入可能

---

## 🛠️ 主なコマンド一覧

```bash
# 基本ビルド
make build     # LaTeX文書をビルド
make f-build   # 文献処理も含む完全ビルド（upBibTeX）
make bib       # 文献のみ処理（upBibTeX）
make watch     # 変更を監視して自動ビルド

# Bibファイル
make a-bib     # Bibファイルに追加
make c-bib     # Bibファイルを作成
make l-bib     # Bibファイルの中身を確認
make s-bib     # Bibファイルを検索

# クリーンアップ
make clean     # 中間ファイルを削除
make f-clean   # 生成物も含めて完全削除

# フォーマット
make fmt       # LaTeX整形（latexindent）

# プロジェクト管理
make c-project # テンプレートから新プロジェクト作成
make dev       # フォーマット → 完全ビルド
make view      # PDF を開く
make status    # プロジェクト状況を表示

# ヘルプ
make help      # ヘルプ表示
```
---

## ✅ 依存環境

- **TeX Live**（upLaTeX, upBibTeX, dvipdfmx）
- **latexmk** - LaTeXビルド自動化
- **Make** - ビルド・管理コマンド
- **Python 3.x**（numpy, matplotlib, jupyter, pandas, scipy など）
- **VS Code + LaTeX Workshop** 拡張
- **Dev Container/Codespaces**（推奨）

---

## 📂 ディレクトリ構成

```bash
.
├── sample/ # 独立サンプル（参考用）
│ ├── sample.tex
│ └── refs.bib
├── tex/ # 本番用LaTeX（make対象）
│ ├── figures/ # 画像ファイル
│ └── section/ # セクションファイル
├── templates/ # upLaTeX テンプレート
│ ├── template-minimal.tex
│ ├── template-simple.tex
│ ├── template-with-bib.tex
│ └── template-academic.tex
├── .latexmkrc # upLaTeX + upBibTeX 設定
├── .indentconfig.yaml # latexindent 設定
├── Makefile # ビルド/整形/文献管理
├── .devcontainer/ # Dev Container 設定
│ ├── Dockerfile
│ ├── docker-compose.yml
│ ├── devcontainer.json
│ └── requirements.txt # Python パッケージ
├── .github/ # GitHub 設定
│ ├── ISSUE_TEMPLATE/
│ ├── pull_request_template.md
│ └── workflows/ # GitHub Actions
│     └── ci.yml # CI/CD ワークフロー
├── .vscode/ # VS Code 設定
├── scripts/ # スクリプトファイル
│ └── generate_ci_images.py # CI用ダミー画像生成Pythonスクリプト
├── .gitignore # Git 除外設定
├── LICENSE # ライセンス情報
└── README.md
```
JupyterNotebookやPythonのフォルダは自由に追加してください。

---

## 🧠 Tips
### 技術的な詳細
- latexmk は `.latexmkrc` で upLaTeX + upBibTeX に設定済み(Lualatexなどにも変更可能)
- Dev Container は `make` をプリインストール済み
- TeX Live の他に必要なパッケージは`Dockerfile`に追加してください

---
## 📜 ライセンス

MIT
