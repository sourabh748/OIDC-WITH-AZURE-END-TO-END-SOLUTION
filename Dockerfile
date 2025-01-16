###################
#  BUILD STAGE 1  #
###################

FROM openjdk:25-slim-bullseye@sha256:5ce7143537cfebb7b8af4700a9f3896910d450ab053d93039020d341d350fafa AS image-builder
# FROM ubuntu/jre:17-22.04_edge_56@sha256:af15e94b4709295fda95779ff555da19732be74a01898ff61678e149324d8ef7

RUN mkdir -p /opt/nifi-2.1.0 && mkdir -p /opt/nifi-2.1.0/start && mkdir -p /opt/nifi-2.1.0/certs \
    && apt-get update -y \
    && apt-get install -y \
    wget \
    unzip \
    dos2unix

COPY ./start.sh /opt/nifi-2.1.0/start/start.sh
COPY ./crts.sh /opt/nifi-2.1.0/start/crts.sh
COPY ./certs/rootCA.key /opt/nifi-2.1.0/certs/rootCA.key
COPY ./certs/rootCA.pem /opt/nifi-2.1.0/certs/rootCA.pem

RUN dos2unix /opt/nifi-2.1.0/start/crts.sh && dos2unix /opt/nifi-2.1.0/start/start.sh && chmod +x /opt/nifi-2.1.0/start/start.sh && chmod +x /opt/nifi-2.1.0/start/crts.sh \
    && wget -P /opt/nifi-2.1.0 https://dlcdn.apache.org/nifi/2.1.0/nifi-2.1.0-bin.zip \
    && unzip /opt/nifi-2.1.0/nifi-2.1.0-bin.zip -d /opt/nifi-2.1.0 \
    && rm -rf /opt/nifi-2.1.0/nifi-2.1.0-bin.zip \
    && apt-get remove --purge -y wget \
    unzip \
    dos2unix \
    && apt-get clean \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/*

###################
#  BUILD STAGE 2  #
###################
FROM openjdk:25-slim-bullseye@sha256:5ce7143537cfebb7b8af4700a9f3896910d450ab053d93039020d341d350fafa

ARG https_port=8443
ARG node_protocol_port=8082
ARG socket_port=10000
ARG load_balancer_port=6342
ARG matrix_expoter_port=9092
ARG TIME_ZONE=Asia/Kolkata

ENV NIFI_HOME=/opt/nifi-2.1.0/nifi-2.1.0 \
    JAVA_HOME=/usr/local/openjdk-25 \
    TZ=${TIME_ZONE} \
    https_map_port=${https_port} \
    node_protocol_map_port=${node_protocol_port} \
    socket_map_port=${socket_port} \
    load_balancer_map_port=${load_balancer_port} \
    matrix_expoter_map_port=${matrix_expoter_port}

VOLUME [ "/opt/nifi-2.1.0/nifi-2.1.0/content_repository", "/opt/nifi-2.1.0/nifi-2.1.0/flowfile_repository", "/opt/nifi-2.1.0/nifi-2.1.0/logs", "/opt/nifi-2.1.0/nifi-2.1.0/provenance_repository", "/opt/nifi-2.1.0/nifi-2.1.0/state" ]

EXPOSE ${https_port}/tcp \
    ${node_protocol_port}/tcp \
    ${socket_port}/tcp \
    ${load_balancer_port}/tcp \
    ${matrix_expoter_port}/tcp

COPY --from=image-builder /opt/nifi-2.1.0 /opt/nifi-2.1.0

RUN echo "*  hard  nofile  50000" >> /etc/security/limits.conf \
    && echo "*  soft  nofile  50000" >> /etc/security/limits.conf \
    && echo "*  hard  nproc  10000" >> /etc/security/limits.conf \
    && echo "*  soft  nproc  10000" >> /etc/security/limits.conf \
    && echo "vm.swappiness = 0" >>  /etc/sysctl.conf

CMD [ "/opt/nifi-2.1.0/start/start.sh" ]