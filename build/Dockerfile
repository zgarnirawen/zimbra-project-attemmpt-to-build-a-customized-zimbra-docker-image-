FROM rockylinux:9

LABEL description="Zimbra ZCS 10.1.0 - Rocky Linux 9 - Custom Image"

ENV ZIMBRA_DOMAIN=entreprise.tn
ENV ZIMBRA_HOST=mail.entreprise.tn
ENV ZIMBRA_TIMEZONE=Africa/Tunis
ENV ZIMBRA_ADMIN_PASS=Admin@Zimbra2025

RUN dnf update -y --allowerasing && dnf install -y --allowerasing \
    perl \
    net-tools \
    hostname \
    sudo \
    wget \
    curl \
    lsof \
    psmisc \
    libaio \
    nmap-ncat \
    bind-utils \
    rsyslog \
    iproute \
    && dnf clean all

WORKDIR /tmp
COPY zimbra.tgz /tmp/zimbra.tgz
RUN tar -xzf zimbra.tgz && \
    mv zcs-NETWORK-10.1.0_GA_4688.RHEL9_64.20240911074203 zimbra-installer && \
    rm zimbra.tgz

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 25 80 110 143 443 465 587 993 995 7071 8080 8443

VOLUME ["/opt/zimbra"]

HEALTHCHECK --interval=60s --timeout=30s --start-period=600s --retries=5 \
    CMD curl -sk https://localhost:7071/zimbraAdmin/ | grep -q "Zimbra" || exit 1

ENTRYPOINT ["/entrypoint.sh"]