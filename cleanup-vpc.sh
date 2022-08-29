##!/bin/bash

REGION=us-west-2
VPC_STACK_NAME="eks-vpc-a-stack"
aws cloudformation delete-stack --stack-name $VPC_STACK_NAME --region $REGION

VPC_STACK_NAME="eks-vpc-b-stack"
aws cloudformation delete-stack --stack-name $VPC_STACK_NAME --region $REGION