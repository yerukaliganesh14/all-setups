#!/bin/bash

set -e

echo "=========================================="
echo " Updating Ubuntu packages"
echo "=========================================="
apt update -y
apt upgrade -y

echo "=========================================="
echo " Installing prerequisites"
echo "=========================================="
apt install -y \
    curl \
    wget \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    conntrack

echo "=========================================="
echo " Installing Docker"
echo "=========================================="
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

systemctl enable docker
systemctl start docker

echo "=========================================="
echo " Installing Minikube"
echo "=========================================="
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

chmod +x minikube-linux-amd64
mv minikube-linux-amd64 /usr/local/bin/minikube

echo "=========================================="
echo " Installing kubectl"
echo "=========================================="
K8S_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)

curl -LO "https://dl.k8s.io/release/${K8S_VERSION}/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/release/${K8S_VERSION}/bin/linux/amd64/kubectl.sha256"

echo "$(cat kubectl.sha256) kubectl" | sha256sum --check

install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

rm -f kubectl kubectl.sha256 get-docker.sh

echo "=========================================="
echo " Installed Versions"
echo "=========================================="
docker --version
kubectl version --client
minikube version

echo "=========================================="
echo " Starting Minikube"
echo "=========================================="

minikube start \
    --driver=docker \
    --cpus=2 \
    --memory=4096 \
    --disk-size=20g \
    --force

echo "=========================================="
echo " Cluster Status"
echo "=========================================="

minikube status

echo
kubectl get nodes

echo
kubectl get pods -A

echo
echo "=========================================="
echo " Minikube installation completed successfully!"
echo "=========================================="
