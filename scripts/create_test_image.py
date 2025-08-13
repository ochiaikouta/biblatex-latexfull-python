#!/usr/bin/env python3
"""
テスト用画像生成スクリプト
CI環境やローカル開発で使用
"""
from PIL import Image, ImageDraw, ImageFont
import os

def create_test_image():
    # 画像サイズ
    width, height = 400, 300

    # 新しい画像を作成
    image = Image.new('RGB', (width, height), color='#f0f0f0')
    draw = ImageDraw.Draw(image)

    # 枠線を描画
    draw.rectangle([10, 10, width-10, height-10], outline='#333333', width=3)

    # 円を描画
    circle_center = (width//2, height//2)
    circle_radius = 60
    draw.ellipse([circle_center[0]-circle_radius, circle_center[1]-circle_radius,
                   circle_center[0]+circle_radius, circle_center[1]+circle_radius],
                  fill='#4CAF50', outline='#2E7D32', width=3)

    # テキストを描画
    try:
        font = ImageFont.load_default()

        # CIテキスト
        text = "CI"
        bbox = draw.textbbox((0, 0), text, font=font)
        text_width = bbox[2] - bbox[0]
        text_height = bbox[3] - bbox[1]
        text_x = circle_center[0] - text_width//2
        text_y = circle_center[1] - text_height//2
        draw.text((text_x, text_y), text, fill='white', font=font)

        # 説明テキスト
        desc_text = "テスト画像"
        bbox = draw.textbbox((0, 0), desc_text, font=font)
        text_width = bbox[2] - bbox[0]
        text_x = width//2 - text_width//2
        text_y = height - 50
        draw.text((text_x, text_y), desc_text, fill='#333333', font=font)

    except Exception as e:
        print(f"フォントエラー: {e}")
        # フォールバック: 簡単なテキスト
        draw.text((width//2-20, height//2-10), "CI", fill='white')
        draw.text((width//2-30, height-50), "テスト画像", fill='#333333')

    return image

if __name__ == "__main__":
    # ディレクトリを作成
    os.makedirs('tex/figures', exist_ok=True)

    # 画像を生成
    image = create_test_image()

    # 画像を保存
    output_path = 'tex/figures/test-image.png'
    image.save(output_path, 'PNG')
    print(f"テスト画像を作成しました: {output_path}")
    print("注意: この画像はGitで管理されません")
