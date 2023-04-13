
##!/bin/bash
REGION=us-west-2
ZONE=us-west-2a
VPC_CIDR="192.168.32.0/20"
VPC_NAME="EKS-VPC-B"
SG_NAME="AuroraIngressSecurityGroup"
VPC_ID=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=$VPC_NAME Name=cidr,Values=$VPC_CIDR --query "Vpcs[].VpcId" --output text --region $REGION)
SG_ID=$(aws ec2 describe-security-groups --filters Name=tag:Name,Values=$SG_NAME Name=vpc-id,Values=$VPC_ID --query "SecurityGroups[].GroupId" --output text --region $REGION)
PRIVATE_SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=tag-key,Values=kubernetes.io/role/internal-elb" "Name=vpc-id,Values=$VPC_ID" --query "Subnets[].SubnetId" --output text --region $REGION)

#
# Default values for variables used in setting up Postgres instance
#
DB_SUBNET_GROUP="eks-subnet-group"
DB_CLUSTER="aurora-eks-cluster"
DB_INSTANCE="eks"
DB_ENGINE="aurora-postgresql"
DB_ENGINE_VERSION="11.9"
DB_MASTER_USER="postgres"          # Set master user
DB_MASTER_PASSWORD=""              # Set master password

DB_SUBNET_GROUP_ARN=$(aws rds create-db-subnet-group \
--db-subnet-group-name $DB_SUBNET_GROUP \
--db-subnet-group-description "Aurora PostgreSQL subnet group" \
--subnet-ids $PRIVATE_SUBNET_IDS \
--query "DBSubnetGroup.DBSubnetGroupArn" --output text \
--region $REGION)

echo "Creating database cluster $DB_CLUSTER"
DB_CLUSTER_ARN=$(aws rds create-db-cluster \
--db-cluster-identifier $DB_CLUSTER \
--engine $DB_ENGINE \
--engine-version $DB_ENGINE_VERSION \
--vpc-security-group-ids $SG_ID \
--master-username $DB_MASTER_USER \
--master-user-password $DB_MASTER_PASSWORD \
--db-subnet-group-name $DB_SUBNET_GROUP \
--availability-zone $ZONE \
--query "DBCluster.DBClusterArn" --output text \
--region $REGION)

dbClusterStatus() {
  aws rds describe-db-clusters --db-cluster-identifier $DB_CLUSTER --query "DBClusters[].Status" --output text --region $REGION     
}
until [ $(dbClusterStatus) != "creating" ]; do
  echo "Waiting for database cluster $DB_CLUSTER to be ready ..."
  sleep 10s
  if [ $(dbClusterStatus) = "available" ]; then
    echo "Database cluster $DB_CLUSTER is ready"
    break
  fi
done
    
echo "Creating database instance $DB_INSTANCE. This will take several minutes ..."
DB_INSTANCE_ARN=$(aws rds create-db-instance \
--db-cluster-identifier $DB_CLUSTER \
--db-instance-identifier $DB_INSTANCE \
--engine $DB_ENGINE \
--engine-version $DB_ENGINE_VERSION \
--db-instance-class db.r5.large \
--db-subnet-group-name $DB_SUBNET_GROUP \
--availability-zone $ZONE \
--no-multi-az \
--no-publicly-accessible \
--query "DBInstance.DBInstanceArn" --output text \
--region $REGION)

dbInstanceStatus() {
  aws rds describe-db-instances --db-instance-identifier $DB_INSTANCE --query "DBInstances[].DBInstanceStatus" --output text --region $REGION     
}
until [ $(dbInstanceStatus) != "creating" ]; do
  echo "Waiting for database instance $DB_INSTANCE to be ready ..."
  sleep 30s
  if [ $(dbInstanceStatus) = "available" ]; then
    echo "Database instance $DB_INSTANCE is ready"
    break
  fi
done
