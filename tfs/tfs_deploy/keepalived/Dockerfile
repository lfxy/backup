FROM 10.213.42.254:10500/root/keepalived:1.2.7

COPY entry /usr/local/bin

RUN chmod +x /usr/local/bin/entry

ENTRYPOINT ["/usr/local/bin/entry"]
