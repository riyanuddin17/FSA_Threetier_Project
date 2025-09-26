#!/usr/bin/env bash
set -euo pipefail

echo "=== Starting KOPS Setup on Amazon Linux ==="

# 1) Prerequisites
echo ">>> Installing prerequisites..."
sudo yum -y install unzip jq git tar

# 2) AWS CLI v2
echo ">>> Installing AWS CLI v2..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip
aws --version

# 3) kOps
echo ">>> Installing kOps v1.28.4..."
curl -LO https://github.com/kubernetes/kops/releases/download/v1.28.4/kops-linux-amd64
chmod +x kops-linux-amd64
sudo mv kops-linux-amd64 /usr/local/bin/kops
kops version

# 4) Create S3 bucket (for kOps state store)
echo ">>> Creating S3 bucket: riyansbucketkops..."
aws s3 mb s3://riyansbucketkops
aws s3 ls
export KOPS_STATE_STORE=s3://riyansbucketkops

# 5) kubectl
echo ">>> Installing kubectl v1.29.2..."
sudo curl --silent --location -o /usr/local/bin/kubectl \
  https://dl.k8s.io/release/v1.29.2/bin/linux/amd64/kubectl
sudo chmod +x /usr/local/bin/kubectl
kubectl version --client

# 6) SSH keygen (if not exists)
if [ ! -f "$HOME/.ssh/id_rsa.pub" ]; then
  echo ">>> Generating SSH key..."
  ssh-keygen -t rsa -b 4096
else
  echo "SSH key already exists at ~/.ssh/id_rsa.pub"
fi

# 7) Create Kubernetes cluster
echo ">>> Creating Kubernetes cluster (this may take several minutes)..."
kops create cluster \
  --name=test.k8s.local \
  --zones=us-east-1a,us-east-1b \
  --node-count=2 \
  --node-size=t3.medium \
  --master-size=t3.medium \
  --node-volume-size=20 \
  --master-volume-size=20 \
  --yes


# 8) Export kubeconfig so kubectl can talk to API server
echo ">>> Exporting kubeconfig for kubectl..."
kops export kubeconfig --admin --name test.k8s.local

echo "=== KOPS Setup Completed Successfully ==="
