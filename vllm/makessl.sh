export HOST_NAME=gpuserver
openssl req -x509 \
  -newkey ed25519 \
  -keyout server.key \
  -out server.crt \
  -days 365 \
  -nodes \
  -subj "/CN=$HOST_NAME" \
  -addext "subjectAltName = DNS:$HOST_NAME,IP:$(hostname -I | awk '{print $2}')"


