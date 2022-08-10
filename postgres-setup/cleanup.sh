
##!/bin/bash
REGION=us-west-2
DB_SUBNET_GROUP="eks-subnet-group"
DB_CLUSTER="aurora-eks-cluster"
DB_INSTANCE="eks"

#
# Delete the database instance
#
echo "Deleting database instance $DB_INSTANCE"
DB_CLUSTER_ARN=$(aws rds delete-db-instance --skip-final-snapshot \
--db-instance-identifier $DB_INSTANCE \
--query "DBInstance.DBInstanceArn" --output text \
--region $REGION)
sleep 30s
dbInstanceStatus() {
  aws rds describe-db-instances --db-instance-identifier $DB_INSTANCE --query "DBInstances[].DBInstanceStatus" --output text --region $REGION     
}
until [ $(dbInstanceStatus) != "deleting" ]; do
  echo "Waiting for database instance $DB_INSTANCE to be deleted ..."
  sleep 20s
done
echo "Database instance $DB_INSTANCE has been deleted"

#
# Delete the database cluster
#
echo "Deleting database cluster $DB_CLUSTER"
DB_CLUSTER_ARN=$(aws rds delete-db-cluster --skip-final-snapshot \
--db-cluster-identifier $DB_CLUSTER \
--query "DBCluster.DBClusterArn" --output text \
--region $REGION)
sleep 30s
dbClusterStatus() {
    aws rds describe-db-clusters --db-cluster-identifier $DB_CLUSTER --query "DBClusters[].Status" --output text --region $REGION
}
until [ $(dbClusterStatus) != "deleting" ]; do
  echo "Waiting for database cluster $DB_CLUSTER to be deleted ..."
  sleep 20s
done
echo "Database cluster $DB_CLUSTER has been deleted"

#
# Delete the database subnet group
#
echo "Deleting database subnet group $DB_SUBNET_GROUP"
aws rds delete-db-subnet-group --db-subnet-group-name $DB_SUBNET_GROUP --region $REGION