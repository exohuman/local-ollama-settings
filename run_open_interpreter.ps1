<#
.SYNOPSIS
    Automated launcher for optimized local Open Interpreter via Ollama.
    Tailored for 8GB VRAM / 32GB RAM split optimization.
#>

# 1. Kill any existing instances to prevent port conflicts or cached memory lockups
Write-Host "🔄 Cleaning up background Ollama processes..." -ForegroundColor Cyan
Stop-Process -Name "ollama" -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# 2. Inject environment variables for the session
# Enables Flash Attention to lower memory usage on your 8GB VRAM
$env:OLLAMA_FLASH_ATTENTION = "1"
# Limits concurrent parallel requests to 1 to protect VRAM allocations
$env:OLLAMA_NUM_PARALLEL = "1"
# Do not use cloud services for this session, ensuring all operations are local
$env:OLLAMA_NO_CLOUD = "1"
# force a context length of 16k tokens to avoid memory fragmentation issues
$env:OLLAMA_CONTEXT_LENGTH = 32768
# change the kvcache type to 8bit to cut ram usage in half for the key/value cache
$env:OLLAMA_KV_CACHE_TYPE = "q8_0"

$env:OLLAMA_VULKAN = "1"
$env:OLLAMA_IGPU_ENABLE = "1"
$env:CUDA_VISIBLE_DEVICES = "-1"

Push-Location
Set-Location "C:\source\models\qwen2.5-coder14b"

# 3. Compile the model
ollama create qwen2.5-coder14b -f .\Modelfile

# 4. Start the Ollama background server in a clean, isolated environment
Write-Host "🚀 Launching Ollama Server with Flash Attention enabled..." -ForegroundColor Green
Start-Process -FilePath "ollama" -ArgumentList "serve" -WindowStyle Hidden

# 5. Loop and wait until the Ollama API is responsive before launching the interpreter
Write-Host "⏳ Waiting for Ollama server to wake up..." -ForegroundColor Yellow
while ($true) {
    try {
        $response = Invoke-WebRequest -Uri "http://127.0.0.1:11434" -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ Ollama server is online and responding!" -ForegroundColor Green
            break
        }
    }
    catch {
        # Server isn't ready yet, pause and retry
        Start-Sleep -Seconds 1
    }
}

# 6. Launch Open Interpreter 
Write-Host "💻 Routing Open Interpreter straight to your custom local model..." -ForegroundColor Magenta

# Launch using custom endpoint targeting your exact model name
# interpreter --local-provider ollama -m qwen2.5-coder14b --context_window 32768 --max_tokens 2048

ollama serve

Pop-Location
