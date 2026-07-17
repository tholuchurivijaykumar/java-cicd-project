#!/bin/bash
set -e

echo "============================================="
echo "  FULL CI/CD AUTOMATION SETUP"
echo "============================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

JENKINS_URL="http://localhost:8080"
CLI_JAR="/tmp/jenkins-cli.jar"
PROJECT_DIR="/home/vijay-chowdary/java-cicd-project"

# ---- Step 1: Install dependencies ----
echo -e "${YELLOW}[Step 1/8] Checking dependencies...${NC}"

check_install() {
    if ! command -v $1 &> /dev/null; then
        echo "Installing $1..."
        $2
        echo -e "${GREEN}$1 installed${NC}"
    else
        echo -e "${GREEN}$1 already installed${NC}"
    fi
}

check_install java "sudo apt-get update && sudo apt-get install -y openjdk-21-jdk"
check_install mvn "sudo apt-get install -y maven"
check_install docker "sudo apt-get install -y docker.io"
check_install minikube "curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm -f minikube-linux-amd64"
check_install kubectl "curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl && sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && rm -f kubectl"

# ---- Step 2: Start Docker ----
echo ""
echo -e "${YELLOW}[Step 2/8] Starting Docker...${NC}"
if ! docker info &> /dev/null; then
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker $USER
fi
echo -e "${GREEN}Docker is running${NC}"

# ---- Step 3: Start Minikube ----
echo ""
echo -e "${YELLOW}[Step 3/8] Starting Minikube...${NC}"
if minikube status 2>/dev/null | grep -q "Running"; then
    echo -e "${GREEN}Minikube already running${NC}"
else
    minikube delete 2>/dev/null || true
    minikube start --driver=docker --force 2>&1 | tail -3
    echo -e "${GREEN}Minikube started${NC}"
fi

# ---- Step 4: Build Java App ----
echo ""
echo -e "${YELLOW}[Step 4/8] Building Java application...${NC}"
cd "$PROJECT_DIR"
mvn clean package -DskipTests -B 2>&1 | tail -3
echo -e "${GREEN}Build successful${NC}"

# ---- Step 5: Build Docker Image ----
echo ""
echo -e "${YELLOW}[Step 5/8] Building Docker image...${NC}"
docker build -t vijay14082003/java-cicd-app:1.0.0 . 2>&1 | tail -3
docker tag vijay14082003/java-cicd-app:1.0.0 vijay14082003/java-cicd-app:latest
echo -e "${GREEN}Docker image built${NC}"

# ---- Step 6: Deploy to Minikube ----
echo ""
echo -e "${YELLOW}[Step 6/8] Deploying to Minikube...${NC}"
minikube image load vijay14082003/java-cicd-app:latest
kubectl apply -f kubernetes/deployment.yaml
kubectl rollout status deployment/java-cicd-app --timeout=120s
echo -e "${GREEN}Deployed to Minikube${NC}"

# ---- Step 7: Verify ----
echo ""
echo -e "${YELLOW}[Step 7/8] Verifying deployment...${NC}"
SERVICE_URL=$(minikube service java-cicd-app-service --url 2>/dev/null)
echo -e "${GREEN}Application URL: ${SERVICE_URL}${NC}"
curl -s "${SERVICE_URL}/api/hello" | python3 -m json.tool 2>/dev/null || curl -s "${SERVICE_URL}/api/hello"
echo ""
curl -s "${SERVICE_URL}/api/health" | python3 -m json.tool 2>/dev/null || curl -s "${SERVICE_URL}/api/health"

# ---- Step 8: Push to DockerHub ----
echo ""
echo -e "${YELLOW}[Step 8/8] Pushing to DockerHub...${NC}"
echo -e "${RED}NOTE: Your DockerHub password may need updating.${NC}"
echo -e "${RED}If push fails, update password at: https://hub.docker.com/settings/security${NC}"
echo "Vijay@1422" | docker login -u vijay14082003 --password-stdin 2>&1 && \
docker push vijay14082003/java-cicd-app:1.0.0 2>&1 && \
docker push vijay14082003/java-cicd-app:latest 2>&1 && \
echo -e "${GREEN}Pushed to DockerHub${NC}" || \
echo -e "${RED}DockerHub push failed - check credentials${NC}"

echo ""
echo "============================================="
echo -e "${GREEN}  CI/CD SETUP COMPLETE!${NC}"
echo "============================================="
echo ""
echo "  Application Endpoints:"
echo "    GET  /api/hello  - Hello message"
echo "    GET  /api/health - Health check"
echo "    GET  /api/info   - App info"
echo "    POST /api/echo   - Echo message"
echo ""
echo "  Minikube:  $(minikube service java-cicd-app-service --url 2>/dev/null)"
echo "  Jenkins:   http://localhost:8080"
echo ""
echo "============================================="
echo "  JENKINS SETUP (Manual Steps)"
echo "============================================="
echo ""
echo "  1. Open: http://localhost:8080"
echo "  2. Get admin password:"
echo "     sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
echo "  3. Install 'Pipeline' and 'Git' plugins"
echo "  4. Create credentials:"
echo "     - ID: dockerhub-creds (Username/Password)"
echo "       Username: vijay14082003"
echo "       Password: <your-dockerhub-password>"
echo "     - ID: github-creds (Username/Password)"
echo "       Username: tholuchurivijaykumar"
echo "       Password: <your-github-pat>"
echo "  5. Create Pipeline job 'java-cicd-pipeline':"
echo "     - Pipeline script from SCM"
echo "     - Git URL: https://github.com/tholuchurivijaykumar/java-cicd-project.git"
echo "     - Branch: */main"
echo "     - Script Path: Jenkinsfile"
echo "  6. Enable 'Build periodically' cron: H/2 * * * *"
echo "  7. Click 'Build Now'"
echo ""
echo "============================================="
