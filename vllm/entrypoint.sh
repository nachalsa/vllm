#!/bin/bash

# 스크립트 실행 중 오류가 발생하면 즉시 중단하도록 설정
set -e

echo "========= [Entrypoint] Starting container setup... ========="

# 1. 공유 라이브러리 캐시를 갱신하여 마운트된 NVIDIA 드라이버를 시스템이 인식하도록 합니다.
echo "[Entrypoint] Running ldconfig..."
ldconfig
echo "[Entrypoint] ldconfig finished."

# 2. vLLM API 서버를 실행합니다.
#    인자들을 보기 쉽게 여러 줄로 나눕니다.
echo "[Entrypoint] Starting vLLM API server..."

API_KEY_ARG=""
if [ -n "${VLLM_API_KEY}" ]; then
  API_KEY_ARG="--api-key ${VLLM_API_KEY}"
  echo "[Entrypoint] API Key detected. Starting vLLM server with authentication."
else
  echo "[Entrypoint] No API Key detected. Starting vLLM server without authentication."
fi


python3 -m vllm.entrypoints.openai.api_server \
    --model "TechxGenus/DeepSeek-Coder-V2-Lite-Instruct-AWQ" \
    --chat-template "/app/templates/coder_template.jinja" \
    --tensor-parallel-size 1 \
    --gpu-memory-utilization 0.285 \
    --max-model-len 32768 \
    --host 0.0.0.0 \
    --quantization awq \
    ${API_KEY_ARG} \
    --trust-remote-code

echo "[Entrypoint] vLLM server process has been launched."
