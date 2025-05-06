#!/bin/bash

# DNS Default (แก้ได้ตามใจ)
DEFAULT_IPV4_DNS="8.8.8.8"
DEFAULT_IPV6_DNS="2001:4860:4860::8888"

# หาอุปกรณ์เชื่อมต่อที่ไม่ใช่ lo หรือ docker0
active_device=$(nmcli -t -f DEVICE,STATE dev status | grep ":connected" | cut -d: -f1 | grep -vE '^(lo|docker0)$' | head -n1)

# หา connection name ที่ผูกกับอุปกรณ์นั้น
connection_name=$(nmcli -t -f DEVICE,CONNECTION dev status | grep "^$active_device:" | cut -d: -f2)

if [ -z "$connection_name" ]; then
    echo "❌ ไม่พบ connection ที่ใช้งานอยู่"
    exit 1
fi

# ดึง DNS ปัจจุบัน
ipv4_dns=$(nmcli -g ipv4.dns connection show "$connection_name")
ipv6_dns=$(nmcli -g ipv6.dns connection show "$connection_name")

# ถ้าไม่มี DNS IPv4 – ตั้งให้เลย
if [ -z "$ipv4_dns" ]; then
    echo "🛠️ ตั้ง IPv4 DNS เป็น $DEFAULT_IPV4_DNS"
    nmcli connection modify "$connection_name" ipv4.dns "$DEFAULT_IPV4_DNS"
    nmcli connection modify "$connection_name" ipv4.ignore-auto-dns yes
    nmcli connection up "$connection_name" >/dev/null
    ipv4_dns=$DEFAULT_IPV4_DNS
fi

# ถ้าไม่มี DNS IPv6 – ตั้งให้เลย
if [ -z "$ipv6_dns" ]; then
    echo "🛠️ ตั้ง IPv6 DNS เป็น $DEFAULT_IPV6_DNS"
    nmcli connection modify "$connection_name" ipv6.dns "$DEFAULT_IPV6_DNS"
    nmcli connection modify "$connection_name" ipv6.ignore-auto-dns yes
    nmcli connection up "$connection_name" >/dev/null
    ipv6_dns=$DEFAULT_IPV6_DNS
fi

# แสดงผล
echo "✅ Connection ที่ใช้งาน: $connection_name"
echo "🧠 IPv4 DNS:"
echo "$ipv4_dns"
echo "🧠 IPv6 DNS:"
echo "$ipv6_dns"
