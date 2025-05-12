# LaTeX レポートテンプレート（BibLaTeX 日本語対応）

LuaLaTeX + BibLaTeX + Biber + VS Code (LaTeX Workshop拡張) に対応した、日本語論文・レポート用テンプレートです。

## ✅ 特徴

- LuaLaTeX + BibLaTeX（和文参考文献スタイル `jecon` 使用）
- VS Code の拡張機能 [LaTeX Workshop](https://marketplace.visualstudio.com/items?itemName=James-Yu.latex-workshop) に最適化済み
- `Makefile` ＆ `build.sh` によるCLIビルドも対応
- 図やセクションの分割管理が可能な `figures/`, `sections/` フォルダ付き
- `.latexmkrc` 同梱で `latexmk` による快適ビルド
- `.vscode/settings.json` により保存時自動ビルドが即使える

---

## 🚀 クイックスタート

### 1. このリポジトリをクローン

```bash
git clone https://github.com/ochiaikouta/biblatex-japanese-template.git
cd biblatex-japanese-template
```

### 2. PDFをビルド

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
これらのコマンドは、テンプレート同梱の `Makefile` を利用して動作します。CLI派の方や、VS Code以外の環境で編集する場合に便利です。

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
├── .latexmkrc          # latexmk用設定
├── .vscode/settings.json  # LaTeX Workshop用のビルド設定（LuaLaTeX対応済）
├── Makefile            # makeコマンドでのビルド操作
├── build.sh            # シェルスクリプトビルド用（オプション）
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

## ✅ 依存環境（例）

- TeX Live 2023 以上（LuaLaTeX 対応済み）
- `latexmk`, `biber`
- VS Code + LaTeX Workshop 拡張

---

## 🔄 今後の追加予定（任意）

- Zoteroとの連携方法（Better BibTeX等）
- 英語版テンプレート

---

## 📜 ライセンス

MIT