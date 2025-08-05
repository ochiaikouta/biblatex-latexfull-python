# LaTeX文書のビルド・管理用Makefile
# LuaLaTeX + BibLaTeX + Biber 構成

# 設定変数
TEXFILE := tex/main
SUBFILES := $(wildcard tex/sections/*.tex)
LATEX := latexmk
BUILDDIR := build

# 安全性チェック
validate-vars:
	@if [ -z "$(TEXFILE)" ]; then echo "❌ TEXFILE が設定されていません"; exit 1; fi
	@if [ "$(BUILDDIR)" = "/" ] || [ "$(BUILDDIR)" = "." ] || [ "$(BUILDDIR)" = ".." ]; then \
		echo "❌ 危険なビルドディレクトリ: $(BUILDDIR)"; exit 1; \
	fi
	@if ! echo "$(TEXFILE)" | grep -q "^tex/"; then \
		echo "❌ TEXFILEはtex/で始まる必要があります: $(TEXFILE)"; exit 1; \
	fi
	@if [ ! -d "tex" ]; then \
		echo "❌ texディレクトリが存在しません"; \
		echo "💡 以下のコマンドで作成してください:"; \
		echo "   mkdir -p tex"; \
		exit 1; \
	fi
	@if [ ! -f "$(TEXFILE).tex" ]; then \
	    echo "❌ LaTeXファイルが存在しません: $(TEXFILE).tex"; \
	    echo "💡 以下のファイルを作成してください:"; \
	    echo "   touch $(TEXFILE).tex"; \
	    exit 1; \
	fi
	@if [ ! -s "$(TEXFILE).tex" ]; then \
		echo "⚠️  LaTeXファイルが空です: $(TEXFILE).tex"; \
		echo "💡 有効なLaTeXコンテンツを追加してください"; \
	fi

# =============================================================================
# ビルド関連
# =============================================================================

# デフォルトターゲット：PDFをビルド
all: validate-vars
	@echo "🚀 ビルド開始: $(TEXFILE).tex"
	$(LATEX) "$(TEXFILE)"

# 文献データベース（.bib）を処理  
bib: validate-vars
	@echo "📚 文献データベースを処理中..."
	@if [ -f "tex/refs.bib" ]; then \
		echo "  📖 tex/refs.bib が見つかりました"; \
		if [ -f "$(BUILDDIR)/main.bcf" ]; then \
	    	biber $(BUILDDIR)/main; \
		else \
	    	echo "  ⚠️  main.bcf が見つかりません。先に 'make all' を実行してください"; \
		fi; \
	else \
	    echo "  ℹ️  tex/refs.bib が見つかりません。文献処理をスキップします"; \
	fi

# 完全ビルド（文献処理も含む）
fullbuild: validate-vars
	@echo "🚀 完全ビルド開始..."
	@echo "  📄 初回ビルド中..."
	$(LATEX) "$(TEXFILE)"
	@if [ -f "tex/refs.bib" ] && [ -f "$(BUILDDIR)/main.bcf" ]; then \
	    echo "  📚 文献データベースを処理中..."; \
	    biber $(BUILDDIR)/main; \
	    echo "  🔄 最終ビルド中..."; \
	    $(LATEX) "$(TEXFILE)"; \
	else \
	    echo "  ℹ️  .bibファイルがないため文献処理をスキップしました"; \
	fi
	@echo "✅ 完全ビルド完了!"

# 開発用ワークフロー（フォーマット→完全ビルド）
dev: fmt fullbuild
	@echo "🚀 開発ワークフロー完了!"

# =============================================================================
# フォーマット・クリーンアップ
# =============================================================================

# LaTeX ファイルをフォーマット
fmt: validate-vars
	@echo "🔧 LaTeXファイルをフォーマット中..."
	@mkdir -p .backups
	latexindent -w -c .backups/ $(TEXFILE).tex
	@echo "🔧 セクションファイルもフォーマット中..."
	@if [ -d "tex/sections" ] && [ -n "$(wildcard tex/sections/*.tex)" ]; then \
	    find tex/sections -name "*.tex" -exec latexindent -w -c .backups/ {} \; ; \
	fi
	@echo "✅ フォーマット完了! (バックアップ: .backups/)"

# 一時ファイルを削除（PDFは残す）
clean: validate-vars
	@echo "🧹 一時ファイルを削除中..."
	$(LATEX) -c $(TEXFILE)
	@if [ -d "$(BUILDDIR)" ] && [ "$(BUILDDIR)" != "/" ] && [ "$(BUILDDIR)" != "." ]; then \
	    echo "  🔍 $(BUILDDIR)/ 内の一時ファイルを削除中..."; \
	    find "$(BUILDDIR)" -maxdepth 1 -name "*.run.xml" -delete 2>/dev/null || true; \
	    find "$(BUILDDIR)" -maxdepth 1 -name "*.synctex.gz" -delete 2>/dev/null || true; \
	    find "$(BUILDDIR)" -maxdepth 1 -name "texput.*" -delete 2>/dev/null || true; \
	    find "$(BUILDDIR)" -maxdepth 1 -type d -name "sections" -exec rm -rf {} + 2>/dev/null || true; \
	else \
	    echo "  ⚠️  無効なビルドディレクトリ: $(BUILDDIR)"; \
	fi
	@find . -maxdepth 1 -name "texput.*" -delete 2>/dev/null || true
	@echo "  ✅ 一時ファイルの削除完了"

# 生成ファイルを完全削除（PDFも含む）
fullclean: validate-vars
	@echo "🧹 すべての生成ファイルを削除中..."
	$(LATEX) -C $(TEXFILE)
	@if [ -d "$(BUILDDIR)" ] && [ "$(BUILDDIR)" != "/" ] && [ "$(BUILDDIR)" != "." ]; then \
	    echo "  🔍 $(BUILDDIR)/ 内のすべてのファイルを削除中..."; \
	    find "$(BUILDDIR)" -maxdepth 1 -name "*.run.xml" -delete 2>/dev/null || true; \
	    find "$(BUILDDIR)" -maxdepth 1 -name "*.synctex.gz" -delete 2>/dev/null || true; \
	    find "$(BUILDDIR)" -maxdepth 1 -name "*.pdf" -delete 2>/dev/null || true; \
	    find "$(BUILDDIR)" -maxdepth 1 -name "texput.*" -delete 2>/dev/null || true; \
	    find "$(BUILDDIR)" -maxdepth 1 -type d -name "sections" -exec rm -rf {} + 2>/dev/null || true; \
	else \
	    echo "  ⚠️  無効なビルドディレクトリ: $(BUILDDIR)"; \
	fi
	@find . -maxdepth 1 -name "texput.*" -delete 2>/dev/null || true
	@echo "  ✅ すべてのファイルの削除完了"

# バックアップファイルを削除 
fmtclean: validate-vars
	@echo "🧹 latexindentのバックアップファイルを削除中..."
	@if [ -d ".backups" ]; then \
	    echo "  📁 .backups/ ディレクトリを削除中..."; \
	    rm -rf ".backups/"; \
	    echo "  ✅ .backups/ を削除しました"; \
	else \
	    echo "  📁 .backups/ ディレクトリは存在しません"; \
	fi
	@echo "  🔍 latexindent バックアップファイルを検索中..."
	@find . -maxdepth 2 -name "*.bak[0-9]*" -delete 2>/dev/null || true
	@find . -maxdepth 2 -name "indent.log" -delete 2>/dev/null || true
	@echo "✅ バックアップファイルの削除が完了しました!"

# =============================================================================
# プロジェクト管理
# =============================================================================

# テンプレートから新しいプロジェクトを作成
new-project:
	@echo "📝 新しいプロジェクトを作成します"
	@echo "利用可能なテンプレート:"
	@echo "  1. with-bib    - 文献管理対応テンプレート"
	@echo "  2. simple      - シンプルテンプレート（文献なし）"
	@echo "  3. academic    - 学術論文テンプレート"
	@read -p "テンプレートを選択してください (1-3): " choice; \
    case $$choice in \
        1) cp templates/template-with-bib.tex tex/main.tex && \
           echo "✅ 文献管理テンプレートを設定しました" && \
           $(MAKE) --no-print-directory create-bib && \
           echo "📚 文献ファイルも自動作成しました";; \
        2) cp templates/template-simple.tex tex/main.tex && \
           echo "✅ シンプルテンプレートを設定しました";; \
        3) cp templates/template-academic.tex tex/main.tex && \
           echo "✅ 学術論文テンプレートを設定しました" && \
           $(MAKE) --no-print-directory create-bib && \
           echo "📚 文献ファイルも自動作成しました";; \
        *) echo "❌ 無効な選択です";; \
    esac

# テンプレート一覧を表示
templates:
	@echo "📋 利用可能なテンプレート:"
	@echo ""
	@echo "LaTeXテンプレート:"
	@ls -la templates/template-*.tex 2>/dev/null || echo "  (未作成)"
	@echo ""
	@echo "文献テンプレート:"
	@ls -la bib-templates/*.bib 2>/dev/null || echo "  (未作成)"

# プロジェクト状況を表示
status:
	@echo "📊 プロジェクト状況:"
	@echo "  メインファイル: $(TEXFILE).tex"
	@echo "  セクション数: $(words $(SUBFILES)) ファイル"
	@if [ -f "tex/refs.bib" ]; then \
	    echo "  文献ファイル: tex/refs.bib ✅"; \
	    echo "  文献数: $$(grep -c '^@' tex/refs.bib) 件"; \
	else \
	    echo "  文献ファイル: なし ℹ️"; \
	fi
	@echo "  ビルド出力: $(BUILDDIR)/"
	@if [ -d "$(BUILDDIR)" ]; then \
	    echo "  生成ファイル:"; \
	    ls -la $(BUILDDIR)/ | grep -E '\.(pdf|synctex\.gz)$$' || echo "    (PDFファイルなし)"; \
	else \
	    echo "  (まだビルドされていません)"; \
	fi

# =============================================================================
# 文献管理
# =============================================================================

# 文献ファイルを新規作成
create-bib:
	@echo "📚 新しい文献ファイルを作成中..."
	@if [ -f "tex/refs.bib" ]; then \
        echo "⚠️  tex/refs.bib が既に存在します"; \
        read -p "上書きしますか？ (y/N): " confirm; \
        if [ "$$confirm" != "y" ] && [ "$$confirm" != "Y" ]; then \
            echo "❌ 操作をキャンセルしました"; \
            exit 1; \
        fi; \
    fi
	@printf '%s\n' \
        '% BibLaTeX用文献データベース' \
        '% 作成日: '"$$(date '+%Y-%m-%d')" \
        '' > tex/refs.bib
	@echo "✅ tex/refs.bib を作成しました"

# 文献エントリを追加
add-bib:
	@echo "📖 文献エントリを追加します"
	@echo "文献の種類を選択してください:"
	@echo "  1. book      - 書籍"
	@echo "  2. article   - 論文（雑誌記事）"
	@echo "  3. inbook    - 書籍の章"
	@echo "  4. online    - オンライン資料"
	@echo "  5. manual    - マニュアル・技術文書"
	@read -p "種類を選択 (1-5): " type; \
	case $$type in \
	    1) $(MAKE) --no-print-directory add-book;; \
	    2) $(MAKE) --no-print-directory add-article;; \
	    3) $(MAKE) --no-print-directory add-inbook;; \
	    4) $(MAKE) --no-print-directory add-online;; \
	    5) $(MAKE) --no-print-directory add-manual;; \
	    *) echo "❌ 無効な選択です";; \
	esac

# 書籍エントリを追加
add-book:
	@echo "📚 書籍エントリを追加"
	@read -p "引用キー (例: author2024): " key; \
	read -p "著者名: " author; \
	read -p "書籍タイトル: " title; \
	read -p "出版年: " year; \
	read -p "出版社: " publisher; \
	read -p "出版地 (オプション): " address; \
	if [ ! -f "bib-templates/book.bib" ]; then \
	    echo "❌ テンプレートファイルが見つかりません: bib-templates/book.bib"; \
	    exit 1; \
	fi; \
	sed -e "s/KEY_PLACEHOLDER/$$key/g" \
	    -e "s/AUTHOR_PLACEHOLDER/$$author/g" \
	    -e "s/TITLE_PLACEHOLDER/$$title/g" \
	    -e "s/YEAR_PLACEHOLDER/$$year/g" \
	    -e "s/PUBLISHER_PLACEHOLDER/$$publisher/g" \
	    -e "s/ADDRESS_PLACEHOLDER/$$address/g" \
	    bib-templates/book.bib | \
	sed '/= {}/d' >> tex/refs.bib; \
	echo "" >> tex/refs.bib; \
	echo "✅ 書籍エントリ '$$key' を追加しました"

# 論文エントリを追加
add-article:
	@echo "📄 論文エントリを追加"
	@read -p "引用キー (例: author2024): " key; \
	read -p "著者名: " author; \
	read -p "論文タイトル: " title; \
	read -p "雑誌名: " journal; \
	read -p "出版年: " year; \
	read -p "巻 (オプション): " volume; \
	read -p "号 (オプション): " number; \
	read -p "ページ (例: 1--10, オプション): " pages; \
	read -p "DOI (オプション): " doi; \
	if [ ! -f "bib-templates/article.bib" ]; then \
	    echo "❌ テンプレートファイルが見つかりません: bib-templates/article.bib"; \
	    exit 1; \
	fi; \
	sed -e "s/KEY_PLACEHOLDER/$$key/g" \
	    -e "s/AUTHOR_PLACEHOLDER/$$author/g" \
	    -e "s/TITLE_PLACEHOLDER/$$title/g" \
	    -e "s/JOURNAL_PLACEHOLDER/$$journal/g" \
	    -e "s/YEAR_PLACEHOLDER/$$year/g" \
	    -e "s/VOLUME_PLACEHOLDER/$$volume/g" \
	    -e "s/NUMBER_PLACEHOLDER/$$number/g" \
	    -e "s/PAGES_PLACEHOLDER/$$pages/g" \
	    -e "s/DOI_PLACEHOLDER/$$doi/g" \
	    bib-templates/article.bib | \
	sed '/= {}/d' >> tex/refs.bib; \
	echo "" >> tex/refs.bib; \
	echo "✅ 論文エントリ '$$key' を追加しました"

# 書籍の章エントリを追加
add-inbook:
	@echo "📖 書籍の章エントリを追加"
	@read -p "引用キー (例: author2024): " key; \
	read -p "著者名: " author; \
	read -p "章タイトル: " title; \
	read -p "書籍タイトル: " booktitle; \
	read -p "編者 (オプション): " editor; \
	read -p "出版年: " year; \
	read -p "出版社: " publisher; \
	read -p "ページ (例: 15--32, オプション): " pages; \
	if [ ! -f "bib-templates/inbook.bib" ]; then \
	    echo "❌ テンプレートファイルが見つかりません: bib-templates/inbook.bib"; \
	    exit 1; \
	fi; \
	sed -e "s/KEY_PLACEHOLDER/$$key/g" \
	    -e "s/AUTHOR_PLACEHOLDER/$$author/g" \
	    -e "s/TITLE_PLACEHOLDER/$$title/g" \
	    -e "s/BOOKTITLE_PLACEHOLDER/$$booktitle/g" \
	    -e "s/EDITOR_PLACEHOLDER/$$editor/g" \
	    -e "s/YEAR_PLACEHOLDER/$$year/g" \
	    -e "s/PUBLISHER_PLACEHOLDER/$$publisher/g" \
	    -e "s/PAGES_PLACEHOLDER/$$pages/g" \
	    bib-templates/inbook.bib | \
	sed '/= {}/d' >> tex/refs.bib; \
	echo "" >> tex/refs.bib; \
	echo "✅ 書籍の章エントリ '$$key' を追加しました"

# オンライン資料エントリを追加
add-online:
	@echo "🌐 オンライン資料エントリを追加"
	@read -p "引用キー (例: website2024): " key; \
	read -p "著者名 (オプション): " author; \
	read -p "タイトル: " title; \
	read -p "URL: " url; \
	read -p "アクセス日 (YYYY-MM-DD): " urldate; \
	read -p "出版年 (オプション): " year; \
	if [ ! -f "bib-templates/online.bib" ]; then \
	    echo "❌ テンプレートファイルが見つかりません: bib-templates/online.bib"; \
	    exit 1; \
	fi; \
	sed -e "s/KEY_PLACEHOLDER/$$key/g" \
	    -e "s/AUTHOR_PLACEHOLDER/$$author/g" \
	    -e "s/TITLE_PLACEHOLDER/$$title/g" \
	    -e "s/URL_PLACEHOLDER/$$url/g" \
	    -e "s/URLDATE_PLACEHOLDER/$$urldate/g" \
	    -e "s/YEAR_PLACEHOLDER/$$year/g" \
	    bib-templates/online.bib | \
	sed '/= {}/d' >> tex/refs.bib; \
	echo "" >> tex/refs.bib; \
	echo "✅ オンライン資料エントリ '$$key' を追加しました"

# マニュアル・技術文書エントリを追加
add-manual:
	@echo "📋 マニュアル・技術文書エントリを追加"
	@read -p "引用キー (例: manual2024): " key; \
	read -p "タイトル: " title; \
	read -p "組織・機関: " organization; \
	read -p "出版年: " year; \
	read -p "バージョン (オプション): " edition; \
	if [ ! -f "bib-templates/manual.bib" ]; then \
	    echo "❌ テンプレートファイルが見つかりません: bib-templates/manual.bib"; \
	    exit 1; \
	fi; \
	sed -e "s/KEY_PLACEHOLDER/$$key/g" \
	    -e "s/TITLE_PLACEHOLDER/$$title/g" \
	    -e "s/ORGANIZATION_PLACEHOLDER/$$organization/g" \
	    -e "s/YEAR_PLACEHOLDER/$$year/g" \
	    -e "s/EDITION_PLACEHOLDER/$$edition/g" \
	    bib-templates/manual.bib | \
	sed '/= {}/d' >> tex/refs.bib; \
	echo "" >> tex/refs.bib; \
	echo "✅ マニュアルエントリ '$$key' を追加しました"


# 文献ファイルの内容を表示
show-bib:
	@echo "📚 現在の文献ファイル内容:"
	@if [ -f "tex/refs.bib" ]; then \
	    echo ""; \
	    cat tex/refs.bib; \
	    echo ""; \
	    echo "📊 統計:"; \
	    echo "  エントリ数: $$(grep -c '^@' tex/refs.bib) 件"; \
	else \
	    echo "❌ tex/refs.bib が見つかりません"; \
	    echo "💡 'make create-bib' で作成してください"; \
	fi

# 文献エントリを検索
search-bib:
	@echo "🔍 文献エントリを検索"
	@if [ ! -f "tex/refs.bib" ]; then \
	    echo "❌ tex/refs.bib が見つかりません"; \
	    exit 1; \
	fi
	@read -p "検索キーワード: " keyword; \
	echo "検索結果:"; \
	grep -i -A 10 -B 1 "$$keyword" tex/refs.bib || echo "該当する文献が見つかりませんでした"

# =============================================================================
# 表示・ヘルプ
# =============================================================================

# VS Code でPDFを開く
view: validate-vars
	@if [ -f "$(BUILDDIR)/main.pdf" ]; then \
	    echo "📖 VS Code でPDFを開いています..."; \
	    code "$(BUILDDIR)/main.pdf"; \
	else \
	    echo "❌ PDFファイルが見つかりません。まず 'make dev' でビルドしてください。"; \
	fi

# VSCode LaTeX Workshop の使用方法を案内
viewhelp:
	@echo "📖 PDFの表示方法:"
	@echo "  1. VS Code で開く:     LaTeX Workshop 拡張機能の 'View PDF' ボタン"
	@echo "  2. ショートカット:     Ctrl+Alt+V (または Mac なら Cmd+Alt+V)"

# 使い方を表示
help:
	@echo "LaTeX開発環境 - 使用方法"
	@echo "========================================"
	@echo ""
	@echo "🚀 基本ワークフロー:"
	@echo "  dev          - フォーマット＋完全ビルド（推奨）"
	@echo "  view         - PDFをVS Codeで表示"
	@echo "  status       - プロジェクト状況を確認"
	@echo ""
	@echo "📝 プロジェクト管理:"
	@echo "  new-project  - テンプレートから新規作成"
	@echo "  templates    - 利用可能なテンプレート一覧"
	@echo ""
	@echo "📚 文献管理:"
	@echo "  create-bib   - 空の文献ファイルを作成"
	@echo "  add-bib      - 文献エントリを追加（対話式）"
	@echo "  show-bib     - 文献ファイルの内容を表示"
	@echo "  search-bib   - 文献エントリを検索"
	@echo ""
	@echo "🔧 ビルド："
	@echo "  all          - LaTeX単体ビルド"
	@echo "  fullbuild    - 文献処理を含む完全ビルド"
	@echo "  bib          - 文献データベースのみ処理"
	@echo ""
	@echo "🧹 メンテナンス:"
	@echo "  fmt          - LaTeXファイルをフォーマット"
	@echo "  clean        - 一時ファイルを削除"
	@echo "  fullclean    - 全生成ファイルを削除"
	@echo "  fmtclean     - フォーマットのバックアップを削除"

.PHONY: all bib fmt dev fmtclean clean fullclean fullbuild view viewhelp status help \
	    new-project templates create-bib add-bib add-book add-article add-inbook add-online add-manual \
		show-bib search-bib
