set DIR_DIR=%__CD__%

if "%1%"=="clean" goto clean

mkdir dist\bin
mkdir dist\properties

echo "build Luajit"
cd ..\src\luajit\src
call %DIR_DIR%luajit.bat
if ERRORLEVEL 1 exit /B 1
cd %DIR_DIR%
copy ..\src\luajit\src\*.exe dist\bin
copy ..\src\luajit\src\*.dll dist\bin

echo "build scintilla"
cd ..\src\scintilla\win32
nmake -f scintilla.mak
if ERRORLEVEL 1 exit /B 1
cd %DIR_DIR%

echo "build scite"
cd ..\src\scite\win32
nmake -f %DIR_DIR%scite.mak
if ERRORLEVEL 1 exit /B 1
cd %DIR_DIR%
copy ..\src\scite\bin\*.properties dist\properties
copy ..\src\scite\bin\*.exe dist\bin
copy ..\src\scite\bin\*.dll dist\bin

echo "Build SciteX"
cd ..\src\scitex
nmake -f scitex.mak
if ERRORLEVEL 1 exit /B 1
cd %DIR_DIR%
copy ..\src\scitex\*.dll dist\bin
exit /B 0

:clean
cd ..\src\scintilla\win32
nmake -f scintilla.mak clean
cd %DIR_DIR%

cd ..\src\scite\win32
nmake -f %DIR_DIR%scite.mak clean
cd %DIR_DIR%

cd ..\src\scitex
nmake -f scitex.mak clean
cd %DIR_DIR%
