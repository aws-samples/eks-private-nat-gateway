##!/bin/bash
kubectl create ns recommender
kubectl create secret generic postgres-credentials \
--from-literal=POSTGRES_USER=eks \
--from-literal=POSTGRES_PASSWORD=eks \
--from-literal=POSTGRES_DATABASE=amazon \
--from-literal=POSTGRES_HOST=eks.cvd1dap4fpfm.us-west-2.rds.amazonaws.com \
--from-literal=POSTGRES_PORT=5432 \
--from-literal=POSTGRES_TABLEPREFIX=popularity_bucket_  -n recommender




