#!/bin/bash

if [ -z "$1" ]; then
    echo -e "\n\n[-] Usage: ./hdiscovery.sh <subnet ip> (-t to use tcp in case icmp is blocked)\n"
    exit 1
fi

ip=$1

if [ $1 = "-t" ]; then
    ip=$2
elif [ $1 = "-h" ] || [ $1 = "--help" ]; then
    echo -e "\n\n[-] Usage: ./hdiscovery.sh <subnet ip> (-t to use tcp in case icmp is blocked)\n\n"
    exit 0
fi

subnet=$(echo $ip | sed 's/\.[^\.]*$//')
use_tcp=false
full_port_scan=false
ports="21,22,80,443,445,8080"

while [[ $# -gt 0 ]]; do
    key="$1"
    if [ "$key" = "-t" ]
    then
        use_tcp=true
        break
    fi
    shift
done; OPTIND=0

echo -e "\n\n[*] Applying host discovery on: $subnet.0"
echo -e "[*] Use TCP: $use_tcp\n"

if [ $use_tcp == false ]; then
    for i in $(seq 1 254); do
        if timeout 1 ping -c 1 $subnet.$i >/dev/null; then
            ttl=$(ping -c 1 $subnet.$i | grep ttl | sed -n 's/.*ttl=\([[:digit:]]*\).*/\1/p')
            if [ $ttl -le 64 ]; then
                echo "[+] Host $subnet.$i (Linux) - ACTIVE"
            else
                echo "[+] Host $subnet.$i (Windows) - ACTIVE"
            fi
        fi &
    done; wait
    echo -e "\n\n[*] ICMP Host Discovery concluded, stopping...\n\n"
    sleep 1
    exit 0
else
    for i in $(seq 1 254); do
        for port in $(echo $ports | tr ',' ' '); do
            timeout 1 bash -c "echo '' > /dev/tcp/$subnet.$i/$port" &>/dev/null && echo "[+] Host $subnet.$i - ACTIVE; Ports: $port" &
        done; wait    
    done; wait
    echo -e "\n\n[*] TCP Host Discovery concluded, stopping...\n\n"
    sleep 1
    exit 0
fi
