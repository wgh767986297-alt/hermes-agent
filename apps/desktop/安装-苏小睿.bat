@echo off
chcp 65001 >nul
title 苏小睿 智能助手 - 安装程序
echo.
echo ========================================
echo   苏小睿 智能助手 - 安装程序
echo ========================================
echo.
powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0install.ps1"
echo.
echo 按任意键退出...
pause >nul
