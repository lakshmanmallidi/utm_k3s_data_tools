#!/bin/bash

# Simple MinIO Deployment Script

set -e

case "${1:-deploy}" in
    deploy)
        echo "Deploying MinIO..."
        kubectl apply -f secret.yaml
        kubectl apply -f pvc.yaml
        kubectl apply -f deployment.yaml
        kubectl apply -f service.yaml
        echo "✓ MinIO deployed"
        ;;
    delete)
        echo "Deleting MinIO..."
        kubectl delete -f service.yaml --ignore-not-found=true
        kubectl delete -f deployment.yaml --ignore-not-found=true
        kubectl delete pvc -l app=minio --ignore-not-found=true
        kubectl delete -f secret.yaml --ignore-not-found=true
        echo "✓ MinIO deleted"
        ;;
    *)
        echo "Usage: $0 [deploy|delete]"
        ;;
esac
