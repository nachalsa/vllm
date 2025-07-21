FROM nvidia/cuda:12.2.2-devel-ubuntu22.04

# 2. 시스템 패키지 설치 및 환경 설정
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y python3-pip python3-dev build-essential git && \
    rm -rf /var/lib/apt/lists/*

# 3. vLLM 설치
RUN pip3 install --no-cache-dir vllm


# 작업 디렉토리를 /app 으로 설정
WORKDIR /app

# 호스트의 entrypoint.sh 스크립트를 컨테이너의 /app 디렉토리로 복사
COPY entrypoint.sh .
COPY templates ./templates/

# API 서버 포트 노출 (컨테이너 내부 포트는 8000 그대로 사용)
EXPOSE 8000

# 컨테이너가 시작될 때 entrypoint.sh 스크립트를 실행하도록 설정
ENTRYPOINT ["/app/entrypoint.sh"]
