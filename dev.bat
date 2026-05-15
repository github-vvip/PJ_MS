@echo off
chcp 65001 >nul
echo ========================================
echo   开发模式启动脚本
echo   前端: http://localhost:3000 (Vite)
echo   后端: http://localhost:8000 (Django)
echo ========================================
echo.

echo [1/4] 安装后端依赖...
cd /d "%~dp0backend"
pip install -r requirements.txt -q

echo [2/4] 执行数据库迁移...
python manage.py makemigrations api
python manage.py migrate

echo [3/4] 安装前端依赖...
cd /d "%~dp0frontend"
call npm install

echo [4/4] 启动服务...
echo.
echo 正在启动 Django 后端 (8000端口)...
start "Django后端" cmd /k "cd /d "%~dp0backend" && python manage.py runserver 0.0.0.0:8000"

echo 正在启动 Vite 前端 (3000端口)...
start "Vite前端" cmd /k "cd /d "%~dp0frontend" && npm run dev"

echo.
echo ========================================
echo   开发环境已启动！
echo   前端: http://localhost:3000
echo   后端: http://localhost:8000
echo   Vite 已配置代理 /api 到 Django
echo ========================================
echo.
pause
