##!/bin/bash
REGION=us-west-2
VPC_A_NAME="EKS-VPC-A"
VPC_B_NAME="EKS-VPC-B"
VPC_A_CIDR="192.168.16.0/20"
VPC_B_CIDR="192.168.32.0/20"
VPC_A_ID=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=$VPC_A_NAME Name=cidr,Values=$VPC_A_CIDR --query "Vpcs[].VpcId" --output text --region $REGION)
VPC_B_ID=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=$VPC_B_NAME Name=cidr,Values=$VPC_B_CIDR --query "Vpcs[].VpcId" --output text --region $REGION)
VPC_A_SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=tag-key,Values=kubernetes.io/role/internal-elb" "Name=vpc-id,Values=$VPC_A_ID" --query "Subnets[].SubnetId" --output text --region $REGION)
VPC_B_SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=tag-key,Values=kubernetes.io/role/internal-elb" "Name=vpc-id,Values=$VPC_B_ID" --query "Subnets[].SubnetId" --output text --region $REGION)

#
# Create Transit Gateway
#
echo "Creating a Transit gateway"
TGW_ID=$(aws ec2 create-transit-gateway \
--description "Transit gateway to bridge VPC A and B" \
--options=AutoAcceptSharedAttachments=enable,DefaultRouteTableAssociation=enable,DefaultRouteTablePropagation=disable,VpnEcmpSupport=enable,DnsSupport=enable \
--tag-specifications "ResourceType=transit-gateway,Tags=[{Key=Name,Value=tgw_ab}]" \
--query "TransitGateway.TransitGatewayId" --output text --region $REGION)

tgwStatus() {
  aws ec2 describe-transit-gateways --transit-gateway-ids $TGW_ID  --query "TransitGateways[].State" --output text --region $REGION
}

until [ $(tgwStatus) != "pending" ]; do
  echo "Waiting for transit gateway $TGW_ID to be ready ..."
  sleep 10s
  if [ $(tgwStatus) = "available" ]; then
    echo "Transit gateway $TGW_ID is ready"
    break
  fi
done

#
# Create Transit Gateway Attachments
#
echo "Creating Transit gateway attachments"
TGW_ATTACHMENT_A_ID=$(aws ec2 create-transit-gateway-vpc-attachment \
--transit-gateway-id $TGW_ID \
--vpc-id $VPC_A_ID \
--subnet-ids $VPC_A_SUBNET_IDS \
--tag-specifications "ResourceType=transit-gateway-attachment,Tags=[{Key=Name,Value=tgw_attachment_vpc_a}]" \
--query "TransitGatewayVpcAttachment.TransitGatewayAttachmentId" --output text \
--region $REGION)

TGW_ATTACHMENT_B_ID=$(aws ec2 create-transit-gateway-vpc-attachment \
--transit-gateway-id $TGW_ID \
--vpc-id $VPC_B_ID \
--subnet-ids $VPC_B_SUBNET_IDS \
--tag-specifications "ResourceType=transit-gateway-attachment,Tags=[{Key=Name,Value=tgw_attachment_vpc_b}]" \
--query "TransitGatewayVpcAttachment.TransitGatewayAttachmentId" --output text \
--region $REGION)

tqwAttachmentAStatus() {
  aws ec2 describe-transit-gateway-vpc-attachments --transit-gateway-attachment-ids $TGW_ATTACHMENT_A_ID --query "TransitGatewayVpcAttachments[].State" --output text --region $REGION
}

tqwAttachmentBStatus() {
  aws ec2 describe-transit-gateway-vpc-attachments --transit-gateway-attachment-ids $TGW_ATTACHMENT_B_ID --query "TransitGatewayVpcAttachments[].State" --output text --region $REGION
}

until [ $(tqwAttachmentAStatus) != "pending" ] || [ $(tqwAttachmentBStatus) != "pending" ]; do
  echo "Waiting for transit gateway attachments $TGW_ATTACHMENT_A_ID and $TGW_ATTACHMENT_B_ID to be ready ..."
  sleep 10s
  if [ $(tqwAttachmentAStatus) = "available" ] && [ $(tqwAttachmentBStatus) = "available" ]; then
    echo "Transit gateway attachments $TGW_ATTACHMENT_A_ID and $TGW_ATTACHMENT_B_ID are ready"
    break
  fi
done

#
# Add Static Routes to the Transit Gateway Route Table
#
echo "Adding routes to Transit gateway route table"
TGW_ROUTE_TABLE_ID=$(aws ec2 describe-transit-gateways --transit-gateway-ids $TGW_ID --query "TransitGateways[].Options.AssociationDefaultRouteTableId" --output text --region $REGION)

aws ec2 create-transit-gateway-route \
--destination-cidr-block $VPC_A_CIDR \
--transit-gateway-route-table-id $TGW_ROUTE_TABLE_ID \
--transit-gateway-attachment-id $TGW_ATTACHMENT_A_ID --region $REGION

aws ec2 create-transit-gateway-route \
--destination-cidr-block $VPC_B_CIDR \
--transit-gateway-route-table-id $TGW_ROUTE_TABLE_ID \
--transit-gateway-attachment-id $TGW_ATTACHMENT_B_ID --region $REGION

#
# Add Static Routes to the Route Tables of Private Routable Subnets in both VPCs
#
echo "Updating routes in VPC route tables"
ROUTE_TABLE1_VPC_A_NAME="EKS-VPC-A-PRIVATE-ROUTE-TABLE-01"
ROUTE_TABLE2_VPC_A_NAME="EKS-VPC-A-PRIVATE-ROUTE-TABLE-02"
ROUTE_TABLE1_VPC_A_ID=$(aws ec2 describe-route-tables --filters Name=tag:Name,Values=$ROUTE_TABLE1_VPC_A_NAME "Name=vpc-id,Values=$VPC_A_ID" --query "RouteTables[].RouteTableId" --output text --region $REGION)
ROUTE_TABLE2_VPC_A_ID=$(aws ec2 describe-route-tables --filters Name=tag:Name,Values=$ROUTE_TABLE2_VPC_A_NAME "Name=vpc-id,Values=$VPC_A_ID" --query "RouteTables[].RouteTableId" --output text --region $REGION)

aws ec2 create-route --destination-cidr-block $VPC_B_CIDR --transit-gateway-id $TGW_ID --route-table-id $ROUTE_TABLE1_VPC_A_ID --region $REGION
aws ec2 create-route --destination-cidr-block $VPC_B_CIDR --transit-gateway-id $TGW_ID --route-table-id $ROUTE_TABLE2_VPC_A_ID --region $REGION

ROUTE_TABLE1_VPC_B_NAME="EKS-VPC-B-PRIVATE-ROUTE-TABLE-01"
ROUTE_TABLE2_VPC_B_NAME="EKS-VPC-B-PRIVATE-ROUTE-TABLE-02"
ROUTE_TABLE1_VPC_B_ID=$(aws ec2 describe-route-tables --filters Name=tag:Name,Values=$ROUTE_TABLE1_VPC_B_NAME "Name=vpc-id,Values=$VPC_B_ID" --query "RouteTables[].RouteTableId" --output text --region $REGION)
ROUTE_TABLE2_VPC_B_ID=$(aws ec2 describe-route-tables --filters Name=tag:Name,Values=$ROUTE_TABLE2_VPC_B_NAME "Name=vpc-id,Values=$VPC_B_ID" --query "RouteTables[].RouteTableId" --output text --region $REGION)

aws ec2 create-route --destination-cidr-block $VPC_A_CIDR --transit-gateway-id $TGW_ID --route-table-id $ROUTE_TABLE1_VPC_B_ID --region $REGION
aws ec2 create-route --destination-cidr-block $VPC_A_CIDR --transit-gateway-id $TGW_ID --route-table-id $ROUTE_TABLE2_VPC_B_ID --region $REGION
