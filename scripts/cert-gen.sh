#!/bin/bash

# Prompt for base directory with a default value
read -p "Enter directory name for certificates [certs/user]: " DIR
DIR=${DIR:-certs/user}

read -p "Enter directory name for config files [../../scripts/config]: " CONF_DIR
CONF_DIR=${CONF_DIR:-../../scripts/config}

read -p "Enter password for the Root CA [password]: " ROOT_CA_PASSWORD
ROOT_CA_PASSWORD=${ROOT_CA_PASSWORD:-password}

# Define directory structure
ROOT_CA_DIR="$DIR/root-ca"
SERVER_DIR="$DIR/server"

# Create directories
mkdir -p "$ROOT_CA_DIR"
mkdir -p "$SERVER_DIR"

# Configuration files and their paths
ROOT_CA_CONF="$CONF_DIR/root_ca.conf"
SERVER_CONF="$CONF_DIR/server_cert.conf"

# File names for certificates and keys
ROOT_CA_KEY="$ROOT_CA_DIR/rootCA.key"
ROOT_CA_CERT="$ROOT_CA_DIR/rootCA.pem"
ROOT_CA_PFX="$ROOT_CA_DIR/rootCA.pfx"
ROOT_CA_CER="$ROOT_CA_DIR/rootCA.cer"
SERVER_KEY="$SERVER_DIR/server.key"
SERVER_CSR="$SERVER_DIR/server.csr"
SERVER_CERT="$SERVER_DIR/server.crt"
SERVER_PEM="$SERVER_DIR/server.pem"

# Step 1: Create the Root CA
openssl genrsa -out "$ROOT_CA_KEY" 2048
openssl req -x509 -new -nodes -key "$ROOT_CA_KEY" -config "$ROOT_CA_CONF" -out "$ROOT_CA_CERT"

# Step 2: Create the Server Certificate
openssl genrsa -out "$SERVER_KEY" 2048
openssl req -new -key "$SERVER_KEY" -config "$SERVER_CONF" -out "$SERVER_CSR"
openssl x509 -req -in "$SERVER_CSR" -CA "$ROOT_CA_CERT" -CAkey "$ROOT_CA_KEY" -CAcreateserial -out "$SERVER_CERT" -days 500

# Step 3: Create PFX file for the Root CA
openssl pkcs12 -export -out "$ROOT_CA_PFX" -inkey "$ROOT_CA_KEY" -in "$ROOT_CA_CERT" -password pass:"$ROOT_CA_PASSWORD"

# Step 4: Create .cer file for the Root CA
openssl x509 -outform der -in "$ROOT_CA_CERT" -out "$ROOT_CA_CER"

# Step 5: Chain the Server Certificate with the CA Certificate
cat "$SERVER_CERT" "$ROOT_CA_CERT" > "$SERVER_PEM"
cp "$SERVER_PEM" "$SERVER_DIR/server.crt"

echo "Certificates generated in $ROOT_CA_DIR and $SERVER_DIR."
