SHELL := /bin/bash
# =============================================================================
# 設定変数
# =============================================================================
LATEX := latexmk
TEXFILE := main
TEXDIR := tex
SECTIONSDIR := sections
SUBFILES := $(wildcard $(TEXDIR)/$(SECTIONSDIR)/*.tex)


# デフォルトの文献ファイル名
DEFAULT_BIBFILE := refs
# 自動検索用のBIBFILES（tex/ディレクトリ内のすべての.bibファイル）
BIBFILES ?= $(shell find $(TEXDIR) -name "*.bib" 2>/dev/null | tr '\n' ' ')

# latexindentのバックアップディレクトリ
BACKUPDIR := .backups

# latexindentの設定ファイル
INDENT_CONFIG := .indentconfig.yaml

# テンプレート
TEMPLATE_DIR := templates
TEMPLATE_A := $(TEMPLATE_DIR)/template-academic.tex
TEMPLATE_S := $(TEMPLATE_DIR)/template-simple.tex
TEMPLATE_W := $(TEMPLATE_DIR)/template-with-bib.tex
TEMPLATE_M := $(TEMPLATE_DIR)/template-minimal.tex

# 日付フォーマット
DATE := $(shell date '+%Y-%m-%d')

# 安全性チェック
validate-vars:
	@if [ -z "$(TEXFILE)" ]; then echo "❌ TEXFILE が設定されていません"; exit 1; fi
	@if [ "$(TEXDIR)" = "/" ] || [ "$(TEXDIR)" = "." ] || [ "$(TEXDIR)" = ".." ]; then \
        echo "❌ 危険なビルドディレクトリ: $(TEXDIR)"; exit 1; \
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
build: validate-vars
	@echo "🚀 ビルド開始: $(TEXFILE).tex"
	$(LATEX) "$(TEXFILE)"

# 文献データベース（.bib）を処理  
bib: validate-vars
	@echo "📚 文献データベースを処理中... (upBibTeX)"
	@if [ -n "$(BIBFILES)" ] && [ -f "$(BIBFILES)" ]; then \
		echo "  📖 $(BIBFILES) が見つかりました"; \
		if [ -f "$(TEXDIR)/$(TEXFILE).aux" ]; then \
			(cd $(TEXDIR) && upbibtex $(TEXFILE)); \
		else \
			echo "  ℹ️  先に 'make build' で .aux を生成してください"; \
		fi; \
	else \
		echo "  ℹ️  .bibファイルが見つかりません。文献処理をスキップします"; \
		echo "  💡 tex/ディレクトリに.bibファイルを作成するか、BIBFILES=...で指定してください"; \
	fi

# 完全ビルド（文献処理も含む）
f-build: validate-vars
	@echo "🚀 完全ビルド開始..."
	@echo "  📄 初回ビルド中..."
	$(LATEX) "$(TEXFILE)"
	@if [ -n "$(BIBFILES)" ] && [ -f "$(BIBFILES)" ]; then \
		echo "  📚 文献データベースを処理中... (upBibTeX)"; \
		(cd $(TEXDIR) && upbibtex $(TEXFILE)) || true; \
		echo "  🔄 最終ビルド中..."; \
		$(LATEX) "$(TEXFILE)"; \
	else \
		echo "  ℹ️  .bibファイルがないため文献処理をスキップしました"; \
		echo "  💡 tex/ディレクトリに.bibファイルを作成するか、BIBFILES=...で指定してください"; \
	fi
	@echo "✅ 完全ビルド完了!"

# 開発用ワークフロー（フォーマット→完全ビルド）
dev: fmt f-build
	@echo "🚀 開発ワークフロー完了!"

# =============================================================================
# フォーマット・クリーンアップ
# =============================================================================

# LaTeX ファイルをフォーマット
fmt: validate-vars
	@echo "🔧 LaTeXファイルをフォーマット中..."
	@mkdir -p $(BACKUPDIR)
	latexindent -w -m -c $(BACKUPDIR) -y=$(INDENT_CONFIG) $(TEXFILE).tex
	@echo "🔧 セクションファイルもフォーマット中..."
	@if [ -d "$(SECTIONSDIR)" ] && [ -n "$(wildcard $(SECTIONSDIR)/*.tex)" ]; then \
        find $(SECTIONSDIR) -name "*.tex" -exec latexindent -w -m -c $(BACKUPDIR)/ -y=$(INDENT_CONFIG) {} \; ; \
    fi
	@echo "✅ フォーマット完了! (バックアップ: $(BACKUPDIR)/)"

# 一時ファイルを削除（PDFは残す）
clean: 
	@echo "🧹 一時ファイルを削除中..."
	$(LATEX) -c $(TEXFILE)
	@echo "  ✅ 一時ファイルの削除完了"

# 生成ファイルを完全削除（PDFも含む）
f-clean: 
	@echo "🧹 すべての生成ファイルを削除中..."
	$(LATEX) -C $(TEXFILE)
	@echo "  ✅ すべてのファイルの削除完了"

# バックアップファイルを削除 
d-back:
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
c-project:
	@echo "📝 新しいプロジェクトを作成します"
	@echo ""
	@echo "🔍 現在の設定:"
	@echo "  作成先: $(TEXFILE).tex"
	@echo "  文献ファイル: $(BIBFILES)"
	@echo "  テンプレートディレクトリ: $(TEMPLATE_DIR)"
	@echo ""
	@if [ -f "$(TEXFILE).tex" ]; then \
        echo "⚠️  $(TEXFILE).tex が既に存在します"; \
        read -p "上書きしますか？ (y/N): " overwrite; \
        if [ "$$overwrite" != "y" ] && [ "$$overwrite" != "Y" ]; then \
            echo "❌ 操作をキャンセルしました"; \
            exit 1; \
        fi; \
    fi
	@if [ ! -d "$(TEXDIR)" ]; then \
        echo "📁 $(TEXDIR)/ ディレクトリを作成中..."; \
        mkdir -p $(TEXDIR); \
        echo "✅ $(TEXDIR)/ ディレクトリを作成しました"; \
    fi
	@if [ ! -d "$(TEMPLATE_DIR)" ]; then \
        echo "⚠️  $(TEMPLATE_DIR)/ ディレクトリが存在しません"; \
        echo "💡 基本的なテンプレートを作成しますか？"; \
        read -p "作成する場合は y を入力: " create; \
        if [ "$$create" = "y" ] || [ "$$create" = "Y" ]; then \
            mkdir -p $(TEMPLATE_DIR); \
            echo "📁 $(TEMPLATE_DIR)/ ディレクトリを作成しました"; \
        else \
            echo "❌ 操作をキャンセルしました"; \
            exit 1; \
        fi; \
    fi
	@echo ""
	@echo "利用可能なテンプレート:"
	@echo "  1. with-bib    - 文献管理対応テンプレート（upLaTeX+upBibTeX）"
	@echo "  2. simple      - シンプルテンプレート（upLaTeX）"
	@echo "  3. academic    - 学術論文テンプレート"
	@echo "  4. minimal     - 最小テンプレート（ファイルからコピー）"
	@echo ""
	@read -p "テンプレートを選択してください (1-4): " choice; \
    case $$choice in \
        1) if [ -f "$(TEMPLATE_W)" ]; then \
               cp $(TEMPLATE_W) $(TEXDIR)/$(TEXFILE).tex && \
               echo "✅ 文献管理テンプレートを設定しました" && \
               $(MAKE) --no-print-directory c-bib && \
               echo "📚 文献ファイルも自動作成しました"; \
           else \
               echo "❌ $(TEMPLATE_W) が見つかりません"; \
           fi;; \
        2) if [ -f "$(TEMPLATE_S)" ]; then \
               cp $(TEMPLATE_S) $(TEXDIR)/$(TEXFILE).tex && \
               echo "✅ シンプルテンプレートを設定しました"; \
           else \
               echo "❌ $(TEMPLATE_S) が見つかりません"; \
           fi;; \
        3) if [ -f "$(TEMPLATE_A)" ]; then \
               cp $(TEMPLATE_A) $(TEXDIR)/$(TEXFILE).tex && \
               echo "✅ 学術論文テンプレートを設定しました" && \
               $(MAKE) --no-print-directory c-bib && \
               echo "📚 文献ファイルも自動作成しました"; \
           else \
               echo "❌ $(TEMPLATE_A) が見つかりません"; \
           fi;; \
        4) if [ -f "$(TEMPLATE_M)" ]; then \
               cp $(TEMPLATE_M) $(TEXDIR)/$(TEXFILE).tex && \
               echo "✅ 最小テンプレートを設定しました"; \
           else \
               echo "❌ $(TEMPLATE_M) が見つかりません"; \
           fi;; \
        *) echo "❌ 無効な選択です";; \
    esac
	@echo ""
	@echo "🎉 プロジェクトの作成が完了しました！"
	@echo ""
	@echo "📋 次のステップ:"
	@echo "  1. $(TEXFILE).tex を編集"
	@echo "  2. 'make dev' でビルド"
	@echo "  3. 'make view' でPDFを確認"
	@if [ -n "$(BIBFILES)" ]; then \
        echo "  4. 'make a-bib' で文献を追加"; \
    fi

# テンプレート一覧を表示
l-tmp:
	@echo "📋 利用可能なテンプレート:"
	@echo ""
	@echo "LaTeXテンプレート:"
	@ls -la $(TEMPLATE_DIR)/template-*.tex 2>/dev/null || echo "  (未作成)"
	@echo ""
	@echo "💡 文献テンプレートはMakefileに統合済みです。"
	@echo "   文献追加: make a-bib"

# =============================================================================
# 文献管理
# =============================================================================

# 文献ファイルを新規作成
c-bib:
	@echo "📚 新しい文献ファイルを作成中..."
	@read -p "文献ファイル名を入力してください (例: refs.bib, デフォルト: refs.bib): " filename; \
	if [ -z "$$filename" ]; then \
		filename="$(DEFAULT_BIBFILE)"; \
	fi; \
	if [ ! "$$filename" = "$${filename%.bib}" ]; then \
		:; \
	else \
		filename="$$filename.bib"; \
	fi; \
	bibpath="$(TEXDIR)/$$filename"; \
	if [ -f "$$bibpath" ]; then \
		echo "⚠️  $$bibpath が既に存在します"; \
		read -p "上書きしますか？ (y/N): " confirm; \
		if [ "$$confirm" != "y" ] && [ "$$confirm" != "Y" ]; then \
			echo "❌ 操作をキャンセルしました"; \
			exit 1; \
		fi; \
	fi; \
	printf '%s\n' \
		'% BibTeX用文献データベース' \
		'% 作成日: $(DATE)' \
		'' > "$$bibpath"; \
	echo "✅ $$bibpath を作成しました"; \
	echo "💡 このファイルを使用するには、LaTeXファイルで \\bibliography{$${filename%.bib}} を指定してください"

# 文献エントリを追加
a-bib:
	@echo "📖 文献エントリを追加します"
	@found_bib=false; \
	for bib in $(BIBFILES); do \
		if [ -f "$$bib" ]; then \
			found_bib=true; \
			break; \
		fi; \
	done; \
	if [ "$$found_bib" = "false" ]; then \
		echo "❌ .bibファイルが見つかりません"; \
		echo " tex/ディレクトリに.bibを作成するか、c-bibを実行してください"; \
		exit 1; \
	fi
	@echo "利用可能な.bibファイル:"
	@counter=1; \
	first_bib=""; \
	for bib in $(BIBFILES); do \
		if [ -f "$$bib" ]; then \
			if [ -z "$$first_bib" ]; then \
				first_bib="$$bib"; \
			fi; \
			echo "  $$counter. $$bib"; \
			counter=$$((counter + 1)); \
		fi; \
	done; \
	echo ""; \
	read -p "どの.bibファイルに追加しますか？ (1-$$((counter-1))から選択してください): " choice; \
	if [ -z "$$choice" ]; then \
		choice=1; \
	fi; \
	if [ "$$choice" -ge 1 ] && [ "$$choice" -le "$$((counter-1))" ]; then \
		choice_counter=1; \
		for bib in $(BIBFILES); do \
			if [ -f "$$bib" ]; then \
				if [ "$$choice" = "$$choice_counter" ]; then \
					target_bib="$$bib"; \
					break; \
				fi; \
				choice_counter=$$((choice_counter + 1)); \
			fi; \
		done; \
	else \
		echo "❌ 無効な選択です: $$choice (1-$$((counter-1))の範囲で選択してください)"; \
		exit 1; \
	fi; \
	echo "✅ 選択されたファイル: $$target_bib"; \
	echo ""; \
	echo "文献の種類を選択してください:"; \
	echo "  1. book           - 書籍"; \
	echo "  2. article        - 論文（雑誌記事）"; \
	echo "  3. inbook         - 書籍の章"; \
	echo "  4. online         - オンライン資料"; \
	echo "  5. manual         - マニュアル・技術文書"; \
	echo "  6. thesis         - 学位論文"; \
	echo "  7. inproceedings  - 会議論文"; \
	read -p "種類を選択 (1-7): " type; \
	case $$type in \
		1) $(MAKE) --no-print-directory a-book TARGET_BIB="$$target_bib";; \
		2) $(MAKE) --no-print-directory a-article TARGET_BIB="$$target_bib";; \
		3) $(MAKE) --no-print-directory a-inbook TARGET_BIB="$$target_bib";; \
		4) $(MAKE) --no-print-directory a-online TARGET_BIB="$$target_bib";; \
		5) $(MAKE) --no-print-directory a-manual TARGET_BIB="$$target_bib";; \
		6) $(MAKE) --no-print-directory a-thesis TARGET_BIB="$$target_bib";; \
		7) $(MAKE) --no-print-directory a-inproceedings TARGET_BIB="$$target_bib";; \
		*) echo "❌ 無効な選択です";; \
	esac

# 書籍エントリを追加
a-book:
	@echo "📚 書籍エントリを追加"
	@if [ -z "$(TARGET_BIB)" ]; then \
		echo "❌ ターゲット.bibファイルが指定されていません"; \
		exit 1; \
	fi
	@echo "💡 入力ガイド: 年は半角数字（2024）、日本語/英語混在OK、空欄でスキップ可能"
	@echo ""
	@read -p "✅ 引用キー (例: tanaka2024): " key; \
    read -p "📝 著者名 (例: 田中太郎 or Tanaka, Taro): " author; \
    read -p "📖 書籍タイトル: " title; \
    read -p "📅 出版年 (半角数字, 例: 2024): " year; \
    read -p "🏢 出版社: " publisher; \
    read -p "🌍 出版地 (オプション, 例: 東京): " address; \
    read -p "📝 編集者 (オプション): " editor; \
    read -p "🔢 版 (オプション, 半角数字): " edition; \
    read -p "📚 巻 (オプション, 半角数字): " volume; \
    read -p "📑 シリーズ名 (オプション): " series; \
    read -p "📝 備考 (オプション): " note; \
    printf "\n@book{%s,\n" "$$key" >> "$(TARGET_BIB)"; \
    printf "  author    = {%s},\n" "$$author" >> "$(TARGET_BIB)"; \
    printf "  title     = {%s},\n" "$$title" >> "$(TARGET_BIB)"; \
    printf "  year      = {%s},\n" "$$year" >> "$(TARGET_BIB)"; \
    printf "  publisher = {%s}" "$$publisher" >> "$(TARGET_BIB)"; \
    if [ -n "$$address" ]; then \
        printf ",\n  address   = {%s}" "$$address" >> "$(TARGET_BIB)"; \
    fi; \
    if [ -n "$$editor" ]; then \
        printf ",\n  editor    = {%s}" "$$editor" >> "$(TARGET_BIB)"; \
    fi; \
    if [ -n "$$edition" ]; then \
        printf ",\n  edition   = {%s}" "$$edition" >> "$(TARGET_BIB)"; \
    fi; \
    if [ -n "$$volume" ]; then \
        printf ",\n  volume    = {%s}" "$$volume" >> "$(TARGET_BIB)"; \
    fi; \
    if [ -n "$$series" ]; then \
        printf ",\n  series    = {%s}" "$$series" >> "$(TARGET_BIB)"; \
    fi; \
    if [ -n "$$note" ]; then \
        printf ",\n  note      = {%s}" "$$note" >> "$(TARGET_BIB)"; \
    fi; \
    printf "\n}\n\n" >> "$(TARGET_BIB)"; \
    echo "✅ 書籍エントリ '$$key' を $(TARGET_BIB) に追加しました"

# 論文エントリを追加
a-article:
	@echo "📄 論文エントリを追加"
	@if [ -z "$(TARGET_BIB)" ]; then \
		echo "❌ ターゲット.bibファイルが指定されていません"; \
		exit 1; \
	fi
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
	read -p "📝 備考 (オプション): " note; \
	printf "\n@article{%s,\n" "$$key" >> "$(TARGET_BIB)"; \
	printf "  author  = {%s},\n" "$$author" >> "$(TARGET_BIB)"; \
	printf "  title   = {%s},\n" "$$title" >> "$(TARGET_BIB)"; \
	printf "  journal = {%s},\n" "$$journal" >> "$(TARGET_BIB)"; \
	printf "  year    = {%s}" "$$year" >> "$(TARGET_BIB)"; \
	if [ -n "$$volume" ]; then \
	    printf ",\n  volume  = {%s}" "$$volume" >> "$(TARGET_BIB)"; \
	fi; \
	if [ -n "$$number" ]; then \
	    printf ",\n  number  = {%s}" "$$number" >> "$(TARGET_BIB)"; \
	fi; \
	if [ -n "$$pages" ]; then \
	    printf ",\n  pages   = {%s}" "$$pages" >> "$(TARGET_BIB)"; \
	fi; \
	note_out="$$note"; \
	if [ -n "$$doi" ]; then \
	  if [ -n "$$note_out" ]; then note_out="doi: $$doi; $$note_out	"; else note_out="doi: $$doi"; fi; \
	fi; \
	if [ -n "$$url" ]; then \
	  if [ -n "$$note_out" ]; then note_out="url: \\url{$$url}; $$note_out"; else note_out="url: \\url{$$url}"; fi; \
	fi; \
	if [ -n "$$note_out" ]; then \
	    printf ",\n  note    = {%s}" "$$note_out" >> "$(TARGET_BIB)"; \
	fi; \
	printf "\n}\n\n" >> "$(TARGET_BIB)"; \
	echo "✅ 論文エントリ '$$key' を $(TARGET_BIB) に追加しました"

# オンライン資料エントリを追加
a-online:
	@echo "📄 オンライン資料エントリを追加"
	@if [ -z "$(TARGET_BIB)" ]; then \
		echo "❌ ターゲット.bibファイルが指定されていません"; \
		exit 1; \
	fi
	@echo "💡 入力ガイド: URLdate は YYYY-MM-DD 形式（例: 2024-08-05）、全角文字OK"
	@echo ""
	@read -p "✅ 引用キー (例: website2024): " key; \
	read -p "📝 著者名 (オプション, 例: 田中太郎): " author; \
	read -p "📖 タイトル: " title; \
	read -p "🌐 URL: " url; \
	read -p "📅 アクセス日 (YYYY-MM-DD, 例: 2024-08-05): " urldate; \
	read -p "📅 発表年 (半角数字, オプション): " year; \
	read -p "🏢 組織名 (オプション): " organization; \
	read -p "📝 備考 (オプション): " note; \
	printf "\n@misc{%s,\n" "$$key" >> "$(TARGET_BIB)"; \
	if [ -n "$$author" ]; then \
	    printf "  author       = {%s},\n" "$$author" >> "$(TARGET_BIB)"; \
	fi; \
	printf "  title        = {%s},\n" "$$title" >> "$(TARGET_BIB)"; \
	printf "  howpublished = {\\url{%s}},\n" "$$url" >> "$(TARGET_BIB)"; \
	note_out="accessed: $$urldate"; \
	if [ -n "$$note" ]; then note_out="$$note_out; $$note"; fi; \
	printf "  note         = {%s}" "$$note_out" >> "$(TARGET_BIB)"; \
	if [ -n "$$year" ]; then \
	    printf ",\n  year         = {%s}" "$$year" >> "$(TARGET_BIB)"; \
	fi; \
	if [ -n "$$organization" ]; then \
	    printf ",\n  organization = {%s}" "$$organization" >> "$(TARGET_BIB)"; \
	fi; \
	printf "\n}\n\n" >> "$(TARGET_BIB)"; \
	echo "✅ オンライン資料エントリ '$$key' を $(TARGET_BIB) に追加しました"

# 書籍の章エントリを追加
a-inbook:
	@echo "📖 書籍の章エントリを追加"
	@if [ -z "$(TARGET_BIB)" ]; then \
		echo "❌ ターゲット.bibファイルが指定されていません"; \
		exit 1; \
	fi
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
    read -p "📝 備考 (オプション): " note; \
    printf "\n@inbook{%s,\n" "$$key" >> "$(TARGET_BIB)"; \
    printf "  author    = {%s},\n" "$$author" >> "$(TARGET_BIB)"; \
    printf "  title     = {%s},\n" "$$title" >> "$(TARGET_BIB)"; \
    printf "  booktitle = {%s},\n" "$$booktitle" >> "$(TARGET_BIB)"; \
    printf "  year      = {%s},\n" "$$year" >> "$(TARGET_BIB)"; \
    printf "  publisher = {%s}" "$$publisher" >> "$(TARGET_BIB)"; \
    if [ -n "$$editor" ]; then \
        printf ",\n  editor    = {%s}" "$$editor" >> "$(TARGET_BIB)"; \
    fi; \
    if [ -n "$$pages" ]; then \
        printf ",\n  pages     = {%s}" "$$pages" >> "$(TARGET_BIB)"; \
    fi; \
    if [ -n "$$address" ]; then \
        printf ",\n  address   = {%s}" "$$address" >> "$(TARGET_BIB)"; \
    fi; \
    if [ -n "$$edition" ]; then \
        printf ",\n  edition   = {%s}" "$$edition" >> "$(TARGET_BIB)"; \
    fi; \
    if [ -n "$$volume" ]; then \
        printf ",\n  volume    = {%s}" "$$volume" >> "$(TARGET_BIB)"; \
    fi; \
    if [ -n "$$series" ]; then \
        printf ",\n  series    = {%s}" "$$series" >> "$(TARGET_BIB)"; \
    fi; \
    if [ -n "$$note" ]; then \
        printf ",\n  note      = {%s}" "$$note" >> "$(TARGET_BIB)"; \
    fi; \
    printf "\n}\n\n" >> "$(TARGET_BIB)"; \
    echo "✅ 書籍の章エントリ '$$key' を $(TARGET_BIB) に追加しました"

# マニュアル・技術文書エントリを追加
a-manual:
	@echo "📋 マニュアル・技術文書エントリを追加"
	@if [ -z "$(TARGET_BIB)" ]; then \
		echo "❌ ターゲット.bibファイルが指定されていません"; \
		exit 1; \
	fi
	@echo "💡 入力ガイド: 版情報は「v1.0」「第2版」など自由形式、組織名は正式名称推奨"
	@echo ""
	@read -p "✅ 引用キー (例: manual2024): " key; \
    read -p "📖 タイトル: " title; \
    read -p "🏢 組織・機関名: " organization; \
    read -p "📅 発行年 (半角数字): " year; \
    read -p "🔢 版・バージョン (オプション, 半角数字): " edition; \
    read -p "📝 著者 (オプション): " author; \
	read -p "📄 サブタイトル (オプション): " subtitle; \
	read -p "🌍 発行地 (オプション): " address; \
	read -p "🌐 URL (オプション): " url; \
	read -p "📅 アクセス日 (URL有りの場合, YYYY-MM-DD): " urldate; \
	read -p "📝 備考 (オプション): " note; \
    printf "\n@manual{%s,\n" "$$key" >> "$(TARGET_BIB)"; \
    printf "  title        = {%s},\n" "$$title" >> "$(TARGET_BIB)"; \
    printf "  organization = {%s},\n" "$$organization" >> "$(TARGET_BIB)"; \
    printf "  year         = {%s}" "$$year" >> "$(TARGET_BIB)"; \
    if [ -n "$$edition" ]; then \
        printf ",\n  edition      = {%s}" "$$edition" >> "$(TARGET_BIB)"; \
    fi; \
    if [ -n "$$author" ]; then \
        printf ",\n  author       = {%s}" "$$author" >> "$(TARGET_BIB)"; \
    fi; \
    if [ -n "$$subtitle" ]; then \
        printf ",\n  subtitle     = {%s}" "$$subtitle" >> "$(TARGET_BIB)"; \
    fi; \
    if [ -n "$$address" ]; then \
        printf ",\n  address      = {%s}" "$$address" >> "$(TARGET_BIB)"; \
    fi; \
    note_out="$$note"; \
    if [ -n "$$url" ]; then \
      	if [ -n "$$note_out" ]; then note_out="\\url{$$url}; $$note_out"; else note_out="\\url{$$url}"; fi; \
    fi; \
    if [ -n "$$urldate" ]; then \
      if [ -n "$$note_out" ]; then note_out="accessed: $$urldate; $$note_out"; else note_out="accessed: $$urldate"; fi; \
    fi; \
    if [ -n "$$note_out" ]; then \
        printf ",\n  note         = {%s}" "$$note_out" >> "$(TARGET_BIB)"; \
    fi; \
    printf "\n}\n\n" >> "$(TARGET_BIB)"; \
    echo "✅ マニュアルエントリ '$$key' を $(TARGET_BIB) に追加しました"

# 学位論文エントリを追加
a-thesis:
	@echo "🎓 学位論文エントリを追加"
	@if [ -z "$(TARGET_BIB)" ]; then \
		echo "❌ ターゲット.bibファイルが指定されていません"; \
		exit 1; \
	fi
	@echo "💡 入力ガイド: 学位論文の種類を選択（修士論文・博士論文など）"
	@read -p "✅ 引用キー (例: sato2024thesis): " key; \
	read -p "📝 著者名: " author; \
	read -p "📖 論文タイトル: " title; \
	read -p "🎓 学位論文種別 (例: MT, PhD, オプション): " type; \
	read -p "🏫 大学・機関名: " school; \
	read -p "📅 提出年 (半角数字): " year; \
	read -p "🌍 所在地 (オプション): " address; \
    read -p "📅 提出日 (オプション, 例: 3月9日): " datejp; \
	read -p "📝 備考 (オプション): " note; \
	if [ "$$type" = "PhD" ]; then \
		entrytype=phdthesis; \
	else \
		entrytype=mastersthesis; \
	fi; \
	printf "\n@%s{%s,\n" "$$entrytype" "$$key" >> "$(TARGET_BIB)"; \
	printf "  author  = {%s},\n" "$$author" >> "$(TARGET_BIB)"; \
	printf "  title   = {%s},\n" "$$title" >> "$(TARGET_BIB)"; \
	printf "  school  = {%s},\n" "$$school" >> "$(TARGET_BIB)"; \
	printf "  year    = {%s}" "$$year" >> "$(TARGET_BIB)"; \
	if [ -n "$$address" ]; then \
		printf ",\n  address = {%s}" "$$address" >> "$(TARGET_BIB)"; \
	fi; \
    note_out="$$note"; \
    if [ -n "$$datejp" ]; then \
        if [ -n "$$note_out" ]; then note_out="$$datejp; $$note_out"; else note_out="$$datejp"; fi; \
    fi; \
    if [ -n "$$note_out" ]; then \
        printf ",\n  note    = {%s}" "$$note_out" >> "$(TARGET_BIB)"; \
    fi; \
	printf "\n}\n\n" >> "$(TARGET_BIB)"; \
	echo "✅ 学位論文エントリ '$$key' を $(TARGET_BIB) に追加しました"

# 会議論文エントリを追加
a-inproceedings:
	@echo "🏛️ 会議論文エントリを追加"
	@if [ -z "$(TARGET_BIB)" ]; then \
		echo "❌ ターゲット.bibファイルが指定されていません"; \
		exit 1; \
	fi
	@echo "💡 入力ガイド: 会議名・開催地・日程など詳細情報を含められます"
	@echo ""
	@read -p "✅ 引用キー (例: conference2024): " key; \
	read -p "📝 著者名: " author; \
    read -p "📖 論文タイトル: " title; \
    read -p "🏛️ 会議名 (proceedings): " booktitle; \
    read -p "📅 開催年 (半角数字): " year; \
    read -p "📄 ページ範囲 (例: 123--135, オプション): " pages; \
    read -p "📝 編集者 (オプション): " editor; \
    read -p "🏢 主催/出版社 (publisher/organization, オプション): " publisher; \
    read -p "🌍 開催地 (オプション): " address; \
    read -p "📅 開催日 (オプション, 例: 3月9日): " datejp; \
    read -p "🔗 DOI (オプション): " doi; \
    read -p "🌐 URL (オプション): " url; \
    read -p "📝 備考 (オプション): " note; \
    printf "\n@inproceedings{%s,\n" "$$key" >> "$(TARGET_BIB)"; \
    printf "  author    = {%s},\n" "$$author" >> "$(TARGET_BIB)"; \
    printf "  title     = {%s},\n" "$$title" >> "$(TARGET_BIB)"; \
    printf "  booktitle = {%s},\n" "$$booktitle" >> "$(TARGET_BIB)"; \
    printf "  year      = {%s}" "$$year" >> "$(TARGET_BIB)"; \
    if [ -n "$$pages" ]; then \
        printf ",\n  pages     = {%s}" "$$pages" >> "$(TARGET_BIB)"; \
    fi; \
    if [ -n "$$editor" ]; then \
        printf ",\n  editor    = {%s}" "$$editor" >> "$(TARGET_BIB)"; \
    fi; \
    if [ -n "$$publisher" ]; then \
        printf ",\n  organization = {%s}" "$$publisher" >> "$(TARGET_BIB)"; \
    fi; \
    if [ -n "$$address" ]; then \
        printf ",\n  address   = {%s}" "$$address" >> "$(TARGET_BIB)"; \
    fi; \
    note_out="$$note"; \
    if [ -n "$$datejp" ]; then \
        if [ -n "$$note_out" ]; then note_out="$$datejp; $$note_out"; else note_out="$$datejp"; fi; \
    fi; \
    if [ -n "$$doi" ]; then \
      if [ -n "$$note_out" ]; then note_out="doi: $$doi; $$note_out"; else note_out="doi: $$doi"; fi; \
    fi; \
    if [ -n "$$url" ]; then \
      if [ -n "$$note_out" ]; then note_out="url: \\url{$$url}; $$note_out"; else note_out="url: \\url{$$url}"; fi; \
    fi; \
    if [ -n "$$note_out" ]; then \
        printf ",\n  note      = {%s}" "$$note_out" >> "$(TARGET_BIB)"; \
    fi; \
    printf "\n}\n\n" >> "$(TARGET_BIB)"; \
    echo "✅ 会議論文エントリ '$$key' を $(TARGET_BIB) に追加しました"

# =============================================================================
# 表示・確認
# =============================================================================

# PDFをVS Codeで表示
view: validate-vars
	@echo "📖 VS Code でPDFを開いています..."
	@if [ -f "$(MAINPDF)" ]; then \
        echo "  📄 $(MAINPDF) を開いています..."; \
        code "$(MAINPDF)" || \
        echo "  ⚠️  VS Codeが利用できません。手動で $(MAINPDF) を開いてください"; \
    else \
        echo "  ❌ PDFファイルが見つかりません: $(MAINPDF)"; \
        echo "  💡 先に 'make all' または 'make dev' でビルドしてください"; \
    fi

# LaTeX Workshop の使用方法を表示
h-view:
	@echo "📖 LaTeX Workshop 使用ガイド"
	@echo ""
	@echo "🚀 VS Code でのLaTeX編集:"
	@echo "  1. LaTeX Workshop 拡張機能をインストール済み"
	@echo "  2. $(TEXFILE).tex を VS Code で開く"
	@echo ""
	@echo "⌨️  便利なショートカット:"
	@echo "  Ctrl+Alt+V      - PDFプレビューを表示"
	@echo "  Ctrl+Click      - SyncTeX（PDF↔TeXの相互ジャンプ）"
	@echo ""
	@echo "📖 LaTeX Workshop の機能:"
	@echo "  • リアルタイムプレビュー"
	@echo "  • シンタックスハイライト"
	@echo "  • オートコンプリート"
	@echo "  • エラーハイライト"
	@echo "  • 文献管理サポート（upBibTeX）"
	@echo "  • SyncTeX（PDF↔TeXの相互ジャンプ）"
	@echo ""
	@echo "💡 トラブルシューティング:"
	@echo "  • ビルドエラー: 出力パネルでログを確認"
	@echo "  • 文献が表示されない: 'make f-build' を実行"
	@echo "  • フォーマット: 'make fmt' でコード整形"
	@echo "  • SyncTeXが動作しない: 'make build' で再ビルド"
	@echo ""
	@if [ -f "$(MAINPDF)" ]; then \
        echo "📄 現在のPDF: $(MAINPDF)"; \
        echo "   ファイルサイズ: $$(du -h $(MAINPDF) | cut -f1)"; \
        echo "   最終更新: $$(stat -c '%y' $(MAINPDF) | cut -d. -f1)"; \
    else \
        echo "📄 PDFファイル: 未作成"; \
        echo "   💡 'make dev' でビルドしてください"; \
    fi

# 文献ファイルの内容を表示
l-bib:
	@echo "📚 文献データベースの内容:"
	@if [ -n "$(BIBFILES)" ]; then \
		echo "  📄 検出された.bibファイル:"; \
		for bib in $(BIBFILES); do \
			if [ -f "$$bib" ]; then \
				echo "    📖 $$bib ($$(grep -c '^@' $$bib) 件)"; \
			fi; \
		done; \
		echo ""; \
		echo "  📊 合計エントリ数: $$(find $(TEXDIR) -name "*.bib" -exec grep -c '^@' {} \; 2>/dev/null | awk '{sum += $$1} END {print sum+0}') 件"; \
		echo ""; \
		echo "  📋 各ファイルの内容:"; \
		echo ""; \
		for bib in $(BIBFILES); do \
			if [ -f "$$bib" ]; then \
				echo "  📄 $$bib:"; \
				echo "  $(shell printf '=%.0s' {1..50})"; \
				cat $$bib; \
				echo ""; \
			fi; \
		done; \
	else \
		echo "  ❌ .bibファイルが見つかりません"; \
		echo "  💡 tex/ディレクトリに.bibファイルを作成してください"; \
	fi

# 文献を検索
s-bib:
	@echo "🔍 文献データベースを検索"
	@if [ -n "$(BIBFILES)" ]; then \
		read -p "検索キーワードを入力してください: " keyword; \
		echo ""; \
		echo "🔍 「$$keyword」の検索結果:"; \
		echo ""; \
		found=false; \
		for bib in $(BIBFILES); do \
			if [ -f "$$bib" ]; then \
				if grep -i -q "$$keyword" $$bib; then \
					echo "   $$bib での検索結果:"; \
					echo "  $(shell printf '-%.0s' {1..40})"; \
					grep -i -n -A 5 -B 2 "$$keyword" $$bib || true; \
					echo ""; \
					found=true; \
				fi; \
			fi; \
		done; \
		if [ "$$found" = "false" ]; then \
			echo "  該当する文献が見つかりませんでした"; \
		fi; \
	else \
		echo "  ❌ .bibファイルが見つかりません"; \
		echo "  💡 tex/ディレクトリに.bibファイルを作成してください"; \
		exit 1; \
	fi

# プロジェクト状況を表示
status:
	@echo "📊 プロジェクト状況:"
	@echo "  メインファイル: $(TEXFILE).tex"
	@echo "  セクション数: $(words $(SUBFILES)) ファイル"
	@if [ -n "$(BIBFILES)" ] && [ -f "$(BIBFILES)" ]; then \
        echo "  文献ファイル: $(BIBFILES) ✅"; \
        echo "  文献数: $$(grep -c '^@' $(BIBFILES)) 件"; \
    else \
        echo "  文献ファイル: なし ℹ️"; \
    fi
	@echo "  ビルド出力: $(TEXDIR)/"
	@if [ -d "$(TEXDIR)" ]; then \
        echo "  生成ファイル:"; \
        ls -la $(TEXDIR)/ | grep -E '\.(pdf|synctex\.gz)$$' || echo "    (PDFファイルなし)"; \
    else \
        echo "  (まだビルドされていません)"; \
    fi

# 文書統計（文字数・ページ数）
count: validate-vars
	@echo "📊 文書統計"
	@if [ -f "$(TEXFILE).tex" ]; then \
		echo "📄 ファイル: $(TEXFILE).tex"; \
		echo " 文字数: $$(wc -c < $(TEXFILE).tex | tr -d ' ')"; \
		echo " 行数: $$(wc -l < $(TEXFILE).tex | tr -d ' ')"; \
		echo " 単語数: $$(wc -w < $(TEXFILE).tex | tr -d ' ')"; \
		if [ -f "$(MAINPDF)" ]; then \
			echo "📄 PDFページ数: $$(pdfinfo $(MAINPDF) 2>/dev/null | grep Pages | cut -d: -f2 | tr -d ' ' || echo '不明')"; \
		else \
			echo "📄 PDFページ数: PDFファイルが存在しません"; \
		fi; \
	else \
		echo "❌ $(TEXFILE).tex が見つかりません"; \
	fi

# =============================================================================
# ヘルプ・使用方法
# =============================================================================

# ヘルプメッセージを表示
help:
	@echo "📖 LaTeX Makefile ヘルプ"
	@echo ""
	@echo "プロジェクトを作成"
	@echo "  make c-project  - 新しいプロジェクトを作成"
	@echo "  make help       - このヘルプを表示"
	@echo ""
	@echo "基本コマンド:"
	@echo "  make build      - LaTeX文書をビルド"
	@echo "  make f-build    - 文献処理を含む完全ビルド"
	@echo "  make dev        - フォーマット→ビルド"
	@echo "  make clean      - 一時ファイルを削除"
	@echo "  make f-clean    - すべての生成ファイルを削除"
	@echo "  make d-back     - バックアップファイルを削除"
	@echo "  make fmt        - LaTeXファイルをフォーマット"
	@echo ""
	@echo "文献管理(upBibTeX):"
	@echo "  make bib        - 文献データベースを処理"
	@echo "  make c-bib      - 新しい文献ファイルを作成"
	@echo "  make a-bib      - 文献エントリを追加"
	@echo "  make l-bib      - 文献ファイルの内容を表示"
	@echo "  make s-bib      - 文献を検索"
	@echo ""
	@echo "便利なコマンド:"
	@echo "  make view       - PDFを表示"
	@echo "  make count      - 文書統計（文字数・   ページ数）"
	@echo "  make h-view     - LaTeX Workshop の使用方法"
	@echo "  make status     - プロジェクト状況を表示"
	@echo "  make l-tmp      - テンプレート一覧を表示"
	@echo ""
	@echo "設定:"
	@echo "  メインファイル: $(TEXFILE).tex"
	@echo "  文献ファイル: $(BIBFILES)"
	@echo "  ビルドディレクトリ: $(TEXDIR)/"

.PHONY : c-project help validate-vars build f-build dev clean f-clean d-back fmt bib \
	c-bib a-bib l-bib s-bib a-book a-article a-online a-inbook a-manual \
	a-thesis a-inproceedings view h-view status count \
	l-tmp 