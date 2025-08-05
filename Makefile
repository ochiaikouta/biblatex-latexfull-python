# LaTeX文書のビルド・管理用Makefile
# LuaLaTeX + BibLaTeX + Biber 構成

# 設定変数　
TEXFILE=tex/main
SUBFILES=$(wildcard tex/sections/*.tex)
LATEX=latexmk
BUILDDIR=build

# デフォルトターゲット：PDFをビルド
all:
	@echo "🚀 ビルド開始: $(TEXFILE).tex"
	$(LATEX) $(TEXFILE)

# 文献データベース（.bib）を処理  
bib:
	@echo "📚 文献データベースを処理中..."
	biber $(BUILDDIR)/main

# LaTeX ファイルをフォーマット（確実性のため -c オプション併用）
fmt:
	@echo "🔧 LaTeXファイルをフォーマット中..."
	@mkdir -p .backups
	latexindent -w -c .backups/ $(TEXFILE).tex
	@echo "🔧 セクションファイルもフォーマット中..."
	@if [ -d "$(dir $(SUBFILES))" ]; then \
		find $(dir $(SUBFILES)) -name "*.tex" -exec latexindent -w -c .backups/ {} \; ; \
	fi
	@echo "✅ フォーマット完了! (バックアップ: .backups/)"

# 一時ファイルを削除（PDFは残す）
clean:
	@echo "🧹 一時ファイルを削除中..."
	$(LATEX) -c $(TEXFILE)
	@echo "  🔍 追加の一時ファイルを検索・削除中..."
	@find $(BUILDDIR) -name "*.run.xml" -delete 2>/dev/null || true
	@find $(BUILDDIR) -name "*.synctex.gz" -delete 2>/dev/null || true
	@find $(BUILDDIR) -type d -name "sections" -exec rm -rf {} + 2>/dev/null || true
	@echo "  ✅ 一時ファイルの削除完了"

# 生成ファイルを完全削除（PDFも含む）
fullclean:
	@echo "🧹 すべての生成ファイルを削除中..."
	$(LATEX) -C $(TEXFILE)
	@echo "  🔍 すべての生成ファイルを検索・削除中..."
	@find $(BUILDDIR) -name "*.run.xml" -delete 2>/dev/null || true
	@find $(BUILDDIR) -name "*.synctex.gz" -delete 2>/dev/null || true
	@find $(BUILDDIR) -name "*.pdf" -delete 2>/dev/null || true
	@find $(BUILDDIR) -type d -name "sections" -exec rm -rf {} + 2>/dev/null || true
	@echo "  ✅ すべてのファイルの削除完了"

# バックアップファイルを削除
fmtclean:
	@echo "🧹 latexindentのバックアップファイルを削除中..."
	@if [ -d ".backups" ]; then \
		echo "  📁 .backups/ ディレクトリを削除中..."; \
		rm -rf .backups/; \
		echo "  ✅ .backups/ を削除しました"; \
	else \
		echo "  📁 .backups/ ディレクトリは存在しません"; \
	fi
	@echo "  🔍 その他のバックアップファイルを検索中..."
	@find . -name "*.bak*" -delete 2>/dev/null || true
	@echo "✅ バックアップファイルの削除が完了しました!"


# VS Code でPDFを開く
view:
	@if [ -f "$(BUILDDIR)/main.pdf" ]; then \
	    echo "📖 VS Code でPDFを開いています..."; \
	    code "$(BUILDDIR)/main.pdf"; \
	else \
	    echo "❌ PDFファイルが見つかりません。まず 'make all' でビルドしてください。"; \
	fi

# VSCode LaTeX Workshop の使用方法を案内
viewhelp:
	@echo "📖 PDFの表示方法:"
	@echo "  1. VS Code で開く:     LaTeX Workshop 拡張機能の 'View PDF' ボタン"
	@echo "  2. ショートカット:     Ctrl+Alt+V (または Mac なら Cmd+Alt+V)"

# 開発用ワークフロー（フォーマット→ビルド）
dev: fmt all
	@echo "🚀 開発ワークフロー完了!"

# プロジェクト状況を表示
status:
	@echo "📊 プロジェクト状況:"
	@echo "  メインファイル: $(TEXFILE).tex"
	@echo "  セクション数: $(words $(SUBFILES)) ファイル"
	@echo "  ビルド出力: $(BUILDDIR)/"
	@if [ -d "$(BUILDDIR)" ]; then \
		echo "  生成ファイル:"; \
		ls -la $(BUILDDIR)/ | grep -E '\.(pdf|synctex\.gz)$$' || echo "    (PDFファイルなし)"; \
	else \
		echo "  (まだビルドされていません)"; \
	fi

# 使い方を表示
help:
	@echo "使い方: make <ターゲット>"
	@echo "ターゲット一覧:"
	@echo "  all          - LuaLaTeX（latexmk）でPDFをビルド"
	@echo "  bib          - biber で文献情報（.bib）を処理"
	@echo "  fmt          - LaTeX ファイルを latexindent でフォーマット"
	@echo "  dev          - フォーマット後にビルド（開発用）"
	@echo "  fmtclean     - latexindent のバックアップファイルを削除"
	@echo "  clean        - 一時ファイルを削除"
	@echo "  fullclean    - 全生成ファイルを完全に削除"
	@echo "  view         - VS Code で PDF を開く"
	@echo "  viewhelp     - PDF表示方法の詳細案内"
	@echo "  status       - プロジェクト状況を表示"

.PHONY: all bib fmt dev fmtclean clean fullclean view  viewhelp status help
