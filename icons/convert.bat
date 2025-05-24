@echo off
REM This script converts an image (PNG, etc.) to an ICO file using ImageMagick.
REM Check if argument is provided
if "%~1"=="" (
    echo Usage: %~nx0 image.png
    exit /b 1
)

REM Get input PNG and output ICO filenames
set "input=%~1"
set "output=%~dpn1.ico"

REM Convert PNG to ICO using ImageMagick
REM Including multiple sizes is important for visual quality. Windows resizing isn't as pretty.
REM See https://usage.imagemagick.org/thumbnails/#favicon for more details.

magick "%input%" -define icon:auto-resize="128,96,64,48,32,16" "%output%"

REM Check if conversion was successful
if exist "%output%" (
    echo Successfully converted "%input%" to "%output%"
) else (
    echo Conversion failed.
    exit /b 1
)