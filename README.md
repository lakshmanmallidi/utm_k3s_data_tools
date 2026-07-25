# K3s Data Tools - Modern Data Stack Learning Platform

A hands-on learning platform for building and practicing a **modern data stack** using Kubernetes (k3s) on an ARM64 virtual machine. Deploy a complete, production-inspired data platform with MyKart, a sample e-commerce application, and practice data engineering skills across multiple technologies.

> **Tested on**: MacBook (Apple Silicon) running Ubuntu Server 22.04 ARM64 via [UTM](https://mac.getutm.app/). Any hypervisor that can run an ARM64 Ubuntu Server VM will work (UTM, Hyper-V, VirtualBox, VMware, etc.).

## 🎯 What is This?

This repository provides a **complete, containerized data platform** that you can run on a single ARM64 Linux VM (using Kubernetes k3s). It combines multiple enterprise-grade open-source tools into a cohesive, practical learning environment.

Perfect for:
- 🎓 **Data engineers** learning modern data stack architecture
- 🔧 **DevOps engineers** practicing Kubernetes deployments
- 📊 **Data analysts** exploring real-time data pipelines
- 🏗️ **Architects** designing data systems
- 👨‍💻 **Developers** understanding end-to-end data workflows

## 📚 What You'll Learn

### Core Concepts
- **Data Ingestion**: CDC (Change Data Capture) using Debezium
- **Streaming**: Real-time event processing with Kafka
- **Data Cataloging**: Using Nessie for table metadata management
- **Analytics**: Spark-based notebook analysis with Iceberg tables
- **Storage**: Object storage patterns with MinIO (S3-compatible)
- **Applications**: Building data-driven web applications

### Practical Skills
- Kubernetes manifests and stateful deployments
- Distributed systems architecture (PostgreSQL, Kafka, Spark)
- Real-time data pipelines and CDC workflows
- Notebook-based analytics and data exploration
- Container networking and service discovery
- Persistent storage and data management

### Technologies You'll Practice
| Component | Purpose | Version |
|-----------|---------|---------|
| **PostgreSQL** | Source database for transactions | 16.10 |
| **Debezium** | Change Data Capture (CDC) | Latest |
| **Kafka** | Event streaming platform | KRaft mode |
| **Nessie** | Iceberg catalog for table versioning | 0.76.6 |
| **Spark** | Distributed analytics engine | 3.4.4 |
| **Jupyter** | Notebook-based exploration | Latest |
| **MinIO** | S3-compatible object storage | Latest |
| **React + Node.js** | Web application example | Latest |
| **Kubernetes** | Container orchestration | k3s (ARM64) |

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                   ARM64 Linux VM (any hypervisor)               │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │            Kubernetes (k3s) Cluster                       │  │
│  │                                                            │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │  │
│  │  │  PostgreSQL  │  │    Kafka     │  │   Jupyter    │   │  │
│  │  │   (Source)   │  │  (Streaming) │  │  (Analytics) │   │  │
│  │  └──────────────┘  └──────────────┘  └──────────────┘   │  │
│  │         ⬇️               ⬇️                  ⬇️            │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │  │
│  │  │  Debezium    │  │   Nessie     │  │   MinIO      │   │  │
│  │  │   (CDC)      │  │  (Catalog)   │  │ (Storage)    │   │  │
│  │  └──────────────┘  └──────────────┘  └──────────────┘   │  │
│  │                                                            │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │  │
│  │  │  MyKart Web  │  │   Kafka UI   │  │  Spark       │   │  │
│  │  │  (React)     │  │ (Monitoring) │  │ (Iceberg)    │   │  │
│  │  └──────────────┘  └──────────────┘  └──────────────┘   │  │
│  │                                                            │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Data Flow
1. **MyKart Application** → User generates events (clicks, purchases, browsing)
2. **PostgreSQL** → Stores transactional data (products, orders)
3. **Debezium CDC** → Captures database changes in real-time
4. **Kafka** → Streams events and changes to all consumers
5. **Jupyter + Spark** → Query tables using Nessie catalog backed by MinIO
6. **Analytics** → Create dashboards and reports

## �️ Setting Up Your ARM64 VM with k3s

### 1. Create an ARM64 Ubuntu Server VM

You can use any hypervisor that supports ARM64 guests. Choose what works for your host OS:

| Hypervisor | Host OS | Notes |
|------------|---------|-------|
| **UTM** | macOS | Free and open source, recommended for Apple Silicon Macs |
| **VirtualBox** | macOS / Windows / Linux | Free and open source, cross-platform |

> This repo was tested on **macOS (Apple Silicon) with UTM**. The k3s setup and all deployment scripts are identical regardless of hypervisor.

**VM configuration**:
1. Download **Ubuntu Server 22.04 ARM64** ISO from [ubuntu.com](https://ubuntu.com/download/server/arm)
2. Create a new VM with: **4 CPU cores, 8GB RAM, 50GB disk**
3. **Network**: Use **Shared Network** (or equivalent NAT/host-only mode in your hypervisor)
   - On UTM with Shared Network, the host gateway is `192.168.64.1`
   - The VM receives an IP like `192.168.64.x` (check with `ip addr` after boot)
   - Adjust the IP range to match your hypervisor's network settings

### 2. Install k3s on the VM

SSH into your VM, then run:

```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC='--write-kubeconfig-mode=644 --disable traefik' K3S_TOKEN='1432' sh -s - server
```

**What this does**:
- Installs k3s with `containerd` as the container runtime (default, no Docker needed)
- Sets kubeconfig world-readable (`--write-kubeconfig-mode=644`) so non-root users can use `kubectl`
- Disables Traefik ingress controller (not needed for this setup)
- Sets a known cluster token (`1432`) for node joining

Verify k3s is running:
```bash
sudo k3s kubectl get nodes
# Should show your node as Ready
```

### 3. Configure kubectl on Your Host Machine

Copy the kubeconfig from the VM to your Mac and update the server address to point to the VM's IP.

**Step 1 — Find your VM's IP address** (run on VM):
```bash
ip addr show | grep "inet 192.168.64"
# Example output: inet 192.168.64.5/24
```

**Step 2 — Copy the kubeconfig to your host machine**:
```bash
# Run on your host machine (macOS/Linux)
mkdir -p ~/.kube
scp <vm-user>@<vm-ip>:/etc/rancher/k3s/k3s.yaml ~/.kube/config
```

**Step 3 — Update the server address** to point to the VM IP instead of `127.0.0.1`:
```bash
# macOS
sed -i '' 's|https://127.0.0.1:6443|https://<vm-ip>:6443|' ~/.kube/config

# Linux / WSL
sed -i 's|https://127.0.0.1:6443|https://<vm-ip>:6443|' ~/.kube/config
```

**Step 4 — Verify connectivity from your host machine**:
```bash
kubectl get nodes
# Should show your k3s node as Ready
kubectl get pods -A
# Should show k3s system pods running
```

> **Note**: All Kubernetes LoadBalancer services deployed in this repo will be accessible from your host machine using the VM's IP (e.g., `<vm-ip>:9092` for Kafka, `<vm-ip>:5432` for PostgreSQL). On UTM with Shared Network the VM IP is typically in the `192.168.64.0/24` range.

---

## 🚀 Quick Start

### Prerequisites
- **VM**: ARM64 Ubuntu Server VM (any hypervisor) with 4+ CPU, 8GB+ RAM, k3s installed (see above)
- **Host Machine**: `kubectl` configured to talk to your k3s VM (see above)
- **Tools**: `bash` and standard Linux utilities

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/utm_k3s_data_tools.git
   cd utm_k3s_data_tools
   ```

2. **Clean your environment** (first-time setup):
   ```bash
   # Stop any running services
   pkill -f "mykart\|node\|react-scripts" || true
   
   # Clear Kubernetes
   kubectl delete all --all
   kubectl delete configmaps --all && kubectl delete pvc --all
   ```

3. **Deploy the platform** (follow sections below):
   - Start with PostgreSQL
   - Then deploy each component in order
   - Verify each step before moving on

### Deployment Steps

#### 1️⃣ Deploy PostgreSQL (Data Foundation)
```bash
cd postgres
./deploy-postgres-wal.sh
# ⏳ Wait 2-3 minutes for postgres-wal-0 pod to be READY
```

**What happens**:
- PostgreSQL 16.10 starts with logical replication enabled
- Debezium user created with proper permissions
- PVCs (5GB data, 2GB archive) attached for persistence

#### 2️⃣ Deploy Nessie Catalog (Table Metadata)
```bash
cd ../nessie
./deploy-nessie.sh deploy
# ⏳ Wait 1-2 minutes for nessie pod to be READY
```

**What happens**:
- Nessie 0.76.6 REST API starts on port 19120
- Connects to PostgreSQL for persistent metadata storage
- Ready to serve as Spark/Trino table catalog

#### 3️⃣ Deploy Kafka (Event Streaming)
```bash
cd ../kafka
./deploy-kafka.sh
# ⏳ Wait 3-5 minutes for kafka-kraft-0 pod to be READY
```

**What happens**:
- Kafka cluster in KRaft mode (no Zookeeper)
- Kafka UI available for topic monitoring
- External access via LoadBalancer IP

#### 4️⃣ Deploy MyKart Database Schema
```bash
cd ../mykart/database
./deploy_database.sh
# Answer 'y' when prompted to create database
```

**What gets created**:
- `mykart` database with sample schema
- 1000 product records pre-loaded
- Debezium CDC topics configured

#### 5️⃣ Deploy Kafka Connect (CDC Connector)
```bash
cd ../../kafka-connect-deployment
./deploy.sh deploy
# ⏳ Wait 2-3 minutes
```

**What happens**:
- Kafka Connect cluster starts
- Debezium connector deployed
- Logs CDC events from PostgreSQL to Kafka

#### 6️⃣ Deploy Debezium Connector
```bash
cd configs
./deploy-connectors.sh
```

**What happens**:
- CDC connector registers with Kafka Connect
- Begins streaming changes from PostgreSQL tables
- Creates `debezium.mykart.public.*` topics

#### 7️⃣ Deploy Web Application
```bash
cd ../../mykart/web-app
./deploy_webapp.sh
```

**What happens**:
- React frontend starts on http://localhost:3000
- Node.js backend on http://localhost:3001
- Connected to PostgreSQL and Kafka for events

#### 8️⃣ Deploy Jupyter Notebook
```bash
cd ../../jupyter
./deploy-jupyter.sh deploy
```

**What happens**:
- Jupyter Notebook/Lab on http://localhost:8888
- PySpark 3.4.4 + Iceberg support pre-installed
- MinIO storage mounted for data persistence
- Nessie catalog ready to query

## 📊 Verify Your Setup

### Check All Components
```bash
# See all running pods
kubectl get pods

# Check services and LoadBalancer IPs
kubectl get svc

# Verify Kafka topics created
kubectl exec kafka-kraft-0 -- /opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --list
```

### Access Points
| Component | URL | Credentials |
|-----------|-----|-------------|
| **MyKart App** | http://localhost:3000 | None |
| **Jupyter** | http://localhost:8888 | Check logs for token |
| **Kafka UI** | http://192.168.0.25:8090 | None |
| **PostgreSQL** | 192.168.0.25:5432 | admin/password123 |
| **Nessie API** | http://nessie.default.svc:19120/api/v1 | None |
| **MinIO** | http://minio.default.svc:9000 | minioadmin/minioadmin |

## 📖 Learning Paths

### Path 1: Data Pipeline Engineer
1. Understand PostgreSQL schema and data model
2. Monitor Debezium CDC in Kafka UI
3. Write Spark queries in Jupyter using Nessie catalog
4. Create analytics dashboards

### Path 2: Kubernetes & DevOps
1. Study each deployment YAML file
2. Learn about StatefulSets, Services, ConfigMaps
3. Troubleshoot pod deployment issues
4. Scale components (add Kafka brokers, Spark executors)

### Path 3: Real-Time Analytics
1. Generate test events in MyKart web app
2. Monitor real-time Kafka topics
3. Query CDC events in Jupyter
4. Build event-driven reports

### Path 4: Data Architecture
1. Study the end-to-end data flow
2. Add new data sources (new databases)
3. Implement schema evolution
4. Design backup and recovery strategies

## 🔧 Common Operations

### Generate Test Data
```bash
# Add products via web app or directly
curl -X POST http://localhost:3001/api/products \
  -H "Content-Type: application/json" \
  -d '{"name": "Test Product", "price": 99.99}'

# Monitor changes in Kafka
kubectl exec kafka-kraft-0 -- /opt/kafka/bin/kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic debezium.mykart.public.products \
  --from-beginning
```

### Query with Spark in Jupyter
```python
# In Jupyter notebook
df = spark.read \
    .format("iceberg") \
    .load("nessie.practice.mykart.products") \
    .limit(5)
df.show()
```

### Monitor Kafka Topics
```bash
# List all topics
kubectl exec kafka-kraft-0 -- /opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server localhost:9092 --list

# Describe a topic
kubectl exec kafka-kraft-0 -- /opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --describe --topic debezium.mykart.public.products
```

### Reset Components
```bash
# Delete Nessie catalog (restart with fresh data)
kubectl delete deployment nessie

# Reset PostgreSQL (wipe all data and redeploy)
kubectl delete pvc postgres-data-postgres-wal-0 postgres-archive-postgres-wal-0
kubectl delete deployment postgres-wal-0

# Delete Kafka topics (careful!)
kubectl exec kafka-kraft-0 -- /opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --delete --topic "mykart..*"
```

## 🐛 Troubleshooting

### Pod won't start / stuck in Pending
```bash
# Check pod events
kubectl describe pod <pod-name>

# Check PVC status
kubectl get pvc

# Check node resources
kubectl top node
```

### Kafka topics not created
```bash
# Verify Kafka is running
kubectl get pods | grep kafka

# Check Kafka Connect status
kubectl exec kafka-connect-0 -- curl localhost:8080/connectors
```

### Jupyter can't connect to Spark
```bash
# Check if Nessie is running
kubectl get pods | grep nessie

# Verify MinIO bucket exists
kubectl exec minio-0 -- mc ls minio/notebook-pod
```

### PostgreSQL won't initialize
```bash
# Check pod logs
kubectl logs postgres-wal-0

# Verify PVC is accessible
kubectl exec postgres-wal-0 -- ls -la /var/lib/postgresql/data
```

## 📚 Additional Resources

- [Kubernetes k3s Documentation](https://docs.k3s.io/)
- [Apache Kafka Official Docs](https://kafka.apache.org/documentation/)
- [Debezium CDC Guide](https://debezium.io/documentation/reference/)
- [Apache Spark with Iceberg](https://iceberg.apache.org/docs/latest/spark-quickstart/)
- [Nessie Catalog Docs](https://projectnessie.org/docs/)
- [PostgreSQL WAL & Replication](https://www.postgresql.org/docs/current/wal-intro.html)

## 📝 License

This project is provided as-is for educational and practice purposes.

## 🤝 Contributing

Found issues or want to improve the learning materials? Feel free to open issues or PRs!

## ⚠️ Production Use

**This setup is NOT production-ready**. It's designed for learning and practice on a single VM. For production:
- Use managed Kubernetes services (EKS, GKE, AKS)
- Implement proper authentication and TLS
- Use persistent storage solutions (AWS EBS, Azure Disk, etc.)
- Add monitoring, alerting, and backup strategies
- Separate dev/test/prod environments
- Implement proper security policies and network isolation
