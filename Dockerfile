FROM ekkoye8888/hermes-web-ui:latest
COPY setup-once.sh /opt/setup-once.sh
RUN chmod +x /opt/setup-once.sh
