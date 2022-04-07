#!/bin/bash

if [ -z "$PROJECT" ]
then
echo "No PROJECT variable set, trying to use gcloud current project..."
export PROJECT=$(gcloud config get-value project)
echo "PROJECT set to $PROJECT"
fi

if [ -z "$LOCATION" ]
then
echo "No LOCATION variable set, using europe-west1..."
export LOCATION="europe-west1-c"
fi

if [ -z "$CLUSTERNAME" ]
then
echo "No CLUSTERNAME variable set, using 'asm-cluster'"
export CLUSTERNAME="asm-cluster"
fi

if [ -z "$API_GATEWAY_NAMESPACE" ]
then
echo "No API_GATEWAY_NAMESPACE variable set, using 'api-ingress'"
export API_GATEWAY_NAMESPACE="api-ingress"
fi

echo "Enabling APIs..."
gcloud services enable compute.googleapis.com

gcloud container clusters get-credentials $CLUSTERNAME \
--project=$PROJECT \
--zone=$LOCATION

kubectl config set-context $CLUSTERNAME

echo "Create namespace"
kubectl create namespace $API_GATEWAY_NAMESPACE

ASM_VERSION=$(kubectl get deploy -n istio-system -l app=istiod -o jsonpath={.items[*].metadata.labels.'istio\.io\/rev'}'{"\n"}')
kubectl label namespace $API_GATEWAY_NAMESPACE istio.io/rev=$ASM_VERSION --overwrite

echo "Create configmap for the proxyservice"
kubectl create configmap proxyconfig --from-file=kubernetes-manifests/config -n $API_GATEWAY_NAMESPACE

echo "Creating Ingress Gateway for the APIs "
kubectl apply -f kubernetes-manifests/api-ingressgateway/. -n $API_GATEWAY_NAMESPACE

