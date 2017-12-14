#!/bin/bash
testdirpath=$1

# Here we need a directories structure with hostnames list 
# and reports from different processes in each, like this:
#
# /testdirpath ..
#               /-> hname-1 ..
#                            /-> report_of_process_#1
#                            /-> report_of_process_#2
#                            /-> report_of_process_#2
#                            ...
# 
#               /-> hname-2 ..
#                            /-> report_of_process_#1
#                            /-> report_of_process_#2
#                            /-> report_of_process_#2
#                            ...
#               ...

HOSTNAMES=(hname-1 hname-2 hname-3 hname-4 hname-5)

reportslist=$(for s in ${HOSTNAMES[@]}; do echo -n ${testdirpath}${s}*/*; echo -n " "; done); 

rps=0.0
latency=0.0
transec=0.0
err_connect=0
err_write=0
err_read=0
err_timeout=0
q50=0.0
q75=0.0
q90=0.0
q99=0.0
net_errors=0
connections=0
transfers=0.0
requests=0
counter=0

for report in $reportslist
do 
    [ ! -f $report ] && continue
#    echo $report | awk -F'/' '{print $6}'
    counter=$(($counter+1))

#    cat $report | grep -i "requests/sec"
    rps_add=$(cat $report | grep -i "requests/sec" | awk '{print $2}')
    rps=$(python -c "print $rps + $rps_add")

#    cat $report | grep -i "latency" | head -1
    latency_add=$(cat $report | grep -i "latency" | head -1 | awk '{print $2}' | sed -r 's/([0-9]*\.[0-9][0-9])(.*)/\1/')
    if [ $counter -eq 1 ]
    then
        latency_measure=$(cat $report | grep -i "latency" | head -1 | awk '{print $2}' | sed -r 's/([0-9]*\.[0-9][0-9])(.*)/\2/')
    elif [ $counter -gt 1 ]
    then
        latency_measure_new=$(cat $report | grep -i "latency" | head -1 | awk '{print $2}' | sed -r 's/([0-9]*\.[0-9][0-9])(.*)/\2/')
        if [ $latency_measure_new != $latency_measure ]
        then
            echo "Error: measures of Avg Latency are different"
        fi
    fi
    latency=$(python -c "print $latency + $latency_add")
    
#    cat $report | grep -i "transfer/sec" 
    transec_add=$(cat $report | grep -i "transfer/sec" | awk '{print $2}' | sed -r 's/([0-9]*\.[0-9][0-9])(.*)/\1/')
    if [ $counter -eq 1 ] 
    then
        transec_measure=$(cat $report | grep -i "transfer/sec" | awk '{print $2}' | sed -r 's/([0-9]*\.[0-9][0-9])(.*)/\2/')
    elif [ $counter -gt 1 ]
    then
        transec_measure_new=$(cat $report | grep -i "transfer/sec" | awk '{print $2}' | sed -r 's/([0-9]*\.[0-9][0-9])(.*)/\2/')
        if [ $transec_measure_new != $transec_measure ]
        then
            echo "Error: measures of Transfer/sec are different"
        fi
    fi
    transec=$(python -c "print $transec + $transec_add")
    
#    cat $report | grep -i "socket"
    connect_add=$(cat $report | grep -i "socket" | awk -F',' '{print $1}' | awk -F 'connect' '{print $2}' | sed 's/ //g')
    read_add=$(cat $report | grep -i "socket" | awk -F',' '{print $2}' | awk -F 'read' '{print $2}' | sed 's/ //g')
    write_add=$(cat $report | grep -i "socket" | awk -F',' '{print $3}' | awk -F 'write' '{print $2}' | sed 's/ //g')
    timeout_add=$(cat $report | grep -i "socket" | awk -F',' '{print $4}' | awk -F 'timeout' '{print $2}' | sed 's/ //g')
    [ -z $connect_add ] && connect_add=0
    [ -z $read_add ] && read_add=0
    [ -z $write_add ] && write_add=0
    [ -z $timeout_add ] && timeout_add=0
    err_connect=$(python -c "print $err_connect + $connect_add")
    err_read=$(python -c "print $err_read + $read_add")
    err_write=$(python -c "print $err_write + $write_add")
    err_timeout=$(python -c "print $err_timeout + $timeout_add")
    
#    cat $report | grep " 99%" | tail -1
    q50_add=$(cat $report | grep " 50%" | tail -1 | awk '{print $2}' | sed -r 's/([0-9]*\.[0-9][0-9])(.*)/\1/')
    q75_add=$(cat $report | grep " 75%" | tail -1 | awk '{print $2}' | sed -r 's/([0-9]*\.[0-9][0-9])(.*)/\1/')
    q90_add=$(cat $report | grep " 90%" | tail -1 | awk '{print $2}' | sed -r 's/([0-9]*\.[0-9][0-9])(.*)/\1/')
    q99_add=$(cat $report | grep " 99%" | tail -1 | awk '{print $2}' | sed -r 's/([0-9]*\.[0-9][0-9])(.*)/\1/')
    q50_m=$(cat $report | grep " 50%" | tail -1 | awk '{print $2}' | sed -r 's/([0-9]*\.[0-9][0-9])(.*)/\2/')
    q75_m=$(cat $report | grep " 75%" | tail -1 | awk '{print $2}' | sed -r 's/([0-9]*\.[0-9][0-9])(.*)/\2/')
    q90_m=$(cat $report | grep " 90%" | tail -1 | awk '{print $2}' | sed -r 's/([0-9]*\.[0-9][0-9])(.*)/\2/')
    q99_m=$(cat $report | grep " 99%" | tail -1 | awk '{print $2}' | sed -r 's/([0-9]*\.[0-9][0-9])(.*)/\2/')
    q50=$(python -c "print $q50 + $q50_add")
    q75=$(python -c "print $q75 + $q75_add")
    q90=$(python -c "print $q90 + $q90_add")
    q99=$(python -c "print $q99 + $q99_add")
    
#    cat $report | grep -i "Non-2xx"
    net_errors_add=$(cat $report | grep -i "Non-2xx" | awk -F':' '{print $2}' | sed 's/ //g')
    [ -z $net_errors_add ] && net_errors_add=0
    net_errors=$(python -c "print $net_errors + $net_errors_add")

#    cat $report | grep -i "connections"
    connections_add=$(cat $report | grep -i "connections" | awk '{print $4}')
    connections=$(python -c "print $connections + $connections_add")

    connections_proc=$(cat $report | grep -i "connections" | awk '{print $4}')
    threads_proc=$(cat $report | grep -i "connections" | awk '{print $1}')

#    cat $report | grep -i "requests in"
    transfers_add=$(cat $report | grep -i "requests in" | awk '{print $5}' | sed -r 's/([0-9]*\.[0-9][0-9])(.*)/\1/')
    if [ $counter -eq 1 ] 
    then
        transfers_measure=$(cat $report | grep -i "requests in" | awk '{print $5}' | sed -r 's/([0-9]*\.[0-9][0-9])(.*)/\2/')
    elif [ $counter -gt 1 ]
    then
        transfers_measure_new=$(cat $report | grep -i "requests in" | awk '{print $5}' | sed -r 's/([0-9]*\.[0-9][0-9])(.*)/\2/')
        if [ $transfers_measure_new != $transfers_measure ]
        then
            echo "Error: measures of Transfers Bytes are different"
        fi
    fi
    transfers=$(python -c "print $transfers + $transfers_add")

    requests_add=$(cat $report | grep -i "requests in" | awk '{print $1}')
    requests=$(python -c "print $requests + $requests_add")

done

latency=$(python -c "print round($latency / $counter, 2)")
q50=$(python -c "print round($q50 / $counter, 2)")
q75=$(python -c "print round($q75 / $counter, 2)")
q90=$(python -c "print round($q90 / $counter, 2)")
q99=$(python -c "print round($q99 / $counter, 2)")

echo "Aggregated report from $counter processes (each with $threads_proc threads and $connections_proc connections)."
echo "Requests/sec: $rps"
echo "Transfer/sec: $transec $transec_measure"
echo "Avg Latency: $latency $latency_measure"
echo "Latency Distribution"
echo "   50% $q50 $q50_m"
echo "   75% $q75 $q75_m"
echo "   90% $q90 $q90_m"
echo "   99% $q99 $q99_m"
echo "Socket errors: connect $err_connect, read $err_read, write $err_write, timeout $err_timeout"
echo "Non-2xx or 3xx responses: $net_errors"
echo "Overall connections: $connections"
echo "Overall requests: $requests, $transfers $transfers_measure read"
