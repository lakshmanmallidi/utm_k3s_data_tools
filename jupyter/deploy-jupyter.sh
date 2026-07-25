#!/bin/bash

set -e

case "${1:-deploy}" in
    deploy)
        echo "Deploying Jupyter Notebook..."
        kubectl apply -f spark-rbac.yaml
        kubectl apply -f secret.yaml
        kubectl apply -f service.yaml
        kubectl apply -f deployment.yaml
        echo "✓ Jupyter Notebook deployed"
        ;;
    delete)
        echo "Deleting Jupyter Notebook..."
        kubectl delete -f service.yaml --ignore-not-found=true
        kubectl delete -f deployment.yaml --ignore-not-found=true
        kubectl delete -f secret.yaml --ignore-not-found=true
        kubectl delete -f spark-rbac.yaml --ignore-not-found=true
        echo "✓ Jupyter Notebook deleted"
        ;;
    *)
        echo "Usage: $0 [deploy|delete]"
        ;;
esac