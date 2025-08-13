#!/bin/bash

# 스크립트 실행 중 오류가 발생하면 즉시 중단하도록 설정
set -e

echo "========= [Entrypoint] Starting container setup... ========="

# 1. 공유 라이브러리 캐시를 갱신하여 마운트된 NVIDIA 드라이버를 시스템이 인식하도록 합니다.
echo "[Entrypoint] Running ldconfig..."
ldconfig
echo "[Entrypoint] ldconfig finished."

# 2. vLLM API 서버를 실행합니다.
# 인자들을 보기 쉽게 여러 줄로 나눕니다.

API_KEY_ARG=""
if [ -n "${VLLM_API_KEY}" ]; then
    API_KEY_ARG="--api-key ${VLLM_API_KEY}"
    echo "[Entrypoint] API Key detected. Starting vLLM server with authentication."
else
    echo "[Entrypoint] No API Key detected. Starting vLLM server without authentication."
fi

# echo "[Entrypoint] Starting vLLM API server with Devstral AWQ model..."

#gpu 2개 분산 각각 21982MiB 사용 -> 1개 38110MiB 사용
#모델로드에 각각 6.6626 GiB -> 1개 13.3162 GiB 사용
#2개 평균 50.7829초 -> 1개 평균 81.0040초
python3 -m vllm.entrypoints.openai.api_server \
    --model "cpatonn/Devstral-Small-2507-AWQ" \
    --tokenizer-mode mistral \
    --config-format hf \
    --load-format safetensors \
    --tool-call-parser mistral \
    --enable-auto-tool-choice \
    --tensor-parallel-size 2 \
    --gpu-memory-utilization 0.375 \
    --max-model-len 128000 \
    --host 0.0.0.0 \
    --port 8000 \
    --quantization awq_marlin \
    --dtype bfloat16 \
    --trust-remote-code \
    ${API_KEY_ARG} \

# python3 -m vllm.entrypoints.openai.api_server \
#     --model "unsloth/Mistral-Small-3.2-24B-Instruct-2506-GGUF" \
#     --tokenizer-mode mistral \
#     --config-format hf \
#     --load-format mistral \
#     --tool-call-parser mistral \
#     --enable-auto-tool-choice \
#     --tensor-parallel-size 2 \
#     --gpu-memory-utilization 0.4 \
#     --max-model-len 128000 \
#     --host 0.0.0.0 \
#     --port 8000 \
#     --dtype bfloat16 \
#     --trust-remote-code \
#     ${API_KEY_ARG}



# 방법 1: GPTQ 4비트 양자화 (권장 - GPU 메모리 75% 절약)
# echo "[Entrypoint] Starting vLLM server with GPTQ 4-bit quantized Mistral-Small..."

# python3 -m vllm.entrypoints.openai.api_server \
#     --model "ISTA-DASLab/Mistral-Small-3.1-24B-Instruct-2503-GPTQ-4b-128g" \
#     --tokenizer-mode mistral \
#     --config-format hf \
#     --load-format auto \
#     --tool-call-parser mistral \
#     --enable-auto-tool-choice \
#     --tensor-parallel-size 2 \
#     --gpu-memory-utilization 0.8 \
#     --max-model-len 4096 \
#     --host 0.0.0.0 \
#     --port 8000 \
#     --dtype auto \
#     --trust-remote-code \
#     ${API_KEY_ARG}

# 방법 2: unsloth GGUF (CPU+GPU 혼합 사용 가능)
# python3 -m vllm.entrypoints.openai.api_server \
#     --model "unsloth/Mistral-Small-3.2-24B-Instruct-2506-GGUF" \
#     --tokenizer-mode mistral \
#     --config-format hf \
#     --load-format auto \
#     --tensor-parallel-size 2 \
#     --gpu-memory-utilization 0.8 \
#     --max-model-len 128000 \
#     --host 0.0.0.0 \
#     --port 8000 \
#     --dtype auto \
#     --trust-remote-code \
#     --enforce-eager \
#     ${API_KEY_ARG}

# vllm serve mistralai/Mistral-Small-3.2-24B-Instruct-2506 --tokenizer_mode mistral --config_format mistral --load_format mistral --tool-call-parser mistral --enable-auto-tool-choice --limit_mm_per_prompt 'image=10' --tensor-parallel-size 2
# # 양자화 안된버전 잘 기능함, 그런데 apikey 안적었는데도 apikey가 적용됨 환경변수때문인거같기도함
# vllm serve mistralai/Mistral-Small-3.2-24B-Instruct-2506 \
#     --host 0.0.0.0 \
#     --port 8000 \
#     --gpu-memory-utilization 0.8 \
#     --max-model-len 128000 \
#     --tokenizer-mode mistral \
#     --config-format mistral \
#     --load-format mistral \
#     --tool-call-parser mistral \
#     --enable-auto-tool-choice \
#     --limit_mm_per_prompt 'image=10' \
#     --tensor-parallel-size 2 \
#     --trust-remote-code \

# #매우매우 멍청함
# python3 -m vllm.entrypoints.openai.api_server \
#   --model "OPEA/Mistral-Small-3.1-24B-Instruct-2503-int4-AutoRound-awq-sym" \
#   --load-format safetensors \
#   --tensor-parallel-size 2 \
#   --gpu-memory-utilization 0.375 \
#   --max-model-len 32768 \
#   --port 8000 \
#   --quantization awq \
#   --dtype float16 \
#   --trust-remote-code

# python3 -m vllm.entrypoints.openai.api_server \
#     --model "OPEA/Mistral-Small-3.1-24B-Instruct-2503-int4-AutoRound-awq-sym" \
#     --tokenizer-mode mistral \
#     --config-format hf \
#     --load-format safetensors \
#     --tool-call-parser mistral \
#     --enable-auto-tool-choice \
#     --tensor-parallel-size 2 \
#     --gpu-memory-utilization 0.375 \
#     --max-model-len 128000 \
#     --host 0.0.0.0 \
#     --port 8000 \
#     --quantization awq \
#     --dtype float16 \
#     --trust-remote-code \


# python3 -m vllm.entrypoints.openai.api_server \
#     --model "/app/model/Mistral-Small-GGUF-Local/" \
#     --tokenizer-mode mistral \
#     --config-format hf \
#     --tool-call-parser mistral \
#     --enable-auto-tool-choice \
#     --tensor-parallel-size 2 \
#     --gpu-memory-utilization 0.375 \
#     --max-model-len 128000 \
#     --host 0.0.0.0 \
#     --port 8000 \
#     --trust-remote-code \
#     ${API_KEY_ARG}

# 방법 3: bartowski GGUF (다양한 양자화 레벨 제공)
# python3 -m vllm.entrypoints.openai.api_server \
#     --model "bartowski/mistralai_Mistral-Small-3.2-24B-Instruct-2506-GGUF" \
#     --tokenizer-mode mistral \
#     --config-format hf \
#     --load-format auto \
#     --tensor-parallel-size 2 \
#     --gpu-memory-utilization 0.8 \
#     --max-model-len 32768 \
#     --host 0.0.0.0 \
#     --port 8000 \
#     --dtype auto \
#     --trust-remote-code \
#     --enforce-eager \
#     ${API_KEY_ARG}


echo "[Entrypoint] vLLM server process has been launched."