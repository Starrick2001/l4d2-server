FROM ubuntu:latest


COPY opt/ ./opt/

WORKDIR /work

# COPY ./install_l4d2_server.sh .
# RUN ./install_l4d2_server.sh

EXPOSE 27015/tcp 27015/udp 27020/tcp 27020/udp

# ENTRYPOINT ["/start_l4d2_server.sh"]
