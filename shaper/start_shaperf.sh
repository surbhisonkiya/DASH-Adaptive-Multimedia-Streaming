#!/bin/bash


# THE FOLLOWING COMMANDS ARE TO CONTROL BANDWIDTH:
# FIRSTLY IT READS DATA FROM TEXT FILE THEN tc Catch values to estimate in the parameters
#TextFile containts 7 columns values	first column is time.
#                                     	second column is bandwidth1.
# 					third column is bandwidth2.
#                                     	fourth column is to delay1.
#					fifth column is delay2 
#                                     	sixth column is to loss1 packets 
#                                     	seventh column is to loss2 packets
#................................................................................................
if [[ $EUID -ne 0 ]]; then
       echo "This script must be run as root, try 'sudo ./start_shaperf.sh'" 
          exit 1
fi
path=$(pwd)
filename=$1
FILE=$path/$filename
echo $FILE
IFS=','
i=0
bwt="mbit"
dt="ms"
lt="%"
stat="add"
ifaces="eth1"
while read t bw1 bw2  d1 d2 l1 l2 ;do    # this loop  to read values of the text file.  
	if [ -z $t ]; then
	echo "[Error] There is an extra empty line in the metrics file. Delete it to avoid malfunction"	
	break
	fi

        bwtotal=$(echo "$bw1 + $bw2"|bc)
	bwtotal=$bwtotal$bwt
	bw1=$bw1$bwt
	bw2=$bw2$bwt
	d1=$d1$dt
	d2=$d2$dt
	l1=$l1$lt
	l2=$l2$lt
	aa=$(( t - i ))   # this equation is used to  find waiting time  between two variables.
        IFS=$'\n'
	for e in $( ifconfig | grep $ifaces | awk '{print $1}' );
        do
            echo $ifaces
	if [ $i -eq 0 ]
	then
    		del="tc qdisc del dev $e root 2>/dev/null"
		eval $del
		handle="tc qdisc add dev $e root handle 1: htb default 20"
		eval $handle
		filter1="tc filter add dev $e protocol ip u32 match ip protocol 0x11 0xff flowid 1:10" #UDP
		filter2="tc filter add dev $e protocol ip u32 match ip protocol 0x6 0xff flowid 1:20"  #TCP
		#eval $filter1
		eval $filter2
		#echo "uno $i  $e"
	fi
        banwtotal="tc class $stat dev $e parent 1: classid 1:1 htb rate $bw1 ceil $bw1 burst 30k"
        banw1="tc class $stat dev $e parent 1:1 classid 1:10 htb rate $bw2 ceil $bw2 burst 30k"
	banw2="tc class $stat dev $e parent 1:1 classid 1:20 htb rate $bw1 ceil $bw1 burst 30k"	
	netem1="tc qdisc $stat dev $e parent 1:10 netem delay $d1 loss $l1"
	netem2="tc qdisc $stat dev $e parent 1:20 netem delay $d2 loss $l2"
	eval $banwtota
	#eval $banw1
	eval $banw2
	#eval $netem1
	#eval $netem2
        done
	echo "At last $aa seconds your TCP BW is $bw1 - waiting time switch is $aa seconds.. Delay of packets: $d1 , packet loss: $l1 "
#	echo "At last $aa seconds your UDP BW is $bw2 - waiting time switch is $aa seconds.. Delay of packets: $d2 , packet loss: $l2 "
        sleep $aa
        i=$t
	stat="replace"
	IFS=","
 done < $FILE
echo $iface
tc qdisc del dev $iface root 2>/dev/null
