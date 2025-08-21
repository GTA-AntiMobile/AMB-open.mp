@echo off
echo Installing YouTube to MP3 Converter...

echo.
echo [1/3] Installing Node.js dependencies...
npm install --package-lock-only=false express cors nodemon

echo.
echo [2/3] Installing yt-dlp...
echo Downloading yt-dlp.exe...
curl -L -o yt-dlp.exe https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe

echo.
echo [3/3] Creating directories...
mkdir mp3_files 2>nul

echo.
echo Testing installation...
echo Testing yt-dlp...
yt-dlp.exe --version

echo.
echo ✅ Installation complete!
echo.
echo To start the MP3 converter server:
echo   node youtube-to-mp3.js
echo.
echo Or in development mode:
echo   nodemon youtube-to-mp3.js
echo.
echo MP3 files will be saved in: mp3_files/
echo Server will run on: http://localhost:8081
echo.
pause


