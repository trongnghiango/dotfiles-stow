import os
import subprocess

cards = [
    # 1. Nhóm Di chuyển (Xanh lá - Green)
    {
        "id": "01_buoc_toi_1_buoc",
        "title": "BƯỚC TỚI 1 BƯỚC",
        "subtitle": "Đi thẳng 1 ô gạch",
        "category": "DI CHUYỂN",
        "theme": {"bg": "#E8F8F5", "border": "#27AE60", "badge": "#2ECC71", "text": "#196F3D"},
        "icon": """
            <g transform="translate(175, 230)">
                <!-- Big Arrow Up -->
                <path d="M 0,-85 L 50,-20 L 22,-20 L 22,60 L -22,60 L -22,-20 L -50,-20 Z" fill="#2ECC71" stroke="#27AE60" stroke-width="6" stroke-linejoin="round"/>
                <!-- Footprint icon -->
                <circle cx="0" cy="95" r="14" fill="#27AE60"/>
                <ellipse cx="-12" cy="72" rx="4" ry="6" fill="#27AE60"/>
                <ellipse cx="-4" cy="68" rx="4" ry="6" fill="#27AE60"/>
                <ellipse cx="4" cy="68" rx="4" ry="6" fill="#27AE60"/>
                <ellipse cx="12" cy="72" rx="4" ry="6" fill="#27AE60"/>
                <!-- Number Badge -->
                <circle cx="50" cy="50" r="24" fill="#F1C40F" stroke="#D68910" stroke-width="4"/>
                <text x="50" y="58" font-family="'Nunito', 'Segoe UI', Arial, sans-serif" font-size="26" font-weight="900" fill="#7D6608" text-anchor="middle">1</text>
            </g>
        """
    },
    {
        "id": "02_buoc_toi_2_buoc",
        "title": "BƯỚC TỚI 2 BƯỚC",
        "subtitle": "Đi thẳng 2 ô gạch liên tiếp",
        "category": "DI CHUYỂN",
        "theme": {"bg": "#E8F8F5", "border": "#27AE60", "badge": "#2ECC71", "text": "#196F3D"},
        "icon": """
            <g transform="translate(175, 230)">
                <!-- Double Arrow Up -->
                <path d="M 0,-100 L 45,-45 L 20,-45 L 20,40 L -20,40 L -20,-45 L -45,-45 Z" fill="#2ECC71" stroke="#27AE60" stroke-width="6" stroke-linejoin="round"/>
                <path d="M 0,-60 L 35,-15 L 15,-15 L 15,20 L -15,20 L -15,-15 L -35,-15 Z" fill="#A9DFBF" opacity="0.6"/>
                <!-- 2 Footprints -->
                <g transform="translate(-25, 80) scale(0.8)">
                    <circle cx="0" cy="15" r="12" fill="#27AE60"/>
                    <circle cx="-10" cy="-2" r="3.5" fill="#27AE60"/>
                    <circle cx="-3" cy="-6" r="3.5" fill="#27AE60"/>
                    <circle cx="4" cy="-6" r="3.5" fill="#27AE60"/>
                    <circle cx="11" cy="-2" r="3.5" fill="#27AE60"/>
                </g>
                <g transform="translate(20, 55) scale(0.8)">
                    <circle cx="0" cy="15" r="12" fill="#27AE60"/>
                    <circle cx="-10" cy="-2" r="3.5" fill="#27AE60"/>
                    <circle cx="-3" cy="-6" r="3.5" fill="#27AE60"/>
                    <circle cx="4" cy="-6" r="3.5" fill="#27AE60"/>
                    <circle cx="11" cy="-2" r="3.5" fill="#27AE60"/>
                </g>
                <!-- Number Badge -->
                <circle cx="55" cy="50" r="24" fill="#F1C40F" stroke="#D68910" stroke-width="4"/>
                <text x="55" y="58" font-family="'Nunito', 'Segoe UI', Arial, sans-serif" font-size="26" font-weight="900" fill="#7D6608" text-anchor="middle">2</text>
            </g>
        """
    },
    {
        "id": "03_buoc_toi_3_buoc",
        "title": "BƯỚC TỚI 3 BƯỚC",
        "subtitle": "Đi thẳng 3 ô gạch thật nhanh",
        "category": "DI CHUYỂN",
        "theme": {"bg": "#E8F8F5", "border": "#27AE60", "badge": "#2ECC71", "text": "#196F3D"},
        "icon": """
            <g transform="translate(175, 230)">
                <path d="M 0,-105 L 50,-40 L 22,-40 L 22,35 L -22,35 L -22,-40 L -50,-40 Z" fill="#2ECC71" stroke="#27AE60" stroke-width="6" stroke-linejoin="round"/>
                <!-- 3 step marks -->
                <rect x="-35" y="55" width="20" height="12" rx="6" fill="#27AE60"/>
                <rect x="-10" y="70" width="20" height="12" rx="6" fill="#27AE60"/>
                <rect x="15" y="85" width="20" height="12" rx="6" fill="#27AE60"/>
                <!-- Number Badge -->
                <circle cx="55" cy="40" r="24" fill="#F1C40F" stroke="#D68910" stroke-width="4"/>
                <text x="55" y="48" font-family="'Nunito', 'Segoe UI', Arial, sans-serif" font-size="26" font-weight="900" fill="#7D6608" text-anchor="middle">3</text>
            </g>
        """
    },
    {
        "id": "04_lui_lai_1_buoc",
        "title": "LÙI LẠI 1 BƯỚC",
        "subtitle": "Đi lùi về sau 1 ô gạch",
        "category": "DI CHUYỂN",
        "theme": {"bg": "#E8F8F5", "border": "#27AE60", "badge": "#2ECC71", "text": "#196F3D"},
        "icon": """
            <g transform="translate(175, 230)">
                <!-- Arrow Down -->
                <path d="M 0,85 L 50,20 L 22,20 L 22,-60 L -22,-60 L -22,20 L -50,20 Z" fill="#58D68D" stroke="#27AE60" stroke-width="6" stroke-linejoin="round"/>
                <!-- Backward footprint icon -->
                <g transform="translate(0, -90) rotate(180)">
                    <circle cx="0" cy="10" r="13" fill="#27AE60"/>
                    <ellipse cx="-10" cy="-6" rx="3.5" ry="5.5" fill="#27AE60"/>
                    <ellipse cx="-3.5" cy="-9" rx="3.5" ry="5.5" fill="#27AE60"/>
                    <ellipse cx="3.5" cy="-9" rx="3.5" ry="5.5" fill="#27AE60"/>
                    <ellipse cx="10" cy="-6" rx="3.5" ry="5.5" fill="#27AE60"/>
                </g>
                <!-- Number Badge -->
                <circle cx="50" cy="-40" r="22" fill="#F1C40F" stroke="#D68910" stroke-width="4"/>
                <text x="50" y="-32" font-family="'Nunito', 'Segoe UI', Arial, sans-serif" font-size="24" font-weight="900" fill="#7D6608" text-anchor="middle">1</text>
            </g>
        """
    },
    {
        "id": "05_nhay_qua_1_o",
        "title": "NHẢY QUA 1 Ô!",
        "subtitle": "Bật nhảy qua chướng ngại vật",
        "category": "HÀNH ĐỘNG VẬN ĐỘNG",
        "theme": {"bg": "#E8F8F5", "border": "#27AE60", "badge": "#1ABC9C", "text": "#148F77"},
        "icon": """
            <g transform="translate(175, 230)">
                <!-- Arc jump arrow -->
                <path d="M -75,45 Q 0,-110 75,45" fill="none" stroke="#16A085" stroke-width="8" stroke-dasharray="8 6"/>
                <polygon points="75,45 85,20 60,30" fill="#16A085"/>
                <!-- Spring / Kangaroo boots -->
                <ellipse cx="0" cy="10" rx="30" ry="12" fill="#F39C12"/>
                <path d="M -20,22 Q 0,35 20,22 Q 0,45 -20,55 Q 0,65 20,75" fill="none" stroke="#E67E22" stroke-width="7" stroke-linecap="round"/>
                <circle cx="-75" cy="55" r="10" fill="#BDC3C7"/>
                <circle cx="75" cy="55" r="10" fill="#2ECC71"/>
            </g>
        """
    },

    # 2. Nhóm Xoay Hướng (Xanh dương - Blue) - MŨI TÊN BẺ VUÔNG GÓC 90° CHUẨN Ô GẠCH!
    {
        "id": "06_quay_trai_90",
        "title": "QUAY SANG TRÁI 90°",
        "subtitle": "Đứng yên trên ô &amp; bẻ góc vuông sang trái",
        "category": "XOAY HƯỚNG VUÔNG GÓC",
        "theme": {"bg": "#EBF5FB", "border": "#1F618D", "badge": "#2980B9", "text": "#154360"},
        "icon": """
            <g transform="translate(175, 215)">
                <!-- Grid Tile Floor Reference (Square tile) -->
                <rect x="-65" y="30" width="130" height="45" rx="8" fill="#D4E6F1" stroke="#A9CCE3" stroke-width="3" stroke-dasharray="6 4"/>
                
                <!-- Center Pivot Point (Vị trí bé đứng chân) -->
                <circle cx="0" cy="52" r="16" fill="#E74C3C" stroke="#C0392B" stroke-width="4"/>
                <circle cx="0" cy="52" r="5" fill="#FFFFFF"/>
                <text x="0" y="86" font-family="'Nunito', Arial, sans-serif" font-size="12" font-weight="900" fill="#2C3E50" text-anchor="middle">ĐỨNG YÊN CHÂN</text>

                <!-- DỨT KHOÁT: MŨI TÊN KHỐI BẺ GÓC VUÔNG 90° SANG TRÁI -->
                <path d="M 18,45 L 18,-38 L -32,-38 L -32,-65 L -92,-19 L -32,27 L -32,0 L -18,0 L -18,45 Z" 
                      fill="#3498DB" stroke="#1B4F72" stroke-width="7" stroke-linejoin="miter"/>
                
                <!-- Ký hiệu góc vuông 90 độ (Right angle symbol) -->
                <rect x="0" y="-38" width="18" height="18" fill="none" stroke="#F1C40F" stroke-width="4"/>
                <circle cx="9" cy="-29" r="3" fill="#F1C40F"/>
                
                <!-- Badge Góc 90 Độ -->
                <rect x="-65" y="102" width="130" height="30" rx="15" fill="#2980B9"/>
                <text x="0" y="123" font-family="'Nunito', Arial, sans-serif" font-size="16" font-weight="900" fill="#FFFFFF" text-anchor="middle">BẺ VUÔNG 90°</text>
            </g>
        """
    },
    {
        "id": "07_quay_phai_90",
        "title": "QUAY SANG PHẢI 90°",
        "subtitle": "Đứng yên trên ô &amp; bẻ góc vuông sang phải",
        "category": "XOAY HƯỚNG VUÔNG GÓC",
        "theme": {"bg": "#EBF5FB", "border": "#1F618D", "badge": "#2980B9", "text": "#154360"},
        "icon": """
            <g transform="translate(175, 215)">
                <!-- Grid Tile Floor Reference (Square tile) -->
                <rect x="-65" y="30" width="130" height="45" rx="8" fill="#D4E6F1" stroke="#A9CCE3" stroke-width="3" stroke-dasharray="6 4"/>
                
                <!-- Center Pivot Point (Vị trí bé đứng chân) -->
                <circle cx="0" cy="52" r="16" fill="#E74C3C" stroke="#C0392B" stroke-width="4"/>
                <circle cx="0" cy="52" r="5" fill="#FFFFFF"/>
                <text x="0" y="86" font-family="'Nunito', Arial, sans-serif" font-size="12" font-weight="900" fill="#2C3E50" text-anchor="middle">ĐỨNG YÊN CHÂN</text>

                <!-- DỨT KHOÁT: MŨI TÊN KHỐI BẺ GÓC VUÔNG 90° SANG PHẢI -->
                <path d="M -18,45 L -18,-38 L 32,-38 L 32,-65 L 92,-19 L 32,27 L 32,0 L 18,0 L 18,45 Z" 
                      fill="#3498DB" stroke="#1B4F72" stroke-width="7" stroke-linejoin="miter"/>
                
                <!-- Ký hiệu góc vuông 90 độ (Right angle symbol) -->
                <rect x="-18" y="-38" width="18" height="18" fill="none" stroke="#F1C40F" stroke-width="4"/>
                <circle cx="-9" cy="-29" r="3" fill="#F1C40F"/>
                
                <!-- Badge Góc 90 Độ -->
                <rect x="-65" y="102" width="130" height="30" rx="15" fill="#2980B9"/>
                <text x="0" y="123" font-family="'Nunito', Arial, sans-serif" font-size="16" font-weight="900" fill="#FFFFFF" text-anchor="middle">BẺ VUÔNG 90°</text>
            </g>
        """
    },
    {
        "id": "08_quay_dang_sau",
        "title": "QUAY ĐẰNG SAU 180°",
        "subtitle": "Bẻ góc vuông 2 lần để quay ngược lại",
        "category": "XOAY HƯỚNG VUÔNG GÓC",
        "theme": {"bg": "#EBF5FB", "border": "#1F618D", "badge": "#2980B9", "text": "#154360"},
        "icon": """
            <g transform="translate(175, 215)">
                <!-- DỨT KHOÁT: MŨI TÊN CHỮ U VUÔNG VỨC 180 ĐỘ -->
                <path d="M 46,55 L 46,-42 L -46,-42 L -46,15 L -72,15 L -30,68 L 12,15 L -16,15 L -16,-12 L 16,-12 L 16,55 Z" 
                      fill="#3498DB" stroke="#1B4F72" stroke-width="7" stroke-linejoin="miter"/>
                
                <!-- 2 Ký hiệu góc vuông ở 2 đỉnh -->
                <rect x="16" y="-42" width="16" height="16" fill="none" stroke="#F1C40F" stroke-width="3"/>
                <rect x="-32" y="-42" width="16" height="16" fill="none" stroke="#F1C40F" stroke-width="3"/>

                <!-- Badge 180 -->
                <circle cx="0" cy="15" r="28" fill="#F39C12" stroke="#B9770E" stroke-width="4"/>
                <text x="0" y="23" font-family="'Nunito', Arial, sans-serif" font-size="19" font-weight="900" fill="#FFFFFF" text-anchor="middle">180°</text>

                <!-- Badge Text -->
                <rect x="-65" y="102" width="130" height="30" rx="15" fill="#2980B9"/>
                <text x="0" y="123" font-family="'Nunito', Arial, sans-serif" font-size="15" font-weight="900" fill="#FFFFFF" text-anchor="middle">XOAY NGƯỢC LẠI</text>
            </g>
        """
    },

    # 3. Nhóm Hành động (Vàng cam - Orange/Yellow)
    {
        "id": "09_cui_xuong_bat_lay",
        "title": "CÚI XUỐNG &amp; BẮT LẤY",
        "subtitle": "Gắp đồ vật/kho báu trên ô gạch",
        "category": "HÀNH ĐỘNG TƯƠNG TÁC",
        "theme": {"bg": "#FEF9E7", "border": "#D68910", "badge": "#F39C12", "text": "#7E5109"},
        "icon": """
            <g transform="translate(175, 225)">
                <!-- Robot Claw Grabber -->
                <path d="M -30,-80 L 30,-80 L 15,-20 L -15,-20 Z" fill="#BDC3C7" stroke="#7F8C8D" stroke-width="4"/>
                <!-- Left Arm -->
                <path d="M -15,-20 Q -55,10 -35,45 Q -25,25 -5,10" fill="#F39C12" stroke="#B9770E" stroke-width="4"/>
                <!-- Right Arm -->
                <path d="M 15,-20 Q 55,10 35,45 Q 25,25 5,10" fill="#F39C12" stroke="#B9770E" stroke-width="4"/>
                <!-- Star inside claw -->
                <polygon points="0,20 8,38 28,38 12,50 18,70 0,58 -18,70 -12,50 -28,38 -8,38" fill="#F1C40F" stroke="#D68910" stroke-width="3"/>
                <!-- Down Motion arrows -->
                <path d="M -60,-30 L -60,0" stroke="#E67E22" stroke-width="5" stroke-linecap="round"/>
                <polyline points="-68,-10 -60,0 -52,-10" fill="none" stroke="#E67E22" stroke-width="5" stroke-linecap="round"/>
                <path d="M 60,-30 L 60,0" stroke="#E67E22" stroke-width="5" stroke-linecap="round"/>
                <polyline points="52,-10 60,0 68,-10" fill="none" stroke="#E67E22" stroke-width="5" stroke-linecap="round"/>
            </g>
        """
    },
    {
        "id": "10_dat_do_xuong",
        "title": "ĐẶT ĐỒ XUỐNG",
        "subtitle": "Thả vật phẩm vào ô gạch",
        "category": "HÀNH ĐỘNG TƯƠNG TÁC",
        "theme": {"bg": "#FEF9E7", "border": "#D68910", "badge": "#F39C12", "text": "#7E5109"},
        "icon": """
            <g transform="translate(175, 225)">
                <!-- Open hands / Platform -->
                <rect x="-40" y="45" width="80" height="12" rx="6" fill="#7F8C8D"/>
                <!-- Item: Gift Box -->
                <rect x="-30" y="-15" width="60" height="50" rx="8" fill="#E74C3C" stroke="#C0392B" stroke-width="4"/>
                <!-- Ribbon -->
                <rect x="-8" y="-15" width="16" height="50" fill="#F1C40F"/>
                <rect x="-30" y="8" width="60" height="12" fill="#F1C40F"/>
                <!-- Downward Arrow -->
                <path d="M 0,-70 L 0,-30" stroke="#27AE60" stroke-width="8" stroke-linecap="round"/>
                <polygon points="0,-20 -15,-40 15,-40" fill="#27AE60"/>
            </g>
        """
    },
    {
        "id": "11_bip_bip_chao_ban",
        "title": "BÍP BÍP! CHÀO BẠN",
        "subtitle": "Phát ra tiếng kêu vui nhộn",
        "category": "ÂM THANH ROBOT",
        "theme": {"bg": "#FEF9E7", "border": "#D68910", "badge": "#F39C12", "text": "#7E5109"},
        "icon": """
            <g transform="translate(175, 225)">
                <!-- Megaphone / Speaker -->
                <path d="M -40,-20 L -15,-20 L 25,-55 L 25,55 L -15,20 L -40,20 Z" fill="#3498DB" stroke="#2471A3" stroke-width="5" stroke-linejoin="round"/>
                <rect x="-55" y="-15" width="15" height="30" rx="4" fill="#BDC3C7"/>
                <!-- Sound waves -->
                <path d="M 40,-30 Q 60,0 40,30" fill="none" stroke="#E67E22" stroke-width="6" stroke-linecap="round"/>
                <path d="M 55,-48 Q 85,0 55,48" fill="none" stroke="#F39C12" stroke-width="7" stroke-linecap="round"/>
                <!-- Text Bubble "BÍP BÍP!" -->
                <rect x="-60" y="70" width="120" height="32" rx="16" fill="#F39C12"/>
                <text x="0" y="92" font-family="'Nunito', 'Segoe UI', Arial, sans-serif" font-size="18" font-weight="900" fill="#FFFFFF" text-anchor="middle">BÍP BÍP ~♪</text>
            </g>
        """
    },
    {
        "id": "12_quan_sat_kiem_tra",
        "title": "QUAN SÁT PHÍA TRƯỚC",
        "subtitle": "Kiểm tra xem có vật cản không",
        "category": "CẢM BIẾN RADAR",
        "theme": {"bg": "#FEF9E7", "border": "#D68910", "badge": "#E67E22", "text": "#7E5109"},
        "icon": """
            <g transform="translate(175, 225)">
                <!-- Magnifying glass / Radar eye -->
                <circle cx="-10" cy="-15" r="45" fill="#E8F8F5" stroke="#16A085" stroke-width="8"/>
                <!-- Eye inside -->
                <ellipse cx="-10" cy="-15" rx="25" ry="16" fill="#FFFFFF" stroke="#2C3E50" stroke-width="4"/>
                <circle cx="-10" cy="-15" r="10" fill="#2980B9"/>
                <circle cx="-14" cy="-18" r="4" fill="#FFFFFF"/>
                <!-- Handle -->
                <line x1="22" y1="18" x2="60" y2="56" stroke="#D35400" stroke-width="14" stroke-linecap="round"/>
                <!-- Beams -->
                <line x1="-55" y1="-50" x2="-75" y2="-70" stroke="#F1C40F" stroke-width="5" stroke-linecap="round"/>
                <line x1="-10" y1="-70" x2="-10" y2="-90" stroke="#F1C40F" stroke-width="5" stroke-linecap="round"/>
                <line x1="35" y1="-50" x2="55" y2="-70" stroke="#F1C40F" stroke-width="5" stroke-linecap="round"/>
            </g>
        """
    },

    # 4. Nhóm Điều khiển & Vòng lặp (Tím - Purple)
    {
        "id": "13_bat_dau_start",
        "title": "BẮT ĐẦU (START)",
        "subtitle": "Bật công tắc, khởi động!",
        "category": "ĐIỀU KHIỂN CHƯƠNG TRÌNH",
        "theme": {"bg": "#F4ECF7", "border": "#8E44AD", "badge": "#27AE60", "text": "#512E5F"},
        "icon": """
            <g transform="translate(175, 225)">
                <!-- Green Play Button Circle -->
                <circle cx="0" cy="0" r="65" fill="#2ECC71" stroke="#27AE60" stroke-width="8"/>
                <polygon points="-18,-35 38,0 -18,35" fill="#FFFFFF"/>
                <!-- Little stars -->
                <circle cx="-55" cy="-55" r="8" fill="#F1C40F"/>
                <circle cx="55" cy="-55" r="6" fill="#F1C40F"/>
                <circle cx="60" cy="50" r="10" fill="#F1C40F"/>
                <!-- Text -->
                <rect x="-65" y="80" width="130" height="30" rx="15" fill="#27AE60"/>
                <text x="0" y="101" font-family="'Nunito', 'Segoe UI', Arial, sans-serif" font-size="16" font-weight="900" fill="#FFFFFF" text-anchor="middle">KHỞI ĐỘNG</text>
            </g>
        """
    },
    {
        "id": "14_ve_dich_finish",
        "title": "VỀ ĐÍCH (FINISH)",
        "subtitle": "Hoàn thành nhiệm vụ xuất sắc",
        "category": "ĐIỀU KHIỂN CHƯƠNG TRÌNH",
        "theme": {"bg": "#F4ECF7", "border": "#8E44AD", "badge": "#E74C3C", "text": "#512E5F"},
        "icon": """
            <g transform="translate(175, 225)">
                <!-- Trophy & Checkered Flags -->
                <path d="M -30,-40 L 30,-40 L 25,10 Q 0,40 -25,10 Z" fill="#F1C40F" stroke="#D68910" stroke-width="5"/>
                <rect x="-8" y="25" width="16" height="30" fill="#D68910"/>
                <rect x="-30" y="55" width="60" height="15" rx="4" fill="#B9770E"/>
                <!-- Handles -->
                <path d="M -28,-25 Q -55,-15 -25,5" fill="none" stroke="#D68910" stroke-width="6"/>
                <path d="M 28,-25 Q 55,-15 25,5" fill="none" stroke="#D68910" stroke-width="6"/>
                <!-- Big Winner Star -->
                <polygon points="0,-15 5,-3 18,-3 8,6 12,18 0,11 -12,18 -8,6 -18,-3 -5,-3" fill="#FFFFFF"/>
                <!-- Checkered Flag top -->
                <g transform="translate(40, -60) scale(0.7)">
                    <rect x="0" y="0" width="15" height="15" fill="#000000"/>
                    <rect x="15" y="0" width="15" height="15" fill="#FFFFFF"/>
                    <rect x="0" y="15" width="15" height="15" fill="#FFFFFF"/>
                    <rect x="15" y="15" width="15" height="15" fill="#000000"/>
                    <line x1="0" y1="0" x2="0" y2="60" stroke="#7F8C8D" stroke-width="4"/>
                </g>
            </g>
        """
    },
    {
        "id": "15_lap_lai_2_lan",
        "title": "LẶP LẠI 2 LẦN",
        "subtitle": "Làm lại thẻ trước đó 2 lần",
        "category": "VÒNG LẶP (LOOP)",
        "theme": {"bg": "#F4ECF7", "border": "#8E44AD", "badge": "#9B59B6", "text": "#512E5F"},
        "icon": """
            <g transform="translate(175, 225)">
                <!-- Circular Loop Arrow -->
                <path d="M 0,-65 A 65 65 0 1 1 -50,40" fill="none" stroke="#9B59B6" stroke-width="12" stroke-linecap="round"/>
                <polygon points="-50,40 -70,25 -40,15" fill="#8E44AD" transform="rotate(-30 -50 40)"/>
                <!-- Multiplier Center -->
                <circle cx="0" cy="0" r="38" fill="#F1C40F" stroke="#D68910" stroke-width="5"/>
                <text x="0" y="14" font-family="'Nunito', 'Segoe UI', Arial, sans-serif" font-size="40" font-weight="900" fill="#7D6608" text-anchor="middle">x2</text>
                <!-- Hint cards below -->
                <rect x="-55" y="80" width="110" height="26" rx="13" fill="#8E44AD"/>
                <text x="0" y="98" font-family="'Nunito', 'Segoe UI', Arial, sans-serif" font-size="14" font-weight="900" fill="#FFFFFF" text-anchor="middle">LẶP 2 LẦN</text>
            </g>
        """
    },
    {
        "id": "16_lap_lai_3_lan",
        "title": "LẶP LẠI 3 LẦN",
        "subtitle": "Làm lại thẻ trước đó 3 lần",
        "category": "VÒNG LẶP (LOOP)",
        "theme": {"bg": "#F4ECF7", "border": "#8E44AD", "badge": "#9B59B6", "text": "#512E5F"},
        "icon": """
            <g transform="translate(175, 225)">
                <!-- Circular Loop Arrow -->
                <path d="M 0,-65 A 65 65 0 1 1 -50,40" fill="none" stroke="#9B59B6" stroke-width="12" stroke-linecap="round"/>
                <polygon points="-50,40 -70,25 -40,15" fill="#8E44AD" transform="rotate(-30 -50 40)"/>
                <!-- Multiplier Center -->
                <circle cx="0" cy="0" r="38" fill="#E67E22" stroke="#B9770E" stroke-width="5"/>
                <text x="0" y="14" font-family="'Nunito', 'Segoe UI', Arial, sans-serif" font-size="40" font-weight="900" fill="#FFFFFF" text-anchor="middle">x3</text>
                <!-- Hint cards below -->
                <rect x="-55" y="80" width="110" height="26" rx="13" fill="#8E44AD"/>
                <text x="0" y="98" font-family="'Nunito', 'Segoe UI', Arial, sans-serif" font-size="14" font-weight="900" fill="#FFFFFF" text-anchor="middle">LẶP 3 LẦN</text>
            </g>
        """
    }
]

def make_svg(c):
    bg = c["theme"]["bg"]
    border = c["theme"]["border"]
    badge = c["theme"]["badge"]
    text_color = c["theme"]["text"]
    
    return f"""<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 350 500" width="350" height="500">
    <defs>
        <filter id="shadow" x="-5%" y="-5%" width="110%" height="110%">
            <feDropShadow dx="0" dy="4" stdDeviation="6" flood-opacity="0.12"/>
        </filter>
    </defs>
    
    <!-- Outer Card Background with Rounded Corner -->
    <rect x="15" y="15" width="320" height="470" rx="28" fill="{bg}" stroke="{border}" stroke-width="7" filter="url(#shadow)"/>
    
    <!-- Inner dashed border (guide for child / friendly look) -->
    <rect x="25" y="25" width="300" height="450" rx="20" fill="none" stroke="{border}" stroke-width="2.5" stroke-dasharray="6 6" opacity="0.6"/>

    <!-- Top Category Badge -->
    <g transform="translate(175, 52)">
        <rect x="-95" y="-14" width="190" height="28" rx="14" fill="{badge}"/>
        <text x="0" y="5" font-family="'Nunito', 'Segoe UI', Arial, sans-serif" font-size="11.5" font-weight="900" fill="#FFFFFF" text-anchor="middle" letter-spacing="0.5">{c["category"]}</text>
    </g>

    <!-- Main Title -->
    <text x="175" y="105" font-family="'Nunito', 'Segoe UI', Arial, sans-serif" font-size="20" font-weight="900" fill="{text_color}" text-anchor="middle">{c["title"]}</text>

    <!-- Subtitle (Small helper for parents) -->
    <text x="175" y="128" font-family="'Nunito', 'Segoe UI', Arial, sans-serif" font-size="12.5" font-weight="600" fill="#7F8C8D" text-anchor="middle">{c["subtitle"]}</text>

    <!-- Center Illustration Area -->
    <g id="illustration">
        {c["icon"]}
    </g>

    <!-- Bottom Decorative Floor Tile Grid Hint -->
    <g transform="translate(175, 435)">
        <rect x="-50" y="-12" width="100" height="24" rx="12" fill="#FFFFFF" stroke="{border}" stroke-width="2" opacity="0.8"/>
        <!-- 3 small floor tile squares -->
        <rect x="-35" y="-7" width="14" height="14" rx="2" fill="{badge}" opacity="0.4"/>
        <rect x="-7" y="-7" width="14" height="14" rx="2" fill="{badge}"/>
        <rect x="21" y="-7" width="14" height="14" rx="2" fill="{badge}" opacity="0.4"/>
    </g>
    
    <!-- Little footprint footer -->
    <text x="175" y="470" font-family="'Nunito', 'Segoe UI', Arial, sans-serif" font-size="11" font-weight="700" fill="#95A5A6" text-anchor="middle" letter-spacing="1">KHU VƯỜN LẬP TRÌNH TÍ HON</text>
</svg>
"""

os.makedirs("kids_coding_cards/svgs", exist_ok=True)
os.makedirs("kids_coding_cards/pngs", exist_ok=True)

print(f"Generating {len(cards)} SVG & PNG cards with crisp orthogonal arrows...")

for c in cards:
    svg_path = f"kids_coding_cards/svgs/{c['id']}.svg"
    png_path = f"kids_coding_cards/pngs/{c['id']}.png"
    
    svg_code = make_svg(c)
    with open(svg_path, "w", encoding="utf-8") as f:
        f.write(svg_code)
    
    # Convert to PNG using rsvg-convert (high quality 700x1000)
    subprocess.run(["rsvg-convert", "-w", "700", "-h", "1000", svg_path, "-o", png_path], check=True)
    print(f" -> Generated: {c['id']}.png")

print("Regenerated all cards with sharp right-angled arrows!")
