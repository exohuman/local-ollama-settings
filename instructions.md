To permanently optimize qwen2.5-coder:14b so it splits flawlessly between your 8GB VRAM and 32GB system RAM, you need to use an Ollama Modelfile. [1, 2] 
Because coding execution tools like OpenCodeInterpreter and Open Interpreter send enormous blocks of code back and forth, the default settings will quickly crash your 8GB VRAM due to "Context Bloat". [3] 
Creating a permanently tuned custom variant of the model prevents crashes, optimizes VRAM layers, and enables Flash Attention to ensure the fastest processing speeds. Follow these instructions to set it up: [4, 5] 
------------------------------
## Step 1: Create your Custom Modelfile

   1. Open your terminal or command prompt.
   2. Create and edit a new file named Modelfile by running:
   * Mac/Linux: nano Modelfile
      * Windows: notepad Modelfile
   3. Paste the exact configuration block below into the file:

# Pull the base 14B modelFROM qwen2.5-coder:14b
# OPTIMIZATION PARAMETERS
# 1. Force Flash Attention for faster generation and lower VRAM usage
PARAMETER flash_attn true
# 2. Restrict context window to 16k (16384) to prevent VRAM Out-Of-Memory crashes. # OpenCode needs context, but the default 32k/128k will crush your 8GB VRAM.
PARAMETER num_ctx 16384
# 3. Prevent Ollama from overloading your 8GB VRAM.# This forces Ollama to cleanly offload the heavy math layers to your 32GB RAM.
PARAMETER num_gpu 32


   1. Save and close the file (in Nano, press Ctrl+O, Enter, then Ctrl+X. In Notepad, just save and exit).

------------------------------
## Step 2: Build your Optimized Model
Run the following command in your terminal to compile your new custom, optimized model. Name it something descriptive, like opencode-14b:

ollama create opencode-14b -f ./Modelfile

Ollama will instantly look at the 14B base model you already downloaded, apply the rules, and save your tuned version. [6] 
------------------------------
## Step 3: Update your Tool Execution Command
Now, instead of pointing Open Interpreter or OpenCodeInterpreter to the stock qwen2.5-coder:14b, point it to your newly built, permanently optimized model:
## For Open Interpreter:

interpreter --local --model ollama/opencode-14b

## For OpenCodeInterpreter config files:
If you are adjusting a JSON config file (like opencode.json), update your model parameter string to match your custom name: [7] 

"model": "opencode-14b"

------------------------------
## 💡 What this permanently fixes:

* 
* No more random crashes: Limiting num_ctx to 16384 acts as a guardrail. When OpenCode reads deep error stack traces, it won't exceed your 8GB VRAM capacity.
* Consistent Speed: By setting num_gpu 32, you lock the exact split ratio. Ollama won't dynamically guess layer layouts on every single prompt, providing predictable and steady performance. [8, 9, 10] 
* 

Are you running this setup on Windows (Nvidia), Linux, or a Mac? If you experience any lag, I can give you a quick background script to check exactly how many layers successfully loaded onto your GPU!

[1] [https://dev.to](https://dev.to/yann_ortodoro/running-qwen-25-coder-14b-locally-in-cursor-with-ollama-4436)
[2] [https://localaimaster.com](https://localaimaster.com/blog/ollama-multi-gpu-setup)
[3] [https://eastondev.com](https://eastondev.com/blog/en/posts/ai/20260410-ollama-performance-optimization/)
[4] [https://forums.truenas.com](https://forums.truenas.com/t/ollama-additional-environment-variables/45344)
[5] [https://github.com](https://github.com/ollama/ollama/issues/11803)
[6] [https://github.com](https://github.com/ollama/ollama/issues/618)
[7] [https://www.youtube.com](https://www.youtube.com/watch?v=BHPtBB5LTl8&vl=en-US)
[8] [https://github.com](https://github.com/ollama/ollama/issues/11437)
[9] [https://eastondev.com](https://eastondev.com/blog/en/posts/ai/ollama-gpu-scheduling/)
[10] [https://github.com](https://github.com/ollama/ollama/issues/11437)
