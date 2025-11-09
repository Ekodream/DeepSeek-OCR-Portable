@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ============================================================
echo DeepSeek-OCR Portable Environment Initializer
echo ============================================================
echo.

:: Check env directory
if exist ".\env\Scripts\python.exe" (
    echo [1/4] Existing virtual environment detected
    echo       Skipping environment creation
    echo.
    
    echo [2/4] Checking Python version...
    for /f "tokens=2" %%i in ('.\env\Scripts\python.exe --version 2^>^&1') do set PYTHON_VERSION=%%i
    echo       Python detected: %PYTHON_VERSION%
    echo.
) else (
    :: Check if system Python is installed for creating venv
    python --version >nul 2>&1
    if errorlevel 1 (
        echo [ERROR] Python not found. Please install Python 3.12 first.
        echo.
        echo You can download it from:
        echo https://www.python.org/downloads/
        echo.
        pause
        exit /b 1
    )
    
    echo [1/4] Checking Python version...
    for /f "tokens=2" %%i in ('python --version 2^>^&1') do set PYTHON_VERSION=%%i
    echo       Python detected: %PYTHON_VERSION%
    echo.
    
    echo [2/4] Creating virtual environment at .\env ...
    python -m venv env
    if errorlevel 1 (
        echo [ERROR] Failed to create virtual environment
        pause
        exit /b 1
    )
    echo       ✓ Virtual environment created
    echo.
)

:: Install dependencies using env Python
echo [3/4] Installing Python dependencies...
echo       This may take a few minutes, please wait...
echo.

:: Upgrade pip
echo       Upgrading pip...
.\env\Scripts\python.exe -m pip install --upgrade pip --quiet

:: Install PyTorch CUDA build (fallback to CPU if failed)
echo       Installing PyTorch (CUDA 12.8)...
.\env\Scripts\pip.exe install torch==2.9.0+cu128 torchvision==0.24.0+cu128 torchaudio==2.9.0+cu128 --index-url https://download.pytorch.org/whl/cu128 --quiet
if errorlevel 1 (
    echo       [WARN] CUDA build failed, trying CPU build...
    .\env\Scripts\pip.exe install torch torchvision torchaudio --quiet
)

:: Install other dependencies
echo       Installing other dependencies...
.\env\Scripts\pip.exe install -r requirements.txt --quiet
if errorlevel 1 (
    echo [ERROR] Dependency installation failed
    pause
    exit /b 1
)

echo       ✓ All dependencies installed
echo.

:: Download models
echo [4/4] Downloading DeepSeek-OCR model files...
echo.

if not exist ".\models" (
    mkdir models
)

.\env\Scripts\python.exe download_models.py
if errorlevel 1 (
    echo.
    echo [WARN] Model download not fully completed
    echo        You can rerun later: .\env\Scripts\python.exe download_models.py
    echo        Or manually download from: https://www.modelscope.cn/models/deepseek-ai/DeepSeek-OCR/files
    echo.
) else (
    echo.
    echo ✓ Model download completed
    echo.
)

:: Done
echo ============================================================
echo Initialization complete!
echo ============================================================
echo.
echo Usage:
echo   1. Run OCR: run_ocr.bat
echo   2. Or run directly: .\env\Scripts\python.exe run_ocr.py
echo.
echo To re-download models:
echo   .\env\Scripts\python.exe download_models.py
echo.

pause
