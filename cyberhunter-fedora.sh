#!/bin/bash

echo "[*] ตรวจสอบ DNF-based system..."
if [ ! -x "$(command -v dnf)" ]; then
    echo "[!!] ระบบนี้ไม่ใช่ Fedora-based (ไม่มี dnf). หยุดการทำงาน."
    exit 1
fi

echo "[*] อัปเดตระบบ..."
sudo dnf update -y

echo "[*] ติดตั้งเครื่องมือพื้นฐาน..."
sudo dnf install -y git curl python3-pip net-tools firewalld \
    tcpdump nmap wireshark macchanger \
    perl-Image-ExifTool proxychains-ng \
    moby-engine docker-compose

echo "[*] เปิดใช้งาน Docker..."
sudo systemctl enable --now docker

echo "[*] เปิดใช้งาน Firewalld..."
sudo systemctl enable --now firewalld

echo "[*] ตั้งค่า Firewall: บล็อก ICMP, SYN scan, stealth config..."
sudo firewall-cmd --permanent --add-icmp-block=echo-request
sudo firewall-cmd --permanent --add-rich-rule='rule protocol value="tcp" reject'
sudo firewall-cmd --reload

echo "[*] ปิด services ที่ไม่จำเป็น..."
sudo systemctl stop avahi-daemon
sudo systemctl disable avahi-daemon
sudo systemctl stop cups
sudo systemctl disable cups

echo "[*] ปิด ICMP ที่ระดับ Kernel..."
sudo sysctl -w net.ipv4.icmp_echo_ignore_all=1
echo "net.ipv4.icmp_echo_ignore_all = 1" | sudo tee -a /etc/sysctl.conf

echo "[*] Spoof MAC address (ตรวจหาชื่อ interface)..."
iface=$(ip -o link show | awk -F': ' '/state UP/ {print $2}' | head -n1)
if [[ -z "$iface" ]]; then
    echo "[!!] ไม่พบ interface ที่ online (เช่น eth0 หรือ enp0s3). ข้าม macchanger"
else
    sudo ip link set "$iface" down
    sudo macchanger -r "$iface"
    sudo ip link set "$iface" up
fi

echo "[*] ตั้ง DNS ปลอดภัยสูง (Cloudflare)..."
echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf > /dev/null

echo "[*] ติดตั้ง virtualenv และ Python OSINT tools..."
pip3 install --user virtualenv maigret

echo "[*] ติดตั้ง Spiderfoot แบบ Git (เพราะ pip ใช้ไม่ได้)..."
git clone https://github.com/smicallef/spiderfoot.git
cd spiderfoot
pip3 install -r requirements.txt
cd ..

echo "[*] Clone OSINT Repos..."
git clone https://github.com/sherlock-project/sherlock.git
git clone https://github.com/laramies/theHarvester.git
git clone https://github.com/s0md3v/Photon.git
git clone https://github.com/trustedsec/social-engineer-toolkit.git setoolkit
git clone https://github.com/mxrch/GHunt.git

echo "[*] เสร็จสิ้นการติดตั้ง! รีสตาร์ทระบบเพื่อให้การเปลี่ยนแปลงทั้งหมดมีผล."
