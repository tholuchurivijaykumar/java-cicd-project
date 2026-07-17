#!/bin/bash
set -e

echo "============================================="
echo "  CI/CD Pipeline - Full Setup Script"
echo "============================================="

echo "[1/8] Installing Minikube..."
if ! command -v minikube &> /dev/null; then
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    rm -f minikube-linux-amd64
    echo "Minikube installed."
else
    echo "Minikube already installed: $(minikube version --short)"
fi

echo "[2/8] Installing kubectl..."
if ! command -v kubectl &> /dev/null; then
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm -f kubectl
    echo "kubectl installed."
else
    echo "kubectl already installed: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
fi

echo "[3/8] Installing Java 21..."
if ! command -v java &> /dev/null; then
    sudo apt-get update
    sudo apt-get install -y openjdk-21-jdk
    echo "Java installed."
else
    echo "Java already installed: $(java -version 2>&1 | head -1)"
fi

echo "[4/8] Installing Maven..."
if ! command -v mvn &> /dev/null; then
    sudo apt-get update
    sudo apt-get install -y maven
    echo "Maven installed."
else
    echo "Maven already installed: $(mvn -version 2>&1 | head -1)"
fi

echo "[5/8] Installing Docker..."
if ! command -v docker &> /dev/null; then
    sudo apt-get update
    sudo apt-get install -y docker.io
    sudo usermod -aG docker $USER
    echo "Docker installed. Please log out and back in for group changes."
else
    echo "Docker already installed: $(docker --version)"
fi

echo "[6/8] Installing Jenkins..."
if ! command -v jenkins &> /dev/null; then
    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
    echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y jenkins
    sudo systemctl enable jenkins
    sudo systemctl start jenkins
    echo "Jenkins installed and started."
else
    echo "Jenkins already installed."
    sudo systemctl start jenkins 2>/dev/null || true
fi

echo "[7/8] Starting Minikube..."
if ! minikube status | grep -q "Running"; then
    sudo usermod -aG docker $USER 2>/dev/null || true
    minikube start --driver=docker --force 2>/dev/null || minikube start --force
    echo "Minikube started."
else
    echo "Minikube already running."
fi

echo "[8/8] Deploying application to Minikube..."
cd "$(dirname "$0")"
kubectl apply -f kubernetes/deployment.yaml
echo "Application deployed to Minikube!"
echo ""
echo "Waiting for pods to be ready..."
kubectl rollout status deployment/java-cicd-app --timeout=120s

echo ""
echo "============================================="
echo "  SETUP COMPLETE!"
echo "============================================="
echo ""
echo "  Minikube IP: $(minikube ip)"
echo "  App URL: http://$(minikube ip):\$(kubectl get svc java-cicd-app-service -o jsonpath='{.spec.ports[0].nodePort}')/api/hello"
echo ""
echo "  Jenkins: http://localhost:8080"
echo "  Jenkins initial password:"
echo "    sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
echo ""
echo "  DockerHub: vijay14082003/java-cicd-app"
echo ""
echo "  API Endpoints:"
echo "    GET  /api/hello  - Hello message"
echo "    GET  /api/health - Health check"
echo "    GET  /api/info   - App info"
echo "    POST /api/echo   - Echo message"
echo "============================================="
