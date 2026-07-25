#!/bin/bash

set -e

case "${1:-deploy}" in
    deploy)
        echo "Deploying Nessie catalog..."
        kubectl apply -f secret.yaml
        kubectl apply -f service.yaml
        kubectl apply -f deployment.yaml
        kubectl rollout status deployment/nessie --timeout=300s
        echo "✓ Nessie deployed"
        echo "  Endpoint: http://nessie.default.svc.cluster.local:19120/api/v1"
        ;;
    delete)
        echo "Deleting Nessie catalog..."
        kubectl delete -f deployment.yaml --ignore-not-found=true
        kubectl delete -f service.yaml --ignore-not-found=true
        echo "✓ Nessie deleted"
        ;;
    *)
        echo "Usage: $0 [deploy|delete]"
        ;;
esac
