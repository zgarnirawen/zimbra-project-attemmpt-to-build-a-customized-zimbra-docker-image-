#!/bin/bash
update-crypto-policies --set DEFAULT 2>/dev/null || true

mkdir -p /opt/zimbra/common/etc/openssl

cat > /opt/zimbra/common/etc/openssl/openssl.cnf << 'SSLCONF'
openssl_conf = openssl_init

[openssl_init]
providers = provider_sect

[provider_sect]
default = default_sect

[default_sect]
activate = 1
SSLCONF

chown -R zimbra:zimbra /opt/zimbra/common/etc/
/opt/zimbra/bin/ldap start