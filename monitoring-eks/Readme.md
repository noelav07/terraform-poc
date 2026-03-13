# EKS & EC2 Hybrid Monitoring Setup

This guide covers the deployment of a centralized monitoring and logging stack on AWS.

## Architecture Overview
- **EC2 Instance**: Hosts the Prometheus Server, Loki, Grafana using Docker Compose.
- **EKS Cluster**: Hosts the Prometheus Agent, Promtail/Fluent Bit, Exporters.

---

## 1. EC2 Setup (Central Server)
Run these commands on your EC2 instance.

1. **Setup server components with docker compose**:
   ```
   docker compose up -d 
   ```
2. **Verify Components**:
   - Grafana: `http://<EC2_IP>:3000`
   - Prometheus: `http://<EC2_IP>:9090`
   - Loki Ready: `curl http://localhost:3100/ready`

---

## 2. EKS Setup: Helm (Recommended)
This is the modern, maintainable way to deploy the agents.

### Prerequisites (Run once)
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add fluent https://fluent.github.io/helm-charts
helm repo update
```

### 2. Deploy Prometheus (Agent + Exporters)
Use this command to force "Agent Mode" and point it to your EC2.
```bash
helm upgrade --install prometheus prometheus-community/prometheus \
  --namespace monitoring --create-namespace \
  --set server.enabled=false \
  --set agentMode=true \
  --set agent.enabled=true \
  -f helm-eks/prometheus-values.yaml
```

### Metrics + Loki Logs (via Fluent Bit)
*Recommended for high performance.*
```bash
# Install Prometheus (same as above)
helm install prometheus prometheus-community/prometheus -n monitoring --create-namespace -f helm-eks/prometheus-values.yaml

# Install Fluent Bit
helm install fluent-bit fluent/fluent-bit -n monitoring -f helm-eks/fluent-bit-values.yaml
```

---

## 4. Visualization (Grafana)
1. Login to Grafana at `http://<EC2_IP>:3000`.
2. **Add Data Sources**:
   - **Prometheus**: URL `http://prometheus:9090`
   - **Loki**: URL `http://loki:3100`
3. **Import Dashboards**:
   - **Kubernetes Cluster (Global)**: ID `15757`
   - **Node Exporter**: ID `1860`

---

## 5. Troubleshooting
- **Metrics not arriving** Check Prometheus Agent logs: `kubectl logs -l app=prometheus-agent -n monitoring`
- **Logs not arriving?** Check Promtail logs: `kubectl logs -l app=promtail -n monitoring`
- **Loki labels missing?** Ensure security group port `3100` is open on EC2.


## 6. Clean-up 

# Cleanup Guide: Monitoring Stack

Use these commands to completely remove all monitoring, logging, and stress-test components from your EKS cluster and EC2 instance.

## 1. EKS Cleanup (Helm)
If you installed using Helm, run these commands:

```bash
# Uninstall the releases
helm uninstall prometheus -n monitoring
helm uninstall promtail -n monitoring
helm uninstall fluent-bit -n monitoring

# Remove the repositories (optional)
helm repo remove prometheus-community grafana fluent
```

## 2. EKS Cleanup (Static YAMLs)
If you installed using individual manifests:

```bash
kubectl delete -f k8s/prometheus-agent.yaml
kubectl delete -f k8s/promtail.yaml
kubectl delete -f k8s/node-exporter.yaml
kubectl delete -f k8s/kube-state-metrics.yaml
```

## 3. Namespace Cleanup
Remove the namespaces to delete any remaining secrets, service accounts, or HPA objects:

```bash
kubectl delete namespace monitoring
kubectl delete namespace stress
```

## 4. EC2 Cleanup (Central Server)
Run these on your EC2 instance terminal:

```bash
# Navigate to the project directory
cd monitoring-eks/ec2

# Stop and remove all containers, networks, and images
docker-compose down --rmi all -v

# (Optional) Remove the local logs and data volumes
sudo rm -rf /tmp/prometheus /tmp/loki
```

---
**Warning**: Deleting the namespaces and Docker volumes will permanently erase all collected metrics and logs.

