#!/bin/bash
set -euo pipefail

echo "=== Installing prerequisites ==="
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg

echo "=== Configuring Docker repository ==="

# GPG key
sudo install -m 0755 -d /etc/apt/keyrings

if [ ! -f /etc/apt/keyrings/docker.asc ]; then
    echo "Installing Docker GPG key..."
    sudo curl -fsSL \
        https://download.docker.com/linux/ubuntu/gpg \
        -o /etc/apt/keyrings/docker.asc
fi

sudo chmod a+r /etc/apt/keyrings/docker.asc

# Docker repository
UBUNTU_CODENAME=$(
    . /etc/os-release
    echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}"
)

ARCH=$(dpkg --print-architecture)

sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: ${UBUNTU_CODENAME}
Components: stable
Architectures: ${ARCH}
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt-get update

echo "=== Installing Docker Engine ==="

sudo apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

echo "=== Enabling Docker service ==="

sudo systemctl enable --now docker

echo "=== Configuring Docker group ==="

# Only add the user if they aren't already a member.
if ! id -nG "$USER" | grep -qw docker; then
    echo "Adding $USER to docker group..."
    sudo usermod -aG docker "$USER"

    echo "NOTE: Log out/in (or restart WSL) for docker group changes to take effect."
else
    echo "$USER is already in the docker group."
fi

echo "=== Installing Minikube ==="

MINIKUBE_VERSION=$(curl -fsSL https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64.sha256 | awk '{print $1}' 2>/dev/null || true)

INSTALL_MINIKUBE=true

if command -v minikube >/dev/null 2>&1; then
    CURRENT_MINIKUBE=$(minikube version --short 2>/dev/null || true)

    if [ -n "$CURRENT_MINIKUBE" ]; then
        echo "Minikube already installed: $CURRENT_MINIKUBE"
        INSTALL_MINIKUBE=false
    fi
fi

if [ "$INSTALL_MINIKUBE" = true ]; then
    echo "Installing latest Minikube..."

    TMP_DIR=$(mktemp -d)
    trap 'rm -rf "$TMP_DIR"' EXIT

    curl -fsSL \
        https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64 \
        -o "$TMP_DIR/minikube"

    sudo install \
        -m 0755 \
        "$TMP_DIR/minikube" \
        /usr/local/bin/minikube

    rm -rf "$TMP_DIR"
    trap - EXIT
fi

echo "=== Installing kubectl ==="

INSTALL_KUBECTL=true

if command -v kubectl >/dev/null 2>&1; then
    CURRENT_KUBECTL=$(kubectl version --client --output=json 2>/dev/null || true)

    if [ -n "$CURRENT_KUBECTL" ]; then
        echo "kubectl already installed."
        INSTALL_KUBECTL=false
    fi
fi

if [ "$INSTALL_KUBECTL" = true ]; then
    echo "Installing latest stable kubectl..."

    KUBECTL_VERSION=$(
        curl -fsSL https://dl.k8s.io/release/stable.txt
    )

    TMP_DIR=$(mktemp -d)
    trap 'rm -rf "$TMP_DIR"' EXIT

    curl -fsSL \
        "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
        -o "$TMP_DIR/kubectl"

    sudo install \
        -o root \
        -g root \
        -m 0755 \
        "$TMP_DIR/kubectl" \
        /usr/local/bin/kubectl

    rm -rf "$TMP_DIR"
    trap - EXIT
fi

echo ""
echo "========================================================"
echo " Installation complete!"
echo "========================================================"
echo ""

echo "Docker:"
docker --version

echo ""
echo "Minikube:"
minikube version --short

echo ""
echo "kubectl:"
kubectl version --client --short 2>/dev/null || kubectl version --client

echo ""
echo "========================================================"

if id -nG "$USER" | grep -qw docker; then
    echo "Docker group: configured"
else
    echo "Docker group: newly added."
    echo "Please log out and back in (or restart WSL)."
fi

echo ""
echo "Then run:"
echo ""
echo "    minikube start --driver=docker"
echo ""
echo "========================================================"
