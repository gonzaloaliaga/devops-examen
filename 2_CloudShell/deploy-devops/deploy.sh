#!/bin/bash
set -e

REGION="us-east-1"
CLUSTER_NAME="devopseks"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URL="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

echo "Actualizando kubeconfig..."
aws eks update-kubeconfig --region ${REGION} --name ${CLUSTER_NAME}

echo "Configurando manifests Kubernetes..."
find ./k8s -type f -name "*.yaml" -exec sed -i "s|{{ECR_URL}}|${ECR_URL}|g" {} \;

echo "Login ECR..."
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ECR_URL}

####################################################
# BUILD & PUSH DE IMÁGENES
####################################################
echo "Build DB..."
docker build -t db-mysql ./database
docker tag db-mysql:latest ${ECR_URL}/db-mysql:latest
docker push ${ECR_URL}/db-mysql:latest

echo "Build Frontend..."
docker build -t front-despacho ./frontend
docker tag front-despacho:latest ${ECR_URL}/front-despacho:latest
docker push ${ECR_URL}/front-despacho:latest

echo "Build Backend Ventas..."
docker build -t back-ventas ./backVentas
docker tag back-ventas:latest ${ECR_URL}/back-ventas:latest
docker push ${ECR_URL}/back-ventas:latest

echo "Build Backend Despachos..."
docker build -t back-despachos ./backDespachos
docker tag back-despachos:latest ${ECR_URL}/back-despachos:latest
docker push ${ECR_URL}/back-despachos:latest

####################################################
# DESPLIEGUE EN KUBERNETES
####################################################
echo "Desplegando Namespace y Base de Datos..."
kubectl apply -f ./k8s/namespace.yaml
kubectl apply -f ./k8s/mysql-secret.yaml
kubectl apply -f ./k8s/mysql-deployment.yaml
kubectl apply -f ./k8s/mysql-service.yaml

echo "Esperando DB..."
kubectl rollout status deployment/mysql-db -n devops --timeout=300s

echo "Desplegando Backends..."
kubectl apply -f ./k8s/back-ventas.yaml
kubectl apply -f ./k8s/back-despachos.yaml

kubectl rollout status deployment/back-ventas -n devops --timeout=300s
kubectl rollout status deployment/back-despachos -n devops --timeout=300s

echo "Desplegando Frontend..."
kubectl apply -f ./k8s/frontend.yaml
kubectl rollout status deployment/front-despacho -n devops --timeout=300s

####################################################
# OBTENER LOAD BALANCER
####################################################
echo "Esperando IP pública del Frontend..."
for i in {1..40}
do
  HOSTNAME=$(kubectl get svc front-despacho-svc -n devops -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
  if [ ! -z "$HOSTNAME" ]; then
    echo "===================================="
    echo "APLICACIÓN DISPONIBLE EN: http://${HOSTNAME}"
    echo "===================================="
    exit 0
  fi
  sleep 15
done