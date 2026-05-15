@echo off
chcp 65001 >nul
echo ========================================
echo   项目配置管理系统 - 一键启动脚本
echo ========================================
echo.

:: 检查 Python
where python >nul 2>nul
if %errorlevel% neq 0 (
    echo [错误] 未找到 Python，请先安装 Python 3.10+
    pause
    exit /b 1
)

:: 检查 Node.js
where node >nul 2>nul
if %errorlevel% neq 0 (
    echo [错误] 未找到 Node.js，请先安装 Node.js 18+
    pause
    exit /b 1
)

echo [1/6] 安装后端依赖...
cd /d "%~dp0backend"
pip install -r requirements.txt -q

echo [2/6] 执行数据库迁移...
python manage.py makemigrations api
python manage.py migrate

echo [3/6] 收集静态文件...
python manage.py collectstatic --noinput

echo [4/6] 安装前端依赖...
cd /d "%~dp0frontend"
call npm install

echo [5/6] 打包前端...
call npm run build

echo [6/6] 启动 Django 服务...
cd /d "%~dp0backend"
echo.
echo ========================================
echo   服务已启动！
echo   本机访问: http://localhost:8000
echo   局域网访问: http://你的IP:8000
echo   注意: 局域网访问需关闭 Windows 防火墙
echo         或在防火墙中放行 8000 端口
echo ========================================
echo.
python manage.py runserver 0.0.0.0:8000
pause
