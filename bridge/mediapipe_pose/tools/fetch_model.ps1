# PowerShell script to download MediaPipe Pose Landmarker models.
# Usage: .\fetch_model.ps1

$ErrorActionPreference = "Stop"

$Models = @{
    "pose_landmarker_lite.task"  = "https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_lite/float16/1/pose_landmarker_lite.task";
    "pose_landmarker_full.task"  = "https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_full/float16/1/pose_landmarker_full.task";
    "pose_landmarker_heavy.task" = "https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_heavy/float16/1/pose_landmarker_heavy.task";
}

# The target runtime version directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BaseDir = Split-Path -Parent $ScriptDir
$RootProjectDir = Split-Path -Parent $BaseDir

$DestPlatforms = @("windows-x86_64", "linux-x86_64")
$VersionDir = "mp_0_10_35"

Write-Host "Starting MediaPipe model downloader..."

foreach ($Platform in $DestPlatforms) {
    $ModelsDir = Join-Path $RootProjectDir "runtime\mediapipe\pose\$VersionDir\$Platform\models"
    if (!(Test-Path $ModelsDir)) {
        New-Item -ItemType Directory -Force -Path $ModelsDir | Out-Null
        Write-Host "Created target folder: $ModelsDir"
    }

    foreach ($ModelName in $Models.Keys) {
        $Url = $Models[$ModelName]
        $OutPath = Join-Path $ModelsDir $ModelName

        if (Test-Path $OutPath) {
            Write-Host "Model $ModelName already exists at $OutPath. Skipping download."
            continue
        }

        Write-Host "Downloading $ModelName from $Url..."
        Invoke-WebRequest -Uri $Url -OutFile $OutPath -UseBasicParsing

        # Calculate file size
        $Size = (Get-Item $OutPath).Length
        Write-Host "Successfully downloaded $ModelName ($Size bytes) to $OutPath"

        # Compute SHA256
        $HashStream = [System.Security.Cryptography.HashAlgorithm]::Create("SHA256")
        $FileStream = [System.IO.File]::OpenRead($OutPath)
        $HashBytes = $HashStream.ComputeHash($FileStream)
        $FileStream.Close()
        $Hash = [System.BitConverter]::ToString($HashBytes).Replace("-", "").ToLower()
        Write-Host "$ModelName SHA256: $Hash"
    }
}

Write-Host "All downloads completed successfully."
