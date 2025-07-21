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
echo "[Entrypoint] Starting vLLM API server with Devstral AWQ model..."

API_KEY_ARG=""
if [ -n "${VLLM_API_KEY}" ]; then
    API_KEY_ARG="--api-key ${VLLM_API_KEY}"
    echo "[Entrypoint] API Key detected. Starting vLLM server with authentication."
else
    echo "[Entrypoint] No API Key detected. Starting vLLM server without authentication."
fi

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
    --ssl-keyfile /app/server.key \
    --ssl-certfile /app/server.crt \

echo "[Entrypoint] vLLM server process has been launched."