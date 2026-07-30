#!/bin/bash

set -e

case "${1:-deploy}" in
    deploy)
        echo "Deploying Trino..."
        kubectl apply -f deployment.yaml
        kubectl apply -f service.yaml
        kubectl rollout status deployment/trino --timeout=300s
        echo "✓ Trino deployed"
        echo "  Service: trino.default.svc.cluster.local:8080"
        echo "  JDBC URL: jdbc:trino://trino.default.svc.cluster.local:8080"
        ;;
    delete)
        echo "Deleting Trino..."
        kubectl delete -f service.yaml --ignore-not-found=true
        kubectl delete -f deployment.yaml --ignore-not-found=true
        echo "✓ Trino deleted"
        ;;
    *)
        echo "Usage: $0 [deploy|delete]"
        ;;
esac
