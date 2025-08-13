#!/usr/bin/env python3
"""
CI環境用画像生成スクリプト
LaTeXファイルを解析して、参照されている画像のダミー画像を自動生成
"""
import re
import os
from pathlib import Path

def get_figures_directory_images():
    """tex/figuresディレクトリ内の画像ファイルを検出"""
    figures_dir = 'tex/figures'

    if not os.path.exists(figures_dir):
        print(f"ℹ️  {figures_dir}ディレクトリが存在しません")
        return set()

    # サポートされている画像形式
    image_extensions = {'.png', '.jpg', '.jpeg', '.gif', '.svg', '.bmp', '.tiff', '.eps', '.ps'}

    image_paths = set()

    for root, dirs, files in os.walk(figures_dir):
        for file in files:
            # 拡張子をチェック
            if any(file.lower().endswith(ext) for ext in image_extensions):
                # 拡張子を除去してベース名を取得
                base_name = os.path.splitext(file)[0]
                # tex/figuresからの相対パス
                rel_path = os.path.relpath(os.path.join(root, base_name), 'tex')
                image_paths.add(rel_path)

    return image_paths

def create_dummy_image(output_path, image_name):
    """ダミー画像を作成"""
    try:
        from PIL import Image, ImageDraw, ImageFont

        # 画像サイズ（より大きく）
        width, height = 500, 400

        # グラデーション背景を作成
        image = Image.new('RGB', (width, height))
        draw = ImageDraw.Draw(image)

        # グラデーション背景（上から下へ）
        for y in range(height):
            # 上は明るい青、下は白に近い色
            r = int(240 + (y / height) * 15)
            g = int(245 + (y / height) * 10)
            b = int(250 + (y / height) * 5)
            draw.line([(0, y), (width, y)], fill=(r, g, b))

        # メインの枠（角丸風）
        margin = 20
        draw.rectangle([margin, margin, width-margin, height-margin],
                      outline='#3b82f6', width=3, fill=None)

        # 左上の装飾的な角
        corner_size = 15
        draw.rectangle([margin, margin, margin+corner_size, margin+corner_size],
                      fill='#3b82f6')
        draw.rectangle([width-margin-corner_size, margin, width-margin, margin+corner_size],
                      fill='#3b82f6')
        draw.rectangle([margin, height-margin-corner_size, margin+corner_size, height-margin],
                      fill='#3b82f6')
        draw.rectangle([width-margin-corner_size, height-margin-corner_size, width-margin, height-margin],
                      fill='#3b82f6')

        # 中央のアイコン（カメラ風）
        icon_size = 80
        icon_x = width // 2 - icon_size // 2
        icon_y = height // 2 - icon_size // 2 - 20

        # カメラ本体
        draw.ellipse([icon_x, icon_y, icon_x + icon_size, icon_y + icon_size],
                     fill='#1e40af', outline='#1e3a8a', width=2)

        # レンズ
        lens_size = 50
        lens_x = width // 2 - lens_size // 2
        lens_y = height // 2 - lens_size // 2 - 20
        draw.ellipse([lens_x, lens_y, lens_x + lens_size, lens_y + lens_size],
                     fill='#60a5fa', outline='#3b82f6', width=2)

        # フラッシュ
        flash_x = width // 2 + 25
        flash_y = height // 2 - 30
        draw.rectangle([flash_x, flash_y, flash_x + 15, flash_y + 20],
                      fill='#fbbf24', outline='#f59e0b', width=1)

                                        # 画像名（ファイル名のみ）
        try:
            # シンプルなフォント設定
            font_size = 28  # ファイル名用の大きなフォント
            font = ImageFont.load_default()

            text = os.path.basename(image_name)

            # テキストサイズを取得
            bbox = draw.textbbox((0, 0), text, font=font)
            text_width = bbox[2] - bbox[0]
            text_height = bbox[3] - bbox[1]

            # 下部に配置（ファイル名を大きく表示）
            text_x = (width - text_width) // 2
            text_y = height - 80

            # テキスト背景（大きく）
            padding = 15
            draw.rectangle([text_x - padding, text_y - padding,
                           text_x + text_width + padding, text_y + text_height + padding],
                          fill='#ffffff', outline='#3b82f6', width=2)

            # テキストを描画
            draw.text((text_x, text_y), text, fill='#1e40af', font=font)

            # ファイル名の詳細情報（拡張子なし）
            detail_font_size = 18
            detail_font = ImageFont.load_default()

            detail_text = f"File: {image_name}"
            detail_bbox = draw.textbbox((0, 0), detail_text, detail_font)
            detail_width = detail_bbox[2] - detail_bbox[0]
            detail_x = (width - detail_width) // 2
            detail_y = height - 40

            # 詳細テキスト背景
            detail_padding = 10
            draw.rectangle([detail_x - detail_padding, detail_y - detail_padding,
                           detail_x + detail_width + detail_padding, detail_y + text_height + detail_padding],
                          fill='#f3f4f6', outline='#d1d5db', width=1)

            # 詳細テキストを描画
            draw.text((detail_x, detail_y), detail_text, fill='#6b7280', font=detail_font)

        except Exception as e:
            # フォールバック
            draw.text((width//2-50, height-80), "Demo", fill='#1e40af')
            draw.text((width//2-80, height-40), f"File: {image_name}", fill='#6b7280')

        # ディレクトリを作成
        os.makedirs(os.path.dirname(output_path), exist_ok=True)

        # 画像を保存
        image.save(output_path, 'PNG')
        print(f"✅ ダミー画像を作成: {output_path}")
        return True

    except ImportError:
        print(f"❌ PILがインストールされていません: {output_path}")
        return False
    except Exception as e:
        print(f"❌ 画像作成エラー {output_path}: {e}")
        return False

def main():
    """メイン処理"""
    print("🖼️  CI環境用ダミー画像を生成中...")

    # tex/figuresディレクトリ内の画像ファイルを検出
    image_paths = get_figures_directory_images()

    if not image_paths:
        print("ℹ️  tex/figuresディレクトリに画像ファイルが見つかりませんでした")
        return

    print(f"📊 検出された画像ファイル: {len(image_paths)}個")
    for path in image_paths:
        print(f"   📷 {path}")

    # ダミー画像を生成
    success_count = 0
    for image_path in image_paths:
        # tex/figuresディレクトリ内にPNGファイルとして保存
        output_path = f"tex/{image_path}.png"
        if create_dummy_image(output_path, image_path):
            success_count += 1

    print(f"\n🎉 完了! {success_count}/{len(image_paths)}個のダミー画像を生成しました")
    print("💡 これらの画像はCI環境でのみ使用され、Gitで管理されません")

if __name__ == "__main__":
    main()
