import os

svg_dir = "kids_coding_cards/svgs"

# Thay thế hoàn toàn các thẻ đạo cụ giấy bằng BỘ TẬP LỆNH BỔ SUNG (Action Cards Expansion)
# Giúp bé có đủ thẻ để lập trình các đường đi dài xuyên suốt phòng khách!
deck_distribution = [
    # Trang 1: Di chuyển cơ bản (6 thẻ)
    ["01_buoc_toi_1_buoc", "01_buoc_toi_1_buoc", "01_buoc_toi_1_buoc", 
     "02_buoc_toi_2_buoc", "02_buoc_toi_2_buoc", "03_buoc_toi_3_buoc"],
    
    # Trang 2: Điều hướng & Xoay góc (6 thẻ)
    ["04_lui_lai_1_buoc", "05_nhay_qua_1_o", 
     "06_quay_trai_90", "06_quay_trai_90",
     "07_quay_phai_90", "07_quay_phai_90"],

    # Trang 3: Tương tác & Hành động (6 thẻ)
    ["08_quay_dang_sau", "11_bip_bip_chao_ban",
     "09_cui_xuong_bat_lay", "09_cui_xuong_bat_lay",
     "10_dat_do_xuong", "12_quan_sat_kiem_tra"],

    # Trang 4: Luồng điều khiển & Vòng lặp (6 thẻ)
    ["13_bat_dau_start", "13_bat_dau_start",
     "14_ve_dich_finish", "14_ve_dich_finish",
     "15_lap_lai_2_lan", "16_lap_lai_3_lan"],

    # Trang 5: TẬP LỆNH TĂNG CƯỜNG (Bổ sung thêm các thẻ hành động hay dùng nhất)
    # Không in đạo cụ giấy nữa vì sàn nhà dùng gối ôm, đồ chơi thật sinh động hơn nhiều!
    ["01_buoc_toi_1_buoc", "01_buoc_toi_1_buoc", 
     "06_quay_trai_90", "07_quay_phai_90",
     "05_nhay_qua_1_o", "09_cui_xuong_bat_lay"]
]

pages_html = ""

for page_idx, page_cards in enumerate(deck_distribution, 1):
    cards_in_page = ""
    for card_id in page_cards:
        svg_file = os.path.join(svg_dir, f"{card_id}.svg")
        with open(svg_file, "r", encoding="utf-8") as f:
            svg_content = f.read()
            if svg_content.startswith("<?xml"):
                svg_content = svg_content[svg_content.find("?>")+2:].strip()
            
            cards_in_page += f"""
            <div class="card-wrapper">
                {svg_content}
            </div>
            """
            
    title_suffix = "(Tập Lệnh Bổ Sung)" if page_idx == 5 else ""
    pages_html += f"""
    <div class="a4-page">
        <div class="page-header">
            <span class="page-title">🌱 KHU VƯỜN LẬP TRÌNH TÍ HON - BỘ TẬP LỆNH HÀNH ĐỘNG {title_suffix}</span>
            <span class="page-number">Trang {page_idx} / {len(deck_distribution)} (Khổ A4)</span>
        </div>
        <div class="cards-grid">
            {cards_in_page}
        </div>
        <div class="page-footer">
            <span>✂ Dùng kéo cắt theo viền nét đứt. Toàn bộ 100% là Thẻ Lệnh (Action Cards) để bé cầm trên tay điều khiển!</span>
        </div>
    </div>
    """

full_html = f"""<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <title>Bộ Thẻ Tập Lệnh Lập Trình Cho Bé (100% Thẻ Hành Động)</title>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Nunito:wght@400;600;700;900&display=swap');
        
        * {{
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }}
        
        @page {{
            size: A4 portrait;
            margin: 0;
        }}

        body {{
            background-color: #2C3E50;
            font-family: 'Nunito', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            color: #333;
            padding: 20px 0;
        }}

        .instructions-banner {{
            width: 210mm;
            margin: 0 auto 20px auto;
            background: #FFFFFF;
            padding: 24px;
            border-radius: 12px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.2);
            line-height: 1.6;
        }}
        
        .instructions-banner h1 {{
            color: #27AE60;
            font-size: 24px;
            margin-bottom: 8px;
        }}
        
        .instructions-banner p {{
            font-size: 14px;
            color: #555;
            margin-bottom: 6px;
        }}
        
        .btn-print {{
            display: inline-block;
            background: #27AE60;
            color: #FFF;
            padding: 10px 22px;
            font-weight: 700;
            border-radius: 8px;
            text-decoration: none;
            margin-top: 10px;
            cursor: pointer;
            border: none;
            font-size: 16px;
        }}
        .btn-print:hover {{
            background: #219150;
        }}

        /* A4 Page Formatting */
        .a4-page {{
            width: 210mm;
            height: 296mm;
            margin: 0 auto 20px auto;
            background: #FFFFFF;
            padding: 10mm 12mm;
            border-radius: 4px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.25);
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            page-break-after: always;
            break-after: page;
            overflow: hidden;
        }}

        .page-header {{
            display: flex;
            justify-content: space-between;
            font-size: 11px;
            font-weight: 700;
            color: #7F8C8D;
            border-bottom: 1.5px dashed #BDC3C7;
            padding-bottom: 4px;
            margin-bottom: 4mm;
        }}

        .cards-grid {{
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            grid-template-rows: repeat(3, 1fr);
            gap: 5mm;
            height: 255mm;
        }}

        .card-wrapper {{
            display: flex;
            align-items: center;
            justify-content: center;
            border: 1.5px dashed #BDC3C7;
            border-radius: 12px;
            padding: 2mm;
            background: #FAFAFA;
            overflow: hidden;
        }}
        
        .card-wrapper svg {{
            width: 100%;
            height: 100%;
            object-fit: contain;
        }}

        .page-footer {{
            text-align: center;
            font-size: 10px;
            color: #95A5A6;
            border-top: 1px solid #ECF0F1;
            padding-top: 4px;
        }}

        /* Print Settings */
        @media print {{
            html, body {{
                background: none !important;
                padding: 0 !important;
                margin: 0 !important;
            }}
            .instructions-banner {{
                display: none !important;
            }}
            .a4-page {{
                margin: 0 !important;
                border-radius: 0 !important;
                box-shadow: none !important;
                width: 210mm !important;
                height: 297mm !important;
                padding: 8mm 10mm !important;
                page-break-after: always !important;
                break-after: page !important;
            }}
        }}
    </style>
</head>
<body>

    <div class="instructions-banner">
        <h1>🌱 BỘ TẬP LỆNH LẬP TRÌNH SÀN GẠCH (100% THẺ HÀNH ĐỘNG CHO BÉ)</h1>
        <p><strong>Triết lý thiết kế:</strong> Tách bạch hoàn toàn giữa <strong>Tập lệnh trong tay bé (Code)</strong> và <strong>Thực tế sàn nhà (Vật dụng thật: gối ôm, đồ chơi, khăn tắm)</strong>.</p>
        <p>Toàn bộ 30 thẻ in ra đều là thẻ lệnh để bé cầm trên tay và xếp ra sàn, không lãng phí giấy in cho các chướng ngại vật giấy.</p>
        <button class="btn-print" onclick="window.print()">🖨️ In Bộ Thẻ (Ctrl + P)</button>
    </div>

    {pages_html}

</body>
</html>
"""

with open("kids_coding_cards/bo_the_in_an_a4.html", "w", encoding="utf-8") as f:
    f.write(full_html)

print("HTML re-generated with 100% action cards!")
