#!/bin/bash

# Simple Kafka Deployment Script

set -e

case "${1:-deploy}" in
    deploy)
        echo "Deploying Kafka..."
        kubectl apply -f service.yaml
        kubectl apply -f statefulset.yaml
        echo "✓ Kafka deployed"
        ;;
    delete)
        echo "Deleting Kafka..."
        kubectl delete -f statefulset.yaml --ignore-not-found=true
        kubectl delete -f service.yaml --ignore-not-found=true
        kubectl delete pvc -l app=kafka-kraft --ignore-not-found=true
        echo "✓ Kafka deleted"
        ;;
    *)
        echo "Usage: $0 [deploy|delete]"
        ;;
esac