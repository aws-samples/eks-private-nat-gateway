
##!/bin/bash

#
# Set Kubernetes context to cluster A using 'kubectl config use-context' before running these commands
#

#
# Deploy the AWS load balancer controller
#
CLUSTER_NAME="EKS-CLUSTER-A"
helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system \
--set clusterName=$CLUSTER_NAME \
--set serviceAccount.create=false \
--set serviceAccount.name=aws-load-balancer-controller


#
# Deploy a Kubernetes Secret which provides connection information for the database
#
kubectl create ns recommender
kubectl create secret generic postgres-credentials \
--from-literal=POSTGRES_USER=eks \
--from-literal=POSTGRES_PASSWORD=eks \
--from-literal=POSTGRES_DATABASE=amazon \
--from-literal=POSTGRES_HOST=XXXXXXX \
--from-literal=POSTGRES_PORT=5432 \
--from-literal=POSTGRES_TABLEPREFIX=popularity_bucket_  -n recommender

#
# Deploy the HTTP web service
#
kubectl apply -f deployment-http-service.yaml

#
# Deploy the Ingres to provision an internet-facing ALB fronting the HTTP web service
#
kubectl apply -f ingress-http-service.yaml
