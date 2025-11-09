@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ============================================================
echo DeepSeek-OCR 便携环境初始化脚本
echo ============================================================
echo.

:: 检查 Python 是否已安装
python --version >nul 2>&1
if errorlevel 1 (
    echo [错误] 未找到 Python，请先安装 Python 3.12
    echo.
    echo 您可以从以下地址下载:
    echo https://www.python.org/downloads/
    echo.
    pause
    exit /b 1
)

echo [1/4] 检查 Python 版本...
for /f "tokens=2" %%i in ('python --version 2^>^&1') do set PYTHON_VERSION=%%i
echo       已安装 Python %PYTHON_VERSION%
echo.

:: 检查 env 目录
if exist ".\env\Scripts\python.exe" (
    echo [2/4] 检测到已存在的虚拟环境
    echo       跳过环境创建步骤
    echo.
) else (
    echo [2/4] 创建虚拟环境到 .\env ...
    python -m venv env
    if errorlevel 1 (
        echo [错误] 创建虚拟环境失败
        pause
        exit /b 1
    )
    echo       ✓ 虚拟环境创建成功
    echo.
)

:: 激活虚拟环境并安装依赖
echo [3/4] 安装 Python 依赖包...
echo       这可能需要几分钟时间，请耐心等待...
echo.

call .\env\Scripts\activate.bat

:: 升级 pip
python -m pip install --upgrade pip --quiet

:: 检查是否需要安装 PyTorch CUDA 版本
echo       安装 PyTorch (CUDA 12.8)...
pip install torch==2.9.0+cu128 torchvision==0.24.0+cu128 torchaudio==2.9.0+cu128 --index-url https://download.pytorch.org/whl/cu128 --quiet
if errorlevel 1 (
    echo       [警告] PyTorch CUDA 版本安装失败，尝试安装 CPU 版本...
    pip install torch torchvision torchaudio --quiet
)

:: 安装其他依赖
echo       安装其他依赖包...
pip install -r requirements.txt --quiet
if errorlevel 1 (
    echo [错误] 依赖安装失败
    pause
    exit /b 1
)

echo       ✓ 所有依赖安装成功
echo.

:: 下载模型
echo [4/4] 下载 DeepSeek-OCR 模型文件...
echo.

if not exist ".\models" (
    mkdir models
)

python download_models.py
if errorlevel 1 (
    echo.
    echo [警告] 模型下载未完全成功
    echo         您可以稍后重新运行: python download_models.py
    echo         或手动访问: https://www.modelscope.cn/models/deepseek-ai/DeepSeek-OCR/files
    echo.
) else (
    echo.
    echo ✓ 模型下载完成
    echo.
)

:: 完成
echo ============================================================
echo 初始化完成！
echo ============================================================
echo.
echo 使用说明:
echo   1. 运行 OCR: run_ocr.bat
echo   2. 或手动激活环境: .\env\Scripts\activate.bat
echo      然后运行: python run_ocr.py
echo.
echo 如需重新下载模型:
echo   .\env\Scripts\python.exe download_models.py
echo.

pause
