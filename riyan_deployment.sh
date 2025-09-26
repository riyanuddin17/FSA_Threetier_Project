#!/bin/bash

eval $(minikube docker-env)

# Build images
docker build -t frontend:local Application-Code/frontend
docker build -t backend:local Application-Code/backend

# Create namespace (ignore if exists)
kubectl create namespace three-tier 2>/dev/null || echo "Namespace already exists"

# Apply Database
kubectl apply -f Kubernetes-Manifests-file/Database/

# Kill old port-forwards first
fuser -k 3500/tcp || true
fuser -k 3000/tcp || true

# Apply Backend
kubectl apply -f Kubernetes-Manifests-file/Backend/

# Wait for backend pod to be ready
echo "Waiting for backend pod to be ready..."
kubectl wait --for=condition=Ready pod -l role=backend -n three-tier --timeout=180s

# Start backend port-forward
kubectl port-forward svc/api -n three-tier 3500:3500 --address 0.0.0.0 &

# Get public IP
EC2_PUBLIC_IP=$(curl -s https://checkip.amazonaws.com)
echo "Public IP: $EC2_PUBLIC_IP"

# Update Frontend deployment YAML
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
sed -i "s|<NodeportIP>|$EC2_PUBLIC_IP|g" "$SCRIPT_DIR/Kubernetes-Manifests-file/Frontend/deployment.yaml"

# Apply Frontend
kubectl apply -f Kubernetes-Manifests-file/Frontend/

# Wait for frontend pod to be ready
echo "Waiting for frontend pod to be ready..."
kubectl wait --for=condition=Ready pod -l role=frontend -n three-tier --timeout=180s

# Restart frontend deployment to pick up new backend IP
kubectl rollout restart deployment frontend -n three-tier

sleep 30

# Start frontend port-forward
kubectl port-forward svc/frontend -n three-tier 3000:3000 --address 0.0.0.0 &
