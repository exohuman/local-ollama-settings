[CmdletBinding()]
param(
    [string] $InstallDirectory = 'C:\source\models\inference\llama-b11425-bin-win-vulkan-x64',
    [string] $TensorSplit = '6,4',
    [int] $ContextSize = 32768,
    [int] $Port = 8080
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$releaseTag = 'b11425'
$assetName = 'llama-b11425-bin-win-vulkan-x64.zip'
$assetUrl = "https://github.com/ggml-org/llama.cpp/releases/download/$releaseTag/$assetName"
$modelRepo = 'Qwen/Qwen2.5-Coder-14B-Instruct-GGUF:Q4_K_M'

if (-not (Test-Path -LiteralPath $InstallDirectory)) {
    New-Item -ItemType Directory -Path $InstallDirectory -Force | Out-Null
}

$serverFile = Get-ChildItem -LiteralPath $InstallDirectory -Filter 'llama-server.exe' -File -Recurse -ErrorAction SilentlyContinue |
    Select-Object -First 1

if (-not $serverFile) {
    Write-Host "Downloading llama.cpp $releaseTag Vulkan build..."
    $zipPath = Join-Path $InstallDirectory $assetName

    if ($PSVersionTable.PSVersion.Major -lt 6) {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    }

    Invoke-WebRequest -Uri $assetUrl -OutFile $zipPath -UseBasicParsing
    Write-Host 'Extracting llama.cpp...'
    Expand-Archive -LiteralPath $zipPath -DestinationPath $InstallDirectory -Force
    Remove-Item -LiteralPath $zipPath -Force

    $serverFile = Get-ChildItem -LiteralPath $InstallDirectory -Filter 'llama-server.exe' -File -Recurse |
        Select-Object -First 1
}

if (-not $serverFile) {
    throw "llama-server.exe was not found under '$InstallDirectory'."
}

$serverPath = $serverFile.FullName
$deviceList = 'Vulkan1,Vulkan0'
Write-Host 'Using Vulkan1 (RTX 4070) and Vulkan0 (Radeon 780M), as previously listed on this laptop.'
Write-Host "Layer split preference: $TensorSplit (RTX 4070 first, Radeon 780M second)."

$portInUse = Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction SilentlyContinue
if ($portInUse) {
    throw "Port $Port is already in use. Stop the existing local server with Ctrl+C, then run this script again."
}

Write-Host "Starting Qwen 2.5 Coder 14B Q4_K_M with $ContextSize context on both GPUs."
Write-Host "API address after the server reports listening: http://127.0.0.1:$Port/v1"
Write-Host 'The model downloads from Hugging Face on first use if it is not already cached.'
Write-Host 'Leave this window open while using the model. Press Ctrl+C to stop it.'

$serverArgs = @(
    '--device', $deviceList,
    '--split-mode', 'layer',
    '--tensor-split', $TensorSplit,
    '--ctx-size', "$ContextSize",
    '--parallel', '1',
    '--host', '127.0.0.1',
    '--port', "$Port",
    '-hf', $modelRepo
)

Write-Host "Working directory: $($serverFile.DirectoryName)"
Push-Location -LiteralPath $serverFile.DirectoryName
try {
    & $serverPath @serverArgs
    $serverExitCode = $LASTEXITCODE
    $exitCodeHex = ([int64]$serverExitCode -band 4294967295).ToString('X8')
    Write-Host "llama-server exited: $serverExitCode (0x$exitCodeHex)"
    if ($serverExitCode -ne 0) {
        throw "llama-server failed with exit code $serverExitCode (0x$exitCodeHex)."
    }
}
finally {
    Pop-Location
}
