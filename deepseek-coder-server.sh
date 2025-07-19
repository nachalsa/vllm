source /home/team03/workspace/jy/gitwork/vllm/.venv/bin/activate
export CUDA_VISIBLE_DEVICES="0,1"
export HF_HOME=/workspace01/team03/jy/hf_cache
export VLLM_API_KEY="huntr/x_How_It's_Done"
python3 -m vllm.entrypoints.openai.api_server     --model "deepseek-ai/DeepSeek-Coder-V2-Instruct"     --tensor-parallel-size 2  --enforce-eager --dtype bfloat16  --host 0.0.0.0     --port 13333     --api-key $VLLM_API_KEY  --trust-remote-code

