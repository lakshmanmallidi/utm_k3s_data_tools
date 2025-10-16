#!/bin/bash

# Deploy PostgreSQL to Kubernetes

echo "Deploying PostgreSQL StatefulSet..."

# Apply the services first
echo "Creating Services..."
kubectl apply -f service.yaml

# Apply the StatefulSet (includes volumeClaimTemplates)
echo "Creating StatefulSet..."
kubectl apply -f statefulset.yaml

# Optionally apply the ConfigMap for init scripts
echo "Creating ConfigMap (optional)..."
kubectl apply -f configmap.yaml

echo "PostgreSQL StatefulSet deployment completed!"
echo ""
echo "Check deployment status with:"
echo "  kubectl get pods -l app=postgres"
echo "  kubectl get services -l app=postgres"
echo ""
echo "To connect to PostgreSQL:"
echo "  Internal: postgres:5432"
echo "  External: kubectl get svc postgres-external (check EXTERNAL-IP)"
echo ""
echo "Default credentials:"
echo "  Database: mydb"
echo "  Username: admin" 
echo "  Password: password123"