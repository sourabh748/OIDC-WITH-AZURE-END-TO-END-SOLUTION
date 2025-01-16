#!/bin/bash

# Set variables
ROOT_CA_PRIVATE_KEY="rootCA.key"                            # Path to the Root CA private key
ROOT_CA_PUBLIC_CERT="rootCA.pem"                            # Path to the Root CA public certificate
NIFI_SERVER_KEY="nifi.key"                                  # Private key for NiFi server
NIFI_SERVER_CSR="nifi.csr"                                  # Certificate Signing Request for NiFi server
NIFI_SERVER_CERT="nifi.crt"                                 # Certificate for NiFi server (signed by Root CA)
KEYSTORE_FILE="nifi_keystore.p12"                           # Keystore file to be generated
TRUSTSTORE_FILE="nifi_truststore.p12"                       # Truststore file to be generated
KEYSTORE_PASSWORD=${NIFI_SECURITY_KEYSTORE_PASSWORD:-065ad6b41cf772b6a47f96cff82698f6}         # Password for keystore
TRUSTSTORE_PASSWORD=${NIFI_SECURITY_TRUSTSTORE_PASSWORD:-61cac7c7fff3ab70e3fe4365192cd966}    # Password for truststore
NIFI_CLUSTER_NODE_ADDRESS=$(hostname -i)

cd /opt/nifi-2.1.0/certs
# Step 1: Generate private key for NiFi server
openssl genrsa -out $NIFI_SERVER_KEY 2048
cat > csr.conf <<EOF
[ req ]
default_bits       = 2048
prompt             = no
default_md         = sha256
req_extensions     = req_ext
distinguished_name = req_distinguished_name

[ req_distinguished_name ]
C  = IN
ST = TELANGANA
L  = HYDRABAD
O  = NIFI
OU = NIFI
CN = ${NIFI_WEB_HTTPS_HOST:-NIFI_CLUSTER_NODE_ADDRESS}

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = ${INHOUSE_DOMAIN_NAME_PREFIX}.${INHOUSE_DOMAIN_NAME_SUFFIX}
DNS.2 = www.${INHOUSE_DOMAIN_NAME_PREFIX}.${INHOUSE_DOMAIN_NAME_SUFFIX}
DNS.4 = localhost
IP.1  = ${INHOUSE_DOMAIN_NAME_IP}

EOF

# Step 2: Generate CSR (Certificate Signing Request) for NiFi server
openssl req -new -key $NIFI_SERVER_KEY -out $NIFI_SERVER_CSR -config csr.conf

cat > v3.ext <<EOF
authorityKeyIdentifier = keyid,issuer
basicConstraints       = CA:FALSE
keyUsage               = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName         = @alt_names

[ alt_names ]
DNS.1 = ${INHOUSE_DOMAIN_NAME_PREFIX}.${INHOUSE_DOMAIN_NAME_SUFFIX}
DNS.2 = www.${INHOUSE_DOMAIN_NAME_PREFIX}.${INHOUSE_DOMAIN_NAME_SUFFIX}
DNS.4 = localhost
DNS.5 = ${NIFI_WEB_HTTPS_HOST:-NIFI_CLUSTER_NODE_ADDRESS}
IP.1  = ${INHOUSE_DOMAIN_NAME_IP}

EOF

# Step 3: Sign the CSR with the Root CA private key to create NiFi server certificate
openssl x509 -req -in $NIFI_SERVER_CSR -CA $ROOT_CA_PUBLIC_CERT -CAkey $ROOT_CA_PRIVATE_KEY -CAcreateserial -out $NIFI_SERVER_CERT -days 500 -sha256 -extfile v3.ext

# Step 4: Create PKCS12 keystore containing the NiFi server certificate and private key
openssl pkcs12 -export -in $NIFI_SERVER_CERT -inkey $NIFI_SERVER_KEY -out $KEYSTORE_FILE -name "nifi" -password pass:$KEYSTORE_PASSWORD

cat $NIFI_SERVER_CERT >> $ROOT_CA_PUBLIC_CERT
# Step 5: Import Root CA certificate into a PKCS12 truststore
keytool -importcert -trustcacerts -file $ROOT_CA_PUBLIC_CERT -keystore $TRUSTSTORE_FILE -storepass $TRUSTSTORE_PASSWORD -storetype PKCS12 -noprompt -alias "rootca"
keytool -importcert -trustcacerts -file $NIFI_SERVER_CERT -keystore $TRUSTSTORE_FILE -storepass $TRUSTSTORE_PASSWORD -storetype PKCS12 -noprompt -alias "leaf${HOSTNAME}"

chmod 640 "/opt/nifi-2.1.0/certs/${KEYSTORE_FILE}"
chmod 640 "/opt/nifi-2.1.0/certs/${TRUSTSTORE_FILE}"
chmod 660 "/opt/nifi-2.1.0/nifi-2.1.0/conf/authorizers.xml"

# Step 6: Output summary
if [ -f "$KEYSTORE_FILE" ] && [ -f "$TRUSTSTORE_FILE" ]; then
  echo "Keystore and Truststore successfully created!"
  echo "Keystore: $KEYSTORE_FILE"
  echo "Truststore: $TRUSTSTORE_FILE"
else
  echo "Error creating keystore or truststore. Please check the script and logs."
fi
