openssl req -new \
  -x509 \
  -nodes \
  -newkey rsa:2048 \
  -subj "/CN=kongdp" \
  -keyout ./KongAir_Internal_CP_Group_Internal.key \
  -out ././KongAir_Internal_CP_Group_Internal.crt