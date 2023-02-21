#!/bin/bash

cd /tmp

echo "Password:"
read pass

echo "CN:"
read cn

cat << EOF > "extfile.cnf"
[ req ]
prompt              = no
default_keyfile     = privkey.pem
distinguished_name  = req_distinguished_name
req_extensions      = req_ext
[ req_distinguished_name ]
countryName         = IN
stateOrProvinceName = Foo
localityName        = Bar
commonName          = $cn
emailAddress        = foo@bar.com
[ req_ext ]
subjectAltName      = DNS:$cn,IP:127.0.0.1
EOF

p="pass:$pass"
openssl req -new -passout $p -config "extfile.cnf" > cert.csr
openssl rsa -passin $p -in privkey.pem -out key.pem
openssl x509 -in cert.csr -out cert.pem -req -signkey key.pem -days 1001 \
  -extfile extfile.cnf -extensions req_ext
cat key.pem>>cert.pem

echo "Key: $(pwd)/key.pem, Cert: $(pwd)/cert.pem"
