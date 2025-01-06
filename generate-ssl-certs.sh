#!/bin/bash

# Set consistent password
PASSWORD="password123"

echo "Generating certificates with password: $PASSWORD"

# Generate CA
keytool -genkeypair \
  -alias ca \
  -dname "CN=chhaya, OU=Engineering, O=Company, L=City, ST=State, C=US" \
  -keystore secrets/ca.keystore.jks \
  -keypass $PASSWORD \
  -storepass $PASSWORD \
  -keyalg RSA \
  -keysize 4096 \
  -ext bc:c \
  -validity 365

# Export CA cert
keytool -exportcert \
  -alias ca \
  -keystore secrets/ca.keystore.jks \
  -storepass $PASSWORD \
  -file secrets/ca.crt \
  -rfc

# Generate server keystore with multiple DNS names
keytool -genkeypair \
  -alias server \
  -dname "CN=chhaya, OU=Engineering, O=Company, L=City, ST=State, C=US" \
  -ext "SAN=DNS:kafka-1,DNS:kafka-2,DNS:kafka-3,DNS:schema-registry,DNS:kafka-ui,DNS:debezium-kafka-connect,DNS:localhost,DNS:kafka.istad.co,IP:202.178.125.77" \
  -keystore secrets/kafka.server.keystore.jks \
  -keypass $PASSWORD \
  -storepass $PASSWORD \
  -keyalg RSA \
  -keysize 2048 \
  -validity 365

# Create server truststore
keytool -keystore secrets/kafka.server.truststore.jks \
  -alias ca \
  -importcert \
  -file secrets/ca.crt \
  -storepass $PASSWORD \
  -keypass $PASSWORD \
  -noprompt

# Sign server certificate with CA
keytool -keystore secrets/kafka.server.keystore.jks \
  -alias server \
  -certreq \
  -file secrets/server.csr \
  -storepass $PASSWORD \
  -keypass $PASSWORD

keytool -keystore secrets/ca.keystore.jks \
  -alias ca \
  -gencert \
  -infile secrets/server.csr \
  -outfile secrets/server.crt \
  -ext "SAN=DNS:kafka-1,DNS:kafka-2,DNS:kafka-3,DNS:schema-registry,DNS:kafka-ui,DNS:debezium-kafka-connect,DNS:localhost,DNS:kafka.istad.co,IP:202.178.125.77" \
  -storepass $PASSWORD \
  -keypass $PASSWORD \
  -ext bc=ca:false \
  -rfc

# Import CA and signed certificate into server keystore
keytool -keystore secrets/kafka.server.keystore.jks \
  -alias ca \
  -importcert \
  -file secrets/ca.crt \
  -storepass $PASSWORD \
  -keypass $PASSWORD \
  -noprompt

keytool -keystore secrets/kafka.server.keystore.jks \
  -alias server \
  -importcert \
  -file secrets/server.crt \
  -storepass $PASSWORD \
  -keypass $PASSWORD \
  -noprompt

# Clean up temporary files
rm secrets/*.csr secrets/*.crt 2>/dev/null || true

echo "Certificate generation completed successfully. Files created in secrets/:"
ls -l secrets/

# Verify the keystore content
echo -e "\nVerifying keystore content:"
keytool -list -v -keystore secrets/kafka.server.keystore.jks -storepass $PASSWORD