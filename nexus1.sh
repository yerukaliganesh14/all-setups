#!/bin/bash
set -e

NEXUS_VERSION="3.79.1-04"
NEXUS_HOME="/app/nexus"
SONATYPE_WORK="/app/sonatype-work"

echo "Updating system..."
yum update -y

echo "Installing Java and utilities..."
yum install -y wget tar java-17-amazon-corretto-devel

echo "Creating application directory..."
mkdir -p /app
cd /app

echo "Creating nexus user..."
id nexus >/dev/null 2>&1 || useradd -r -m -s /bin/bash nexus

echo "Downloading Nexus..."
wget -O nexus.tar.gz https://download.sonatype.com/nexus/3/nexus-${NEXUS_VERSION}-linux-x86_64.tar.gz

echo "Extracting Nexus..."
tar -xzf nexus.tar.gz

mv nexus-${NEXUS_VERSION} nexus

echo "Creating sonatype-work directory..."
mkdir -p ${SONATYPE_WORK}

echo "Setting permissions..."
chown -R nexus:nexus /app/nexus
chown -R nexus:nexus ${SONATYPE_WORK}

echo "Configuring Nexus to run as nexus user..."
cat > ${NEXUS_HOME}/bin/nexus.rc <<EOF
run_as_user="nexus"
EOF

chown nexus:nexus ${NEXUS_HOME}/bin/nexus.rc

echo "Configuring kernel settings..."
grep -q vm.max_map_count /etc/sysctl.conf || echo "vm.max_map_count=262144" >> /etc/sysctl.conf
sysctl -p

JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))

echo "Creating systemd service..."

cat > /etc/systemd/system/nexus.service <<EOF
[Unit]
Description=Nexus Repository Manager
After=network.target

[Service]
Type=forking

LimitNOFILE=65536
User=nexus
Group=nexus

Environment=JAVA_HOME=${JAVA_HOME}
Environment=NEXUS_HOME=${NEXUS_HOME}
Environment=RUN_AS_USER=nexus

ExecStart=${NEXUS_HOME}/bin/nexus start
ExecStop=${NEXUS_HOME}/bin/nexus stop

Restart=on-failure
TimeoutStartSec=600
TimeoutStopSec=600

[Install]
WantedBy=multi-user.target
EOF

echo "Reloading systemd..."
systemctl daemon-reload

echo "Enabling Nexus service..."
systemctl enable nexus

echo "Starting Nexus..."
systemctl start nexus

echo "Waiting for Nexus to initialize..."
sleep 60

echo "========================================"
echo "Nexus installation completed"
echo "========================================"

systemctl status nexus --no-pager

echo ""
echo "Initial admin password location:"
echo "/app/sonatype-work/nexus3/admin.password"
echo ""

PUBLIC_IP=$(curl -s http://checkip.amazonaws.com || true)

echo "Nexus URL:"
echo "http://${PUBLIC_IP}:8081"
echo ""
echo "Retrieve admin password with:"
echo "cat /app/sonatype-work/nexus3/admin.password"
