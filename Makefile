# LaTeX文書のビルド・管理用Makefile
# LuaLaTeX + BibLaTeX + Biber 構成

# =============================================================================
# 設定変数
# =============================================================================
TEXFILE := tex/main
MAINTEX := main
SUBFILES := $(wildcard tex/sections/*.tex)
LATEX := latexmk
BUILDDIR := build

# 文献管理関連
BIBFILE := tex/refs.bib
TEXDIR := tex
SECTIONSDIR := $(TEXDIR)/sections
TEMPLATESDIR := templates
BACKUPDIR := .backups

# ビルド関連の派生変数
MAINTEXNAME := $(notdir $(TEXFILE))
MAINPDF := $(BUILDDIR)/$(MAINTEXNAME).pdf
MAINBCF := $(BUILDDIR)/$(MAINTEXNAME).bcf
MAINBBL := $(BUILDDIR)/$(MAINTEXNAME).bbl

# ブラウザ設定（環境変数またはデフォルト）
BROWSER ?= xdg-open

# 日付フォーマット
DATE := $(shell date '+%Y-%m-%d')

# 安全性チェック
validate-vars:
	@if [ -z "$(TEXFILE)" ]; then echo "❌ TEXFILE が設定されていません"; exit 1; fi
	@if [ "$(BUILDDIR)" = "/" ] || [ "$(BUILDDIR)" = "." ] || [ "$(BUILDDIR)" = ".." ]; then \
        echo "❌ 危険なビルドディレクトリ: $(BUILDDIR)"; exit 1; \
    fi
	@if ! echo "$(TEXFILE)" | grep -q "^$(TEXDIR)/"; then \
        echo "❌ TEXFILEは$(TEXDIR)/で始まる必要があります: $(TEXFILE)"; exit 1; \
    fi
	@if [ ! -d "$(TEXDIR)" ]; then \
        echo "❌ $(TEXDIR)ディレクトリが存在しません"; \
        echo "💡 以下のコマンドで作成してください:"; \
        echo "   mkdir -p $(TEXDIR)"; \
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
    @if [ -f "$(BIBFILE)" ]; then \
        echo "  📖 $(BIBFILE) が見つかりました"; \
        if [ -f "$(MAINBCF)" ]; then \
            biber $(BUILDDIR)/$(MAINTEXNAME); \
        else \
            echo "  ⚠️  $(MAINTEXNAME).bcf が見つかりません。先に 'make all' を実行してください"; \
        fi; \
    else \
        echo "  ℹ️  $(BIBFILE) が見つかりません。文献処理をスキップします"; \
    fi

# 完全ビルド（文献処理も含む）
fullbuild: validate-vars
	@echo "🚀 完全ビルド開始..."
	@echo "  📄 初回ビルド中..."
	$(LATEX) "$(TEXFILE)"
	@if [ -f "$(BIBFILE)" ] && [ -f "$(MAINBCF)" ]; then \
        echo "  📚 文献データベースを処理中..."; \
        biber $(BUILDDIR)/$(MAINTEXNAME); \
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
	@mkdir -p $(BACKUPDIR)
	latexindent -w -c $(BACKUPDIR)/ $(TEXFILE).tex
	@echo "🔧 セクションファイルもフォーマット中..."
	@if [ -d "$(SECTIONSDIR)" ] && [ -n "$(wildcard $(SECTIONSDIR)/*.tex)" ]; then \
        find $(SECTIONSDIR) -name "*.tex" -exec latexindent -w -c $(BACKUPDIR)/ {} \; ; \
    fi
	@echo "✅ フォーマット完了! (バックアップ: $(BACKUPDIR)/)"

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
	@if [ -d "$(BACKUPDIR)" ]; then \
        echo "  📁 $(BACKUPDIR)/ ディレクトリを削除中..."; \
        rm -rf "$(BACKUPDIR)/"; \
        echo "  ✅ $(BACKUPDIR)/ を削除しました"; \
	else \
        echo "  📁 $(BACKUPDIR)/ ディレクトリは存在しません"; \
    fi
	@echo "  🔍 latexindent バックアップファイルを検索中..."
	@find . -maxdepth 2 -name "*.bak[0-9]*" -delete 2>/dev/null || true
	@find . -maxdepth 2 -name "indent.log" -delete 2>/dev/null || true
	@echo "✅ バックアップファイルの削除が完了しました!"

# =============================================================================
# プロジェクト管理
# =============================================================================

# テンプレートから新しいプロジェクトを作成
new-project: validate-vars
    @echo "📝 新しいプロジェクトを作成します"
    @if [ ! -d "$(TEMPLATESDIR)" ]; then \
        echo "⚠️  $(TEMPLATESDIR)/ ディレクトリが存在しません"; \
        echo "💡 基本的なテンプレートを作成しますか？"; \
        read -p "作成する場合は y を入力: " create; \
        if [ "$$create" = "y" ] || [ "$$create" = "Y" ]; then \
            mkdir -p $(TEMPLATESDIR); \
            echo "📁 $(TEMPLATESDIR)/ ディレクトリを作成しました"; \
        else \
            echo "❌ 操作をキャンセルしました"; \
            exit 1; \
        fi; \
    fi
    @echo "利用可能なテンプレート:"
    @echo "  1. with-bib    - 文献管理対応テンプレート"
    @echo "  2. simple      - シンプルテンプレート（文献なし）"
    @echo "  3. academic    - 学術論文テンプレート"
    @read -p "テンプレートを選択してください (1-3): " choice; \
    case $$choice in \
        1) if [ -f "$(TEMPLATESDIR)/template-with-bib.tex" ]; then \
               cp $(TEMPLATESDIR)/template-with-bib.tex $(TEXFILE).tex && \
               echo "✅ 文献管理テンプレートを設定しました" && \
               $(MAKE) --no-print-directory create-bib && \
               echo "📚 文献ファイルも自動作成しました"; \
           else \
               echo "❌ $(TEMPLATESDIR)/template-with-bib.tex が見つかりません"; \
           fi;; \
        2) if [ -f "$(TEMPLATESDIR)/template-simple.tex" ]; then \
               cp $(TEMPLATESDIR)/template-simple.tex $(TEXFILE).tex && \
               echo "✅ シンプルテンプレートを設定しました"; \
           else \
               echo "❌ $(TEMPLATESDIR)/template-simple.tex が見つかりません"; \
           fi;; \
        3) if [ -f "$(TEMPLATESDIR)/template-academic.tex" ]; then \
               cp $(TEMPLATESDIR)/template-academic.tex $(TEXFILE).tex && \
               echo "✅ 学術論文テンプレートを設定しました" && \
               $(MAKE) --no-print-directory create-bib && \
               echo "📚 文献ファイルも自動作成しました"; \
           else \
               echo "❌ $(TEMPLATESDIR)/template-academic.tex が見つかりません"; \
           fi;; \
        *) echo "❌ 無効な選択です";; \
    esac

# テンプレート一覧を表示
templates:
	@echo "📋 利用可能なテンプレート:"
	@echo ""
	@echo "LaTeXテンプレート:"
	@ls -la $(TEMPLATESDIR)/template-*.tex 2>/dev/null || echo "  (未作成)"
	@echo ""
	@echo "文献テンプレート:"

# プロジェクト状況を表示
status:
	@echo "📊 プロジェクト状況:"
	@echo "  メインファイル: $(TEXFILE).tex"
	@echo "  セクション数: $(words $(SUBFILES)) ファイル"
	@if [ -f "$(BIBFILE)" ]; then \
        echo "  文献ファイル: $(BIBFILE) ✅"; \
        echo "  文献数: $$(grep -c '^@' $(BIBFILE)) 件"; \
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
	@if [ -f "$(BIBFILE)" ]; then \
        echo "⚠️  $(BIBFILE) が既に存在します"; \
        read -p "上書きしますか？ (y/N): " confirm; \
        if [ "$$confirm" != "y" ] && [ "$$confirm" != "Y" ]; then \
            echo "❌ 操作をキャンセルしました"; \
            exit 1; \
        fi; \
    fi
	@printf '%s\n' \
        '% BibLaTeX用文献データベース' \
        '% 作成日: $(DATE)' \
        '' > $(BIBFILE)
	@echo "✅ $(BIBFILE) を作成しました"

# 文献エントリを追加
add-bib:
	@echo "📖 文献エントリを追加します"
	@echo "文献の種類を選択してください:"
	@echo "  1. book           - 書籍"
	@echo "  2. article        - 論文（雑誌記事）"
	@echo "  3. inbook         - 書籍の章"
	@echo "  4. online         - オンライン資料"
	@echo "  5. manual         - マニュアル・技術文書"
	@echo "  6. thesis         - 学位論文"
	@echo "  7. inproceedings  - 会議論文"
	@read -p "種類を選択 (1-7): " type; \
    case $$type in \
        1) $(MAKE) --no-print-directory add-book;; \
        2) $(MAKE) --no-print-directory add-article;; \
        3) $(MAKE) --no-print-directory add-inbook;; \
        4) $(MAKE) --no-print-directory add-online;; \
        5) $(MAKE) --no-print-directory add-manual;; \
        6) $(MAKE) --no-print-directory add-thesis;; \
        7) $(MAKE) --no-print-directory add-inproceedings;; \
        *) echo "❌ 無効な選択です";; \
    esac

# 書籍エントリを追加（完全版）
add-book:
	@echo "📚 書籍エントリを追加"
	@echo "💡 入力ガイド: 年は半角数字（2024）、日本語/英語混在OK、空欄でスキップ可能"
	@echo ""
	@read -p "✅ 引用キー (例: tanaka2024): " key; \
    read -p "📝 著者名 (例: 田中太郎 or Tanaka, Taro): " author; \
    read -p "📖 書籍タイトル: " title; \
    read -p "📅 出版年 (半角数字, 例: 2024): " year; \
    read -p "🏢 出版社: " publisher; \
    read -p "🌍 出版地 (オプション, 例: 東京): " address; \
    read -p "📄 サブタイトル (オプション): " subtitle; \
    read -p "📝 編集者 (オプション): " editor; \
    read -p "🔢 版 (オプション, 例: 2nd, 第2版): " edition; \
    read -p "📚 巻 (オプション, 半角数字): " volume; \
    read -p "📑 シリーズ名 (オプション): " series; \
    read -p "🆔 ISBN (オプション): " isbn; \
    read -p "🌐 言語 (オプション, 例: japanese, english): " language; \
    read -p "📝 備考 (オプション): " note; \
    printf "\n@book{%s,\n" "$$key" >> $(BIBFILE); \
    printf "  author    = {%s},\n" "$$author" >> $(BIBFILE); \
    printf "  title     = {%s},\n" "$$title" >> $(BIBFILE); \
    printf "  year      = {%s},\n" "$$year" >> $(BIBFILE); \
    printf "  publisher = {%s}" "$$publisher" >> $(BIBFILE); \
    if [ -n "$$address" ]; then \
        printf ",\n  address   = {%s}" "$$address" >> $(BIBFILE); \
    fi; \
    if [ -n "$$subtitle" ]; then \
        printf ",\n  subtitle  = {%s}" "$$subtitle" >> $(BIBFILE); \
    fi; \
    if [ -n "$$editor" ]; then \
        printf ",\n  editor    = {%s}" "$$editor" >> $(BIBFILE); \
    fi; \
    if [ -n "$$edition" ]; then \
        printf ",\n  edition   = {%s}" "$$edition" >> $(BIBFILE); \
    fi; \
    if [ -n "$$volume" ]; then \
        printf ",\n  volume    = {%s}" "$$volume" >> $(BIBFILE); \
    fi; \
    if [ -n "$$series" ]; then \
        printf ",\n  series    = {%s}" "$$series" >> $(BIBFILE); \
    fi; \
    if [ -n "$$isbn" ]; then \
        printf ",\n  isbn      = {%s}" "$$isbn" >> $(BIBFILE); \
    fi; \
    if [ -n "$$language" ]; then \
        printf ",\n  language  = {%s}" "$$language" >> $(BIBFILE); \
    fi; \
    if [ -n "$$note" ]; then \
        printf ",\n  note      = {%s}" "$$note" >> $(BIBFILE); \
    fi; \
    printf "\n}\n\n" >> $(BIBFILE); \
    echo "✅ 書籍エントリ '$$key' を追加しました"

# 論文エントリを追加（完全版）
add-article:
	@echo "📄 論文エントリを追加"
	@echo "💡 入力ガイド: 巻・号・ページは半角数字、ページ範囲は「--」で区切り（例: 123--135）"
	@echo ""
	@read -p "✅ 引用キー (例: yamada2024): " key; \
    read -p "📝 著者名 (例: 山田花子 or Yamada, Hanako): " author; \
    read -p "📖 論文タイトル: " title; \
    read -p "📰 雑誌名: " journal; \
    read -p "📅 出版年 (半角数字, 例: 2024): " year; \
    read -p "🔢 巻 (半角数字, オプション): " volume; \
    read -p "🔢 号 (半角数字, オプション): " number; \
    read -p "📄 ページ範囲 (例: 123--135, オプション): " pages; \
    read -p "🔗 DOI (オプション): " doi; \
    read -p "🌐 URL (オプション): " url; \
    read -p "📄 サブタイトル (オプション): " subtitle; \
    read -p "🆔 ISSN (オプション): " issn; \
    read -p "🌐 言語 (オプション, 例: japanese): " language; \
    read -p "📝 備考 (オプション): " note; \
    printf "\n@article{%s,\n" "$$key" >> $(BIBFILE); \
    printf "  author  = {%s},\n" "$$author" >> $(BIBFILE); \
    printf "  title   = {%s},\n" "$$title" >> $(BIBFILE); \
    printf "  journal = {%s},\n" "$$journal" >> $(BIBFILE); \
    printf "  year    = {%s}" "$$year" >> $(BIBFILE); \
    if [ -n "$$volume" ]; then \
        printf ",\n  volume  = {%s}" "$$volume" >> $(BIBFILE); \
    fi; \
    if [ -n "$$number" ]; then \
        printf ",\n  number  = {%s}" "$$number" >> $(BIBFILE); \
    fi; \
    if [ -n "$$pages" ]; then \
        printf ",\n  pages   = {%s}" "$$pages" >> $(BIBFILE); \
    fi; \
    if [ -n "$$subtitle" ]; then \
        printf ",\n  subtitle = {%s}" "$$subtitle" >> $(BIBFILE); \
    fi; \
    if [ -n "$$doi" ]; then \
        printf ",\n  doi     = {%s}" "$$doi" >> $(BIBFILE); \
    fi; \
    if [ -n "$$url" ]; then \
        printf ",\n  url     = {%s}" "$$url" >> $(BIBFILE); \
    fi; \
    if [ -n "$$issn" ]; then \
        printf ",\n  issn    = {%s}" "$$issn" >> $(BIBFILE); \
    fi; \
    if [ -n "$$language" ]; then \
        printf ",\n  language = {%s}" "$$language" >> $(BIBFILE); \
    fi; \
    if [ -n "$$note" ]; then \
        printf ",\n  note    = {%s}" "$$note" >> $(BIBFILE); \
    fi; \
    printf "\n}\n\n" >> $(BIBFILE); \
    echo "✅ 論文エントリ '$$key' を追加しました"

# オンライン資料エントリを追加（完全版）
add-online:
	@echo "🌐 オンライン資料エントリを追加"
	@echo "💡 入力ガイド: URLdate は YYYY-MM-DD 形式（例: 2024-08-05）、全角文字OK"
	@echo ""
	@read -p "✅ 引用キー (例: website2024): " key; \
    read -p "📝 著者名 (オプション, 例: 田中太郎): " author; \
    read -p "📖 タイトル: " title; \
    read -p "🌐 URL: " url; \
    read -p "📅 アクセス日 (YYYY-MM-DD, 例: 2024-08-05): " urldate; \
    read -p "📅 発表年 (半角数字, オプション): " year; \
    read -p "📄 サブタイトル (オプション): " subtitle; \
    read -p "🏢 組織名 (オプション): " organization; \
    read -p "🌐 言語 (オプション, 例: japanese): " language; \
    read -p "📝 備考 (オプション): " note; \
    printf "\n@online{%s,\n" "$$key" >> $(BIBFILE); \
    if [ -n "$$author" ]; then \
        printf "  author       = {%s},\n" "$$author" >> $(BIBFILE); \
    fi; \
    printf "  title        = {%s},\n" "$$title" >> $(BIBFILE); \
    printf "  url          = {%s},\n" "$$url" >> $(BIBFILE); \
    printf "  urldate      = {%s}" "$$urldate" >> $(BIBFILE); \
    if [ -n "$$year" ]; then \
        printf ",\n  year         = {%s}" "$$year" >> $(BIBFILE); \
    fi; \
    if [ -n "$$subtitle" ]; then \
        printf ",\n  subtitle     = {%s}" "$$subtitle" >> $(BIBFILE); \
    fi; \
    if [ -n "$$organization" ]; then \
        printf ",\n  organization = {%s}" "$$organization" >> $(BIBFILE); \
    fi; \
    if [ -n "$$language" ]; then \
        printf ",\n  language     = {%s}" "$$language" >> $(BIBFILE); \
    fi; \
    if [ -n "$$note" ]; then \
        printf ",\n  note         = {%s}" "$$note" >> $(BIBFILE); \
    fi; \
    printf "\n}\n\n" >> $(BIBFILE); \
    echo "✅ オンライン資料エントリ '$$key' を追加しました"

# 書籍の章エントリを追加（完全版）
add-inbook:
	@echo "📖 書籍の章エントリを追加"
	@echo "💡 入力ガイド: ページ範囲は「--」で区切り（例: 10--25）、章と本のタイトル両方必須"
	@echo ""
	@read -p "✅ 引用キー (例: suzuki2024chapter): " key; \
    read -p "📝 章の著者名: " author; \
    read -p "📖 章のタイトル: " title; \
    read -p "📚 書籍タイトル: " booktitle; \
    read -p "📝 書籍の編集者 (オプション): " editor; \
    read -p "📅 出版年 (半角数字): " year; \
    read -p "🏢 出版社: " publisher; \
    read -p "📄 ページ範囲 (例: 10--25, オプション): " pages; \
    read -p "🌍 出版地 (オプション): " address; \
    read -p "🔢 版 (オプション): " edition; \
    read -p "📚 巻 (オプション): " volume; \
    read -p "📑 シリーズ名 (オプション): " series; \
    read -p "🌐 言語 (オプション): " language; \
    read -p "📝 備考 (オプション): " note; \
    printf "\n@inbook{%s,\n" "$$key" >> $(BIBFILE); \
    printf "  author    = {%s},\n" "$$author" >> $(BIBFILE); \
    printf "  title     = {%s},\n" "$$title" >> $(BIBFILE); \
    printf "  booktitle = {%s},\n" "$$booktitle" >> $(BIBFILE); \
    printf "  year      = {%s},\n" "$$year" >> $(BIBFILE); \
    printf "  publisher = {%s}" "$$publisher" >> $(BIBFILE); \
    if [ -n "$$editor" ]; then \
        printf ",\n  editor    = {%s}" "$$editor" >> $(BIBFILE); \
    fi; \
    if [ -n "$$pages" ]; then \
        printf ",\n  pages     = {%s}" "$$pages" >> $(BIBFILE); \
    fi; \
    if [ -n "$$address" ]; then \
        printf ",\n  address   = {%s}" "$$address" >> $(BIBFILE); \
    fi; \
    if [ -n "$$edition" ]; then \
        printf ",\n  edition   = {%s}" "$$edition" >> $(BIBFILE); \
    fi; \
    if [ -n "$$volume" ]; then \
        printf ",\n  volume    = {%s}" "$$volume" >> $(BIBFILE); \
    fi; \
    if [ -n "$$series" ]; then \
        printf ",\n  series    = {%s}" "$$series" >> $(BIBFILE); \
    fi; \
    if [ -n "$$language" ]; then \
        printf ",\n  language  = {%s}" "$$language" >> $(BIBFILE); \
    fi; \
    if [ -n "$$note" ]; then \
        printf ",\n  note      = {%s}" "$$note" >> $(BIBFILE); \
    fi; \
    printf "\n}\n\n" >> $(BIBFILE); \
    echo "✅ 書籍の章エントリ '$$key' を追加しました"

# マニュアル・技術文書エントリを追加（完全版）
add-manual:
	@echo "📋 マニュアル・技術文書エントリを追加"
	@echo "💡 入力ガイド: 版情報は「v1.0」「第2版」など自由形式、組織名は正式名称推奨"
	@echo ""
	@read -p "✅ 引用キー (例: manual2024): " key; \
    read -p "📖 タイトル: " title; \
    read -p "🏢 組織・機関名: " organization; \
    read -p "📅 発行年 (半角数字): " year; \
    read -p "🔢 版・バージョン (オプション, 例: v1.0, 第2版): " edition; \
    read -p "📝 著者 (オプション): " author; \
    read -p "📄 サブタイトル (オプション): " subtitle; \
    read -p "🌍 発行地 (オプション): " address; \
    read -p "🌐 URL (オプション): " url; \
    read -p "📅 アクセス日 (URL有りの場合, YYYY-MM-DD): " urldate; \
    read -p "🌐 言語 (オプション): " language; \
    read -p "📝 備考 (オプション): " note; \
    printf "\n@manual{%s,\n" "$$key" >> $(BIBFILE); \
    printf "  title        = {%s},\n" "$$title" >> $(BIBFILE); \
    printf "  organization = {%s},\n" "$$organization" >> $(BIBFILE); \
    printf "  year         = {%s}" "$$year" >> $(BIBFILE); \
    if [ -n "$$edition" ]; then \
        printf ",\n  edition      = {%s}" "$$edition" >> $(BIBFILE); \
    fi; \
    if [ -n "$$author" ]; then \
        printf ",\n  author       = {%s}" "$$author" >> $(BIBFILE); \
    fi; \
    if [ -n "$$subtitle" ]; then \
        printf ",\n  subtitle     = {%s}" "$$subtitle" >> $(BIBFILE); \
    fi; \
    if [ -n "$$address" ]; then \
        printf ",\n  address      = {%s}" "$$address" >> $(BIBFILE); \
    fi; \
    if [ -n "$$url" ]; then \
        printf ",\n  url          = {%s}" "$$url" >> $(BIBFILE); \
    fi; \
    if [ -n "$$urldate" ]; then \
        printf ",\n  urldate      = {%s}" "$$urldate" >> $(BIBFILE); \
    fi; \
    if [ -n "$$language" ]; then \
        printf ",\n  language     = {%s}" "$$language" >> $(BIBFILE); \
    fi; \
    if [ -n "$$note" ]; then \
        printf ",\n  note         = {%s}" "$$note" >> $(BIBFILE); \
    fi; \
    printf "\n}\n\n" >> $(BIBFILE); \
    echo "✅ マニュアルエントリ '$$key' を追加しました"

# 学位論文エントリを追加
add-thesis:
	@echo "🎓 学位論文エントリを追加"
	@echo "💡 入力ガイド: 学位論文の種類を選択（修士論文・博士論文など）"
	@echo ""
	@read -p "✅ 引用キー (例: sato2024thesis): " key; \
    read -p "📝 著者名: " author; \
    read -p "📖 論文タイトル: " title; \
    read -p "🎓 学位論文種別 (例: 修士論文, Master's thesis): " type; \
    read -p "🏫 大学・機関名: " school; \
    read -p "📅 提出年 (半角数字): " year; \
    read -p "🌍 所在地 (オプション): " address; \
    read -p "📅 提出月 (オプション, 例: March): " month; \
    read -p "🌐 言語 (オプション): " language; \
    read -p "📝 備考 (オプション): " note; \
    printf "\n@mastersthesis{%s,\n" "$$key" >> $(BIBFILE); \
    printf "  author  = {%s},\n" "$$author" >> $(BIBFILE); \
    printf "  title   = {%s},\n" "$$title" >> $(BIBFILE); \
    printf "  school  = {%s},\n" "$$school" >> $(BIBFILE); \
    printf "  year    = {%s}" "$$year" >> $(BIBFILE); \
    if [ -n "$$type" ]; then \
        printf ",\n  type    = {%s}" "$$type" >> $(BIBFILE); \
    fi; \
    if [ -n "$$address" ]; then \
        printf ",\n  address = {%s}" "$$address" >> $(BIBFILE); \
    fi; \
    if [ -n "$$month" ]; then \
        printf ",\n  month   = {%s}" "$$month" >> $(BIBFILE); \
    fi; \
    if [ -n "$$language" ]; then \
        printf ",\n  language = {%s}" "$$language" >> $(BIBFILE); \
    fi; \
    if [ -n "$$note" ]; then \
        printf ",\n  note    = {%s}" "$$note" >> $(BIBFILE); \
    fi; \
    printf "\n}\n\n" >> $(BIBFILE); \
    echo "✅ 学位論文エントリ '$$key' を追加しました"

# 会議論文エントリを追加
add-inproceedings:
	@echo "🏛️ 会議論文エントリを追加"
	@echo "💡 入力ガイド: 会議名・開催地・日程など詳細情報を含められます"
	@echo ""
	@read -p "✅ 引用キー (例: conference2024): " key; \
	read -p "📝 著者名: " author; \
    read -p "📖 論文タイトル: " title; \
    read -p "🏛️ 会議名 (proceedings): " booktitle; \
    read -p "📅 開催年 (半角数字): " year; \
    read -p "📄 ページ範囲 (例: 123--135, オプション): " pages; \
    read -p "📝 編集者 (オプション): " editor; \
    read -p "🏢 出版社 (オプション): " publisher; \
    read -p "🌍 開催地 (オプション): " address; \
    read -p "📅 開催月 (オプション): " month; \
    read -p "🔗 DOI (オプション): " doi; \
    read -p "🌐 URL (オプション): " url; \
    read -p "🌐 言語 (オプション): " language; \
    read -p "📝 備考 (オプション): " note; \
    printf "\n@inproceedings{%s,\n" "$$key" >> $(BIBFILE); \
    printf "  author    = {%s},\n" "$$author" >> $(BIBFILE); \
    printf "  title     = {%s},\n" "$$title" >> $(BIBFILE); \
    printf "  booktitle = {%s},\n" "$$booktitle" >> $(BIBFILE); \
    printf "  year      = {%s}" "$$year" >> $(BIBFILE); \
    if [ -n "$$pages" ]; then \
        printf ",\n  pages     = {%s}" "$$pages" >> $(BIBFILE); \
    fi; \
    if [ -n "$$editor" ]; then \
        printf ",\n  editor    = {%s}" "$$editor" >> $(BIBFILE); \
    fi; \
    if [ -n "$$publisher" ]; then \
        printf ",\n  publisher = {%s}" "$$publisher" >> $(BIBFILE); \
    fi; \
    if [ -n "$$address" ]; then \
        printf ",\n  address   = {%s}" "$$address" >> $(BIBFILE); \
    fi; \
    if [ -n "$$month" ]; then \
        printf ",\n  month     = {%s}" "$$month" >> $(BIBFILE); \
    fi; \
    if [ -n "$$doi" ]; then \
        printf ",\n  doi       = {%s}" "$$doi" >> $(BIBFILE); \
    fi; \
    if [ -n "$$url" ]; then \
        printf ",\n  url       = {%s}" "$$url" >> $(BIBFILE); \
    fi; \
    if [ -n "$$language" ]; then \
        printf ",\n  language  = {%s}" "$$language" >> $(BIBFILE); \
    fi; \
    if [ -n "$$note" ]; then \
        printf ",\n  note      = {%s}" "$$note" >> $(BIBFILE); \
    fi; \
    printf "\n}\n\n" >> $(BIBFILE); \
    echo "✅ 会議論文エントリ '$$key' を追加しました"

# =============================================================================
# 表示・確認
# =============================================================================

# PDFを表示
view: validate-vars
	@echo "📖 PDFを表示中..."
	@if [ -f "$(MAINPDF)" ]; then \
        echo "  📄 $(MAINPDF) を開いています..."; \
        "$$BROWSER" "$(MAINPDF)" || \
        xdg-open "$(MAINPDF)" 2>/dev/null || \
        echo "  ⚠️  ブラウザでPDFを開けませんでした。手動で $(MAINPDF) を開いてください"; \
    else \
        echo "  ❌ PDFファイルが見つかりません: $(MAINPDF)"; \
        echo "  💡 先に 'make all' または 'make dev' でビルドしてください"; \
    fi

# VS Code でPDFを開く
viewhelp:
	@echo "📖 VS Code でPDFを開いています..."
	@if [ -f "$(MAINPDF)" ]; then \
        code "$(MAINPDF)" || \
        echo "  ⚠️  VS Codeが利用できません。代替方法でPDFを開きます..."; \
        $(MAKE) --no-print-directory view; \
    else \
        echo "  ❌ PDFファイルが見つかりません: $(MAINPDF)"; \
        echo "  💡 先に 'make all' または 'make dev' でビルドしてください"; \
    fi

# 文献ファイルの内容を表示
show-bib:
	@echo "📚 文献データベースの内容:"
	@if [ -f "$(BIBFILE)" ]; then \
        echo "  📄 ファイル: $(BIBFILE)"; \
        echo "  📊 エントリ数: $$(grep -c '^@' $(BIBFILE)) 件"; \
        echo ""; \
        cat $(BIBFILE); \
    else \
        echo "  ❌ $(BIBFILE) が見つかりません"; \
        echo "  💡 'make create-bib' で作成してください"; \
    fi

# 文献を検索
search-bib:
	@echo "🔍 文献データベースを検索"
	@if [ ! -f "$(BIBFILE)" ]; then \
        echo "  ❌ $(BIBFILE) が見つかりません"; \
        echo "  💡 'make create-bib' で作成してください"; \
        exit 1; \
    fi
	@read -p "検索キーワードを入力してください: " keyword; \
    echo ""; \
    echo "🔍 「$$keyword」の検索結果:"; \
    echo ""; \
    grep -i -n -A 10 -B 2 "$$keyword" $(BIBFILE) || \
    echo "  該当する文献が見つかりませんでした"

# プロジェクト状況を表示
status:
	@echo "📊 プロジェクト状況:"
	@echo "  メインファイル: $(TEXFILE).tex"
	@echo "  セクション数: $(words $(SUBFILES)) ファイル"
	@if [ -f "$(BIBFILE)" ]; then \
        echo "  文献ファイル: $(BIBFILE) ✅"; \
        echo "  文献数: $$(grep -c '^@' $(BIBFILE)) 件"; \
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
# ヘルプ・使用方法
# =============================================================================

# ヘルプメッセージを表示
help:
	@echo "📖 LaTeX文書ビルドシステム ヘルプ"
	@echo ""
	@echo "🚀 基本的な使用方法:"
	@echo "  make all        - PDFをビルド"
	@echo "  make dev        - フォーマット→完全ビルド"
	@echo "  make view       - PDFをブラウザで表示"
	@echo "  make viewhelp   - PDFをVS Codeで表示"
	@echo ""
	@echo "🧹 クリーンアップ:"
	@echo "  make clean      - 一時ファイルを削除（PDFは残す）"
	@echo "  make fullclean  - すべての生成ファイルを削除"
	@echo "  make fmtclean   - フォーマット用バックアップを削除"
	@echo ""
	@echo "📚 文献管理:"
	@echo "  make create-bib - 新しい文献ファイルを作成"
	@echo "  make add-bib    - 文献エントリを追加（対話式）"
	@echo "  make show-bib   - 文献ファイルの内容を表示"
	@echo "  make search-bib - 文献を検索"
	@echo ""
	@echo "📋 プロジェクト管理:"
	@echo "  make new-project - 新しいプロジェクトを作成"
	@echo "  make templates   - 利用可能なテンプレートを表示"
	@echo "  make status      - プロジェクト状況を表示"
	@echo ""
	@echo "🔧 高度な機能:"
	@echo "  make fmt         - LaTeXファイルをフォーマット"
	@echo "  make bib         - 文献データベースのみ処理"
	@echo "  make fullbuild   - 完全ビルド（文献処理込み）"
	@echo ""
	@echo "📖 個別の文献エントリ追加:"
	@echo "  make add-book           - 書籍"
	@echo "  make add-article        - 論文（雑誌記事）"
	@echo "  make add-online         - オンライン資料"
	@echo "  make add-inbook         - 書籍の章"
	@echo "  make add-manual         - マニュアル・技術文書"
	@echo "  make add-thesis         - 学位論文"
	@echo "  make add-inproceedings  - 会議論文"
	@echo ""
	@echo "💡 ヒント:"
	@echo "  - 文献管理には BibLaTeX + Biber を使用"
	@echo "  - 日本語・英語混在対応"
	@echo "  - VS Code 拡張機能との連携対応"
	@echo "  - 安全性チェック機能内蔵"

.PHONY : all dev clean fullclean fmtclean fmt bib fullbuild validate-vars \
	create-bib add-bib add-book add-article add-online add-inbook add-manual \
	add-thesis add-inproceedings view viewhelp show-bib search-bib help status