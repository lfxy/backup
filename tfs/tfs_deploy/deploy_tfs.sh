#!/bin/bash

function usage() {
cat << EOF
Examples:

    -t  node type
    -v  VIP
    -m  nameserver master IP
    -s  nameserver slave IP
    -d  if need init dataserver
    -i  dataserver IP
    -p  dataserver port
    -q  dataserver init num

  Deploy to node 10.209.216.20:
    ./deploy_tfs.sh -t ns -n master/slave/single -v 10.15.136.249 -m 10.15.136.240 -s 10.15.136.244
    or
    ./deploy_tfs.sh -t ds -d first/second -v 10.15.136.249 -m 10.15.136.240 -s 10.15.136.244 [-i 10.15.136.243] [-p 18101] [-q 1]

EOF
    return 0
}

function deploy_ns_master() {
    echo "deploy master..."
    ns_exist=`sudo docker ps -q -a -f=name=$NSNAME`
    if [ -n "$ns_exist" ] ; then
        echo "Delete old ns!"
        sudo docker rm -f $NSNAME
    fi
    ka_exist=`sudo docker ps -q -a -f=name=keepalived`
    if [ -n "$ka_exist" ] ; then
        echo "Delete old keepalived!"
        sudo docker rm -f keepalived
    fi

    sudo ip a | grep $NSVIP > /dev/null 2>&1
    [[ $? == 0 ]] && sudo ip a del $NSVIP dev $NETNAME > /dev/null 2>&1

    sudo docker run -d --net=host \
        --privileged=true --restart=on-failure \
        --name=$NSNAME -e NS_VIP=$NSVIP \
        -e NS_MASTER_IP=$MASTERIP \
        -e NS_SLAVE_IP=$SLAVEIP -e DEV_NAME=$NETNAME -e NS_PORT=$NSPORT  -e DS_PORT=$DSPORT -e MAX_REPLICATION=$MAXREPLICATION -e GROUP_MASK=$GROUPMASK \
        10.213.42.254:10500/caozhiqiang1/tfs:v2.6 ns > /dev/null 2>&1

    sudo docker run --name=keepalived --restart=on-failure \
        --net=host --privileged=true \
        --volume=$PWD/:/ka-data/scripts/ \
        -e NS_PORT=$NSPORT -e NS_NAME=$NSNAME \
        -d 10.213.42.254:10500/caozhiqiang1/keepalived:1.2.7 \
        --master --override-check check-tfs-status.sh --enable-check \
        --auth-pass pass --vrid 52 $NETNAME 101 $NSVIP/24/$NETNAME > /dev/null 2>&1

    return 0
}

function deploy_ns_slave() {
    echo "deploy slave..."
    ns_exist=`sudo docker ps -q -a -f=name=$NSNAME`
    if [ -n "$ns_exist" ] ; then
        echo "Delete old ns!"
        sudo docker rm -f $NSNAME
    fi
    ka_exist=`sudo docker ps -q -a -f=name=keepalived`
    if [ -n "$ka_exist" ] ; then
        echo "Delete old keepalived!"
        sudo docker rm -f keepalived
    fi

    sudo ip a | grep $NSVIP > /dev/null 2>&1
    [[ $? == 0 ]] && sudo ip a del $NSVIP dev $NETNAME > /dev/null 2>&1

    sudo docker run -d --net=host \
        --privileged=true --restart=on-failure \
        --name=$NSNAME -e NS_VIP=$NSVIP \
        -e NS_MASTER_IP=$MASTERIP \
        -e NS_SLAVE_IP=$SLAVEIP -e DEV_NAME=$NETNAME -e NS_PORT=$NSPORT  -e DS_PORT=$DSPORT -e MAX_REPLICATION=$MAXREPLICATION -e GROUP_MASK=$GROUPMASK \
        10.213.42.254:10500/caozhiqiang1/tfs:v2.6 ns > /dev/null 2>&1

    sudo docker run --name=keepalived --restart=on-failure \
        --net=host --privileged=true \
        --volume=$PWD/:/ka-data/scripts/ \
        -e NS_PORT=$NSPORT -e NS_NAME=$NSNAME \
        -d 10.213.42.254:10500/caozhiqiang1/keepalived:1.2.7 \
        --override-check check-tfs-status.sh --enable-check \
        --auth-pass pass --vrid 52 $NETNAME 99 10.15.136.249/24/$NETNAME > /dev/null 2>&1

        #--override-check check-tfs-status.sh --enable-check \
        #--volume=$PWD/:/ka-data/scripts/ \
        #--log-driver=syslog \
    return 0
}

function deploy_ns_single() {
    echo "deploy single..."
    ns_exist=`sudo docker ps -q -a -f=name=$NSNAME`
    if [ -n "$ns_exist" ] ; then
        echo "Delete old ns!"
        sudo docker rm -f $NSNAME
    fi
    ka_exist=`sudo docker ps -q -a -f=name=keepalived`
    if [ -n "$ka_exist" ] ; then
        echo "Delete old keepalived!"
        sudo docker rm -f keepalived
    fi

    sudo docker run -d --net=host \
        --privileged=true --restart=on-failure \
        --name=$NSNAME -e NS_VIP=$NSVIP \
        -e NS_MASTER_IP=$MASTERIP \
        -e NS_SLAVE_IP=$SLAVEIP -e DEV_NAME=$NETNAME -e NS_PORT=$NSPORT  -e DS_PORT=$DSPORT -e MAX_REPLICATION=$MAXREPLICATION -e GROUP_MASK=$GROUPMASK \
        10.213.42.254:10500/caozhiqiang1/tfs:v2.6 ns > /dev/null 2>&1

    return 0
}

function deploy_ds() {
    echo "deploy ds..."
    ds_exist=`sudo docker ps -q -a -f=name=$DSNAME`
    if [ -n "$ds_exist" ] ; then
        echo "Delete old ns!"
        sudo docker rm -f $DSNAME
    fi
    if [[ $ds_type = "first" ]]; then
        if [ ! -d /root/tfs_data ]; then
            sudo mkdir -p /root/tfs_data
        else
            sudo rm -rf /root/tfs_data/*
        fi
        sudo docker run -d --net=host --privileged=true \
        --restart=always --name=$DSNAME \
        -e DS_IP=$DSIP -e NS_VIP=$NSVIP -e NS_MASTER_IP=$MASTERIP -e NS_SLAVE_IP=$SLAVEIP -e DEV_NAME=$NETNAME -e NS_PORT=$NSPORT -e DS_PORT=$DSPORT -e MOUNT_MAXSIZE=$MOUNTMAXSIZE -v /root/tfs_data:/data 10.213.42.254:10500/caozhiqiang1/tfs:v2.6 ds $DSNUM first
    elif [[ $ds_type = "second" ]]; then
        if [ ! -d /root/tfs_data ]; then
            echo "Don't exist /root/tfs_data!! Can't deploy ds with second!"
            return 1
        fi
        sudo docker run -d --net=host --privileged=true \
        --restart=always --name=$DSNAME \
        -e DS_IP=$DSIP -e NS_VIP=$NSVIP -e NS_MASTER_IP=$MASTERIP -e NS_SLAVE_IP=$SLAVEIP -e DEV_NAME=$NETNAME -e NS_PORT=$NSPORT -e DS_PORT=$DSPORT -e MOUNT_MAXSIZE=$MOUNTMAXSIZE -v /root/tfs_data:/data 10.213.42.254:10500/caozhiqiang1/tfs:v2.6 ds $DSNUM second
    fi

    return 0
}

function get_local_ip () {
    local_ip=""
    first_ip=""
    for i in $(hostname -I | awk '{for(n = 1; n <= NF; n++ ) print $n }'); do
        if [ -z "$first_ip" ] ; then
            first_ip=$i
        fi
        ip=`grep $i /etc/sysconfig/network-scripts/ifcfg-*`
        if [ -n "$ip" ] ; then
            local_ip=$i
            break
        fi
    done
    if [ -z "$local_ip" ] ; then
        local_ip=$first_ip
    fi
    DSIP=$local_ip
    return 0
}

tfs_type=""
ns_type=""
ds_type=""

NSVIP=""
MASTERIP=""
SLAVEIP=""
DSIP=""
DSPORT=18101
DSNUM=1

NETNAME=bond0
NSPORT=8667
NSNAME=tfsnameserver
MOUNTMAXSIZE=1000000
MAXREPLICATION=1
GROUPMASK=255.255.255.255


while getopts ":h:t:n:d:v:m:s:i:p:q:" opt
do
    case $opt in
        h)
            usage && exit 0;;
        t)
            tfs_type=$OPTARG;;
        n)
            ns_type=$OPTARG;;
        d)
            ds_type=$OPTARG;;
        v)
            NSVIP=$OPTARG;;
        m)
            MASTERIP=$OPTARG;;
        s)
            SLAVEIP=$OPTARG;;
        i)
            DSIP=$OPTARG;;
        p)
            DSPORT=$OPTARG;;
        q)
            DSNUM=$OPTARG;;
        ?)
            usage && exit 1
            ;;
    esac
done

DSNAME="tfsdataserver$DSNUM"
if [[ -z "$NSVIP" || -z "$MASTERIP" || -z "$SLAVEIP" ]]; then
    echo "error, need nameserver ips!!"
    exit 1
fi

if [ $tfs_type = "ns" ]; then
    if [ $ns_type = "master" ]; then
        deploy_ns_master
    elif [ $ns_type = "slave" ]; then
        deploy_ns_slave
    elif [ $ns_type = "single" ]; then
        deploy_ns_single
    else
        echo "error ns param"
    fi
elif [ $tfs_type = "ds" ]; then
    if [ -z "$DSIP" ]; then
        get_local_ip
    fi
    if [[ $ds_type = "first" || $ds_type = "second" ]]; then
        deploy_ds
        if [ $? -ne 0 ]; then
            echo "deploy ds failed"
        fi
    fi
else
    echo "error deploy type"
fi
