
##!/bin/bash

REGION=us-west-2
DB_SUBNET_GROUP="eks-subnet-group"
DB_CLUSTER="aurora-eks-cluster"
DB_INSTANCE="eks"



#
# Delete the database cluster
#
echo "Deleting database cluster $DB_CLUSTER"
aws rds delete-db-cluster --skip-final-snapshot --db-cluster-identifier $DB_CLUSTER --region $REGION
sleep 30s
dbClusterDeletionStatus() {
    aws rds describe-db-clusters --db-cluster-identifier $DB_CLUSTER --query "DBClusters[].Status" --output text --region $REGION
}
until [ $(dbClusterDeletionStatus) != "deleting" ]; do
  echo "Waiting for database cluster $DB_CLUSTER to be deleted ..."
  sleep 10s
done
echo "Database cluster $DB_CLUSTER has been deleted"

#
# Delete the database subnet group
#
aws rds delete-db-subnet-group --db-subnet-group-name $DB_SUBNET_GROUP --region $REGION