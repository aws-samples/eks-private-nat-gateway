
##!/bin/bash
REGION=us-west-2

TGW_ID=$(aws ec2 describe-transit-gateways --filters "Name=tag:Name,Values=tgw_ab" --query "TransitGateways[].TransitGatewayId" --output text --region $REGION)
TGW_ATTACHMENT_A_ID=$(aws ec2 describe-transit-gateway-vpc-attachments --filters "Name=tag:Name,Values=tgw_attachment_vpc_a" --query "TransitGatewayVpcAttachments[].TransitGatewayAttachmentId" --output text --region $REGION)
TGW_ATTACHMENT_B_ID=$(aws ec2 describe-transit-gateway-vpc-attachments --filters "Name=tag:Name,Values=tgw_attachment_vpc_b" --query "TransitGatewayVpcAttachments[].TransitGatewayAttachmentId" --output text --region $REGION)

aws ec2 delete-transit-gateway-vpc-attachment --transit-gateway-attachment-id $TGW_ATTACHMENT_A_ID --region $REGION
aws ec2 delete-transit-gateway-vpc-attachment --transit-gateway-attachment-id $TGW_ATTACHMENT_B_ID --region $REGION

tqwAttachmentAStatus() {
  aws ec2 describe-transit-gateway-vpc-attachments --transit-gateway-attachment-ids $TGW_ATTACHMENT_A_ID --query "TransitGatewayVpcAttachments[].State" --output text --region $REGION
}
tqwAttachmentBStatus() {
  aws ec2 describe-transit-gateway-vpc-attachments --transit-gateway-attachment-ids $TGW_ATTACHMENT_B_ID --query "TransitGatewayVpcAttachments[].State" --output text --region $REGION
}
until [ $(tqwAttachmentAStatus) != "deleting" ] || [ $(tqwAttachmentBStatus) != "deleting" ]; do
  echo "Waiting for transit gateway attachments $TGW_ATTACHMENT_A_ID and $TGW_ATTACHMENT_B_ID to be deleted ..."
  sleep 5s
  if [ $(tqwAttachmentAStatus) = "deleted" ] && [ $(tqwAttachmentBStatus) = "deleted" ]; then
    echo "Transit gateway attachments $TGW_ATTACHMENT_A_ID and $TGW_ATTACHMENT_B_ID have been deleted"
    break
  fi
done


aws ec2 delete-transit-gateway --transit-gateway-id $TGW_ID --region $REGION

tgwStatus() {
  aws ec2 describe-transit-gateways --transit-gateway-ids $TGW_ID  --query "TransitGateways[].State" --output text --region $REGION
}
until [ $(tgwStatus) != "deleting" ]; do
  echo "Waiting for transit gateway $TGW_ID to be deleted ..."
  sleep 5s
  if [ $(tgwStatus) = "available" ]; then
    echo "Transit gateway $TGW_ID has been deleted"
    break
  fi
done