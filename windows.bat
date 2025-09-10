@echo off

title JDK 21, Maven & Git Installation Checker

color 0A

cls

:: Function to check admin rights

:checkAdmin

net session >nul 2>&1

if %errorlevel% neq 0 (

    echo.

    echo **********************************************

    echo * WARNING: Not running as administrator!     *

    echo * Some operations may fail.                  *

    echo * Right-click and "Run as administrator"     *

    echo * for complete installation.                *

    echo **********************************************

    echo.

    timeout /t 3 >nul

)

:: Initialize variables

set "dev_paths="

set "current_dir=%CD%"

set "stellar_project_dir=%current_dir%\stellar-sample-project"

set "git_path_added=0"

:: Check Java Installation

call :checkJava

if %java_installed% equ 1 (

    call :showJavaInfo

) else (

    call :installJava

)

:: Check Maven Installation

call :checkMaven

if %maven_installed% equ 1 (

    call :showMavenInfo

) else (

    call :installMaven

)

:: Check Git Installation

call :checkGit

if %git_installed% equ 1 (

    call :showGitInfo

) else (

    call :installGit

)

:: Update PATH with all dev paths

if defined dev_paths (

    echo.

    echo Updating PATH environment variable...

    echo Adding to PATH: %dev_paths%

    setx PATH "%PATH%%dev_paths%" /m >nul 2>&1

)

:: Clone Stellar project

call :cloneStellarProject

echo.

echo Installation summary:

echo - JDK Status:

where java >nul 2>&1 && echo JDK is working properly || echo JDK not working properly

echo.

echo - Maven Status:

where mvn >nul 2>&1 && echo Maven is working properly || echo Maven not working properly

echo.

echo - Git Status:

where git >nul 2>&1 && echo Git is working properly || echo Git not working properly

echo.

echo Environment variables set:

if defined dev_paths echo Added to PATH: %dev_paths%

echo.

echo Project Information:

echo Stellar project cloned to: %stellar_project_dir%

echo.

:: Show next steps

echo Next steps:

echo 1. Close and reopen Command Prompt for PATH changes to take effect

echo 2. cd stellar-sample-project

echo 3. mvn clean test

echo.

pause

exit /b

:checkJava

set "java_installed=0"

where java >nul 2>&1 && set "java_installed=1"

goto :eof

:showJavaInfo

echo.

echo **************************************

echo *       JDK ALREADY INSTALLED       *

echo **************************************

echo.

java -version

for /f "delims=" %%j in ('where java') do (

    echo.

    echo Java Path: %%~dpj

)

if not defined JAVA_HOME (

    for /f "tokens=*" %%a in ('dir /b /ad "C:\Program Files\Java\jdk-*" 2^>nul') do (

        set "dev_paths=%dev_paths%;C:\Program Files\Java\%%a\bin"

    )

)

goto :eof

:installJava

echo.

echo **************************************

echo *    INSTALLING JDK 21              *

echo **************************************

echo.

:: Download JDK 21

echo Downloading JDK 21 installer...

powershell -Command "(New-Object Net.WebClient).DownloadFile('https://download.oracle.com/java/21/latest/jdk-21_windows-x64_bin.exe', 'jdk-21-installer.exe')"

if not exist "jdk-21-installer.exe" (

    echo Failed to download JDK 21

    goto :eof

)

:: Install JDK 21

echo Installing JDK 21...

start /wait "" "jdk-21-installer.exe" /s

:: Add Java bin to PATH

for /f "tokens=*" %%a in ('dir /b /ad "C:\Program Files\Java\jdk-21*"') do (

    set "dev_paths=%dev_paths%;C:\Program Files\Java\%%a\bin"

)

:: Verify installation

where java >nul 2>&1

if %errorlevel% equ 0 (

    echo.

    echo JDK 21 installed successfully!

) else (

    echo.

    echo JDK installation completed but verification failed

)

:: Cleanup

del "jdk-21-installer.exe"

goto :eof

:checkMaven

set "maven_installed=0"

where mvn >nul 2>&1 && set "maven_installed=1"

goto :eof

:showMavenInfo

echo.

echo **************************************

echo *       MAVEN ALREADY INSTALLED     *

echo **************************************

echo.

mvn --version

for /f "delims=" %%m in ('where mvn') do (

    echo.

    echo Maven Path: %%~dpm..

)

if not defined MAVEN_HOME (

    for /f "tokens=*" %%m in ('dir /b /ad "C:\Program Files\apache-maven\apache-maven-*" 2^>nul') do (

        set "dev_paths=%dev_paths%;C:\Program Files\apache-maven\%%m\bin"

    )

)

goto :eof

:installMaven

echo.

echo **************************************

echo *    INSTALLING MAVEN 3.9.11         *

echo **************************************

echo.

:: Download Maven

echo Downloading Maven...

powershell -Command "(New-Object Net.WebClient).DownloadFile('https://downloads.apache.org/maven/maven-3/3.9.11/binaries/apache-maven-3.9.11-bin.zip', 'maven.zip')"

if not exist "maven.zip" (

    echo Failed to download Maven

    goto :eof

)

:: Install Maven

echo Installing...

if not exist "C:\Program Files\apache-maven" (

    mkdir "C:\Program Files\apache-maven"

)

powershell -Command "Expand-Archive -Path 'maven.zip' -DestinationPath 'C:\Program Files\apache-maven'"

:: Add Maven bin to PATH

for /d %%m in ("C:\Program Files\apache-maven\apache-maven-*") do (

    set "dev_paths=%dev_paths%;%%m\bin"

)

:: Cleanup

del "maven.zip"

echo.

echo Maven installed successfully!

goto :eof

:checkGit

set "git_installed=0"

where git >nul 2>&1 && set "git_installed=1"

goto :eof

:showGitInfo

echo.

echo **************************************

echo *       GIT ALREADY INSTALLED       *

echo **************************************

echo.

git --version

:: Ensure Git path is added to dev_paths

for /f "delims=" %%g in ('where git 2^>nul') do (

    set "git_dir=%%~dpg"

    :: Remove trailing backslash

    set "git_dir=!git_dir:~0,-1!"

    :: Check if this path is already in dev_paths

    echo %dev_paths% | find /i "!git_dir!" >nul

    if errorlevel 1 (

        set "dev_paths=%dev_paths%;!git_dir!"

    )

)

goto :eof

:installGit

echo.

echo **************************************

echo *    INSTALLING GIT                  *

echo **************************************

echo.

:: Download Git for Windows

echo Downloading Git for Windows...

powershell -Command "(New-Object Net.WebClient).DownloadFile('https://github.com/git-for-windows/git/releases/download/v2.45.2.windows.1/Git-2.45.2-64-bit.exe', 'git-installer.exe')"

if not exist "git-installer.exe" (

    echo Failed to download Git

    goto :eof

)

:: Install Git silently with proper options

echo Installing Git...

start /wait "" "git-installer.exe" /VERYSILENT /NORESTART /NOCANCEL /SP- /COMPONENTS="icons,ext\reg\shellhere,assoc,assoc_sh"

:: Wait for installation to complete

timeout /t 15 /nobreak >nul

:: Add Git to PATH (Git usually adds itself to PATH during installation)

where git >nul 2>&1

if %errorlevel% neq 0 (

    :: If Git not in PATH, try to find and add it

    if exist "C:\Program Files\Git\bin\git.exe" (

        set "dev_paths=%dev_paths%;C:\Program Files\Git\bin"

    )

    if exist "C:\Program Files (x86)\Git\bin\git.exe" (

        set "dev_paths=%dev_paths%;C:\Program Files (x86)\Git\bin"

    )

) else (

    :: If Git is already in PATH, make sure we add it to dev_paths too

    for /f "delims=" %%g in ('where git 2^>nul') do (

        set "git_dir=%%~dpg"

        :: Remove trailing backslash

        set "git_dir=!git_dir:~0,-1!"

        :: Check if this path is already in dev_paths

        echo %dev_paths% | find /i "!git_dir!" >nul

        if errorlevel 1 (

            set "dev_paths=%dev_paths%;!git_dir!"

        )

    )

)

:: Cleanup

del "git-installer.exe"

echo.

echo Git installed successfully!

goto :eof

:cloneStellarProject

echo.

echo **************************************

echo *    CLONING STELLAR PROJECT         *

echo **************************************

echo.

:: Purana project delete karo (agar exists hai to)

if exist "%stellar_project_dir%" (

    echo Removing existing project...

    rmdir /s /q "%stellar_project_dir%" 2>nul

)

:: Naya project clone karo

echo Cloning fresh Stellar sample project...

git clone https://asadrazamahmood@bitbucket.org/stellar2/stellar-sample-project.git "%stellar_project_dir%"

if %errorlevel% equ 0 (

    echo.

    echo Project cloned successfully!

    echo Location: %stellar_project_dir%

    :: Show project structure

    echo.

    echo Project structure:

    cd /d "%stellar_project_dir%"

    dir

) else (

    echo.

    echo Error: Failed to clone project

    echo Please check your credentials and try again

)

goto :eof
