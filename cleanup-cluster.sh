##!/bin/bash

REGION=us-west-2

#
# Delete the managed node groups
#
WORKER_STACK_NAME="eks-workers-a-stack"
aws cloudformation delete-stack --stack-name $WORKER_STACK_NAME --region $REGION

WORKER_STACK_NAME="eks-workers-b-stack"
aws cloudformation delete-stack --stack-name $WORKER_STACK_NAME --region $REGION


#
# Delete the clusters
#
CLUSTER_STACK_NAME="eks-cluster-a-stack"
aws cloudformation delete-stack --stack-name $CLUSTER_STACK_NAME --region $REGION

CLUSTER_STACK_NAME="eks-cluster-b-stack"
aws cloudformation delete-stack --stack-name $CLUSTER_STACK_NAME --region $REGION

