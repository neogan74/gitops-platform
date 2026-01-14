# Network Policies

Network Policies implement network segmentation and zero-trust networking principles in Kubernetes.

## Architecture

### Default Deny (Zero Trust)

All application namespaces start with **default deny all ingress**:
- No pod can receive traffic unless explicitly allowed
- Forces intentional allow rules
- Reduces blast radius of compromised pods

Production namespace also has **default deny egress**:
- No outbound traffic unless explicitly allowed
- Prevents data exfiltration
- Limits lateral movement

### Allow Rules

Specific allow rules are created for required communication:

1. **DNS Resolution** (`allow-dns.yaml`)
   - Required for service discovery
   - Allows UDP/TCP port 53 to kube-system namespace
   - Applied to all application namespaces

2. **Ingress Controller** (`allow-ingress.yaml`)
   - Allows traffic from nginx-ingress namespace
   - Targets demo-app-go pods on port 8080
   - Enables external HTTP/HTTPS access

3. **Prometheus Monitoring** (`allow-monitoring.yaml`)
   - Allows monitoring namespace to scrape metrics
   - Targets demo-app-go pods on port 8080
   - Required for observability

4. **Istio Service Mesh** (`allow-istio.yaml`)
   - Allows bidirectional traffic with istio-system namespace
   - Required for ambient mesh (ztunnel)
   - Enables mTLS and traffic management

5. **Kubernetes API** (`allow-kubernetes-api.yaml`)
   - Allows egress to API server (port 443/6443)
   - Only in namespaces that need API access
   - Required for controllers and operators

## Policy Layers

```
┌─────────────────────────────────────────────────────┐
│             External Traffic (Internet)             │
└────────────────────┬────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────┐
│          Ingress Controller (ingress-nginx)         │
└────────────────────┬────────────────────────────────┘
                     │ ✅ allow-ingress.yaml
                     ▼
┌─────────────────────────────────────────────────────┐
│         Application Pods (demo-app-go)              │
│                                                      │
│  ⛔ default-deny-ingress.yaml (default deny)        │
│  ⛔ default-deny-egress.yaml (production only)      │
│                                                      │
│  Allowed:                                           │
│  ✅ From: ingress-nginx                             │
│  ✅ From: monitoring (Prometheus)                   │
│  ✅ From/To: istio-system (service mesh)            │
│  ✅ To: kube-system:53 (DNS)                        │
│  ✅ To: API server (if needed)                      │
└─────────────────────────────────────────────────────┘
```

## Testing Network Policies

### Verify Policies Applied

```bash
# List all network policies
kubectl get networkpolicies -A

# Check specific namespace
kubectl get networkpolicy -n production

# Describe policy
kubectl describe networkpolicy default-deny-ingress -n production
```

### Test Default Deny

```bash
# Deploy test pod
kubectl run test-pod --image=nginx -n production

# Try to access application (should fail - default deny)
kubectl exec -it test-pod -n production -- curl demo-app-go

# Expected: Connection timeout or refused
```

### Test Allowed Traffic

```bash
# Test from ingress namespace (should work)
INGRESS_POD=$(kubectl get pods -n ingress-nginx -l app.kubernetes.io/component=controller -o name | head -1)
kubectl exec -n ingress-nginx $INGRESS_POD -- curl http://prod-demo-app-go.production.svc.cluster.local/health

# Expected: {"status":"healthy",...}
```

### Test Prometheus Scraping

```bash
# Get Prometheus pod
PROM_POD=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus -o name | head -1)

# Test scraping metrics (should work)
kubectl exec -n monitoring $PROM_POD -- curl http://prod-demo-app-go.production.svc.cluster.local:80/metrics

# Expected: Prometheus metrics output
```

### Test DNS Resolution

```bash
# Test DNS from application pod
APP_POD=$(kubectl get pods -n production -l app=demo-app-go -o name | head -1)
kubectl exec -n production $APP_POD -- nslookup kubernetes.default.svc.cluster.local

# Expected: DNS resolution successful
```

## Production Best Practices

### Principle of Least Privilege
- Start with default deny all
- Add only required allow rules
- Review and remove unused rules regularly

### Namespace Isolation
- Different policies for dev/staging/production
- Production has strictest rules (deny egress)
- Development more permissive for testing

### Service Mesh Integration
- Network policies complement service mesh
- Policies provide defense in depth
- Istio adds mTLS on top of network segmentation

### Monitoring
- Log policy violations (audit mode first)
- Alert on unexpected traffic patterns
- Review allowed/denied connections regularly

## Common Patterns

### Allow Same-Namespace Communication

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-same-namespace
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector: {}
```

### Allow Specific External IPs

```yaml
egress:
- to:
  - ipBlock:
      cidr: 203.0.113.0/24  # External service CIDR
  ports:
  - protocol: TCP
    port: 443
```

### Allow Specific Labels

```yaml
ingress:
- from:
  - podSelector:
      matchLabels:
        role: frontend
  ports:
  - protocol: TCP
    port: 8080
```

## Troubleshooting

### Pod Can't Reach Other Services

1. Check if network policy exists:
   ```bash
   kubectl get networkpolicy -n <namespace>
   ```

2. Verify policy allows required traffic:
   ```bash
   kubectl describe networkpolicy <name> -n <namespace>
   ```

3. Check pod labels match policy selectors:
   ```bash
   kubectl get pod <name> -n <namespace> --show-labels
   ```

### DNS Not Working

Ensure `allow-dns.yaml` is applied:
```bash
kubectl get networkpolicy allow-dns -n <namespace>
```

### Metrics Not Scraped

Verify Prometheus can reach pods:
```bash
kubectl get networkpolicy allow-prometheus-scraping -n <namespace>
```

## Migration Strategy

1. **Audit Mode**: Deploy policies in audit mode (namespaceSelector with non-existent label)
2. **Monitor**: Watch logs for legitimate traffic that would be blocked
3. **Create Allow Rules**: Add specific allow rules for identified traffic
4. **Enforce**: Apply default deny policies
5. **Iterate**: Adjust based on application needs

## References

- [Kubernetes Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Network Policy Recipes](https://github.com/ahmetb/kubernetes-network-policy-recipes)
- [Calico Network Policy](https://docs.tigera.io/calico/latest/network-policy/)
