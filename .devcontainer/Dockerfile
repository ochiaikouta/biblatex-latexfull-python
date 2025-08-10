FROM paperist/texlive-ja:latest

# =============================================================================
# システムパッケージの一括インストール
# =============================================================================
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    make \
    # Perlモジュール
    libyaml-tiny-perl \
    libfile-homedir-perl \
    liblog-log4perl-perl \
    # Python環境
    python3 \
    python3-pip \
    # PDF関連ツール
    poppler-utils && \
    rm -rf /var/lib/apt/lists/* && \
    echo "✅ システムパッケージが正常にインストールされました"
    
# =============================================================================
# Python環境のセットアップ
# =============================================================================
COPY requirements.txt /tmp/requirements.txt
RUN pip3 install --break-system-packages -r /tmp/requirements.txt && \
    python3 --version && \
    echo "✅ Python 環境が正常にインストールされました"

# =============================================================================
# TeX Live パッケージの更新（全更新はオプトイン）
# =============================================================================
ARG TL_UPDATE=0
RUN tlmgr update --self && \
    if [ "$TL_UPDATE" = "1" ]; then tlmgr update --all; fi && \
    tlmgr install latexindent physics mhchem quantikz algorithm2e && \
    echo "✅ TeX Live パッケージの更新が完了しました"
