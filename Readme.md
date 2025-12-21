# GitOps Platform Lab - Complete Implementation Guide

## Table of Contents

1. [Project Overview](#project-overview)
1. [Portfolio Strategy](#portfolio-strategy)
1. [Project 1: GitOps Platform Lab](#project-1-gitops-platform-lab)
1. [Project 2: CI/CD Platform Templates](#project-2-cicd-platform-templates)
1. [Project 3: SRE Toolkit](#project-3-sre-toolkit)
1. [Week 1: Foundation](#week-1-foundation-days-1-7)
1. [Week 2: Observability Stack](#week-2-observability-stack---logging--tracing)

-----

# Project Overview

## 🎯 Общая стратегия портфолио

Цель портфолио: Показать переход Senior Go Backend → Staff Engineer / Platform Engineer

Ключевые сигналы для работодателей:

- Системное мышление (не просто код, а архитектура)
- Production-ready подход (observability, security, reliability)
- Platform engineering mindset (инструменты для других команд)
- SRE practices (automation, monitoring, incident response)

Философия: Портфолио должно держаться на 3–4 сильных проектах, а не на 20 мелких.

-----

# Portfolio Strategy

## 📋 Рекомендованный набор проектов

### 🔹 Проект 1. GitOps + Kubernetes Platform

Цель: показать, что ты platform / SRE

Состав:

- Kubernetes (kind / k3s)
- Argo CD
- Helm
- Canary / Blue-Green
- TLS (cert-manager)
- Observability

Репозиторий: gitops-platform-lab

-----

### 🔹 Проект 2. CI/CD Platform Templates

Цель: показать мышление платформенного инженера

Состав:

- GitLab CI templates или GitHub Actions
- Go / Kotlin / Docker
- Reusable pipelines
- Security, caching, stages

Репозиторий: cicd-templates-platform

-----

### 🔹 Проект 3. SRE Tool / Go Utility

Цель: показать, что ты не просто YAML-инженер

Примеры:

- CLI для проверки Kubernetes
- Tool для анализа алертов
- Chaos / load generator
- Config linter

Репозиторий: sre-toolkit-go

-----

## 📊 Timeline Overview
Month 1: GitOps Platform Lab        [████████████] 100%
Month 2: CI/CD Templates            [████████████] 100%
Month 3: SRE Toolkit                [████████████] 100%
Month 4: Polish, Documentation      [████████████] 100%

-----

## 🎯 Критерии готовности портфолио

### Must Have

- [ ] Все 3 проекта завершены
- [ ] README с архитектурой и screenshots
- [ ] Работающие demos (видео/gif)
- [ ] Production-grade code quality
- [ ] Comprehensive documentation

### Nice to Have

- [ ] Blog posts about learnings
- [ ] Conference talk materials
- [ ] Community contributions (PRs, issues)
- [ ] YouTube walkthrough videos

-----

# Project 1: GitOps Platform Lab

## 🎯 Цели проекта

Для работодателя:

- Показать platform engineering мышление
- Демонстрация production-ready подхода
- Понимание GitOps principles и best practices
- Опыт с современным cloud-native stack

Для тебя:

- Глубокое понимание ArgoCD и GitOps workflow
- Hands-on с observability stack
- Опыт с progressive delivery
- Материал для tech talks и статей

-----

## 📐 High-Level Architecture
┌─────────────────────────────────────────────────────────────┐
│                      Git Repository                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │Infrastructure│  │  Platform    │  │ Applications │     │
│  │   (Bootstrap)│  │  (Services)  │  │  (Workloads) │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ GitOps Sync
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                   Kubernetes Cluster (Kind)                  │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │                   Control Plane                         │ │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐            │ │
│  │  │ ArgoCD   │  │Cert-Mgr  │  │  Nginx   │            │ │
│  │  │          │  │          │  │ Ingress  │            │ │
│  │  └──────────┘  └──────────┘  └──────────┘            │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              Platform Services Layer                    │ │
│  │                                                         │ │
│  │  ┌─────────────────┐        ┌─────────────────┐       │ │
│  │  │  Observability  │        │    Security     │       │ │
│  │  │  ┌───────────┐  │        │  ┌───────────┐  │       │ │
│  │  │  │Prometheus │  │        │  │   Falco   │  │       │ │
│  │  │  │   Loki    │  │        │  │   Trivy   │  │       │ │
│  │  │  │   Tempo   │  │        │  │  Policies │  │       │ │
│  │  │  │  Grafana  │  │        │  └───────────┘  │       │ │
│  │  │  └───────────┘  │        └─────────────────┘       │ │
│  │  └─────────────────┘                                   │ │
│  │                                                         │ │
│  │  ┌─────────────────┐        ┌─────────────────┐       │ │
│  │  │   Service Mesh  │        │ Progressive     │       │ │
│  │  │  ┌───────────┐  │        │   Delivery      │       │ │
│  │  │  │  Istio    │  │        │  ┌───────────┐  │       │ │
│  │  │  │  Ambient  │  │        │  │   Argo    │  │       │ │
│  │  │  │   Mode    │  │        │  │  Rollouts │  │       │ │
│  │  │  └───────────┘  │        │  └───────────┘  │       │ │
│  │  └─────────────────┘        └─────────────────┘       │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              Application Layer                          │ │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐             │ │
│  │  │Demo App  │  │Demo App  │  │Demo App  │             │ │
│  │  │  (Dev)   │  │(Staging) │  │  (Prod)  │             │ │
│  │  └──────────┘  └──────────┘  └──────────┘             │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘

-----

## 🗂️ Repository Structure - Final
gitops-platform-lab/
├── README.md                          # Главная документация
├── Makefile                           # Автоматизация всех операций
├── .github/
│   └── workflows/
│       ├── validate-manifests.yml     # Pre-commit validation
│       └── sync-check.yml             # ArgoCD sync status
│
├── infrastructure/                    # Bootstrap layer
│   ├── kind/
│   │   ├── cluster-config.yaml        # Multi-node, ingress-ready
│   │   └── registry-config.yaml       # Local registry
│   ├── argocd/
│   │   ├── install.yaml               # ArgoCD installation
│   │   ├── argocd-cm.yaml            # Config (repo, notifications)
│   │   ├── argocd-rbac-cm.yaml       # RBAC settings
│   │   └── projects/
│   │       ├── platform.yaml          # Platform project
│   │       └── applications.yaml      # Apps project
│   ├── cert-manager/
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── cluster-issuer.yaml        # Self-signed issuer
│   └── ingress-nginx/
│       ├── Chart.yaml
│       └── values.yaml
│
├── platform/                          # Platform services
│   ├── app-of-apps.yaml              # Root ArgoCD application
│   │
│   ├── observability/
│   │   ├── kube-prometheus-stack/
│   │   │   ├── Chart.yaml
│   │   │   ├── values.yaml           # Custom scrape configs
│   │   │   └── servicemonitors/
│   │   │       └── custom-metrics.yaml
│   │   ├── loki/
│   │   │   ├── Chart.yaml
│   │   │   ├── values.yaml
│   │   │   └── datasource.yaml       # Grafana datasource
│   │   ├── tempo/
│   │   │   ├── Chart.yaml
│   │   │   ├── values.yaml
│   │   │   └── datasource.yaml
│   │   ├── opentelemetry-collector/
│   │   │   ├── Chart.yaml
│   │   │   └── values.yaml           # OTLP receiver config
│   │   └── grafana-dashboards/
│   │       ├── slo-dashboard.json
│   │       ├── golden-signals.json
│   │       ├── kubernetes-cluster.json
│   │       └── application-metrics.json
│   │
│   ├── service-mesh/
│   │   ├── istio-base/
│   │   │   ├── Chart.yaml
│   │   │   └── values.yaml
│   │   ├── istiod/
│   │   │   ├── Chart.yaml
│   │   │   └── values.yaml           # Ambient mode
│   │   ├── istio-cni/
│   │   │   ├── Chart.yaml
│   │   │   └── values.yaml
│   │   └── ztunnel/                  # Ambient mode proxy
│   │       ├── Chart.yaml
│   │       └── values.yaml
│   │
│   ├── progressive-delivery/
│   │   ├── argo-rollouts/
│   │   │   ├── Chart.yaml
│   │   │   ├── values.yaml
│   │   │   └── dashboard-ingress.yaml
│   │   └── analysis-templates/
│   │       ├── success-rate.yaml
│   │       ├── latency-p95.yaml
│   │       └── error-rate.yaml
│   │
│   └── security/
│       ├── falco/
│       │   ├── Chart.yaml
│       │   ├── values.yaml
│       │   └── rules/
│       │       └── custom-rules.yaml
│       ├── trivy-operator/
│       │   ├── Chart.yaml
│       │   └── values.yaml
│       ├── pod-security-standards/
│       │   ├── baseline.yaml
│       │   └── restricted.yaml
│       └── network-policies/
│           ├── default-deny.yaml
│           └── allow-monitoring.yaml
│
├── applications/                      # Application workloads
│   ├── app-of-apps.yaml              # Apps root application
│   │
│   └── demo-app/
│       ├── base/
│       │   ├── kustomization.yaml
│       │   ├── deployment.yaml
│       │   ├── service.yaml
│       │   ├── servicemonitor.yaml
│       │   └── ingress.yaml
│       ├── overlays/
│       │   ├── dev/
│       │   │   ├── kustomization.yaml
│       │   │   ├── patch-replicas.yaml
│       │   │   └── patch-resources.yaml
│       │   ├── staging/
│       │   │   ├── kustomization.yaml
│       │   │   └── rollout.yaml      # Canary strategy
│       │   └── production/
│       │       ├── kustomization.yaml
│       │       ├── rollout.yaml      # Blue-Green strategy
│       │       └── hpa.yaml
│       └── src/                       # Demo app source
│           ├── main.go               # Simple Go HTTP server
│           ├── Dockerfile
│           └── Makefile
│
├── docs/
│   ├── architecture.md               # Detailed architecture
│   ├── setup-guide.md                # Step-by-step setup
│   ├── gitops-workflow.md            # GitOps principles used
│   ├── observability.md              # Monitoring guide
│   ├── progressive-delivery.md       # Deployment strategies
│   ├── disaster-recovery.md          # Backup/restore procedures
│   └── runbooks/
│       ├── argocd-sync-failure.md
│       ├── pod-crashloop.md
│       └── certificate-renewal.md
│
├── scripts/
│   ├── bootstrap.sh                  # Full cluster bootstrap
│   ├── validate-manifests.sh         # Pre-deploy validation
│   ├── backup-argocd.sh             # Backup ArgoCD state
│   └── load-test.sh                 # Generate traffic
│
└── tests/
    ├── integration/
    │   └── deployment_test.go        # Test deployments
    └── e2e/
        └── gitops_workflow_test.go   # End-to-end tests

-----

## 🚀 Ключевые Features

### 1. Progressive Delivery
# Argo Rollouts с автоматическим анализом
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: demo-app
spec:
  strategy:
    canary:
      analysis:
        templates:
        - templateName: success-rate
        - templateName: latency-p95
      steps:
      - setWeight: 20
      - pause: {duration: 5m}
      - setWeight: 50
      - pause: {duration: 5m}

### 2. Full Observability Stack

- Metrics: Prometheus + Thanos (long-term storage)
- Logs: Loki + promtail
- Traces: Tempo + OpenTelemetry collector
- Dashboards: Grafana with pre-built SLO dashboards

### 3. Security Baseline

- Pod Security Standards
- Network Policies
- Image scanning (Trivy)
- Runtime security (Falco)
- Secret management (External Secrets Operator)

### 4. Self-Healing
# Custom HPA с custom metrics
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
spec:
  metrics:
  - type: Pods
    pods:
      metric:
        name: http_requests_per_second
      target:
        type: AverageValue
        averageValue: "1000"

-----

# Week 1: Foundation (Days 1-7)

## Day 1-2: Cluster Setup & Bootstrap

### Задачи

1.

Kind cluster с ingress и local registry
1. ArgoCD installation
1. Cert-manager setup
1. Basic ingress controller

### Kind Cluster Config
# infrastructure/kind/cluster-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: gitops-platform
nodes:
  - role: control-plane
    kubeadmConfigPatches:
    - |
      kind: InitConfiguration
      nodeRegistration:
        kubeletExtraArgs:
          node-labels: "ingress-ready=true"
    extraPortMappings:
    - containerPort: 80
      hostPort: 80
      protocol: TCP
    - containerPort: 443
      hostPort: 443
      protocol: TCP
  - role: worker
  - role: worker
networking:
  podSubnet: "10.244.0.0/16"
  serviceSubnet: "10.96.0.0/16"
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:5001"]
    endpoint = ["http://kind-registry:5000"]

### Makefile (начальная версия)
.PHONY: help
help: ## Show this help
 @grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: create-cluster
create-cluster: ## Create Kind cluster with local registry
 @echo "🚀 Creating Kind cluster..."
 ./scripts/create-registry.sh
 kind create cluster --config infrastructure/kind/cluster-config.yaml
 kubectl cluster-info --context kind-gitops-platform

.PHONY: delete-cluster
delete-cluster: ## Delete Kind cluster
 @echo "🗑️  Deleting Kind cluster..."
 kind delete cluster --name gitops-platform
 docker stop kind-registry && docker rm kind-registry

.PHONY: install-argocd
install-argocd: ## Install ArgoCD
 @echo "📦 Installing ArgoCD..."
 kubectl create namespace argocd || true
 kubectl apply -n argocd -f infrastructure/argocd/install.yaml
 kubectl apply -n argocd -f infrastructure/argocd/argocd-cm.yaml
 kubectl apply -n argocd -f infrastructure/argocd/argocd-rbac-cm.yaml
 @echo "⏳ Waiting for ArgoCD to be ready..."
 kubectl wait --for=condition=available --timeout=300s \
  deployment/argocd-server -n argocd
 @echo "✅ ArgoCD installed!"
 @echo "🔑 Admin password:"
 @kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo

.PHONY: install-cert-manager
install-cert-manager: ## Install cert-manager
 @echo "📦 Installing cert-manager..."
 kubectl create namespace cert-manager || true
 helm repo add jetstack https://charts.jetstack.io
 helm repo update
 helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --version v1.13.0 \
  --set installCRDs=true \
  --values infrastructure/cert-manager/values.yaml
 @echo "⏳ Waiting for cert-manager..."
 kubectl wait --for=condition=available --timeout=300s \
  deployment/cert-manager -n cert-manager
 kubectl apply -f infrastructure/cert-manager/cluster-issuer.yaml
 @echo "✅ cert-manager installed!"

.PHONY: install-ingress
install-ingress: ## Install Nginx Ingress Controller
 @echo "📦 Installing Nginx Ingress..."
 helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
 helm repo update
 helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --values infrastructure/ingress-nginx/values.yaml
 @echo "⏳ Waiting for ingress controller..."
 kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s
 @echo "✅ Ingress controller installed!"

.PHONY: bootstrap
bootstrap: create-cluster install-argocd install-cert-manager install-ingress ## Full cluster bootstrap
 @echo "🎉 Bootstrap complete!"
 @echo ""
 @echo "📊 Access ArgoCD UI:"
 @echo "   URL: https://argocd.local (add to /etc/hosts)"
 @echo "   User: admin"
 @echo "   Password: run 'make argocd-password'"
 @echo ""
 @echo "Next steps:"
 @echo "  1. Deploy platform services: make deploy-platform"
 @echo "  2. Deploy demo application: make deploy-apps"

.PHONY: argocd-password
argocd-password: ## Get ArgoCD admin password
 @kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo

### ArgoCD Configuration
# infrastructure/argocd/argocd-cm.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cm
  namespace: argocd
data:
  # Repository credentials
  repositories: |
    - url: https://github.com/yourusername/gitops-platform-lab.git
      type: git
  
  # Resource customizations
  resource.customizations: |
    argoproj.io/Rollout:
      health.lua: |
        hs = {}
        if obj.status ~= nil then
          if obj.status.phase == "Degraded" then
            hs.status = "Degraded"
            hs.message = obj.status.message
            return hs
          end
          if obj.status.phase == "Progressing" then
            hs.status = "Progressing"
            hs.message = obj.status.message
            return hs
          end
        end
        hs.status = "Healthy"
        return hs
  
  # Webhook configurations (for GitLab/GitHub)
  webhook.github.secret: webhook-secret
  
  # UI customizations
  ui.bannercontent: "🚀 GitOps Platform Lab - Demo Environment"
  ui.bannerurl: "https://github.com/yourusername/gitops-platform-lab"

### Scripts
#!/bin/bash
# scripts/create-registry.sh

set -o errexit

# Create registry container unless it already exists
reg_name='kind-registry'
reg_port='5001'

if [ "$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)" != 'true' ]; then
  docker run \
    -d --restart=always -p "127.0.0.1:${reg_port}:5000" --name "${reg_name}" \
    registry:2
fi

# Connect the registry to the kind network
if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' "${reg_name}")" = 'null' ]; then
  docker network connect "kind" "${reg_name}"
fi

# Document the local registry
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${reg_port}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF

### Deliverables Week 1

- ✅ Working Kind cluster
- ✅ ArgoCD UI accessible
- ✅ Cert-manager issuing certificates
- ✅ Ingress controller routing traffic
- ✅ make bootstrap command работает

-----

## Day 3-4: Basic Monitoring Setup

### Задачи

1. kube-prometheus-stack deployment
1. Grafana dashboards
1. Basic ServiceMonitors

### Prometheus Stack Values
# platform/observability/kube-prometheus-stack/values.yaml
prometheus:
  prometheusSpec:
    retention: 7d
    storageSpec:
      volumeClaimTemplate:
        spec:
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 10Gi
    
    # Additional scrape configs
    additionalScrapeConfigs:
    - job_name: 'demo-app'
      kubernetes_sd_configs:
      - role: pod
      relabel_configs:
      - source_labels: [__meta_kubernetes_pod_label_app]
        action: keep
        regex: demo-app

grafana:
  enabled: true
  adminPassword: admin # Change in production!
  
  ingress:
    enabled: true
    ingressClassName: nginx
    hosts:
      - grafana.local
    tls:
    - secretName: grafana-tls
      hosts:
        - grafana.local
  
  # Datasources
  additionalDataSources:
  - name: Loki
    type: loki
    url: http://loki:3100
    access: proxy
  - name: Tempo
    type: tempo
    url: http://tempo:3100
    access: proxy
  
  # Pre-installed dashboards
  dashboardProviders:
    dashboardproviders.yaml:
      apiVersion: 1
      providers:
      - name: 'default'
        orgId: 1
        folder: 'Platform'
        type: file
        disableDeletion: false
        options:
          path: /var/lib/grafana/dashboards/default
  
  dashboards:
    default:
      kubernetes-cluster:
        gnetId: 7249
        revision: 1
        datasource: Prometheus
      node-exporter:
        gnetId: 1860
        revision: 27
        datasource: Prometheus

alertmanager:
  enabled: true
  config:
    route:
      group_by: ['alertname', 'cluster']
      group_wait: 10s
      group_interval: 10s
      repeat_interval: 12h
      receiver: 'null'
    receivers:
    - name: 'null'

### ArgoCD Application для Monitoring

# platform/observability/kube-prometheus-stack/application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: kube-prometheus-stack
  namespace: argocd
spec:
  project: platform
  source:
    repoURL: https://prometheus-community.github.io/helm-charts
    chart: kube-prometheus-stack
    targetRevision: 51.0.0
    helm:
      valueFiles:
      - values.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: monitoring
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true

-----

## Day 5-7: App of Apps Pattern

### Root Application
# platform/app-of-apps.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: platform-services
  namespace: argocd
  finalizers:
  - resources-finalizer.argocd.argoproj.io
spec:
  project: platform
  source:
    repoURL: https://github.com/yourusername/gitops-platform-lab.git
    targetRevision: main
    path: platform
    directory:
      recurse: true
      jsonnet: {}
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true

### Makefile additions
.PHONY: deploy-platform
deploy-platform: ## Deploy platform services via ArgoCD
 @echo "🚀 Deploying platform services..."
 kubectl apply -f platform/app-of-apps.yaml
 @echo "✅ Platform services deployed!"
 @echo "📊 Check status: kubectl get applications -n argocd"

.PHONY: deploy-apps
deploy-apps: ## Deploy demo applications
 @echo "🚀 Deploying applications..."
 kubectl apply -f applications/app-of-apps.yaml
 @echo "✅ Applications deployed!"

.PHONY: status
status: ## Show ArgoCD applications status
 @kubectl get applications -n argocd

-----

# Week 2: Observability Stack - Logging & Tracing

## 🎯 Цели Week 2

Результат:

- Централизованный сбор логов (Loki)
- Distributed tracing (Tempo)
- OpenTelemetry collector для метрик/логов/трейсов
- Unified Grafana dashboards с корреляцией данных
- Demo app с полной observability

-----

## 📊 Day 8-9: Loki Stack

### Architecture
┌─────────────┐
│   Pods      │
│  (Apps)     │
└──────┬──────┘
       │ stdout/stderr
       ▼
┌─────────────┐
│  Promtail   │ ◄─── DaemonSet на каждой ноде
│  (Agent)    │
└──────┬──────┘
       │ Push logs
       ▼
┌─────────────┐
│    Loki     │ ◄─── Centralized log aggregation
│  (Server)   │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Grafana   │ ◄─── Query & visualize
└─────────────┘

### Loki Configuration
# platform/observability/loki/values.yaml
loki:
  auth_enabled: false
  
  commonConfig:
    replication_factor: 1
  
  storage:
    type: 'filesystem'
    filesystem:
      chunks_directory: /var/loki/chunks
      rules_directory: /var/loki/rules
  
  schemaConfig:
    configs:
      - from: 2023-01-01
        store: boltdb-shipper
        object_store: filesystem
        schema: v11
        index:
          prefix: loki_index_
          period: 24h
  
  limits_config:
    enforce_metric_name: false
    reject_old_samples: true
    reject_old_samples_max_age: 168h
    max_cache_freshness_per_query: 10m
    split_queries_by_interval: 15m
    retention_period: 744h  # 31 days
  
  # Compactor для очистки старых данных
  compactor:
    working_directory: /var/loki/compactor
    shared_store: filesystem
    compaction_interval: 10m
    retention_enabled: true
    retention_delete_delay: 2h
    retention_delete_worker_count: 150

# Promtail configuration
promtail:
  enabled: true
  
  config:
    clients:
      - url: http://loki:3100/loki/api/v1/push
    
    positions:
      filename: /tmp/positions.yaml
    
    scrape_configs:
      # Kubernetes pods logs
      - job_name: kubernetes-pods
        kubernetes_sd_configs:
          - role: pod
        
        relabel_configs:
          # Drop logs from specific namespaces
          - source_labels: [__meta_kubernetes_namespace]
            regex: kube-system
            action: drop
          
          # Add namespace label
          - source_labels: [__meta_kubernetes_namespace]

target_label: namespace
          
          # Add pod name label
          - source_labels: [__meta_kubernetes_pod_name]
            target_label: pod
          
          # Add container name label
          - source_labels: [__meta_kubernetes_pod_container_name]
            target_label: container
          
          # Add app label
          - source_labels: [__meta_kubernetes_pod_label_app]
            target_label: app
          
          # Add environment label (if exists)
          - source_labels: [__meta_kubernetes_pod_label_environment]
            target_label: environment
        
        # Pipeline stages для парсинга логов
        pipeline_stages:
          # Парсинг JSON logs
          - json:
              expressions:
                level: level
                message: msg
                timestamp: ts
          
          # Extract timestamp
          - timestamp:
              source: timestamp
              format: RFC3339
          
          # Labels из parsed fields
          - labels:
              level:
          
          # Output только message
          - output:
              source: message

  # Resources
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 200m
      memory: 256Mi

# Single Binary deployment для demo
singleBinary:
  replicas: 1
  persistence:
    enabled: true
    size: 10Gi
  
  resources:
    requests:
      cpu: 200m
      memory: 512Mi
    limits:
      cpu: 1000m
      memory: 2Gi

# Gateway (optional, для production)
gateway:
  enabled: false

### ArgoCD Application для Loki
# platform/observability/loki/application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: loki
  namespace: argocd
spec:
  project: platform
  source:
    repoURL: https://grafana.github.io/helm-charts
    chart: loki
    targetRevision: 5.41.0
    helm:
      values: |
        {{- readFile "values.yaml" | nindent 8 }}
  destination:
    server: https://kubernetes.default.svc
    namespace: monitoring
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true

### Grafana Datasource для Loki
# platform/observability/loki/datasource.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: loki-datasource
  namespace: monitoring
  labels:
    grafana_datasource: "1"
data:
  loki-datasource.yaml: |
    apiVersion: 1
    datasources:
      - name: Loki
        type: loki
        access: proxy
        url: http://loki:3100
        isDefault: false
        jsonData:
          maxLines: 1000
          derivedFields:
            # Корреляция с Tempo traces
            - datasourceUid: tempo
              matcherRegex: "trace_id=(\\w+)"
              name: TraceID
              url: "$${__value.raw}"

### Example Loki Queries для Dashboard
# platform/observability/grafana-dashboards/logs-dashboard.json
{
  "dashboard": {
    "title": "Application Logs",
    "panels": [
      {
        "title": "Error Logs",
        "targets": [
          {
            "expr": "{app=\"demo-app\", level=\"error\"}",
            "refId": "A"
          }
        ]
      },
      {
        "title": "Logs by Namespace",
        "targets": [
          {
            "expr": "sum by (namespace) (count_over_time({job=\"kubernetes-pods\"}[5m]))",
            "refId": "A"
          }
        ]
      },
      {
        "title": "Top Log Producers",
        "targets": [
          {
            "expr": "topk(10, sum by (pod) (count_over_time({namespace=\"default\"}[5m])))",
            "refId": "A"
          }
        ]
      }
    ]
  }
}

-----

## 🔍 Day 10-11: Tempo Stack (Distributed Tracing)

### Architecture
┌─────────────┐
│   Apps      │
│  (with OTLP)│
└──────┬──────┘
       │ OTLP traces
       ▼
┌─────────────┐
│ OpenTelemetry│
│  Collector  │ ◄─── Receive, process, export
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Tempo     │ ◄─── Store traces
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Grafana   │ ◄─── Visualize traces
└─────────────┘

### Tempo Configuration

# Resource detection
    resourcedetection:
      detectors: [env, system, docker, kubernetes]
      timeout: 5s
    
    # Kubernetes attributes
    k8sattributes:
      auth_type: serviceAccount
      passthrough: false
      extract:
        metadata:
          - k8s.namespace.name
          - k8s.deployment.name
          - k8s.statefulset.name
          - k8s.daemonset.name
          - k8s.cronjob.name
          - k8s.job.name
          - k8s.node.name
          - k8s.pod.name
          - k8s.pod.uid
          - k8s.pod.start_time
        labels:
          - tag_name: app
            key: app.kubernetes.io/name
            from: pod
          - tag_name: version
            key: app.kubernetes.io/version
            from: pod
    
    # Tail sampling (для production - уменьшает объем traces)
    tail_sampling:
      policies:
        # Всегда сохраняем errors
        - name: errors
          type: status_code
          status_code:
            status_codes: [ERROR]
        # Всегда сохраняем медленные запросы
        - name: slow-traces
          type: latency
          latency:
            threshold_ms: 1000
        # Семплируем остальное (10%)
        - name: probabilistic
          type: probabilistic
          probabilistic:
            sampling_percentage: 10
  
  exporters:
    # Prometheus exporter (для метрик)
    prometheus:
      endpoint: 0.0.0.0:8889
      namespace: otelcol
      const_labels:
        environment: demo
    
    # Tempo exporter (для traces)
    otlp/tempo:
      endpoint: tempo:4317
      tls:
        insecure: true
    
    # Loki exporter (для logs)
    loki:
      endpoint: http://loki:3100/loki/api/v1/push
      labels:
        resource:
          service.name: "service_name"
          service.namespace: "service_namespace"
        attributes:
          level: "severity"
    
    # Debug exporter (для troubleshooting)
    debug:
      verbosity: detailed
  
  service:
    pipelines:
      # Traces pipeline
      traces:
        receivers: [otlp]
        processors: [memory_limiter, resourcedetection, k8sattributes, tail_sampling, batch]
        exporters: [otlp/tempo, debug]
      
      # Metrics pipeline
      metrics:
        receivers: [otlp, prometheus, hostmetrics, k8s_cluster]
        processors: [memory_limiter, resourcedetection, k8sattributes, batch]
        exporters: [prometheus]
      
      # Logs pipeline
      logs:
        receivers: [otlp]
        processors: [memory_limiter, resourcedetection, k8sattributes, batch]
        exporters: [loki, debug]

# Service configuration
service:
  type: ClusterIP
  ports:
    otlp:
      enabled: true
      containerPort: 4317
      servicePort: 4317
      protocol: TCP
    otlp-http:
      enabled: true
      containerPort: 4318
      servicePort: 4318
      protocol: TCP
    metrics:
      enabled: true
      containerPort: 8889
      servicePort: 8889
      protocol: TCP

# Resources
resources:
  limits:
    cpu: 500m
    memory: 1Gi
  requests:
    cpu: 200m
    memory: 512Mi

# RBAC для доступа к Kubernetes API
rbac:
  create: true

serviceAccount:
  create: true
  name: opentelemetry-collector

### ArgoCD Application
# platform/observability/opentelemetry-collector/application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: opentelemetry-collector
  namespace: argocd
spec:
  project: platform
  source:
    repoURL: https://open-telemetry.github.io/opentelemetry-helm-charts
    chart: opentelemetry-collector
    targetRevision: 0.73.0
    helm:
      values: |
        {{- readFile "values.yaml" | nindent 8 }}
  destination:
    server: https://kubernetes.default.svc
    namespace: monitoring
  syncPolicy:
    automated:
      prune: true
      selfHeal: true

-----

## 📱 Day 14: Demo Application с Full Observability

### Demo App - Go HTTP Server с OpenTelemetry
// applications/demo-app/src/main.go
package main

import (
 "context"
 "encoding/json"
 "fmt"
 "log"
 "math/rand"
 "net/http"
 "os"
 "time"

 "github.com/gorilla/mux"
 "github.com/prometheus/client_golang/prometheus"
 "github.

# platform/observability/tempo/values.yaml
tempo:
  multitenancyEnabled: false
  
  # Storage configuration
  storage:
    trace:
      backend: local
      local:
        path: /var/tempo/traces
      wal:
        path: /var/tempo/wal
  
  # Retention
  retention: 168h  # 7 days
  
  # Receivers
  receivers:
    otlp:
      protocols:
        grpc:
          endpoint: 0.0.0.0:4317
        http:
          endpoint: 0.0.0.0:4318
    jaeger:
      protocols:
        grpc:
          endpoint: 0.0.0.0:14250
        thrift_http:
          endpoint: 0.0.0.0:14268
    zipkin:
      endpoint: 0.0.0.0:9411
  
  # Query frontend
  queryFrontend:
    search:
      enabled: true

# Service configuration
service:
  type: ClusterIP
  ports:
    # OTLP gRPC receiver
    - name: otlp-grpc
      port: 4317
      targetPort: 4317
      protocol: TCP
    # OTLP HTTP receiver
    - name: otlp-http
      port: 4318
      targetPort: 4318
      protocol: TCP
    # Jaeger gRPC
    - name: jaeger-grpc
      port: 14250
      targetPort: 14250
      protocol: TCP
    # Tempo query
    - name: tempo
      port: 3100
      targetPort: 3100
      protocol: TCP

# Resources
resources:
  requests:
    cpu: 200m
    memory: 512Mi
  limits:
    cpu: 1000m
    memory: 2Gi

# Persistence
persistence:
  enabled: true
  size: 10Gi

### Grafana Datasource для Tempo
# platform/observability/tempo/datasource.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: tempo-datasource
  namespace: monitoring
  labels:
    grafana_datasource: "1"
data:
  tempo-datasource.yaml: |
    apiVersion: 1
    datasources:
      - name: Tempo
        type: tempo
        access: proxy
        url: http://tempo:3100
        isDefault: false
        jsonData:
          httpMethod: GET
          tracesToLogs:
            datasourceUid: loki
            tags: ['pod', 'namespace']
            mappedTags: [{ key: 'service.name', value: 'app' }]
            mapTagNamesEnabled: true
            spanStartTimeShift: '-1h'
            spanEndTimeShift: '1h'
            filterByTraceID: true
            filterBySpanID: false
          tracesToMetrics:
            datasourceUid: prometheus
            tags: [{ key: 'service.name', value: 'app' }]
            queries:
              - name: 'Request Rate'
                query: 'rate(http_server_requests_total{$$__tags}[5m])'
          serviceMap:
            datasourceUid: prometheus
          search:
            hide: false
          nodeGraph:
            enabled: true
          lokiSearch:
            datasourceUid: loki

-----

## 📡 Day 12-13: OpenTelemetry Collector

### Why OpenTelemetry Collector?

Benefits:

- Единая точка сбора для metrics, logs, traces
- Vendor-agnostic (можем менять backends)
- Preprocessing и filtering данных
- Батчинг для эффективности

### OpenTelemetry Collector Configuration
# platform/observability/opentelemetry-collector/values.yaml
mode: daemonset  # или deployment для gateway pattern

config:
  receivers:
    # OTLP receiver (для приложений)
    otlp:
      protocols:
        grpc:
          endpoint: 0.0.0.0:4317
        http:
          endpoint: 0.0.0.0:4318
    
    # Prometheus receiver (scrape метрики)
    prometheus:
      config:
        scrape_configs:
          - job_name: 'otel-collector'
            scrape_interval: 30s
            static_configs:
              - targets: ['localhost:8888']
    
    # Host metrics (для DaemonSet mode)
    hostmetrics:
      collection_interval: 30s
      scrapers:
        cpu:
        disk:
        filesystem:
        load:
        memory:
        network:
    
    # Kubernetes metrics
    k8s_cluster:
      auth_type: serviceAccount
      node_conditions_to_report: [Ready, MemoryPressure, DiskPressure]
      allocatable_types_to_report: [cpu, memory, storage]
  
  processors:
    # Батчинг для эффективности
    batch:
      timeout: 10s
      send_batch_size: 1024
      send_batch_max_size: 2048
    
    # Memory limiter (защита от OOM)
    memory_limiter:
      check_interval: 1s
      limit_percentage: 80
      spike_limit_percentage: 25

com/prometheus/client_golang/prometheus/promauto"
 "github.com/prometheus/client_golang/prometheus/promhttp"
 "go.opentelemetry.io/contrib/instrumentation/github.com/gorilla/mux/otelmux"
 "go.opentelemetry.io/otel"
 "go.opentelemetry.io/otel/attribute"
 "go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
 "go.opentelemetry.io/otel/propagation"
 "go.opentelemetry.io/otel/sdk/resource"
 sdktrace "go.opentelemetry.io/otel/sdk/trace"
 semconv "go.opentelemetry.io/otel/semconv/v1.17.0"
 "go.opentelemetry.io/otel/trace"
 "go.uber.org/zap"
 "go.uber.org/zap/zapcore"
)

var (
 // Prometheus metrics
 httpRequestsTotal = promauto.NewCounterVec(
  prometheus.CounterOpts{
   Name: "http_requests_total",
   Help: "Total number of HTTP requests",
  },
  []string{"method", "endpoint", "status"},
 )

 httpRequestDuration = promauto.NewHistogramVec(
  prometheus.HistogramOpts{
   Name:    "http_request_duration_seconds",
   Help:    "HTTP request duration in seconds",
   Buckets: prometheus.DefBuckets,
  },
  []string{"method", "endpoint"},
 )

 // Logger
 logger *zap.Logger

 // Tracer
 tracer trace.Tracer
)

func main() {
 // Initialize logger
 initLogger()
 defer logger.Sync()

 // Initialize OpenTelemetry
 ctx := context.Background()
 shutdown, err := initTracer(ctx)
 if err != nil {
  logger.Fatal("Failed to initialize tracer", zap.Error(err))
 }
 defer shutdown(ctx)

 // Create router
 r := mux.NewRouter()

 // Add OpenTelemetry middleware
 r.Use(otelmux.Middleware("demo-app"))
 r.Use(loggingMiddleware)
 r.Use(metricsMiddleware)

 // Routes
 r.HandleFunc("/", homeHandler).Methods("GET")
 r.HandleFunc("/api/hello", helloHandler).Methods("GET")
 r.HandleFunc("/api/users/{id}", getUserHandler).Methods("GET")
 r.HandleFunc("/api/slow", slowHandler).Methods("GET")
 r.HandleFunc("/api/error", errorHandler).Methods("GET")
 r.Handle("/metrics", promhttp.Handler()).Methods("GET")
 r.HandleFunc("/health", healthHandler).Methods("GET")

 // Start server
 port := getEnv("PORT", "8080")
 logger.Info("Starting server", zap.String("port", port))

 srv := &http.Server{
  Addr:         ":" + port,
  Handler:      r,
  ReadTimeout:  15 * time.Second,
  WriteTimeout: 15 * time.Second,
  IdleTimeout:  60 * time.Second,
 }

 if err := srv.ListenAndServe(); err != nil {
  logger.Fatal("Server failed", zap.Error(err))
 }
}

func initLogger() {
 config := zap.NewProductionConfig()
 config.EncoderConfig.TimeKey = "ts"
 config.EncoderConfig.EncodeTime = zapcore.ISO8601TimeEncoder
 config.EncoderConfig.MessageKey = "msg"
 config.EncoderConfig.LevelKey = "level"

 var err error
 logger, err = config.Build()
 if err != nil {
  log.Fatalf("Failed to initialize logger: %v", err)
 }
}

func initTracer(ctx context.Context) (func(context.Context) error, error) {
 otelEndpoint := getEnv("OTEL_EXPORTER_OTLP_ENDPOINT", "opentelemetry-collector:4317")

 exporter, err := otlptracegrpc.New(
  ctx,
  otlptracegrpc.WithEndpoint(otelEndpoint),
  otlptracegrpc.WithInsecure(),
 )
 if err != nil {
  return nil, fmt.Errorf("failed to create trace exporter: %w", err)
 }

 res, err := resource.New(ctx,
  resource.WithAttributes(
   semconv.ServiceNameKey.String("demo-app"),
   semconv.ServiceVersionKey.String(getEnv("APP_VERSION", "1.0.0")),
   attribute.String("environment", getEnv("ENVIRONMENT", "dev")),
  ),
 )
 if err != nil {
  return nil, fmt.Errorf("failed to create resource: %w", err)
 }

 tp := sdktrace.NewTracerProvider(
  sdktrace.WithBatcher(exporter),
  sdktrace.WithResource(res),
  sdktrace.WithSampler(sdktrace.AlwaysSample()),
 )

 otel.SetTracerProvider(tp)
 otel.SetTextMapPropagator(propagation.NewCompositeTextMapPropagator(
  propagation.TraceContext{},
  propagation.Baggage{},
 ))

 tracer = tp.Tracer("demo-app")

 return tp.Shutdown, nil
}

// Middleware
func loggingMiddleware(next http.Handler) http.Handler {
 return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
  start := time.Now()

  // Extract trace ID from context
  span := trace.SpanFromContext(r.Context())
  traceID := span.SpanContext().TraceID().String()

  logger.
Info("Request started",
   zap.String("method", r.Method),
   zap.String("path", r.URL.Path),
   zap.String("trace_id", traceID),
  )

  next.ServeHTTP(w, r)

  logger.Info("Request completed",
   zap.String("method", r.Method),
   zap.String("path", r.URL.Path),
   zap.Duration("duration", time.Since(start)),
   zap.String("trace_id", traceID),
  )
 })
}

func metricsMiddleware(next http.Handler) http.Handler {
 return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
  start := time.Now()
  route := mux.CurrentRoute(r)
  path, _ := route.GetPathTemplate()

  // Wrap ResponseWriter to capture status code
  rw := &responseWriter{ResponseWriter: w, statusCode: http.StatusOK}

  next.ServeHTTP(rw, r)

  duration := time.Since(start).Seconds()

  httpRequestsTotal.WithLabelValues(
   r.Method,
   path,
   fmt.Sprintf("%d", rw.statusCode),
  ).Inc()

  httpRequestDuration.WithLabelValues(
   r.Method,
   path,
  ).Observe(duration)
 })
}

// Handlers
func homeHandler(w http.ResponseWriter, r *http.Request) {
 ctx, span := tracer.Start(r.Context(), "homeHandler")
 defer span.End()

 logger.Info("Home endpoint called", zap.String("trace_id", span.SpanContext().TraceID().String()))

 response := map[string]string{
  "message": "Welcome to Demo App with Full Observability!",
  "version": getEnv("APP_VERSION", "1.0.0"),
 }

 span.SetAttributes(attribute.String("response.message", response["message"]))

 w.Header().Set("Content-Type", "application/json")
 json.NewEncoder(w).Encode(response)
}

func helloHandler(w http.ResponseWriter, r *http.Request) {
 ctx, span := tracer.Start(r.Context(), "helloHandler")
 defer span.End()

 name := r.URL.Query().Get("name")
 if name == "" {
  name = "World"
 }

 span.SetAttributes(attribute.String("user.name", name))

 // Simulate external call
 simulateExternalCall(ctx)

 response := map[string]string{
  "message": fmt.Sprintf("Hello, %s!", name),
 }

 w.Header().Set("Content-Type", "application/json")
 json.NewEncoder(w).Encode(response)
}

func getUserHandler(w http.ResponseWriter, r *http.Request) {
 ctx, span := tracer.Start(r.Context(), "getUserHandler")
 defer span.End()

 vars := mux.Vars(r)
 userID := vars["id"]

 span.SetAttributes(attribute.String("user.id", userID))

 // Simulate database query
 user := simulateDatabaseQuery(ctx, userID)

 w.Header().Set("Content-Type", "application/json")
 json.NewEncoder(w).Encode(user)
}

func slowHandler(w http.ResponseWriter, r *http.Request) {
 ctx, span := tracer.Start(r.Context(), "slowHandler")
 defer span.End()

 // Random delay 1-3 seconds
 delay := time.Duration(rand.Intn(2000)+1000) * time.Millisecond
 span.SetAttributes(attribute.Int64("delay.ms", delay.Milliseconds()))

 logger.Warn("Slow operation",
  zap.Duration("delay", delay),
  zap.String("trace_id", span.SpanContext().TraceID().String()),
 )

 time.Sleep(delay)

 response := map[string]interface{}{
  "message":  "Slow operation completed",
  "delay_ms": delay.Milliseconds(),
 }

 w.Header().Set("Content-Type", "application/json")
 json.NewEncoder(w).Encode(response)
}

func errorHandler(w http.ResponseWriter, r *http.Request) {
 ctx, span := tracer.Start(r.Context(), "errorHandler")
 defer span.End()

 logger.Error("Intentional error triggered",
  zap.String("trace_id", span.SpanContext().TraceID().String()),
 )

 span.RecordError(fmt.Errorf("intentional error for testing"))

 w.Header().Set("Content-Type", "application/json")
 w.WriteHeader(http.StatusInternalServerError)
 json.NewEncoder(w).Encode(map[string]string{
  "error": "Something went wrong!",
 })
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
 w.Header().Set("Content-Type", "application/json")
 json.NewEncoder(w).Encode(map[string]string{
  "status": "healthy",
 })
}

// Helper functions
func simulateExternalCall(ctx context.Context) {
 _, span := tracer.Start(ctx, "externalAPICall")
 defer span.End()

 span.SetAttributes(
  attribute.String("external.service", "fake-api"),
  attribute.String("external.url", "https://api.example.com/data"),
 )

 // Simulate network call
 time.

Sleep(time.Duration(rand.Intn(100)+50) * time.Millisecond)
}

func simulateDatabaseQuery(ctx context.Context, userID string) map[string]interface{} {
 _, span := tracer.Start(ctx, "databaseQuery")
 defer span.End()

 span.SetAttributes(
  attribute.String("db.system", "postgresql"),
  attribute.String("db.statement", "SELECT * FROM users WHERE id = $1"),
  attribute.String("db.user.id", userID),
 )

 // Simulate query
 time.Sleep(time.Duration(rand.Intn(50)+20) * time.Millisecond)

 return map[string]interface{}{
  "id":    userID,
  "name":  "John Doe",
  "email": "john@example.com",
 }
}

func getEnv(key, defaultValue string) string {
 if value := os.Getenv(key); value != "" {
  return value
 }
 return defaultValue
}

// ResponseWriter wrapper
type responseWriter struct {
 http.ResponseWriter
 statusCode int
}

func (rw *responseWriter) WriteHeader(code int) {
 rw.statusCode = code
 rw.ResponseWriter.WriteHeader(code)
}

### Demo App Deployment
# applications/demo-app/base/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-app
  labels:
    app: demo-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: demo-app
  template:
    metadata:
      labels:
        app: demo-app
        version: v1
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/metrics"
    spec:
      containers:
      - name: app
        image: localhost:5001/demo-app:latest
        ports:
        - containerPort: 8080
          name: http
          protocol: TCP
        env:
        - name: PORT
          value: "8080"
        - name: APP_VERSION
          value: "1.0.0"
        - name: ENVIRONMENT
          value: "dev"
        - name: OTEL_EXPORTER_OTLP_ENDPOINT
          value: "opentelemetry-collector.monitoring.svc.cluster.local:4317"
        - name: OTEL_SERVICE_NAME
          value: "demo-app"
        - name: OTEL_RESOURCE_ATTRIBUTES
          value: "service.version=1.0.0,deployment.environment=dev"
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5

### ServiceMonitor для Prometheus
# applications/demo-app/base/servicemonitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: demo-app
  labels:
    app: demo-app
spec:
  selector:
    matchLabels:
      app: demo-app
  endpoints:
  - port: http
    path: /metrics
    interval: 30s

-----

## 📊 Grafana Unified Dashboard
// platform/observability/grafana-dashboards/unified-observability.json
{
  "dashboard": {
    "title": "Unified Observability - Demo App",
    "tags": ["observability", "demo-app"],
    "panels": [
      {
        "title": "Request Rate",
        "type": "graph",
        "datasource": "Prometheus",
        "targets": [
          {
            "expr": "rate(http_requests_total{app=\"demo-app\"}[5m])",
            "legendFormat": "{{method}} {{endpoint}}"
          }
        ]
      },
      {
        "title": "Error Rate",
        "type": "graph",
        "datasource": "Prometheus",
        "targets": [
          {
            "expr": "rate(http_requests_total{app=\"demo-app\",status=~\"5..\"}[5m])",
            "legendFormat": "Errors"
          }
        ]
      },
      {
        "title": "Latency (p95)",
        "type": "graph",
        "datasource": "Prometheus",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{app=\"demo-app\"}[5m]))",
            "legendFormat": "p95"
          }
        ]
      },
      {
        "title": "Recent Logs",
        "type": "logs",
        "datasource": "Loki",
        "targets": [
          {


VERSION=$(semver bump major)
      elif [[ "$CI_COMMIT_MESSAGE" == feat:* ]]; then
        VERSION=$(semver bump minor)
      else
        VERSION=$(semver bump patch)
      fi

### 4. Cost Optimization

- Parallel job execution
- Conditional pipeline execution
- Artifact lifecycle management
- Runner tagging strategy

## 📋 План реализации

### Week 1: Core Templates

- [ ] Go build template (multi-stage, optimized)
- [ ] Kotlin build template
- [ ] Testing templates (unit, integration, e2e)
- [ ] Quality gates (coverage, linting)

### Week 2: Security Integration

- [ ] SAST/DAST templates
- [ ] Container scanning
- [ ] Dependency scanning
- [ ] Secret detection

### Week 3: Deployment Patterns

- [ ] K8s deployment templates
- [ ] Helm chart deployments
- [ ] Blue/Green deployment
- [ ] Rollback automation

### Week 4: Tooling & Documentation

- [ ] Pipeline validator CLI (Go)
- [ ] Cost analyzer tool
- [ ] Migration guides
- [ ] Best practices docs

## ✅ Success Metrics

- ✅ <5 min build time для Go services
- ✅ 100% security scan coverage
- ✅ Zero-config для standard services
- ✅ Cost reduction documentation

-----

# Project 3: SRE Toolkit (Go)

## 🛠️ Концепция

Production-grade CLI tool collection для SRE tasks - показывает Go expertise и SRE mindset.

## 🎯 Выбор главного инструмента

Рекомендация: Kubernetes Health Analyzer

Почему:

- Решает real production pain (debugging cluster issues)
- Показывает k8s client-go expertise
- Применим в любой компании с k8s
- Можно расширять модулями

## 📁 Архитектура
sre-toolkit-go/
├── cmd/
│   ├── k8s-health/               # Main CLI
│   ├── alert-analyzer/           # Bonus tool
│   └── config-validator/         # Bonus tool
├── pkg/
│   ├── analyzer/
│   │   ├── pods.go               # Pod health checks
│   │   ├── nodes.go              # Node conditions
│   │   ├── networking.go         # Network policies
│   │   ├── storage.go            # PVC/PV issues
│   │   └── security.go           # Security posture
│   ├── reporter/
│   │   ├── terminal.go           # Pretty output
│   │   ├── json.go
│   │   └── html.go               # Генерация отчета
│   └── metrics/
│       └── prometheus.go         # Metrics collection
├── internal/
│   ├── k8s/                      # K8s client wrappers
│   └── cache/                    # Result caching
├── configs/
│   └── rules/                    # Health check rules
├── docs/
│   ├── architecture.md
│   └── rules-reference.md
└── examples/
    └── sample-report.html

## 🔍 Core Features

### 1. Comprehensive Health Checks
type HealthCheck struct {
    Name        string
    Category    string
    Severity    Severity
    Description string
    Check       func(ctx context.Context) Result
}

// Example checks:
// - Pod stuck in Pending/CrashLoopBackOff
// - Node pressure (memory, disk, PID)
// - Network policy misconfigurations
// - PVC provisioning issues
// - Image pull secrets missing
// - Resource quotas exceeded
// - Unhealthy endpoints
// - Certificate expiration

### 2. Smart Analysis
// Анализ root cause, а не просто reporting
type Analysis struct {
    Issue       Issue
    RootCause   string
    Impact      Impact
    Remediation []Step
    Related     []Issue  // Связанные проблемы
}

### 3. Plugin System
// Расширяемость через plugins
type Plugin interface {
    Name() string
    RunChecks(ctx context.Context) []Result
}

// Примеры plugins:
// - istio-health
// - argocd-health
// - cert-manager-health

### 4. Export Formats

- Terminal (colored, interactive)
- JSON (для CI/CD)
- HTML report (для sharing)
- Prometheus metrics (для alerting)

## 📋 План реализации

### Week 1: Core Framework

- [ ] CLI framework (cobra)
- [ ] K8s client setup
- [ ] Basic health checks (pods, nodes)
- [ ] Terminal reporter

### Week 2: Advanced Checks

- [ ] Networking analysis
- [ ] Storage issues detection
- [ ] Security posture checks
- [ ] Smart root cause analysis

### Week 3: Reporting & Export

- [ ] HTML report generator
- [ ] JSON export
- [ ] Prometheus metrics exporter
- [ ] Plugin system

### Week 4: Polish & Documentation

- [ ] Unit tests (>80% coverage)
- [ ] Integration tests
- [ ] User documentation
- [ ] Demo recordings

## ✅ Success Metrics

- ✅ <30s для full cluster scan (100 pods)
- ✅ >80% test coverage
- ✅ Discovers real production issues
- ✅ Clear, actionable recommendations

-----

# Следующие шаги

Этот документ содержит полный план для всех трех проектов портфолио, с детальной разбивкой первых двух недель для GitOps Platform Lab.

Что уже готово:

- ✅ Полная архитектура всех проектов
- ✅ Детальный план Week 1 (Bootstrap)
- ✅ Детальный план Week 2 (Observability)
- ✅ Repository structure
- ✅ Конфигурации и код

Следующие шаги:

1. Начать имплементацию Week 1
1. Создать GitHub repository
1. Начать документацию
1. Настроить CI/CD для самого портфолио

🚀 Готов начинать!​​​​​​​​​​​​​​​​