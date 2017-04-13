#!/bin/bash

nsconfpath=/usr/local/tfs/conf/ns.conf
dsconfpath=/usr/local/tfs/conf/ds.conf

if [ $# == 0 ]; then
  echo "please input param which service to start"
  exit 1
fi

if [[ -z "$NS_MASTER_IP" || -z "$NS_SLAVE_IP" || -z "$NS_VIP" ]]; then
  echo "need vip, NS_MASTER_IP and NS_SLAVE_IP!"
  exit 1
fi

if [[ $1 == "ds" && -z "$DS_IP" ]]; then
  echo "need DS_IP in ds server!"
  exit 1
fi

LINE=`sed -n -r '/^ip_addr =/=' $nsconfpath | head -n 1`
sed -i  "${LINE}d" $nsconfpath
sed -i "${LINE} iip_addr\ =\ $NS_VIP" $nsconfpath

LINE=`sed -n -r '/^ip_addr_list =/=' $nsconfpath | head -n 1`
sed -i  "${LINE}d" $nsconfpath
sed -i "${LINE} iip_addr_list\ =\ $NS_MASTER_IP|$NS_SLAVE_IP" $nsconfpath


LINE=`sed -n -r '/^ip_addr =/=' $dsconfpath | head -n 2`
array=($LINE)

if [[ -n "$DS_IP" ]]; then
  sed -i  "${array[0]}d" $dsconfpath
  sed -i "${array[0]} iip_addr\ =\ $DS_IP" $dsconfpath
fi
sed -i  "${array[1]}d" $dsconfpath
sed -i "${array[1]} iip_addr\ =\ $NS_VIP" $dsconfpath
#for each in ${array[*]}
#do
#  sed -i  "${each}d" $dsconfpath
#  sed -i "${each} iip_addr\ =\ $NS_MASTER_IP" $dsconfpath
#done

LINE=`sed -n -r '/^ip_addr_list =/=' $dsconfpath | head -n 1`
sed -i  "${LINE}d" $dsconfpath
sed -i "${LINE} iip_addr_list\ =\ $NS_MASTER_IP|$NS_SLAVE_IP" $dsconfpath


if [[ -n "$DEV_NAME" ]]; then
  LINE=`sed -n -r '/^dev_name=/=' $nsconfpath | head -n 1`
  sed -i  "${LINE}d" $nsconfpath
  sed -i "${LINE} idev_name=\ $DEV_NAME" $nsconfpath

  LINE=`sed -n -r '/^dev_name=/=' $dsconfpath | head -n 1`
  sed -i  "${LINE}d" $dsconfpath
  sed -i "${LINE} idev_name=\ $DEV_NAME" $dsconfpath
fi

if [[ -n "$MOUNT_MAXSIZE " ]]; then
  LINE=`sed -n -r '/^mount_maxsize =/=' $dsconfpath | head -n 1`
  sed -i  "${LINE}d" $dsconfpath
  sed -i "${LINE} imount_maxsize\ =\ $MOUNT_MAXSIZE" $dsconfpath
fi

if [[ -n "$NS_PORT" ]]; then
  LINE=`sed -n -r '/^port =/=' $nsconfpath | head -n 1`
  sed -i  "${LINE}d" $nsconfpath
  sed -i "${LINE} iport\ =\ $NS_PORT" $nsconfpath
fi


if [[ -n "$MAX_REPLICATION" ]]; then
  LINE=`sed -n -r '/^max_replication =/=' $nsconfpath | head -n 1`
  sed -i  "${LINE}d" $nsconfpath
  sed -i "${LINE} imax_replication\ =\ $MAX_REPLICATION" $nsconfpath
fi
if [[ -n "$MIN_REPLICATION" ]]; then
  LINE=`sed -n -r '/^min_replication =/=' $nsconfpath | head -n 1`
  sed -i  "${LINE}d" $nsconfpath
  sed -i "${LINE} imin_replication\ =\ $MIN_REPLICATION" $nsconfpath
fi

LINE=`sed -n -r '/^port =/=' $dsconfpath | head -n 2`
array=($LINE)
if [[ -n "$DS_PORT" ]]; then
  sed -i  "${array[0]}d" $dsconfpath
  sed -i "${array[0]} iport\ =\ $DS_PORT" $dsconfpath
fi
if [[ -n "$NS_PORT" ]]; then
  sed -i  "${array[1]}d" $dsconfpath
  sed -i "${array[1]} iport\ =\ $NS_PORT" $dsconfpath
fi

if [[ -n "$GROUP_MASK" ]]; then
  LINE=`sed -n -r '/^group_mask =/=' $nsconfpath | head -n 1`
  sed -i  "${LINE}d" $nsconfpath
  sed -i "${LINE} igroup_mask\ =\ $GROUP_MASK" $nsconfpath
fi

if [ $1 == "ns" ]; then
  /usr/local/tfs/scripts/tfs start_ns
elif [ $1 == "ds" ]; then
  if [ $3 == "first" ]; then
    /usr/local/tfs/scripts/stfs format $2
  fi
  /usr/local/tfs/scripts/tfs start_ds $2
else
  echo "error param!"
  exit 1
fi
