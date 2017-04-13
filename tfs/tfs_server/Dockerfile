FROM 10.213.42.254:10500/base/centos:6.7
#FROM 10.213.42.254:10500/base/java_centos_1.7.65:1.5

ADD tfs.tar.gz /usr/local
COPY start_tfs.sh /opt/

RUN yum clean all && \
    yum install -y libtool zlib-devel autoconf readline-devel readline libuuid-devel mysql-devel automake libuuid ncurses-devel.x86_64 ncurses.x86_64 gcc-c++ vim wget net-tools svn libstdc++.so.6 glibc.i686 unzip make lrzsz && \
    mkdir /data && \
    chmod +x /opt/*.sh


EXPOSE 8666 18100

#ENTRYPOINT [ "/bin/bash", "-c", "/usr/local/tfs/scripts/tfs start_ns" ]
#ENTRYPOINT [ "/bin/bash", "-c", "/usr/local/tfs/scripts/stfs format 1 && /usr/local/tfs/scripts/tfs start_ds 1" ]
#ENTRYPOINT [ "/bin/bash", "-c", "/opt/start_tfs.sh" ]
ENTRYPOINT [ "/opt/start_tfs.sh" ]
