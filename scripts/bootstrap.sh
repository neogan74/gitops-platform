#!/bin/bash

set -e

echo "=========================================="
echo "GitOps Platform Lab - Bootstrap"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check prerequisites
echo "🔍 Checking prerequisites..."
command -v docker >/dev/null 2>&1 || { echo "❌ Docker is not installed. Please install Docker first."; exit 1; }
command -v kind >/dev/null 2>&1 || { echo "❌ Kind is not installed. Please install Kind first."; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "❌ kubectl is not installed. Please install kubectl first."; exit 1; }
command -v helm >/dev/null 2>&1 || { echo "❌ Helm is not installed. Please install Helm first."; exit 1; }
echo "✅ All prerequisites met!"
echo ""

# Create local registry
echo "📦 Step 1/4: Creating local registry..."
./scripts/create-registry.sh
echo ""

# Create Kind cluster
echo "🚀 Step 2/4: Creating Kind cluster..."
kind create cluster --config infrastructure/kind/cluster-config.yaml
kubectl cluster-info --context kind-gitops-platform
echo "✅ Kind cluster created!"
echo ""

# Install ArgoCD
echo "📦 Step 3/4: Installing ArgoCD..."
kubectl create namespace argocd 2>/dev/null || true
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "⏳ Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

kubectl apply -n argocd -f infrastructure/argocd/argocd-cm.yaml
kubectl apply -n argocd -f infrastructure/argocd/argocd-rbac-cm.yaml
kubectl apply -n argocd -f infrastructure/argocd/projects/
kubectl rollout restart deployment/argocd-server -n argocd

echo "✅ ArgoCD installed!"
echo ""

# Install cert-manager
echo "📦 Step 4/4: Installing cert-manager..."
kubectl create namespace cert-manager 2>/dev/null || true
helm repo add jetstack https://charts.jetstack.io 2>/dev/null || true
helm repo update

helm upgrade --install cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --version v1.13.3 \
    --set installCRDs=true \
    --values infrastructure/cert-manager/values.yaml \
    --wait

echo "⏳ Waiting for cert-manager..."
kubectl wait --for=condition=available --timeout=300s deployment/cert-manager -n cert-manager
kubectl apply -f infrastructure/cert-manager/cluster-issuer.yaml

echo "✅ cert-manager installed!"
echo ""

# Install ingress-nginx
echo "📦 Step 5/5: Installing Nginx Ingress..."
kubectl create namespace ingress-nginx 2>/dev/null || true
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx 2>/dev/null || true
helm repo update

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
    --namespace ingress-nginx \
    --version 4.8.3 \
    --values infrastructure/ingress-nginx/values.yaml \
    --wait

echo "⏳ Waiting for ingress controller..."
kubectl wait --namespace ingress-nginx \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=300s

echo "✅ Ingress controller installed!"
echo ""

# Summary
echo "=========================================="
echo "🎉 Bootstrap Complete!"
echo "=========================================="
echo ""
echo "📊 Cluster Status:"
kubectl get nodes
echo ""
echo "📦 Deployed Components:"
echo "  ✅ Kind Cluster (3 nodes)"
echo "  ✅ Local Registry (localhost:5001)"
echo "  ✅ ArgoCD"
echo "  ✅ Cert-Manager"
echo "  ✅ Nginx Ingress"
echo ""
echo "🔑 ArgoCD Admin Password:"
kubectl -n argocd get secret argocd-initial-admin-secret \
    -o jsonpath="{.data.password}" 2>/dev/null | base64 -d && echo
echo ""
echo "📊 Access ArgoCD UI:"
echo "   kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "   Then visit: https://localhost:8080"
echo "   User: admin"
echo ""
echo "Next steps:"
echo "  1. Deploy platform services: kubectl apply -f platform/app-of-apps.yaml"
echo "  2. Deploy demo application: kubectl apply -f applications/app-of-apps.yaml"
echo ""
