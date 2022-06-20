# db2haip
# db2 HADR – highly available virtual ip address manager script
•	This settings must be implemented on both the primary and standby server. The settings need to be the very similar (or same in specific cases) on both the systems

•	Create a timer service at operating system level
file path and name: /etc/system/system/db2haip.timer
file content as below
you may adjust the OnCalendar line to change the default every minute value to a longer one
[Unit]
Description=Timer service for the db2haip service
Requires=db2haip.service

[Timer]
Unit=db2haip.service
OnCalendar=*-*-* *:*:00
AccuracySec=1s

[Install]
WantedBy=timers.target

•	Create service unit file
file path and name: /etc/system/system/db2haip.service
file content as below
may be the script location is not perfect and may be adjusted (ExecStart)
[Unit]
Description=Service assigns Virtual IP to the db2 HADR primary system
Wants=myMonitor.timer

[Service]
Type=oneshot
ExecStart=/root/db2haip.sh

[Install]
WantedBy=multi-user.target

•	Create the worker script
file path and name: /root/db2haip.sh – as in the service file
file content as below
please fix the static variables, like virtual address, mask and network device
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

•	Make the worker script executable:
chmod +x /root/db2haip.sh
•	Start the timer service
systemctl start myMonitor.service
•	Enable the timer service
systemctl enable myMonitor.service
•	You may montor the service log using the below command:
journalctl -S today -f -u myMonitor.service

