#!/bin/bash

# static data
VIP=10.0.2.100
VNM=24
DEV=enp0s3

#dynamic data
HADR_ROLE=$(su - db2inst1 -c 'db2 connect to sample > /dev/null; db2 -x select HADR_ROLE from table \(mon_get_hadr\(-2\)\)' | tr -d [:space:])
echo HADR_ROLE: $HADR_ROLE
IPAS=$(ip a s | grep $VIP)
echo $IPAS


if [ "$HADR_ROLE" == "PRIMARY" ]; then
  echo assign vip
  if [ -z "$IPAS" ]; then
    ip a add $VIP/$VNM dev $DEV
    echo vip added
  else
    echo vip already assigned
  fi
else
  echo remove vip
  if [ -z "$IPAS" ]; then
    echo vip is not assigned, no need to remove
  else
    ip a delete $VIP/$VNM dev $DEV
    echo vip removed
  fi
fi

