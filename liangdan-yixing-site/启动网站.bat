@echo off
chcp 65001 >nul
title 两弹一星精神宣传网
echo.
echo ============================================
echo   两弹一星精神宣传网 - 正在启动浏览器
echo   合肥工业大学 · 核炬薪传宣讲团
echo ============================================
echo.
cd /d "%~dp0pages"
if exist "index.html" (
    start "" "index.html"
) else (
    echo 找不到 pages\index.html，请确认解压完整。
    pause
)
