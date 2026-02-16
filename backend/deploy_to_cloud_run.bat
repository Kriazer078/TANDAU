@echo off
setlocal

:: Get variables from the user
echo ------------------------------------------
echo ** TANDAU - Cloud Run Deployment Script **
echo ------------------------------------------
echo.

set /p PROJECT_ID="Enter your Google Cloud Project ID (e.g., tandau-1234): "
if "%PROJECT_ID%"=="" (
    echo Error: Project ID cannot be empty.
    pause
    exit /b 1
)

set /p SERVICE_NAME="Enter a name for your service (default: tandau-backend): "
if "%SERVICE_NAME%"=="" set SERVICE_NAME=tandau-backend

echo.
echo Deploying %SERVICE_NAME% to project %PROJECT_ID%...
echo This may take a few minutes. You may be asked to choose a region (e.g., europe-west1).
echo.

:: Authenticate (if not already logged in, script will prompt)
echo Checking authentication...
call gcloud auth login --brief

:: Set Project Config
call gcloud config set project %PROJECT_ID%

:: Deploy using Cloud Build (source upload)
:: This builds the container remotely and deploys it
:: --allow-unauthenticated: Allows public access (important for the API backend)
call gcloud run deploy %SERVICE_NAME% ^
    --source . ^
    --platform managed ^
    --allow-unauthenticated ^
    --region europe-west1

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Deployment Failed! Please check the errors above.
    pause
    exit /b 1
)

echo.
echo ------------------------------------------
echo Deployment Successful!
echo Your service URL is shown above.
echo IMPORTANT: Make sure to verify your environment variables (GEMINI_API_KEY) in the Cloud Run Console.
echo ------------------------------------------
pause
Endlocal
