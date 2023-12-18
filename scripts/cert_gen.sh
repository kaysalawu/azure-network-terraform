#!/bin/bash

# OpenSSL configuration file path
configFile="openssl.cnf"

# Certificate and key names
certName="yourCertificateName"
password="changeme"

# Create OpenSSL Config File
cat > $configFile <<EOF
[ req ]
default_bits = 2048
default_md = sha256
prompt = no
distinguished_name = dn

[ dn ]
C=US
ST=California
L=San Francisco
O=Example Organization
CN=example.com
EOF

# Generate a private key and certificate using the config file
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout $certName.key \
    -out $certName.crt \
    -config $configFile

# Convert the certificate and key to PFX format
openssl pkcs12 -export -out $certName.pfx \
    -inkey $certName.key \
    -in $certName.crt \
    -passout pass:$password
