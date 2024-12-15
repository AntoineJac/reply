mkdir dp_cert cp_cert
mkdir ca_cert && cd "$_"

echo "Create CA certificate"

openssl genrsa -out ca-cert.key 2048
openssl req -x509 -new -nodes -key ca-cert.key -sha256 -days 1825 -out ca-cert.pem

cd ../cp_cert

echo "Create controle plane certificate"

openssl genrsa -out control-plane.key 2048
openssl req -new -key control-plane.key -out control-plane.csr

cat > control-plane.ext << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = wss.stargate.starsweb.io
EOF

openssl x509 -req -in control-plane.csr -CA ../ca_cert/ca-cert.pem -CAkey ../ca_cert/ca-cert.key -CAcreateserial \
-out control-plane.crt -days 825 -sha256 -extfile control-plane.ext

cd ../dp_cert

echo "Create data plane certificate"

read -p "Please enter your data plane Domaine Name: " DOMAIN

openssl genrsa -out data-plane.key 2048
openssl req -new -key data-plane.key -out data-plane.csr

cat > data-plane.ext << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = $DOMAIN
EOF

openssl x509 -req -in data-plane.csr -CA ../ca_cert/ca-cert.pem -CAkey ../ca_cert/ca-cert.key -CAcreateserial \
-out data-plane.crt -days 825 -sha256 -extfile data-plane.ext