
##!/bin/bash

#
# Set Kubernetes context to cluster B using 'kubectl config use-context' before running these commands
#

#
# Deploy the AWS load balancer controller
#
CLUSTER_NAME="EKS-CLUSTER-B"
helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system \
--set clusterName=$CLUSTER_NAME \
--set serviceAccount.create=false \
--set serviceAccount.name=aws-load-balancer-controller

#
# Deploy the TCP web service
# This will provision an internal NLB fronting the web service
#
kubectl create ns tcp-services
kubectl apply -f deployment-tcp-service.yaml

