@echo off
title Estudai - API FastAPI
color 0A

echo ========================================
echo       ESTUDAI - INICIANDO API
echo ========================================
echo.

:: Entra na pasta onde este BAT esta localizado
cd /d "%~dp0"

:: Verifica o ambiente virtual
if not exist ".venv\Scripts\python.exe" (
    echo ERRO: Ambiente virtual nao encontrado.
    echo Caminho esperado: %~dp0.venv\Scripts\python.exe
    pause
    exit /b 1
)

:: Verifica o arquivo de configuracao
if not exist ".env" (
    echo ERRO: Arquivo .env nao encontrado.
    pause
    exit /b 1
)

echo Python utilizado:
".venv\Scripts\python.exe" --version

echo.
echo Iniciando FastAPI...
echo API:  http://127.0.0.1:8000
echo Docs: http://127.0.0.1:8000/docs
echo.
echo Para encerrar, pressione CTRL+C.
echo ========================================
echo.

".venv\Scripts\python.exe" -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

echo.
echo Servidor encerrado.
pause
