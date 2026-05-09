#!/bin/bash
set -e

echo "=========================================="
echo "  Zimbra ZCS 10.1.0 - Rocky Linux 9"
echo "  Démarrage du conteneur"
echo "=========================================="

# 1. Configuration réseau
HOSTNAME=$(hostname)
DOMAIN=${ZIMBRA_DOMAIN:-"entreprise.tn"}
FQDN="mail.${DOMAIN}"

echo "Configuration hostname : ${FQDN}"
hostname ${FQDN} 2>/dev/null || true

# 2. Fixer /etc/hosts
cat > /etc/hosts << EOF
127.0.0.1   localhost localhost.localdomain
127.0.0.1   ${FQDN} ${HOSTNAME}
::1         localhost localhost.localdomain
EOF

echo "/etc/hosts configuré :"
cat /etc/hosts

# 3. Reset flag si installation incomplète
if [ -f /opt/zimbra/.install_complete ] && [ ! -f /opt/zimbra/bin/zmcontrol ]; then
    echo "Installation incomplète détectée, réinitialisation..."
    rm -f /opt/zimbra/.install_complete
fi

# 4. Créer l'utilisateur zimbra si absent
if ! id zimbra &>/dev/null; then
    echo "Création de l'utilisateur zimbra..."
    groupadd -g 1000 zimbra 2>/dev/null || true
    useradd -u 1000 -g zimbra -d /opt/zimbra -s /bin/bash zimbra 2>/dev/null || true
fi

# 5. Détection première installation
if [ ! -f /opt/zimbra/.install_complete ]; then
    echo ""
    echo "=========================================="
    echo "  PREMIÈRE INSTALLATION ZIMBRA ZCS 10.1.0"
    echo "=========================================="

    # 6. Nettoyer les verrous LDAP potentiels
    rm -f /opt/zimbra/data/ldap/mdb/db/lock.mdb 2>/dev/null || true
    rm -f /opt/zimbra/data/ldap/state/run/slapd.pid 2>/dev/null || true

    # 7. Aller dans l'installateur
    cd /tmp/zimbra-installer

    # 8. Créer le fichier de config AUTO
    cat > /tmp/zimbra-auto.conf << EOF2
AVDOMAIN="${DOMAIN}"
AVUSER="admin@${DOMAIN}"
CREATEADMIN="admin@${DOMAIN}"
CREATEADMINPASS="${ZIMBRA_ADMIN_PASS:-Admin@Zimbra2025}"
CREATEDOMAIN="${DOMAIN}"
DOCREATEADMIN="yes"
DOCREATEDOMAIN="yes"
EXPANDMENU="no"
HOSTNAME="${FQDN}"
HTTPPORT="8080"
HTTPPROXY="TRUE"
HTTPPROXYPORT="80"
HTTPSPORT="8443"
HTTPSPROXYPORT="443"
IMAPPORT="7143"
IMAPPROXYPORT="143"
IMAPSSLPORT="7993"
IMAPSSLPROXYPORT="993"
INSTALL_WEBAPPS="service zimlet zimbra zimbraAdmin"
JAVAHOME="/opt/zimbra/common/lib/jvm/java"
LDAPAMAVISPASS="${ZIMBRA_ADMIN_PASS:-Admin@Zimbra2025}"
LDAPPOSTPASS="${ZIMBRA_ADMIN_PASS:-Admin@Zimbra2025}"
LDAPROOTPASS="${ZIMBRA_ADMIN_PASS:-Admin@Zimbra2025}"
LDAPADMINPASS="${ZIMBRA_ADMIN_PASS:-Admin@Zimbra2025}"
LDAPREPPASS="${ZIMBRA_ADMIN_PASS:-Admin@Zimbra2025}"
LDAPBESSEARCHSET="set"
LDAPHOST="${FQDN}"
LDAPPORT="389"
LDAPREPLICATIONTYPE="master"
LDAPSERVERID="1"
MAILBOXDMEMORY="512"
MAILPROXY="TRUE"
MODE="https"
MYSQLMEMORYPERCENT="30"
POPPORT="7110"
POPPROXYPORT="110"
POPSSLPORT="7995"
POPSSLPROXYPORT="995"
PROXYMODE="https"
REMOVE="no"
RUNARCHIVING="no"
RUNAV="yes"
RUNCBPOLICYD="no"
RUNDKIM="yes"
RUNSA="yes"
RUNVMHA="no"
SERVICEWEBAPP="yes"
SMTPDEST="admin@${DOMAIN}"
SMTPHOST="${FQDN}"
SMTPNOTIFY="yes"
SMTPSOURCE="admin@${DOMAIN}"
SNMPNOTIFY="yes"
SNMPTRAPHOST="${FQDN}"
STARTSERVERS="yes"
SYSTEMMEMORY="6.8"
UIWEBAPPS="yes"
UPGRADE="yes"
VERSIONUPDATECHECKS="FALSE"
zimbraDefaultDomainName="${DOMAIN}"
zimbraIPMode="ipv4"
zimbraPrefTimeZoneId="${ZIMBRA_TIMEZONE:-Africa/Tunis}"
zimbra_server_hostname="${FQDN}"
INSTALL_PACKAGES="zimbra-core zimbra-ldap zimbra-logger zimbra-mta zimbra-snmp zimbra-store zimbra-apache zimbra-spell zimbra-memcached zimbra-proxy"
EOF2

    # 9. Installation complète (avec configuration)
    echo "Installation Zimbra (10-15 minutes)..."
    ./install.sh \
        --platform-override \
        --skip-activation-check \
        /tmp/zimbra-auto.conf \
        < /dev/null 2>&1 | tee /tmp/zimbra-install.log

    # 10. Fix ownership
    chown -R zimbra:zimbra /opt/zimbra/ 2>/dev/null || true

    # 11. Vérifier le succès
    if [ -f /opt/zimbra/bin/zmcontrol ]; then
        touch /opt/zimbra/.install_complete
        echo "=== Installation réussie ! ==="
    else
        echo "=== ECHEC installation ==="
        cat /tmp/zimbra-install.log
        exit 1
    fi

else
    echo "Installation existante détectée, démarrage des services..."
fi

# 12. Fix ownership
chown -R zimbra:zimbra /opt/zimbra/ 2>/dev/null || true

# 13. Démarrer les services Zimbra
echo "Démarrage des services Zimbra..."
su - zimbra -c "zmcontrol start" || true

echo ""
echo "=========================================="
echo "  ZIMBRA PRÊT !"
echo "  Webmail : https://$(hostname)"
echo "  Admin   : https://$(hostname):7071"
echo "  Login   : admin@${DOMAIN}"
echo "  Pass    : ${ZIMBRA_ADMIN_PASS:-Admin@Zimbra2025}"
echo "=========================================="

# 14. Garder le container actif
tail -f /dev/null