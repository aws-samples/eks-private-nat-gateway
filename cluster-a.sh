##!/bin/bash

REGION=us-west-2
CLUSTER_TEMPLATE=eks-cluster-stack.yaml
VPC_STACK_NAME="eks-vpc-a-stack"
CLUSTER_STACK_NAME="eks-cluster-a-stack"
CLUSTER_NAME="EKS-CLUSTER-A"

#
# Create the EKS cluster
#
aws cloudformation deploy --stack-name $CLUSTER_STACK_NAME --template-file $CLUSTER_TEMPLATE --parameter-overrides \
VPCStackName=$VPC_STACK_NAME \
ClusterName=$CLUSTER_NAME \
--capabilities CAPABILITY_IAM --region $REGION


WORKER_TEMPLATE=eks-managed-workernode-stack.yaml
WORKER_STACK_NAME="eks-workers-a-stack"

CLUSTER_API_SERVER_URL=$(aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query cluster.endpoint --output text)
B64_CLUSTER_CA=$(aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query cluster.certificateAuthority --output text)
CLUSTER_SECURITY_GROUP_ID=$(aws eks describe-cluster --name $CLUSTER_NAME --query cluster.resourcesVpcConfig.clusterSecurityGroupId --output text --region $REGION)

#
# Create a EKS managed node group for the cluster
#
aws cloudformation deploy --stack-name $WORKER_STACK_NAME --template-file $WORKER_TEMPLATE --parameter-overrides \
VPCStackName=$VPC_STACK_NAME \
ClusterStackName=$CLUSTER_STACK_NAME \
ClusterName=$CLUSTER_NAME \
ClusterSecurityGroup=$CLUSTER_SECURITY_GROUP_ID \
ClusterEndpoint=$CLUSTER_API_SERVER_URL \
ClusterCertificateAuthority=$B64_CLUSTER_CA \
--capabilities CAPABILITY_IAM --region $REGION