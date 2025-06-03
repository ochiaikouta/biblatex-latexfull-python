FROM python:3.11-bullseye

# 日本語フォント（Noto Sans CJK JP）をインストール
RUN apt-get update && \
    apt-get install -y fonts-noto-cjk && \
    rm -rf /var/lib/apt/lists/*

# TeX Live（LuaLaTeX, biber含む）をインストール
RUN apt-get update && \
    apt-get install -y texlive-full latexmk biber && \
    rm -rf /var/lib/apt/lists/*

# 必要なPythonパッケージをインストール
COPY requirements.txt .
RUN pip install --break-system-packages -r requirements.txt