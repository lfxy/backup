#!/bin/bash

# Author owner: chenqiangzhishen@163.com

#NS_PORT=8668
#NS_NAME=tfsnameserver

sudo netstat -anp | grep $NS_PORT | grep LISTEN > /dev/null 2>&1
#echo $CHECKED_IP $CHECKED_NAME
#for check_times in `seq 1 3`; do
#    sudo netstat -anp | grep $NS_PORT | grep LISTEN > /dev/null 2>&1
#    if [[ $? -eq 1 ]]; then
#        sleep 1
#        if [ $check_times -eq 3 ]; then
#            echo "aaaaaaaaaaaaa"
#            #sudo pkill keepalived
#        fi
#    fi
#done

