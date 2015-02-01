#!/bin/bash

# Generate a passphrase
export PASSPHRASE=$(head -c 500 /dev/urandom | tr -dc a-z0-9A-Z | head -c 128; echo)

# Certificate details; replace items in angle brackets with your own info
subj="
C=WA
ST=WA
O=WA
localityName=WA
commonName="$CERTIFICATE_NAME"
organizationalUnitName=WA
emailAddress=WA
"

# Generate the server private key
openssl genrsa -des3 -out /opt/certs/server.key -passout env:PASSPHRASE 2048

# Generate the CSR
openssl req \
    -new \
    -batch \
    -subj "$(echo -n "$subj" | tr "\n" "/")" \
    -key /opt/certs/server.key \
    -out /opt/certs/server.csr \
    -passin env:PASSPHRASE

cp /opt/certs/server.key /opt/certs/server.key.org

# Strip the password so we don't have to type it every time we restart Apache
openssl rsa -in /opt/certs/server.key.org -out /opt/certs/server.key -passin env:PASSPHRASE

# Generate the cert (good for 10 years)
openssl x509 -req -days 3650 -in /opt/certs/server.csr -signkey /opt/certs/server.key -out /opt/certs/server.crt

chmod 0755 /opt/certs/server.crt
chmod 0755 /opt/certs/server.key