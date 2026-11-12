import subprocess
import os

def test():
    # Test Left Arrow
    icon_left = """
    <g transform="translate(175, 220)">
        <!-- Crisp Right-Angle Block Arrow Left -->
        <path d="M 18,75 L 18,-36 L -35,-36 L -35,-60 L -88,-18 L -35,24 L -35,0 L -18,0 L -18,75 Z" 
              fill="#3498DB" stroke="#1B4F72" stroke-width="7" stroke-linejoin="miter"/>
        <!-- 90 Degree Angle Marker -->
        <rect x="0" y="-36" width="18" height="18" fill="none" stroke="#F1C40F" stroke-width="4"/>
        <circle cx="9" cy="-27" r="3" fill="#F1C40F"/>
        <!-- Center Rotation Pivot on Floor Tile -->
        <circle cx="0" cy="75" r="14" fill="#2ECC71" stroke="#27AE60" stroke-width="4"/>
        <text x="0" y="80" font-family="'Nunito', Arial, sans-serif" font-size="12" font-weight="900" fill="#FFFFFF" text-anchor="middle">TÂM</text>
        <!-- Badge -->
        <rect x="-80" y="98" width="160" height="32" rx="16" fill="#2980B9"/>
        <text x="0" y="120" font-family="'Nunito', Arial, sans-serif" font-size="16" font-weight="900" fill="#FFFFFF" text-anchor="middle">BẺ VUÔNG 90° TRÁI</text>
    </g>
    """
    
    # Test Right Arrow
    icon_right = """
    <g transform="translate(175, 220)">
        <!-- Crisp Right-Angle Block Arrow Right -->
        <path d="M -18,75 L -18,-36 L 35,-36 L 35,-60 L 88,-18 L 35,24 L 35,0 L 18,0 L 18,75 Z" 
              fill="#3498DB" stroke="#1B4F72" stroke-width="7" stroke-linejoin="miter"/>
        <!-- 90 Degree Angle Marker -->
        <rect x="-18" y="-36" width="18" height="18" fill="none" stroke="#F1C40F" stroke-width="4"/>
        <circle cx="-9" cy="-27" r="3" fill="#F1C40F"/>
        <!-- Center Rotation Pivot on Floor Tile -->
        <circle cx="0" cy="75" r="14" fill="#2ECC71" stroke="#27AE60" stroke-width="4"/>
        <text x="0" y="80" font-family="'Nunito', Arial, sans-serif" font-size="12" font-weight="900" fill="#FFFFFF" text-anchor="middle">TÂM</text>
        <!-- Badge -->
        <rect x="-80" y="98" width="160" height="32" rx="16" fill="#2980B9"/>
        <text x="0" y="120" font-family="'Nunito', Arial, sans-serif" font-size="16" font-weight="900" fill="#FFFFFF" text-anchor="middle">BẺ VUÔNG 90° PHẢI</text>
    </g>
    """
    print("Testing arrow icons syntax...")

test()
