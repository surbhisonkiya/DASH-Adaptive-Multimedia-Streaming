#!/bin/bash 
ifaces="eth1"
if [[ $EUID -ne 0 ]]; then
       echo "This script must be run as root, try 'sudo ./cancel_shaper.sh'" 
          exit 1
fi

tc qdisc del dev $ifaces root 2>/dev/null

