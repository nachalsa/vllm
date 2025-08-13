#!/bin/bash
# 이 스크립트는 클라이언트에서 실행되어야합니다.

# --- sudo 권한 확인 ---
if [ "$EUID" -ne 0 ]; then
    echo "오류: 이 스크립트는 sudo 권한으로 실행되어야 합니다."
    echo "사용법: sudo ./install_autossh_tunnel.sh"
    exit 1
fi

# --- autossh 설치 확인 ---
AUTOSSH_EXEC=$(which autossh)
if [ -z "${AUTOSSH_EXEC}" ]; then
    echo "오류: 'autossh' 실행 파일을 찾을 수 없습니다."
    echo "autossh가 설치되어 있고, PATH에 포함되어 있는지 확인하세요."
    echo "설치되어 있지 않다면, 'sudo apt install autossh' 또는 'sudo yum install autossh' 등으로 설치하세요."
    exit 1
fi

# --- 설정 변수 (이 부분들을 실제 환경에 맞게 수정하세요) ---
SERVICE_NAME="autossh-vllm-tunnel.service"
SYSTEMD_DIR="/etc/systemd/system"
LOCAL_PORT="54321"              # 로컬 PC에서 열릴 포트
REMOTE_HOST_ALIAS="gpuserverwithoutcmd" # ~/.ssh/config에 정의된 호스트 별칭
REMOTE_TARGET_HOST="localhost"  # gpuserver 내부에서 vLLM이 리스닝하는 호스트 (대부분 localhost)
REMOTE_TARGET_PORT="12345"      # gpuserver 내부에서 vLLM이 리스닝하는 포트 (docker-compose에 명시된 포트)
AUTOSSH_EXEC=$(which autossh)   # 일반적으로 /usr/bin/autossh
LOCAL_USER=${SUDO_USER:-$(logname)} # 현재 스크립트를 실행하는 사용자 (systemd 서비스의 User)

# --- SSH 설정 파일 (~/.ssh/config) 설정 안내 ---
echo "--- SSH Config 설정 안내 ---"
echo "먼저, '~/.ssh/config' 파일을 열거나 생성하여 다음 내용을 추가해야 합니다."
echo "Host ${REMOTE_HOST_ALIAS}"
echo "    HostName <gpuserver의 실제 IP 주소 또는 도메인 이름>"
echo "    User <gpuserver에 SSH 접속할 사용자 이름>"
echo "    Port 22"
echo "    IdentityFile ~/.ssh/id_rsa # 또는 ~/.ssh/your_ssh_key_name"
echo ""
echo "SSH 키 기반 인증이 설정되어 있고, 비밀번호 없이 gpuserver에 접속 가능한지 확인하세요."
read -p "SSH Config 설정 및 키 확인 후 엔터를 누르세요..."

# --- systemd 서비스 파일 내용 정의 ---
SERVICE_CONTENT="
[Unit]
Description=AutoSSH Local Port Forward to gpuserver vLLM
After=network-online.target

[Service]
User=${LOCAL_USER}
ExecStart=${AUTOSSH_EXEC} -M 0 -N -L ${LOCAL_PORT}:${REMOTE_TARGET_HOST}:${REMOTE_TARGET_PORT} ${REMOTE_HOST_ALIAS}
Environment="AUTOSSH_GATETIME=0"
Restart=always
RestartSec=10
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=${SERVICE_NAME}

[Install]
WantedBy=multi-user.target
"

# --- 서비스 파일 생성 및 권한 설정 ---
echo "--- systemd 서비스 파일 생성 ---"
echo "서비스 파일을 ${SYSTEMD_DIR}/${SERVICE_NAME} 에 생성합니다."
echo "${SERVICE_CONTENT}" | sudo tee ${SYSTEMD_DIR}/${SERVICE_NAME} > /dev/null

sudo chmod 644 ${SYSTEMD_DIR}/${SERVICE_NAME}
echo "서비스 파일 권한 설정 완료."

# --- systemd 데몬 재로드 및 서비스 활성화/시작 ---
echo "--- systemd 서비스 활성화 및 시작 ---"
sudo systemctl daemon-reload
echo "systemd 데몬 재로드 완료."

sudo systemctl enable ${SERVICE_NAME}
echo "서비스가 시스템 부팅 시 자동 시작되도록 설정되었습니다."

sudo systemctl start ${SERVICE_NAME}
echo "서비스가 시작되었습니다. 잠시 후 상태를 확인하세요."

# --- 서비스 상태 확인 안내 ---
echo ""
echo "--- 서비스 상태 확인 ---"
echo "서비스가 정상적으로 실행되는지 확인하려면 다음 명령어를 사용하세요:"
echo "sudo systemctl status ${SERVICE_NAME}"
echo "로그를 실시간으로 확인하려면:"
echo "sudo journalctl -u ${SERVICE_NAME} -f"
echo ""
echo "설치 및 시작 완료."