#!/bin/bash

# mise a jour
sudo apt update && sudo apt upgrade -y

# docker
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done

sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$UBUNTU_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

#docker registry
docker run -d -p 5000:5000 --name registry registry:2

# permission docker pour jenkins
sudo usermod -aG docker $USER
sudo usermod -aG docker jenkins
sudo systemctl restart docker

#jenkins
sudo rm -f /etc/apt/sources.list.d/jenkins.list
sudo rm -f /usr/share/keyrings/jenkins-keyring.asc

# installer jenkins
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# mise ajour puis installer
sudo apt-get update
sudo apt-get install -y jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Créer le dossier de configuration
sudo mkdir -p /var/lib/jenkins/casc_configs

#config jenkins
sudo cp Jenkins/jenkins.yml /var/lib/jenkins/casc_configs/ 
sudo chown jenkins:jenkins /var/lib/jenkins/casc_configs/jenkins.yml

sudo mkdir -p /etc/systemd/system/jenkins.service.d
sudo tee /etc/systemd/system/jenkins.service.d/casc.conf << EOF
[Service]
Environment="CASC_JENKINS_CONFIG=/var/lib/jenkins/casc_configs/jenkins.yml"
EOF

sudo systemctl daemon-reload

# redemarrer jenkins pour appliquer la config
sudo systemctl restart jenkins

# kubernetes
curl -sfL https://get.k3s.io | sh -

# configuaration pour avoir les droit
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config

#langages
sudo apt install -y openjdk-17-jdk nodejs python3 python3-pip build-essential maven

# lance service dokcer
sudo systemctl enable docker
sudo systemctl start docker

#jq
sudo apt install -y jq

#yq
sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
sudo chmod a+x /usr/local/bin/yq

#kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

#traefik
kubectl apply -f Kubernetes/traefik.service.yaml
kubectl apply -f Kubernetes/traefik.deployment.yaml
kubectl apply -f Kubernetes/traefik.rbac.yaml