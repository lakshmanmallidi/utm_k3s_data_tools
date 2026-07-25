#!/bin/bash

set -e

if ! command -v kubectl &> /dev/null; then
    echo "kubectl is not installed or not in PATH"
    exit 1
fi

MINIO_ENDPOINT=${MINIO_ENDPOINT:-http://minio:9000}
NOTEBOOK_BUCKET=${NOTEBOOK_BUCKET:-notebook-pod}

ROOT_USER=$(kubectl get secret minio-credentials -o jsonpath='{.data.MINIO_ROOT_USER}' | base64 --decode)
ROOT_PASSWORD=$(kubectl get secret minio-credentials -o jsonpath='{.data.MINIO_ROOT_PASSWORD}' | base64 --decode)

kubectl run minio-mc-bootstrap \
    --rm -i --restart=Never \
    --image=minio/mc:latest \
    --env="MINIO_ENDPOINT=${MINIO_ENDPOINT}" \
    --env="NOTEBOOK_BUCKET=${NOTEBOOK_BUCKET}" \
    --env="ROOT_USER=${ROOT_USER}" \
    --env="ROOT_PASSWORD=${ROOT_PASSWORD}" \
    --command -- sh -c '
set -e
mc alias set minio "$MINIO_ENDPOINT" "$ROOT_USER" "$ROOT_PASSWORD"
mc mb --ignore-existing "minio/$NOTEBOOK_BUCKET"
'

echo "Bucket ${NOTEBOOK_BUCKET} is ready at ${MINIO_ENDPOINT}"