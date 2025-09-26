#!/bin/bash
set -e

echo ">>> Updating system..."
sudo apt-get update -y

echo ">>> Installing Java (OpenJDK 17)..."
sudo apt install openjdk-17-jre-headless -y

echo ">>> Adding Jenkins repository key..."
sudo mkdir -p /etc/apt/keyrings
sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key

echo ">>> Adding Jenkins repo to sources list..."
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] \
https://pkg.jenkins.io/debian-stable binary/" | \
sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

echo ">>> Updating apt and installing Jenkins..."
sudo apt-get update -y
sudo apt-get install jenkins -y

echo ">>> Enabling Jenkins service..."
sudo systemctl enable jenkins
sudo systemctl start jenkins

echo ">>> Installing Docker..."
sudo apt-get update -y
sudo apt install docker.io -y

echo ">>> Adding permissions to Docker socket..."
sudo chown $USER /var/run/docker.sock

echo ">>> Adding users to docker group..."
sudo usermod -aG docker $USER
sudo usermod -aG docker jenkins

echo ">>> Checking Docker installation..."
docker ps

echo ">>> Jenkins and Docker installation completed!"
echo "⚠️ Please log out and log back in for group changes to take effect."
